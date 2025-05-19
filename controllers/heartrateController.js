const pool = require('../db');

exports.saveHeartrate = async (req, res) => {
  const user_id = req.user.user_id;
  const { bpm } = req.body;

  if (!bpm) {
    return res.status(400).json({ error: 'BPM tidak boleh kosong' });
  }

  try {
    const rideResult = await pool.query(
      `SELECT id FROM rides WHERE user_id = $1 AND ended_at IS NULL ORDER BY started_at DESC LIMIT 1`,
      [user_id]
    );

    if (rideResult.rows.length === 0) {
      return res.status(400).json({ error: 'Belum mulai ride' });
    }

    const ride_id = rideResult.rows[0].id;

    // 1. Simpan ke heartrates
    const result = await pool.query(
      `INSERT INTO heartrates (ride_id, bpm, recorded_at)
       VALUES ($1, $2, NOW()) RETURNING *`,
      [ride_id, bpm]
    );

    // 2. Update last_heartrate di realtime_stats
    await pool.query(
      `UPDATE realtime_stats
       SET last_heartrate = $1, updated_at = NOW()
       WHERE ride_id = $2`,
      [bpm, ride_id]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
