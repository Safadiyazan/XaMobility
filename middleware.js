// middleware.js
const logRequests = (req, res, next) => {
    console.log(`${req.method} ${req.url}`);
    next();
};

const errorHandler = (error, res) => {
    console.error('Error:', error);
    res.status(500).json({ message: 'Internal Server Error' });
};

module.exports = { logRequests, errorHandler };
