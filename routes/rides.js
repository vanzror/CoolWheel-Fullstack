const express = require('express');
const router = express.Router();
const ridesController = require('../controllers/ridesController');
const authenticateToken = require('../middleware/authMiddleware');

router.post('/start', authenticateToken, ridesController.startRide);
router.post('/end', authenticateToken, ridesController.endRide);
router.get('/duration/live', authenticateToken, ridesController.getLiveDuration);


module.exports = router;
