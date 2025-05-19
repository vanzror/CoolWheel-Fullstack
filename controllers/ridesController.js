const pool = require('../db');

exports.startRide = async (req, res) => {
  const user_id = req.user.user_id;

  if (!user_id) {
    return res.status(401).json({ error: 'Unauthorized, user_id not found' });
  }

  try {
    const result = await pool.query(
      'INSERT INTO rides (user_id, started_at, is_active) VALUES ($1, CURRENT_TIMESTAMP, true) RETURNING *',
      [user_id]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.endRide = async (req, res) => {
  const user_id = req.user.user_id;
  const rideId = req.params.rideId;

  try {
    const updateResult = await pool.query(
      `UPDATE rides 
       SET ended_at = NOW(), is_active = false 
       WHERE id = $1 AND user_id = $2`,
      [rideId, user_id]
    );

    if (updateResult.rowCount === 0) {
      return res.status(404).json({ error: 'Ride tidak ditemukan atau bukan milik user' });
    }

    res.status(200).json({ message: 'Ride selesai' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getLiveDuration = async (req, res) => {
  const user_id = req.user.user_id;

  try {
    const result = await pool.query(
      `SELECT id, EXTRACT(EPOCH FROM (NOW() - started_at)) AS duration_seconds
       FROM rides
       WHERE user_id = $1 AND ended_at IS NULL
       ORDER BY started_at DESC
       LIMIT 1`,
      [user_id]
    );

    if (result.rows.length === 0) {
      return res.status(400).json({ error: 'Tidak ada ride aktif' });
    }

    const ride_id = result.rows[0].id;
    const durationSeconds = Math.floor(result.rows[0].duration_seconds);
    const durationMinutes = Math.floor(durationSeconds / 60); // ubah ke menit

    const hours = Math.floor(durationSeconds / 3600);
    const minutes = Math.floor((durationSeconds % 3600) / 60);
    const seconds = durationSeconds % 60;

    // Update kolom duration dalam MENIT
    await pool.query(
      `UPDATE rides SET duration = $1 WHERE id = $2`,
      [durationMinutes, ride_id]
    );

    res.json({
      ride_id,
      duration_minutes: durationMinutes,
      formatted: `${hours}h ${minutes}m ${seconds}s`
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
