import * as admin from "firebase-admin";
import {onRequest} from "firebase-functions/v2/https";
import cors from "cors";

admin.initializeApp();

const corsHandler = cors({origin: true});
const db = admin.firestore();

export const sendNotification = onRequest((req, res) => {
  corsHandler(req, res, async () => {
    if (req.method !== "POST") {
      res.status(405).json({success: false, message: "Method not allowed"});
      return;
    }

    try {
      const {target, title, body, fcmToken, imageUrl, actionUrl} = req.body;

      if (!title || !body) {
        res.status(400).json({
          success: false,
          message: "title and body are required",
        });
        return;
      }

      if (target === "single_user" && !fcmToken) {
        res.status(400).json({
          success: false,
          message: "fcmToken is required for single user",
        });
        return;
      }

      // Build data payload — only include imageUrl/actionUrl if they have values
      const data: {[key: string]: string} = {type: "push"};
      if (imageUrl) data.imageUrl = imageUrl;
      if (actionUrl) data.actionUrl = actionUrl;

      // Build FCM message
      const message: admin.messaging.Message = {
        notification: {
          title,
          body,
        },
        data,
        android: {
          priority: "high",
          notification: {
            sound: "hayya_ala_salah",
            channelId: "com.amatullah.prayer_times_push_notification",
          },
        },
        ...(target === "single_user" ? {token: fcmToken} : {topic: "all_users"}),
      };

      const result = await admin.messaging().send(message);

      // Log success to Firestore
      await db.collection("notification_logs").add({
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        target: target === "single_user" ? "single_user" : "all_users",
        title,
        body,
        status: "success",
        messageId: result,
      });

      res.status(200).json({
        success: true,
        message: "Notification sent successfully!",
        messageId: result,
      });
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : String(error);

      // Log failure to Firestore
      try {
        await db.collection("notification_logs").add({
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          target: req.body?.target === "single_user" ? "single_user" : "all_users",
          title: req.body?.title || "",
          body: req.body?.body || "",
          status: "fail",
          messageId: null,
          error: errorMessage,
        });
      } catch (_) {
        // Don't let logging failure mask the original error
      }

      res.status(500).json({
        success: false,
        message: `Failed to send: ${errorMessage}`,
      });
    }
  });
});

export const getNotificationHistory = onRequest((req, res) => {
  corsHandler(req, res, async () => {
    if (req.method !== "GET") {
      res.status(405).json({success: false, message: "Method not allowed"});
      return;
    }

    try {
      const limit = parseInt(req.query.limit as string) || 50;
      const startAfter = req.query.startAfter as string | undefined;

      let query = db
        .collection("notification_logs")
        .orderBy("timestamp", "desc")
        .limit(limit);

      if (startAfter) {
        const startAfterDoc = await db
          .collection("notification_logs")
          .doc(startAfter)
          .get();
        if (startAfterDoc.exists) {
          query = query.startAfter(startAfterDoc);
        }
      }

      const snapshot = await query.get();

      const logs = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
        timestamp: doc.data().timestamp?.toDate()?.toISOString() ?? null,
      }));

      res.status(200).json({
        success: true,
        data: logs,
        lastDocId: snapshot.docs.length > 0
          ? snapshot.docs[snapshot.docs.length - 1].id
          : null,
      });
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      res.status(500).json({
        success: false,
        message: `Failed to fetch history: ${errorMessage}`,
      });
    }
  });
});
