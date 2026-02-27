import * as admin from "firebase-admin";
import {onRequest} from "firebase-functions/v2/https";
import cors from "cors";

admin.initializeApp();

const corsHandler = cors({origin: true});

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

      res.status(200).json({
        success: true,
        message: "Notification sent successfully!",
        messageId: result,
      });
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      res.status(500).json({
        success: false,
        message: `Failed to send: ${errorMessage}`,
      });
    }
  });
});
