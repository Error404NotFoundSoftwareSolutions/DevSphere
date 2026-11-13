// Plays the VS Code guide extension: finds the worker's session for a lab folder, connects with the extension's own
// compiled client, asks for the lab state and checks the answer. Used by tools/windows_e2e (Windows CI).
// Usage: node client.js <extension dist folder> <lab folder>
'use strict';
const path = require('node:path');
const [, , dist, labRoot] = process.argv;
const { defaultRuntimeDir, discoverSession } = require(path.join(dist, 'src', 'host', 'session.js'));
const { ChannelClient } = require(path.join(dist, 'src', 'host', 'channel.js'));

(async () => {
  const dir = defaultRuntimeDir();
  const session = discoverSession(labRoot, dir);
  if (!session) { console.error(`no session found for ${labRoot} in ${dir}`); process.exit(3); }
  console.log(`session found: ${session.labId} at ${session.socketPath}`);
  const client = new ChannelClient(session, '0.0.0-e2e');
  const events = [];
  client.onEvent((e) => events.push(e));
  await client.connect();
  console.log('connected and welcomed');
  client.send({ type: 'getLabState' });
  const end = Date.now() + 5000;
  while (!events.some((e) => e.type === 'labState') && Date.now() < end) await new Promise((r) => setTimeout(r, 50));
  const state = events.find((e) => e.type === 'labState');
  client.close();
  if (!state) { console.error('no labState came back'); process.exit(4); }
  console.log(`labState received for ${state.labId ?? session.labId}`);
})().catch((e) => { console.error(`FAILED: ${e && e.message ? e.message : e}`); process.exit(5); });
