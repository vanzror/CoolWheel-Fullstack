const express = require('express');
const router = express.Router();
const statsController = require('../controllers/realtimeController');

router.post('/', statsController.realtimeStats);

module.exports = router;
