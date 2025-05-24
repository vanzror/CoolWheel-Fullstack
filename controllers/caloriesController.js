const pool = require('../db');
const { calculateCalories } = require('../utils/calculateCalories');

exports.calculateAndStoreCalories = async (req, res) => {
  const user_id = req.user.user_id;

  try {
    // Ambil ride aktif
    const rideResult = await pool.query(
      `SELECT id, EXTRACT(EPOCH FROM (NOW() - started_at)) / 60 AS duration_minutes
       FROM rides WHERE user_id = $1 AND ended_at IS NULL
       ORDER BY started_at DESC LIMIT 1`,
      [user_id]
    );

    if (rideResult.rows.length === 0) {
      return res.status(400).json({ error: 'Tidak ada ride aktif' });
    }

    const ride = rideResult.rows[0];
    const ride_id = ride.id;
    const durationMinutes = ride.duration_minutes;

    // Ambil berat badan user
    const userResult = await pool.query(
      `SELECT weight FROM users WHERE id = $1`,
      [user_id]
    );

    if (userResult.rows.length === 0) {
      return res.status(400).json({ error: 'Data pengguna tidak ditemukan' });
    }

    const weight = userResult.rows[0].weight;

    // Ambil pace dan heartrate dari realtime_stats
    const statsResult = await pool.query(
      `SELECT pace, last_heartrate FROM realtime_stats WHERE ride_id = $1`,
      [ride_id]
    );

    if (statsResult.rows.length === 0) {
      return res.status(400).json({ error: 'Data realtime_stats tidak ditemukan' });
    }

    const { pace, last_heartrate } = statsResult.rows[0];

    // Hitung kalori
    const calories = calculateCalories(weight, pace, last_heartrate, durationMinutes);

    // Simpan ke realtime_stats
    await pool.query(
      `UPDATE realtime_stats SET calories = $1, updated_at = NOW() WHERE ride_id = $2`,
      [calories, ride_id]
    );

    res.json({ ride_id, calories, pace });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
