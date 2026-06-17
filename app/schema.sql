-- Student Records schema (reference copy).
-- The application also creates this automatically on first boot via db.js
-- (ensureSchema). Kept here so the data model is documented and reviewable.

CREATE DATABASE IF NOT EXISTS student_records;
USE student_records;

CREATE TABLE IF NOT EXISTS students (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  first_name      VARCHAR(100) NOT NULL,
  last_name       VARCHAR(100) NOT NULL,
  email           VARCHAR(255) NOT NULL UNIQUE,
  major           VARCHAR(100),
  enrollment_year INT,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO students (first_name, last_name, email, major, enrollment_year) VALUES
  ('Ada',   'Lovelace', 'ada.lovelace@ue-germany.de', 'Computer Science',     2023),
  ('Alan',  'Turing',   'alan.turing@ue-germany.de',  'Mathematics',          2022),
  ('Grace', 'Hopper',   'grace.hopper@ue-germany.de', 'Software Engineering', 2024);
