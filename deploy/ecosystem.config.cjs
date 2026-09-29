module.exports = {
  apps: [
    {
      name: "circular-frontend",
      script: "serve",
      cwd: "/www/wwwroot/circular-mgmt/frontend",
      env: {
        PM2_SERVE_PATH: "dist",
        PM2_SERVE_PORT: "3009",
        PM2_SERVE_SPA: "true",
        PM2_SERVE_HOMEPAGE: "./index.html",
      },
      autorestart: true,
      watch: false,
    },
  ],
};
