const pool = require('../db');
function calculateCalories(pace, heartRate, weightKg, durationMinutes) {
  let MET;
  if (pace < 10) MET = 4;
  else if (pace < 15) MET = 6;
  else if (pace < 20) MET = 8;
  else MET = 10;

  if (heartRate) {
    MET += (heartRate - 120) / 30;
    MET = Math.max(MET, 4);
  }

  const durationHours = durationMinutes / 60;
  const calories = MET * weightKg * durationHours;

  return Math.round(calories);
}

module.exports = { calculateCalories };
