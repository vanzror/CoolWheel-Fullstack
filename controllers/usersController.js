const pool = require('../db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

exports.registerUser = async (req, res) => {
    const { username, email, password, height, weight, sos_number, nama_sos, age } = req.body;
  
    // Validasi input
    if (!username || !email || !password || !height || !weight || !sos_number || !nama_sos || !age) {
      return res.status(400).json({ message: 'Please fill all required fields' });
    }
  
    try {
      const hashed = await bcrypt.hash(password, 10);
      const result = await pool.query(
        `INSERT INTO users (username, email, password, height, weight, sos_number, nama_sos, age)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING id, username, email, height, weight, sos_number, nama_sos, age`,
        [username, email, hashed, height, weight, sos_number, nama_sos, age]
      );
  
      // Kirim response setelah berhasil
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
