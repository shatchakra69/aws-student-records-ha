'use strict';

// Smoke test: the app boots and the shallow health endpoint returns 200.
// Runs without a database (the /health route never touches the DB), so CI can
// execute it with no MySQL service.
const test = require('node:test');
const assert = require('node:assert');
const app = require('../server');

test('GET /health returns 200 ok', async () => {
  const server = app.listen(0);
  const { port } = server.address();
  try {
    const res = await fetch(`http://127.0.0.1:${port}/health`);
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.strictEqual(body.status, 'ok');
  } finally {
    server.close();
  }
});
