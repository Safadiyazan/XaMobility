// backend/server.js
const express = require('express');
const subdomain = require('express-subdomain');
const path = require('path');
const cors = require('cors');
const { open } = require('sqlite');
const sqlite3 = require('sqlite3');
const bcrypt = require('bcrypt');
const { errorHandler, logRequests } = require('./middleware');
const history = require('connect-history-api-fallback');
const axios = require('axios');
const fs = require('fs');
const app = express();
const PORT = process.env.PORT || 1110;

// Middleware for handling subdomains
// const subdomainMiddleware = subdomain('api'); // Replace 'subdomain' with your desired subdomain

// Use the subdomain middleware
// app.use(subdomainMiddleware);

app.use(cors({ origin: 'http://localhost:1111', credentials: true }));  // Configure cors middleware
app.use(express.json());
app.use(logRequests); // Log incoming requests
// =======================================================================================
// USER & LOGIN & LOGOUT =================================================================
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

// =======================================================================================
// MATLAB Call ===========================================================================
// Running MATLAB on the py (must run the py code first)
app.post('/api/run_matlab_code', async (req, res) => {
    // Perform any necessary cleanup or session handling on the server side
    console.log(`Running MATLAB`);
    try {
        const response = await axios.get('http://127.0.0.1:5000/run_matlab_code');

        if (response.status === 200) {
            console.log('Server MATLAB Result Directory:', response.data.NewJSONDir);

            // Send the expected structure to the frontend
            res.json({ result: response.data.NewJSONDir });
        } else {
            console.error('Error:', response.data.error);
            res.status(response.status).json({ error: response.data.error });
        }
    } catch (error) {
        console.error('Error:', error.message);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// =======================================================================================
// MATLAB Settings =======================================================================
// Endpoint to handle saving settings
app.post('/api/save_settings', async (req, res) => {
    // Extract the settings data from the request body
    const { NewSettings } = req.body;
    console.log(NewSettings)
    const jsonFilePath = path.join(__dirname, 'public', 'NewSettings.json');
    try {
        // Save the settings to a JSON file
        fs.writeFileSync(jsonFilePath, JSON.stringify(NewSettings, null, 2));

        // Send the file path to the frontend
        res.json({ result: jsonFilePath });
    } catch (error) {
        console.error('Error:', error.message);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// app.post('/api/save_vertiports', (req, res) => {
//     const vertiportData = req.body.vertiportData;
//     const filePath = path.join(__dirname, 'public', 'vertiports.json');

//     fs.writeFile(filePath, JSON.stringify(vertiportData, null, 2), (err) => {
//         if (err) {
//             console.error('Error saving vertiport data:', err);
//             res.status(500).json({ message: 'Failed to save vertiport data.' });
//         } else {
//             res.status(200).json({ message: 'Vertiport data saved successfully.' });
//         }
//     });
// });

const filePath = path.join(__dirname, 'public', 'VertiportsSettings.json');

// Reset the file to an empty array when the server starts
fs.writeFile(filePath, JSON.stringify([], null, 2), (err) => {
    if (err) {
        console.error('Error resetting vertiport data:', err);
    } else {
        console.log('Vertiport data reset to empty array.');
    }
});

app.post('/api/save_vertiports', (req, res) => {
    const VertiportData = req.body.VertiportData;

    fs.writeFile(filePath, JSON.stringify(VertiportData, null, 2), (err) => {
        if (err) {
            console.error('Error saving vertiport data:', err);
            res.status(500).json({ message: 'Failed to save vertiport data.' });
        } else {
            res.status(200).json({ message: 'Vertiport data saved successfully.' });
        }
    });
});

// =======================================================================================
// Update dropdown list in simulation data ===============================================
const folderPath = path.join(__dirname, 'public/Outputs'); // Update the path accordingly
app.get('/api/getJsonFiles', (req, res) => {
    fs.readdir(folderPath, (err, files) => {
      if (err) {
        console.error(err);
        res.status(500).json({ error: 'Internal Server Error' });
        return;
      }
  
      const jsonFiles = files.filter(file => file.endsWith('.json'));
      res.json({ files: jsonFiles });
    });
  });
// export { NewJSONDir };
// END  ==================================================================================
// =======================================================================================