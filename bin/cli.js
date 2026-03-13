#!/usr/bin/env node

const { execSync } = require("child_process");
const path = require("path");

const packageRoot = path.resolve(__dirname, "..");
const args = process.argv.slice(2);

const isDiagnose = args.includes("--diagnose");
const scriptName = isDiagnose ? "diagnose.sh" : "install.sh";
const scriptPath = path.join(packageRoot, scriptName);
const passArgs = args.filter((a) => a !== "--diagnose").join(" ");

try {
  execSync(`bash "${scriptPath}" ${passArgs}`, {
    stdio: "inherit",
    env: { ...process.env, PACKAGE_ROOT: packageRoot },
  });
} catch (err) {
  process.exit(err.status || 1);
}
