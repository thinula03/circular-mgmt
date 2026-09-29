# Ubuntu 24.04 + aaPanel deployment

This deployment uses:

- aaPanel Nginx for HTTPS and the public domain
- Supervisor for the Flask/Gunicorn backend on `127.0.0.1:5000`
- PM2 for the compiled React SPA on port `3000`
- the existing MySQL database on `127.0.0.1:3306`
- optional Ollama for local summaries and chat on `127.0.0.1:11434`

The examples use `/www/wwwroot/circular` and the Linux user `www`. If the aaPanel
site uses another path or user, change those values in every deployment file.

## 1. Create the aaPanel site

In **Website > Add site**, add the real domain. Choose **Static** (not PHP), enable
SSL, issue a Let's Encrypt certificate, and force HTTPS. The site root should be:

```text
/www/wwwroot/circular
```

Upload or clone this repository into that directory. Do not upload local virtual
environments, `node_modules`, `.env`, logs, uploads, or model cache files.

## 2. Install server packages

Open aaPanel Terminal as root:

```bash
apt update
apt install -y python3 python3-venv python3-dev build-essential pkg-config \
  default-libmysqlclient-dev tesseract-ocr poppler-utils curl
```

Install Node.js 20 or 22 LTS using aaPanel's Node Manager, then confirm:

```bash
node --version
npm --version
npm install -g pm2@latest
```

Install the **Supervisor Manager** from aaPanel's App Store if it is not already
installed.

## 3. Configure the existing MySQL database

Do not run `seed.py` against the working database. If the database is on this VPS,
create a least-privilege application account in aaPanel's database manager (or in
MySQL) and grant it access only to `circular_management`.

If the working database must be moved, export it from the source and import it in
aaPanel before starting the application. Confirm that migrations 001 through 008
are already represented in the imported schema. Do not blindly rerun the ALTER
migrations: they are not all safe to run twice.

The final database URL has this form:

```text
mysql+pymysql://USER:URL_ENCODED_PASSWORD@127.0.0.1:3306/circular_management?charset=utf8mb4
```

Characters such as `@`, `:`, `/`, `#`, and `%` in the password must be URL-encoded.

## 4. Create the backend environment

```bash
cd /www/wwwroot/circular/backend
python3 -m venv .venv
.venv/bin/python -m pip install --upgrade pip wheel
.venv/bin/pip install -r requirements.txt
.venv/bin/python -m spacy download en_core_web_sm
mkdir -p logs uploads model_cache
cp ../deploy/backend.env.example .env
```

Edit `.env` and replace the domain, database credentials, bank name, and both
secrets. Generate two different secrets with:

```bash
openssl rand -hex 48
```

Protect runtime data and give the aaPanel web user ownership:

```bash
chown -R www:www /www/wwwroot/circular
chmod 600 /www/wwwroot/circular/backend/.env
chmod 750 /www/wwwroot/circular/backend/uploads
```

## 5. Prepare the local AI models

The complete transformer cache needs several gigabytes of disk and considerable
RAM. Download it once as the same `www` user that runs the application:

```bash
cd /www/wwwroot/circular/backend
sudo -u www .venv/bin/python download_models.py
```

Install Ollama only if local generated summaries/chat are required, then pull the
models named in `.env`:

```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3.2:3b
ollama pull llama3.2:1b
systemctl enable --now ollama
curl http://127.0.0.1:11434/api/tags
```

On a small VPS, set `USE_LLM_SUMMARY=false` and `USE_LLM_CHAT=false` first, prove
the web application works, and enable AI only after checking available RAM and
disk. Keep port 11434 private.

## 6. Build and start the frontend with PM2

```bash
cd /www/wwwroot/circular/frontend
npm ci
npm run build
sudo -u www -H pm2 start /www/wwwroot/circular/deploy/ecosystem.config.cjs
sudo -u www -H pm2 save
pm2 startup systemd -u www --hp /home/www
```

Run the exact command printed by `pm2 startup`, then run `sudo -u www -H pm2 save`
again. If `/home/www` does not exist, create it and assign it to `www`, or use the
actual home shown by `getent passwd www`.

Verify locally:

```bash
curl -I http://127.0.0.1:3000
sudo -u www -H pm2 status
```

## 7. Start the backend with Supervisor

In aaPanel **Supervisor Manager**, add a daemon named `circular-backend` using:

```text
Run directory: /www/wwwroot/circular/backend
Start command: /www/wwwroot/circular/backend/.venv/bin/gunicorn -c /www/wwwroot/circular/backend/gunicorn_conf.py run:app
Run user: www
```

Alternatively, copy `deploy/supervisor-circular.conf` into Supervisor's active
configuration directory, reload Supervisor, and start `circular-backend`. The
exact directory differs between aaPanel Supervisor plugin versions, so using its
UI is safer.

Verify that the backend is running with the MySQL configuration:

```bash
curl -i http://127.0.0.1:5000/health
tail -n 100 /www/wwwroot/circular/backend/logs/supervisor.log
```

The health response must report `status: ok` and database `mysql`. The login API
test in the final-check section is what proves the application can actually query
the database.

## 8. Configure aaPanel Nginx

Open the site's **Config** page. Inside its HTTPS `server { ... }` block, add the
three location blocks from `deploy/nginx-circular.conf`. Remove conflicting PHP,
static-root, or existing `location /` rules. Keep aaPanel's SSL certificate lines.

Test and reload:

```bash
nginx -t
systemctl reload nginx
```

Only ports 22, 80, and 443 should be public. Do not open 3000, 5000, 3306, or
11434 in aaPanel Security or UFW.

## 9. Final checks

```bash
curl -I https://YOUR_DOMAIN/
curl -i https://YOUR_DOMAIN/health
curl -i https://YOUR_DOMAIN/api/auth/login \
  -H 'Content-Type: application/json' \
  --data '{"username":"YOUR_REAL_USER","password":"YOUR_REAL_PASSWORD"}'
```

Also test in a browser: login, refresh a nested route, upload a real PDF, generate
a summary, open chat, and verify an existing user can see expected circulars.

## Updating later

Back up the database and uploaded PDFs before updating. Then:

```bash
cd /www/wwwroot/circular
git pull
backend/.venv/bin/pip install -r backend/requirements.txt
cd frontend && npm ci && npm run build
sudo -u www -H pm2 restart circular-frontend
```

Restart `circular-backend` from aaPanel Supervisor Manager. Apply only new,
reviewed database migrations; never rerun every migration automatically against
production.

## Useful diagnostics

```bash
sudo -u www -H pm2 logs circular-frontend --lines 100
supervisorctl status
ss -lntp | grep -E ':(3000|5000|3306|11434)'
tail -n 100 /www/wwwroot/circular/backend/logs/error.log
tail -n 100 /www/wwwroot/circular/backend/logs/access.log
```
