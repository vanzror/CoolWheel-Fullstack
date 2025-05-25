const twilio = require('twilio');
const client = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);

const sendWhatsappAlert = async (toNumber, message) => {
  await client.messages.create({
    from: process.env.TWILIO_WHATSAPP_NUMBER,
    to: `whatsapp:${toNumber}`, // harus +62 format internasional
    body: message,
  });
};

module.exports = sendWhatsappAlert;
