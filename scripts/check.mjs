import { runMoon } from './toolchain.mjs';

for (const target of ['wasm-gc', 'js']) {
  runMoon(['check', '--target', target, '--deny-warn'], `check-${target}`);
  runMoon(['test', '--target', target], `test-${target}`);
}
runMoon(['info', '--target', 'wasm-gc'], 'info');
runMoon(['fmt', '--check'], 'fmt');
