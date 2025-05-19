const express = require('express');
const router = express.Router();
const statsController = require('../controllers/heartrateController');
const authenticateToken = require('../middleware/authMiddleware');

router.post('/', authenticateToken, statsController.saveHeartrate);

module.exports = router;