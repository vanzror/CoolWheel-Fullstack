const express = require('express');
const router = express.Router();
const usersController = require('../controllers/usersController');
const authenticateToken = require('../middleware/authMiddleware'); 

// Register & Login
router.post('/register', usersController.registerUser);
router.post('/login', usersController.login);
router.post('/logout', authenticateToken, usersController.logout);
module.exports = router;
