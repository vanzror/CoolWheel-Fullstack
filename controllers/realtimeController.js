const pool = require('../db');
const { calculateORSMDistance } = require('../utils/calculateDistance');

exports.realtimeStats= async (req, res) => {
  const { ride_id } = req.body;
  if (!ride_id) return res.status(400).json({ error: 'ride_id is required' });

  try {
    const gpsResult = await pool.query(
      'SELECT lat, lon, timestamp FROM gps_data WHERE ride_id = $1 ORDER BY timestamp ASC',
      [ride_id]
    );
    const gpsData = gpsResult.rows;
    if (gpsData.length < 2) {
      return res.status(400).json({ error: 'Not enough GPS points to calculate distance' });
    }

    // Gunakan OSRM
    const totalDistance = await calculateORSMDistance(gpsData);

    const start = new Date(gpsData[0].timestamp);
    const end = new Date(gpsData[gpsData.length - 1].timestamp);
    const durationSeconds = Math.floor((end - start) / 1000);

    const pace = totalDistance > 0 ? durationSeconds / totalDistance : 0;
    const calories = totalDistance * 40; // asumsi

    const heartRate = 120; // bisa diganti kalau sudah ada sensor

    await pool.query(
      `INSERT INTO realtime_stats (ride_id, timestamp, distance_km, duration_seconds, calories, pace, heart_rate)
       VALUES ($1, NOW(), $2, $3, $4, $5, $6)`,
      [ride_id, totalDistance, durationSeconds, calories, pace, heartRate]
    );

    res.json({
      ride_id,
      distance_km: totalDistance,
      duration_seconds: durationSeconds,
      calories,
      pace,
      heart_rate: heartRate
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
