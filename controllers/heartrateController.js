const pool = require('../db');
const twilio = require('twilio');
const client = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);

exports.saveHeartrate = async (req, res) => {
  const user_id = req.user.user_id;
  const { bpm } = req.body;

  if (!bpm) {
    return res.status(400).json({ error: 'BPM tidak boleh kosong' });
  }

  try {
    // Ambil ride aktif
    const rideResult = await pool.query(
      `SELECT id FROM rides WHERE user_id = $1 AND ended_at IS NULL ORDER BY started_at DESC LIMIT 1`,
      [user_id]
    );
    if (rideResult.rows.length === 0) {
      return res.status(400).json({ error: 'Belum mulai ride' });
    }
    const ride_id = rideResult.rows[0].id;

    // Simpan ke heartrates
    const result = await pool.query(
      `INSERT INTO heartrates (ride_id, bpm, recorded_at)
       VALUES ($1, $2, NOW()) RETURNING *`,
      [ride_id, bpm]
    );

    // Update last_heartrate
    await pool.query(
      `UPDATE realtime_stats
       SET last_heartrate = $1, updated_at = NOW()
       WHERE ride_id = $2`,
      [bpm, ride_id]
    );

    // Ambil nomor darurat dan username
    const userResult = await pool.query(
      `SELECT username, sos_number FROM users WHERE id = $1`,
      [user_id]
    );
    const { username, sos_number } = userResult.rows[0];

    // Kirim WA jika bpm tinggi
    if (bpm > 160 && sos_number) {
      const message = `⚠️ Detak jantung pada ${username} tinggi (${bpm} bpm).`;
      await client.messages.create({
        from: `whatsapp:${process.env.TWILIO_WHATSAPP_NUMBER}`,
        to: `whatsapp:${sos_number}`,
        body: message,
      });
    }

    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
