// backend/server.js
const express = require('express');
const path = require('path');
const cors = require('cors');
const { open } = require('sqlite');
const sqlite3 = require('sqlite3');
const bcrypt = require('bcrypt');
const { errorHandler, logRequests } = require('./middleware');
const history = require('connect-history-api-fallback');
const axios = require('axios');
const app = express();
const PORT = process.env.PORT || 1110;
app.use(cors({ origin: 'http://localhost:8080', credentials: true }));  // Configure cors middleware
app.use(express.json());
app.use(logRequests); // Log incoming requests


// -----------------------------------------------------------
// USER & LOGIN & LOGOUT
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

app.use(history());
app.use(express.static(path.join(__dirname, 'public')));

// Handle other routes
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname + '/index.html'));
});

app.listen(PORT, () => {
    console.log(`Server is running on port http://localhost:${PORT}/`);
});

// -----------------------------------------------------------
// Running MATLAB on the py (must run the py code first)
app.post('/run_matlab_code', (req, res) => {
    // Perform any necessary cleanup or session handling on the server side
    console.log(`Running MATLAB`);
    const runMatlabCode = async () => {
        try {
          const response = await axios.get('http://127.0.0.1:5000/run_matlab_code');
          
          if (response.status === 200) {
            console.log('MATLAB Result:', response.data.result);
          } else {
            console.error('1 Error:', response.data.error);
          }
        } catch (error) {
          console.error('2 Error:', error.message);
        }
      };
      
      // Call the function to run MATLAB code
      runMatlabCode();
});

// -----------------------------------------------------------
// Read the JSON file
const fs = require('fs');
/* app.get('/data', (req, res) => {
    fs.readFile('./public/LAATSimData/SimOutput_ObjAircraft.json', 'utf8', (err, data) => {
        if (err) {
            console.error(err);
            res.status(500).json({ error: 'Error reading JSON file' });
        } else {
            const jsonData = JSON.parse(data);
            res.json(jsonData);
        }
    });
}); */
app.get('/data', (req, res) => {
    const selectedFilename = req.query.filename || 'SimOutput_ObjAircraft.json';
    const filePath = `./public/LAATSimData/${selectedFilename}`;

    fs.readFile(filePath, 'utf8', (err, data) => {
        if (err) {
            console.error(err);
            res.status(500).json({ error: 'Error reading JSON file' });
        } else {
            const jsonData = JSON.parse(data);
            res.json(jsonData);
        }
    });
});

// ... (other routes)
