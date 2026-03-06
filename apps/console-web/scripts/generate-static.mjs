import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { renderConsoleShell } from "../dist/main.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const distDir = resolve(__dirname, "../dist");
const outputFile = resolve(distDir, "index.html");

mkdirSync(distDir, { recursive: true });
writeFileSync(outputFile, renderConsoleShell("en"), "utf8");
