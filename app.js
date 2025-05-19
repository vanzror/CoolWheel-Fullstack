const express = require('express');
const app = express();
require('dotenv').config();
const port = process.env.PORT || 3000;

app.use(express.json());

// Routes
const usersRoutes = require('./routes/users');
const gpsRoutes = require('./routes/gps');
const realtimeRoutes = require('./routes/realtime');
const ridesRoutes = require('./routes/rides');
const heartrateRoutes = require ('./routes/heartrate')

app.use('/api/users', usersRoutes);
app.use('/api/gps', gpsRoutes);
app.use('/api/realtime', realtimeRoutes);
app.use('/api/rides', ridesRoutes);
app.use ('/api/heartrate', heartrateRoutes)

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
