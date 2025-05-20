const express = require('express');
const router = express.Router();
const caloriesController = require('../controllers/caloriesController');
const authenticateToken = require('../middleware/authMiddleware');

// Endpoint untuk menghitung dan menyimpan kalori
router.post('/calculate', authenticateToken, caloriesController.calculateAndStoreCalories);

module.exports = router;
