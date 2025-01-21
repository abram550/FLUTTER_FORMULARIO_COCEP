const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
admin.initializeApp();

exports.enviarAlertaFaltas = functions
    .region("us-central1")
    .https.onCall(async (data, context) => {
    // Declarar alertaId fuera del try
      const alertaId = data.alertaId;

      const transporter = nodemailer.createTransport({
        service: "gmail",
        auth: {
          user: "abrahamfaju18@gmail.com",
          pass: "srlo vtow qtlo oxkl",
        },
      });

      try {
        const {emailCoordinador, nombreJoven, nombreTimoteo, faltas} = data;
        if (!emailCoordinador || !nombreJoven || !nombreTimoteo || faltas == null) {
          throw new functions.https.HttpsError(
              "invalid-argument",
              "Faltan datos requeridos",
          );
        }

        const mailOptions = {
          from: "Sistema de Alertas <abrahamfaju18@gmail.com>",
          to: emailCoordinador,
          subject: `Alerta de Asistencia - ${nombreJoven}`,
          text: `
🚨 ALERTA DE ASISTENCIA
El joven ${nombreJoven} ha acumulado ${faltas} faltas consecutivas.
Timoteo asignado: ${nombreTimoteo}
Por favor, realizar seguimiento urgente.
Este es un mensaje automático, no responder a este correo.
          `,
        };

        await transporter.sendMail(mailOptions);

        if (alertaId) {
          await admin.firestore()
              .collection("alertas")
              .doc(alertaId)
              .update({
                "emailEnviado": true,
                "fechaEnvioEmail": admin.firestore.FieldValue.serverTimestamp(),
              });
        }

        return {
          success: true,
          message: "Email enviado correctamente",
        };
      } catch (error) {
        console.error("Error en enviarAlertaFaltas:", error);

        if (alertaId) {
          await admin.firestore()
              .collection("alertas")
              .doc(alertaId)
              .update({
                "emailEnviado": false,
                "errorEmail": error.message,
                "fechaError": admin.firestore.FieldValue.serverTimestamp(),
              });
        }

        throw new functions.https.HttpsError(
            "internal",
            "Error al enviar el email: " + error.message,
        );
      }
    });
