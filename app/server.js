'use strict';

require('dotenv').config();

const path = require('path');
const express = require('express');
const { pool, ensureSchema, ping } = require('./db');

const app = express();
const PORT = Number(process.env.PORT || 3000);

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(express.urlencoded({ extended: false }));
app.use(express.static(path.join(__dirname, 'public')));

// --- Health checks -------------------------------------------------------
// Shallow check for the ALB target group: returns 200 as long as the process
// is up. We deliberately do NOT check the database here, otherwise a brief RDS
// hiccup would make the ALB kill every healthy app instance at once.
app.get('/health', (_req, res) => res.status(200).json({ status: 'ok' }));

// Deep check for humans/debugging: also verifies database connectivity.
app.get('/health/db', async (_req, res) => {
  try {
    await ping();
    res.status(200).json({ status: 'ok', db: 'up' });
  } catch (err) {
    res.status(503).json({ status: 'degraded', db: 'down', error: err.code });
  }
});

// Minimal server-side validation shared by create and update.
function validateStudent(body) {
  if (!body.first_name || !body.first_name.trim()) return 'First name is required.';
  if (!body.last_name || !body.last_name.trim()) return 'Last name is required.';
  if (!body.email || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(body.email)) return 'A valid email is required.';
  return null;
}

// --- CRUD routes ---------------------------------------------------------
app.get('/', async (req, res, next) => {
  const q = (req.query.q || '').trim();
  try {
    let students;
    if (q) {
      const like = `%${q}%`;
      [students] = await pool.query(
        `SELECT * FROM students
         WHERE first_name LIKE ? OR last_name LIKE ? OR email LIKE ? OR major LIKE ?
         ORDER BY id DESC`,
        [like, like, like, like]
      );
    } else {
      [students] = await pool.query('SELECT * FROM students ORDER BY id DESC');
    }
    res.render('index', { students, q, msg: req.query.msg || null });
  } catch (err) {
    next(err);
  }
});

app.get('/students/new', (_req, res) => {
  res.render('new', { error: null });
});

app.post('/students', async (req, res, next) => {
  const { first_name, last_name, email, major, enrollment_year } = req.body;
  const error = validateStudent(req.body);
  if (error) return res.status(400).render('new', { error });
  try {
    await pool.query(
      'INSERT INTO students (first_name, last_name, email, major, enrollment_year) VALUES (?, ?, ?, ?, ?)',
      [first_name, last_name, email, major || null, enrollment_year || null]
    );
    res.redirect('/?msg=created');
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(400).render('new', { error: 'A student with that email already exists.' });
    }
    next(err);
  }
});

app.get('/students/:id/edit', async (req, res, next) => {
  try {
    const [rows] = await pool.query('SELECT * FROM students WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).send('Student not found');
    res.render('edit', { student: rows[0], error: null });
  } catch (err) {
    next(err);
  }
});

app.post('/students/:id', async (req, res, next) => {
  const { first_name, last_name, email, major, enrollment_year } = req.body;
  const error = validateStudent(req.body);
  if (error) {
    return res.status(400).render('edit', { student: { id: req.params.id, ...req.body }, error });
  }
  try {
    await pool.query(
      'UPDATE students SET first_name = ?, last_name = ?, email = ?, major = ?, enrollment_year = ? WHERE id = ?',
      [first_name, last_name, email, major || null, enrollment_year || null, req.params.id]
    );
    res.redirect('/?msg=updated');
  } catch (err) {
    next(err);
  }
});

app.post('/students/:id/delete', async (req, res, next) => {
  try {
    await pool.query('DELETE FROM students WHERE id = ?', [req.params.id]);
    res.redirect('/?msg=deleted');
  } catch (err) {
    next(err);
  }
});

// --- Error handler -------------------------------------------------------
// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).send('Internal Server Error');
});

// Only start listening when run directly (so tests can import `app`).
if (require.main === module) {
  ensureSchema()
    .then(() => {
      app.listen(PORT, '0.0.0.0', () => {
        console.log(`Student Records app listening on port ${PORT}`);
      });
    })
    .catch((err) => {
      console.error('Failed to initialise database schema:', err);
      process.exit(1);
    });
}

module.exports = app;
