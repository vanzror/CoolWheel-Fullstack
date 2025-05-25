const pool = require('../db');

exports.saveCoolerTemp = async (req, res) => {
  const user_id = req.user.user_id;
  const { temperature } = req.body;

  if (temperature === undefined) {
    return res.status(400).json({ error: 'Temperature tidak boleh kosong' });
  }

  try {
    // 1. Cari ride aktif
    const rideResult = await pool.query(
      `SELECT id FROM rides 
       WHERE user_id = $1 AND ended_at IS NULL 
       ORDER BY started_at DESC 
       LIMIT 1`,
      [user_id]
    );

    if (rideResult.rows.length === 0) {
      return res.status(400).json({ error: 'Belum mulai ride' });
    }

    const ride_id = rideResult.rows[0].id;

    // 2. Simpan data suhu ke tabel coolertemp
    const result = await pool.query(
      `INSERT INTO coolertemp (ride_id, temperature, recorded_at)
       VALUES ($1, $2, NOW()) RETURNING *`,
      [ride_id, temperature]
    );

    // 3. Update suhu terakhir ke realtime_stats
    await pool.query(
      `UPDATE realtime_stats 
       SET last_temperature = $1, updated_at = NOW() 
       WHERE ride_id = $2`,
      [temperature, ride_id]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
