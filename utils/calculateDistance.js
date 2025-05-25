const axios = require('axios');

async function calculateORSMDistance(gpsPoints) {
  if (gpsPoints.length < 2) {
    throw new Error('Minimal dua titik GPS dibutuhkan');
  }

  const coordinates = gpsPoints
    .map((p) => `${p.lon},${p.lat}`)
    .join(';');

  const url = `http://router.project-osrm.org/route/v1/bike/${coordinates}?overview=false&geometries=polyline`;

  try {
    const response = await axios.get(url);
    const routes = response.data.routes;

    if (!routes || routes.length === 0) {
      throw new Error('OSRM tidak mengembalikan rute');
    }

    const distanceKm = routes[0].distance / 1000; // dalam km
    return distanceKm;
  } catch (error) {
    throw new Error('Gagal mengambil data dari OSRM: ' + error.message);
  }
}

module.exports = { calculateORSMDistance };
