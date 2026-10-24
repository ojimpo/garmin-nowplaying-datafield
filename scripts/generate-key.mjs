import { generateKeyPairSync } from 'node:crypto';
import { mkdirSync, writeFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const directory = new URL('../.local/', import.meta.url);
const output = new URL('developer_key.der', directory);
if (existsSync(output)) {
  throw new Error('A signing key already exists; it will not be overwritten.');
}
mkdirSync(directory, { recursive: true });
const { privateKey } = generateKeyPairSync('rsa', {
  modulusLength: 4096,
  privateKeyEncoding: { type: 'pkcs8', format: 'der' },
  publicKeyEncoding: { type: 'spki', format: 'der' },
});
writeFileSync(output, privateKey, { flag: 'wx', mode: 0o600 });
console.log(`Created local signing key: ${fileURLToPath(output)}`);
