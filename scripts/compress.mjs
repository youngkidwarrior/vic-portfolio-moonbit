import fs from 'node:fs';
import path from 'node:path';
import { brotliCompressSync, gzipSync, constants } from 'node:zlib';

export function compressAssets(directory) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const file = path.join(directory, entry.name);
    if (entry.isDirectory()) { compressAssets(file); continue; }
    if (!/\.(html|css|js|json|svg|wasm)$/.test(file)) continue;
    const bytes = fs.readFileSync(file);
    if (bytes.length < 1024) continue;
    fs.writeFileSync(`${file}.br`, brotliCompressSync(bytes, { params: { [constants.BROTLI_PARAM_QUALITY]: 9 } }));
    fs.writeFileSync(`${file}.gz`, gzipSync(bytes, { level: 9 }));
  }
}
