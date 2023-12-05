// db-init.js
const sqlite3 = require('sqlite3');
const { open } = require('sqlite');
const bcrypt = require('bcrypt');

(async () => {
  const db = await open({
    filename: './Database.db',
    driver: sqlite3.Database,
  });

  // Define the user table schema
  await db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY,
      username TEXT UNIQUE,
      password TEXT
    );
  `);

  // Insert a sample user with a hashed password
  const passwordHash1 = await bcrypt.hash('SyP@55w0rd!', 10);
  await db.run('INSERT INTO users (username, password) VALUES (?, ?)', ['admin', passwordHash1]);
  const passwordHash2 = await bcrypt.hash('JackHaddad1909!', 10);
  await db.run('INSERT INTO users (username, password) VALUES (?, ?)', ['Jack', passwordHash2]);
  const passwordHash3 = await bcrypt.hash('YazanSafadi1110!', 10);
  await db.run('INSERT INTO users (username, password) VALUES (?, ?)', ['Yazan', passwordHash3]);

  console.log('User database initialized');
})();
