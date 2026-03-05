import { spawnSync } from "node:child_process";

const files = ["src/index.js", "test/smoke.test.js", "scripts/build.mjs", "scripts/lint.mjs"];

for (const file of files) {
  const result = spawnSync(process.execPath, ["--check", file], { stdio: "inherit" });
  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

console.log("browser lint: OK");
