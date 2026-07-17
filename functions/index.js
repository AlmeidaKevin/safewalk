const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

/**
 * Se dispara automaticamente cuando se crea un nuevo documento en
 * la coleccion 'sos_events'. Busca el fcmToken de cada contacto
 * notificado y les envia un push de alerta.
 */
exports.onSosEventCreated = onDocumentCreated(
    "sos_events/{eventId}",
    async (event) => {
      const snapshot = event.data;
      if (!snapshot) {
        console.log("No hay datos en el evento, se ignora.");
        return;
      }

      const sosEvent = snapshot.data();
      const notifiedContactIds = sosEvent.notifiedContactIds || [];
      const ownerName = sosEvent.ownerName || "Alguien";

      if (notifiedContactIds.length === 0) {
        console.log("No hay contactos que notificar para este evento.");
        return;
      }

      // Buscamos el fcmToken de cada contacto notificado.
      const userDocs = await Promise.all(
          notifiedContactIds.map((uid) =>
            db.collection("users").doc(uid).get(),
          ),
      );

      const tokens = userDocs
          .map((doc) => doc.exists ? doc.data().fcmToken : null)
          .filter((token) => token && token.length > 0);

      if (tokens.length === 0) {
        console.log("Ningun contacto tiene un fcmToken valido.");
        return;
      }

      const message = {
        notification: {
          title: "SafeWalk - Alerta SOS",
          body: `${ownerName} necesita ayuda`,
        },
        data: {
          eventId: event.params.eventId,
          type: "sos_alert",
        },
        tokens: tokens,
      };

      try {
        const response = await messaging.sendEachForMulticast(message);
        console.log(
            `Notificaciones enviadas: ${response.successCount} exitosas, ` +
            `${response.failureCount} fallidas.`,
        );
      } catch (error) {
        console.error("Error enviando notificaciones:", error);
      }
    },
);