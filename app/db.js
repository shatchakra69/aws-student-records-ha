'use strict';

const mysql = require('mysql2/promise');

// Connection settings come entirely from the environment. Nothing is hardcoded
// so the same image runs locally (docker-compose) and on AWS (RDS endpoint +
// credentials injected from Secrets Manager via the EC2 instance role).
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'app',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'student_records',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

const SEED_STUDENTS = [
  ['Ada', 'Lovelace', 'ada.lovelace@ue-germany.de', 'Computer Science', 2023],
  ['Alan', 'Turing', 'alan.turing@ue-germany.de', 'Mathematics', 2022],
  ['Grace', 'Hopper', 'grace.hopper@ue-germany.de', 'Software Engineering', 2024],
];

// Create the table if it does not exist and seed a few rows on first boot.
// This makes a fresh EC2 instance self-provision its schema against RDS without
// a manual migration step. Controlled by RUN_MIGRATIONS (default: on).
async function ensureSchema() {
  if (process.env.RUN_MIGRATIONS === 'false') return;

  await pool.query(`
    CREATE TABLE IF NOT EXISTS students (
      id              INT AUTO_INCREMENT PRIMARY KEY,
      first_name      VARCHAR(100) NOT NULL,
      last_name       VARCHAR(100) NOT NULL,
      email           VARCHAR(255) NOT NULL UNIQUE,
      major           VARCHAR(100),
      enrollment_year INT,
      created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);

  const [rows] = await pool.query('SELECT COUNT(*) AS n FROM students');
  if (rows[0].n === 0) {
    await pool.query(
      'INSERT INTO students (first_name, last_name, email, major, enrollment_year) VALUES ?',
      [SEED_STUDENTS]
    );
  }
}

// Lightweight DB liveness check used by the deep health endpoint.
async function ping() {
  const [rows] = await pool.query('SELECT 1 AS ok');
  return rows[0].ok === 1;
}

module.exports = { pool, ensureSchema, ping };
