# Nginx is the only public entry point. Do not expose Gunicorn directly.
bind = '127.0.0.1:5000'
workers = 1
threads = 2
backlog = 512
chdir = '/www/wwwroot/circular/backend'
access_log_format = '%(t)s %(p)s %(h)s "%(r)s" %(s)s %(L)s %(b)s %(f)s" "%(a)s"'
loglevel = 'info'
worker_class = 'sync'
# Local AI inference can take several minutes on a CPU-only VPS.
timeout = 1200
graceful_timeout = 30
keepalive = 5
errorlog = chdir + '/logs/error.log'
accesslog = chdir + '/logs/access.log'
pidfile = chdir + '/logs/circular-py.pid'
