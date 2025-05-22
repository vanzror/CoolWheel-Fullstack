const pool = require('../db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

exports.registerUser = async (req, res) => {
  const { email, password } = req.body;

  // Validasi input minimal
  if (!email || !password) {
    return res.status(400).json({ message: 'Email dan password wajib diisi' });
  }

  try {
    // Cek apakah email sudah digunakan
    const existing = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (existing.rows.length > 0) {
      return res.status(409).json({ error: 'Email sudah terdaftar' });
    }

    const hashed = await bcrypt.hash(password, 10);

    const result = await pool.query(
      `INSERT INTO users (email, password)
       VALUES ($1, $2)
       RETURNING id, email`,
      [email, hashed]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

exports.login = async (req, res) => {
  const { email, password } = req.body;

  const userResult = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
  const user = userResult.rows[0];
  if (!user) return res.status(401).json({ error: 'Email tidak ditemukan' });

  const validPassword = await bcrypt.compare(password, user.password);
  if (!validPassword) return res.status(401).json({ error: 'Password salah' });

  const token = jwt.sign({ user_id: user.id }, process.env.JWT_SECRET, { expiresIn: '7d' });

  // Simpan token baru, ganti token lama
  await pool.query('UPDATE users SET token = $1 WHERE id = $2', [token, user.id]);

  res.json({ token });
};

exports.logout = async (req, res) => {
  const user_id = req.user.user_id;

  try {
    await pool.query('UPDATE users SET token = NULL WHERE id = $1', [user_id]);
    res.json({ message: 'Logout berhasil' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getUser = async (req, res) => {
  const user_id = req.user.user_id;

  try {
    const result = await pool.query(
      `SELECT id, username, email, height, weight, sos_number, nama_sos, age 
       FROM users WHERE id = $1`,
      [user_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User tidak ditemukan' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.updateUser = async (req, res) => {
  const user_id = req.user.user_id;
  const { username, height, weight, sos_number, nama_sos, age } = req.body;

  // Validasi input minimal (bisa dikembangkan lagi sesuai kebutuhan)
  if (!username && !height && !weight && !sos_number && !nama_sos && !age) {
    return res.status(400).json({ error: 'Tidak ada data yang dikirim untuk diperbarui' });
  }

  try {
    // Ambil data user saat ini
    const current = await pool.query('SELECT * FROM users WHERE id = $1', [user_id]);
    if (current.rows.length === 0) {
      return res.status(404).json({ error: 'User tidak ditemukan' });
    }

    const user = current.rows[0];

    // Gunakan data yang dikirim, atau fallback ke data lama
    const updated = {
      username: username || user.username,
      height: height || user.height,
      weight: weight || user.weight,
      sos_number: sos_number || user.sos_number,
      nama_sos: nama_sos || user.nama_sos,
      age: age || user.age
    };

    const result = await pool.query(
      `UPDATE users 
       SET username = $1, height = $2, weight = $3, sos_number = $4, nama_sos = $5, age = $6 
       WHERE id = $7 
       RETURNING id, username, email, height, weight, sos_number, nama_sos, age`,
      [updated.username, updated.height, updated.weight, updated.sos_number, updated.nama_sos, updated.age, user_id]
    );

    res.json({ message: 'User berhasil diperbarui', user: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};