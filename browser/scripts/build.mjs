import { mkdirSync, readFileSync, writeFileSync } from "node:fs";

mkdirSync("dist", { recursive: true });
const source = readFileSync("src/index.js", "utf8");
writeFileSync("dist/bundle.js", source, "utf8");
console.log("browser build: dist/bundle.js");
