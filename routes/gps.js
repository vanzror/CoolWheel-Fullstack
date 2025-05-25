const express = require('express');
const router = express.Router();
const authenticateToken = require('../middleware/authMiddleware');
const {
  saveGpsData,
  getGpsDataByUser,
  getDistanceByUser
} = require('../controllers/gpsController');

// ✅ Middleware diletakkan sebagai parameter sebelum handler-nya
router.post('/', authenticateToken, saveGpsData);
router.get('/', authenticateToken, getGpsDataByUser);
router.get('/distance', authenticateToken, getDistanceByUser);

module.exports = router;
