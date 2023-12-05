// backend/server.js
const express = require('express');
const cors = require('cors');
const { open } = require('sqlite');
const sqlite3 = require('sqlite3');
const bcrypt = require('bcrypt');
const { errorHandler, logRequests } = require('./middleware');

const app = express();
const PORT = process.env.PORT || 1110;

app.use(cors({ origin: 'http://localhost:8080', credentials: true }));  // Configure cors middleware
app.use(express.json());
app.use(logRequests); // Log incoming requests

// Connect to SQLite database
const dbPromise = open({
    filename: './Database.db',
    driver: sqlite3.Database,
});

// User registration route
app.post('/api/register', async (req, res) => {
    try {
        const { username, password } = req.body;

        // Hash the password before storing it
        const passwordHash = await bcrypt.hash(password, 10);

        const db = await dbPromise;
        await db.run('INSERT INTO users (username, password) VALUES (?, ?)', [username, passwordHash]);

        res.json({ message: 'User registered successfully!' });
    } catch (error) {
        errorHandler(error, res);
    }
});

// User login route
app.post('/api/login', async (req, res) => {
    try {
        const { username, password } = req.body;

        const db = await dbPromise;
        const user = await db.get('SELECT * FROM users WHERE username = ?', [username]);

        if (!user || !(await bcrypt.compare(password, user.password))) {
            return res.status(401).json({ message: 'Invalid username or password' });
        }

        res.json({ message: 'Login successful!', username: user.username });
    } catch (error) {
        errorHandler(error, res);
    }
});

// User logout route
app.post('/api/logout', (req, res) => {
    // Perform any necessary cleanup or session handling on the server side

    res.clearCookie('SESSION_ID'); // If using cookies, clear the session cookie

    res.status(200).json({ message: 'Logout successful!' });
});



app.listen(PORT, () => {
    console.log(`Server is running on port http://localhost:${PORT}/`);
});

// ... (other routes)
