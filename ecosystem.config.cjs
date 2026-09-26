const fs = require("node:fs");
const path = require("node:path");

function loadDeployConfig() {
  const file = path.join(__dirname, "deploy/config.env");
  const out = {};
  for (const raw of fs.readFileSync(file, "utf8").split("\n")) {
    const line = raw.trim();
    if (!line || line.startsWith("#")) continue;
    const i = line.indexOf("=");
    if (i === -1) continue;
    out[line.slice(0, i)] = line.slice(i + 1);
  }
  return out;
}

const cfg = loadDeployConfig();
const port = cfg.PORT || "38471";
const host = cfg.HOST || "127.0.0.1";

module.exports = {
  apps: [
    {
      name: cfg.APP_NAME || "sergeybondarenko",
      cwd: __dirname,
      script: ".output/server/index.mjs",
      interpreter: process.env.NODE_BIN || "node",
      instances: 1,
      exec_mode: "fork",
      autorestart: true,
      max_restarts: 10,
      min_uptime: "5s",
      env: {
        NODE_ENV: "production",
        HOST: host,
        PORT: port,
        NITRO_HOST: host,
        NITRO_PORT: port,
        VITE_AUTH_ENABLED: "false",
      },
    },
  ],
};
