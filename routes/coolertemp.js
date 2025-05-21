const express = require('express');
const router = express.Router();
const coolertempController = require('../controllers/coolerController');
const authenticateToken = require('../middleware/authMiddleware');

router.post('/temp', authenticateToken, coolertempController.saveCoolerTemp);

module.exports = router;