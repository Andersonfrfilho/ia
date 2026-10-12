// Indexa projetos no SocratiCode falando direto com o servidor MCP, com espera de verdade.
// Uso (no Ubuntu, Node no PATH):  node socraticode-index.mjs <pasta-base> <projeto> [<projeto>...]
// Ex.:  node socraticode-index.mjs /mnt/c/Users/ander/Documentos/personal quickcart transportada
// Lê o bloco env de ~/.claude/settings.json (QDRANT_URL etc.). Retoma de onde parou se já houver índice.
import { spawn } from 'node:child_process';
import readline from 'node:readline';
import fs from 'node:fs';
import os from 'node:os';

const [base, ...projects] = process.argv.slice(2);
if (!base || projects.length === 0) {
  console.error('uso: node socraticode-index.mjs <pasta-base> <projeto> [<projeto>...]');
  process.exit(1);
}
const env = JSON.parse(fs.readFileSync(`${os.homedir()}/.claude/settings.json`, 'utf8')).env ?? {};
const child = spawn('npx', ['-y', '--prefer-online', 'socraticode@latest'], {
  env: { ...process.env, ...env },
  stdio: ['pipe', 'pipe', 'inherit'],
});
const pending = new Map();
let nextId = 0;
readline.createInterface({ input: child.stdout }).on('line', (line) => {
  try {
    const msg = JSON.parse(line);
    pending.get(msg.id)?.(msg);
    pending.delete(msg.id);
  } catch {}
});
const rpc = (method, params) =>
  new Promise((resolve) => {
    const id = ++nextId;
    pending.set(id, resolve);
    child.stdin.write(`${JSON.stringify({ jsonrpc: '2.0', id, method, params })}\n`);
  });
const call = async (name, args) => {
  const r = await rpc('tools/call', { name, arguments: args });
  return (r.result?.content ?? []).map((c) => c.text).join('\n') || JSON.stringify(r.error ?? r);
};
const log = (m) => console.log(`[${new Date().toTimeString().slice(0, 8)}] ${m}`);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

await rpc('initialize', { protocolVersion: '2024-11-05', capabilities: {}, clientInfo: { name: 'idx', version: '1' } });
child.stdin.write(`${JSON.stringify({ jsonrpc: '2.0', method: 'notifications/initialized', params: {} })}\n`);

for (const name of projects) {
  const projectPath = `${base}/${name}`;
  log(`===== ${name} =====`);
  log((await call('codebase_index', { projectPath })).split('\n')[0]);
  let quiet = 0;
  let last = '';
  for (let i = 0; i < 720 && quiet < 2; i++) {
    await sleep(20_000);
    last = await call('codebase_status', { projectPath });
    const busy = /in progress|building|embedding|scanning|indexing now|running/i.test(last) && !/completed|up to date/i.test(last.split('\n')[0] ?? '');
    quiet = busy ? 0 : quiet + 1;
  }
  log(`FIM ${name}:\n${last}`);
}
child.kill();
process.exit(0);
