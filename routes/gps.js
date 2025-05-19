const express = require('express');
const router = express.Router();
const authenticateToken = require('../middleware/authMiddleware');
const {
  saveGpsData,
  getGpsDataByUser,
  getDistanceByUser
} = require('../controllers/gpsController');

// ✅ Middleware diletakkan sebagai parameter sebelum handler-nya
router.post('/gps', authenticateToken, saveGpsData);
router.get('/gps', authenticateToken, getGpsDataByUser);
router.get('/gps/distance', authenticateToken, getDistanceByUser);

module.exports = router;
