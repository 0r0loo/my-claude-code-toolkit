#!/usr/bin/env node

const { execSync } = require("child_process");
const path = require("path");

const packageRoot = path.resolve(__dirname, "..");
const installScript = path.join(packageRoot, "install.sh");

const args = process.argv.slice(2).join(" ");

try {
  execSync(`bash "${installScript}" ${args}`, {
    stdio: "inherit",
    env: { ...process.env, PACKAGE_ROOT: packageRoot },
  });
} catch (err) {
  process.exit(err.status || 1);
}
