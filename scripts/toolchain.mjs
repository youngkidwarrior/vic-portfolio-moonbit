import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

export const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const localMoonHome = path.resolve(root, '../.tools/moon');
export const moonHome = process.env.MOON_HOME || localMoonHome;
export const moon = path.join(moonHome, 'bin/moon');
export const env = { ...process.env, MOON_HOME: moonHome, PATH: `${moonHome}/bin:${process.env.PATH}` };

export function runMoon(args, label) {
  if (!fs.existsSync(moon)) throw new Error(`MoonBit compiler missing: ${moon}. Set MOON_HOME to an installed toolchain.`);
  fs.mkdirSync(path.join(root, 'evidence/checks'), { recursive: true });
  const result = spawnSync(moon, args, { cwd: root, env, encoding: 'utf8', timeout: 120000 });
  fs.writeFileSync(path.join(root, `evidence/checks/${label}.log`), `${result.stdout || ''}${result.stderr || ''}`);
  if (result.stdout) process.stdout.write(result.stdout);
  if (result.stderr) process.stderr.write(result.stderr);
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error(`moon ${args.join(' ')} exited ${result.status}`);
}
