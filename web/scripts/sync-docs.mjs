import fs from "node:fs";
import path from "node:path";

function ensureFrontmatter(md) {
  if (md.startsWith('---\n')) {
    const match = md.match(/^---\n([\s\S]*?)\n---\n/);
    if (!match) return md;
    if (/\nhead\s*:/.test(match[1])) return md;

    const updated = match[0].replace(/\n---\n$/, "\nhead: []\n---\n");
    return updated + md.slice(match[0].length);
  }

  const firstHeading = md.match(/^#\s+(.+)\s*$/m);
  const title = firstHeading?.[1]?.trim() ?? "Documentación";
  const body = firstHeading ? md.replace(/^#\s+.+\s*\n?/, "") : md;

  return `---\ntitle: "${title.replaceAll('"', '\\"')}"\nhead: []\n---\n\n` + body;
}

function copyDir(src, dest) {
  fs.mkdirSync(dest, { recursive: true });
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    const s = path.join(src, entry.name);
    const d = path.join(dest, entry.name);

    if (entry.isDirectory()) {
      copyDir(s, d);
      continue;
    }

    if (entry.isFile() && entry.name.endsWith(".md")) {
      const md = fs.readFileSync(s, "utf8");
      fs.writeFileSync(d, ensureFrontmatter(md), "utf8");
    } else {
      fs.copyFileSync(s, d);
    }
  }
}

const SRC = path.resolve("../docs");
const COLLECTION_ROOT = path.resolve("src/content/docs");
const DEST = path.resolve("src/content/docs/docs"); // para /docs/...

fs.rmSync(COLLECTION_ROOT, { recursive: true, force: true });
copyDir(SRC, DEST);

console.log(`Synced docs: ${SRC} -> ${DEST}`);
