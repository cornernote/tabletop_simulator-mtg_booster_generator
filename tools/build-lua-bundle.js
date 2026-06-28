const fs = require("fs");
const path = require("path");
let luabundle;

try {
  luabundle = require("luabundle");
} catch {
  luabundle = require("../.codex_deps/node_modules/luabundle");
}

const root = path.resolve(__dirname, "..");
const input = path.join(root, "src", "main.lua");
const output = path.join(root, "lua", "booster-generator.lua");

const bundled = luabundle.bundle(input, {
  force: true,
  luaVersion: "5.2",
  metadata: true,
  paths: [path.join(root, "src", "?.lua")],
  rootModuleName: "__root",
});

fs.writeFileSync(output, bundled + "\n", "utf8");
console.log(`Bundled ${path.relative(root, input)} -> ${path.relative(root, output)}`);
