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

// ==================== APP UPDATE ====================

export const getAppUpdate = onRequest((req, res) => {
  corsHandler(req, res, async () => {
    if (req.method !== "GET") {
      res.status(405).json({success: false, message: "Method not allowed"});
      return;
    }

    try {
      const doc = await db.collection("settings").doc("app_update").get();

      if (!doc.exists) {
        res.status(200).json({
          success: true,
          data: {
            title: "",
            change_logs: "",
            latest_version: "",
            min_supported_version: "",
            force_update: false,
            store_url: "",
            ios_store_url: "",
          },
        });
        return;
      }

      res.status(200).json({success: true, data: doc.data()});
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      res.status(500).json({
        success: false,
        message: `Failed to fetch app update: ${errorMessage}`,
      });
    }
  });
});

export const updateAppUpdate = onRequest((req, res) => {
  corsHandler(req, res, async () => {
    if (req.method !== "POST") {
      res.status(405).json({success: false, message: "Method not allowed"});
      return;
    }

    try {
      const data = req.body;

      const updateData: {[key: string]: unknown} = {};
      if (data.title !== undefined) updateData.title = data.title;
      if (data.change_logs !== undefined) updateData.change_logs = data.change_logs;
      if (data.latest_version !== undefined) updateData.latest_version = data.latest_version;
      if (data.min_supported_version !== undefined) updateData.min_supported_version = data.min_supported_version;
      if (data.force_update !== undefined) updateData.force_update = data.force_update;
      if (data.store_url !== undefined) updateData.store_url = data.store_url;
      if (data.ios_store_url !== undefined) updateData.ios_store_url = data.ios_store_url;

      await db.collection("settings").doc("app_update").set(updateData, {merge: true});

      res.status(200).json({
        success: true,
        message: "App update settings saved successfully!",
      });
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      res.status(500).json({
        success: false,
        message: `Failed to update: ${errorMessage}`,
      });
    }
  });
});

// ==================== EVENTS ====================

export const getEvents = onRequest((req, res) => {
  corsHandler(req, res, async () => {
    if (req.method !== "GET") {
      res.status(405).json({success: false, message: "Method not allowed"});
      return;
    }

    try {
      const year = parseInt(req.query.year as string) || new Date().getFullYear();

      const snapshot = await db
        .collection("events")
        .where("year", "==", year)
        .orderBy("date", "asc")
        .get();

      const events = snapshot.docs.map((doc) => ({
        id: doc.id,
        title: doc.data().title ?? "",
        description: doc.data().description ?? "",
        holiday_type: doc.data().holiday_type ?? "",
        date: doc.data().date ?? "",
        color: doc.data().color ?? "#FF4CAF50",
        year: doc.data().year ?? year,
        is_active: doc.data().is_active ?? true,
      }));

      res.status(200).json({success: true, data: events});
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      res.status(500).json({
        success: false,
        message: `Failed to fetch events: ${errorMessage}`,
      });
    }
  });
});

export const manageEvent = onRequest((req, res) => {
  corsHandler(req, res, async () => {
    if (req.method !== "POST") {
      res.status(405).json({success: false, message: "Method not allowed"});
      return;
    }

    try {
      const {action, id, title, description, holiday_type, date, color, year, is_active} = req.body;

      if (!action) {
        res.status(400).json({success: false, message: "action is required"});
        return;
      }

      const eventsRef = db.collection("events");

      switch (action) {
      case "create": {
        if (!title || !date) {
          res.status(400).json({success: false, message: "title and date are required"});
          return;
        }
        const docRef = await eventsRef.add({
          title,
          description: description || "",
          holiday_type: holiday_type || "",
          date,
          color: color || "#FF4CAF50",
          year: year || new Date().getFullYear(),
          is_active: is_active !== undefined ? is_active : true,
        });
        res.status(200).json({
          success: true,
          message: "Event created successfully!",
          id: docRef.id,
        });
        break;
      }

      case "update": {
        if (!id) {
          res.status(400).json({success: false, message: "id is required for update"});
          return;
        }
        const updateData: {[key: string]: unknown} = {};
        if (title !== undefined) updateData.title = title;
        if (description !== undefined) updateData.description = description;
        if (holiday_type !== undefined) updateData.holiday_type = holiday_type;
        if (date !== undefined) updateData.date = date;
        if (color !== undefined) updateData.color = color;
        if (year !== undefined) updateData.year = year;
        if (is_active !== undefined) updateData.is_active = is_active;

        await eventsRef.doc(id).update(updateData);
        res.status(200).json({success: true, message: "Event updated successfully!"});
        break;
      }

      case "delete": {
        if (!id) {
          res.status(400).json({success: false, message: "id is required for delete"});
          return;
        }
        await eventsRef.doc(id).delete();
        res.status(200).json({success: true, message: "Event deleted successfully!"});
        break;
      }

      case "toggle": {
        if (!id) {
          res.status(400).json({success: false, message: "id is required for toggle"});
          return;
        }
        const doc = await eventsRef.doc(id).get();
        if (!doc.exists) {
          res.status(404).json({success: false, message: "Event not found"});
          return;
        }
        const currentActive = doc.data()?.is_active ?? true;
        await eventsRef.doc(id).update({is_active: !currentActive});
        res.status(200).json({
          success: true,
          message: `Event ${!currentActive ? "activated" : "deactivated"} successfully!`,
        });
        break;
      }

      default:
        res.status(400).json({success: false, message: `Unknown action: ${action}`});
      }
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      res.status(500).json({
        success: false,
        message: `Failed to manage event: ${errorMessage}`,
      });
    }
  });
});

// ==================== ANALYTICS ====================

export const getAnalytics = onRequest((req, res) => {
  corsHandler(req, res, async () => {
    if (req.method !== "GET") {
      res.status(405).json({success: false, message: "Method not allowed"});
      return;
    }

    try {
      const [devicesSnapshot, logsSnapshot] = await Promise.all([
        db.collection("device_tokens").get(),
        db.collection("notification_logs").get(),
      ]);

      const now = new Date();
      const ms24h = 24 * 60 * 60 * 1000;
      const ms7d = 7 * ms24h;
      const ms30d = 30 * ms24h;

      let active24h = 0;
      let active7d = 0;
      let active30d = 0;
      const platformMap: {[key: string]: number} = {};
      const versionMap: {[key: string]: number} = {};
      const brandMap: {[key: string]: number} = {};
      const trendMap: {[key: string]: number} = {};

      const trendStart = new Date(now.getTime() - ms30d);

      for (const doc of devicesSnapshot.docs) {
        const data = doc.data();

        // Active users
        const updatedAt = data.updated_at?.toDate?.();
        if (updatedAt) {
          const diff = now.getTime() - updatedAt.getTime();
          if (diff <= ms24h) active24h++;
          if (diff <= ms7d) active7d++;
          if (diff <= ms30d) active30d++;
        }

        // Platform distribution
        const platform = data.platform || "unknown";
        platformMap[platform] = (platformMap[platform] || 0) + 1;

        // App version distribution
        const version = data.app_version || "unknown";
        versionMap[version] = (versionMap[version] || 0) + 1;

        // Brand distribution
        const brand = (data.brand || "unknown").toLowerCase();
        brandMap[brand] = (brandMap[brand] || 0) + 1;

        // Registration trend (last 30 days)
        const createdAt = data.created_at?.toDate?.();
        if (createdAt && createdAt >= trendStart) {
          const dateKey = createdAt.toISOString().split("T")[0];
          trendMap[dateKey] = (trendMap[dateKey] || 0) + 1;
        }
      }

      // Notification stats
      let notifSuccess = 0;
      let notifFail = 0;
      for (const doc of logsSnapshot.docs) {
        const data = doc.data();
        if (data.status === "success") notifSuccess++;
        else notifFail++;
      }

      // Sort and format distributions
      const platformDistribution = Object.entries(platformMap)
        .map(([platform, count]) => ({platform, count}))
        .sort((a, b) => b.count - a.count);

      const appVersionDistribution = Object.entries(versionMap)
        .map(([version, count]) => ({version, count}))
        .sort((a, b) => b.count - a.count);

      const brandDistribution = Object.entries(brandMap)
        .map(([brand, count]) => ({brand, count}))
        .sort((a, b) => b.count - a.count)
        .slice(0, 10);

      // Fill 30-day trend
      const registrationTrend: {date: string; count: number}[] = [];
      for (let i = 29; i >= 0; i--) {
        const d = new Date(now.getTime() - i * ms24h);
        const dateKey = d.toISOString().split("T")[0];
        registrationTrend.push({date: dateKey, count: trendMap[dateKey] || 0});
      }

      res.status(200).json({
        success: true,
        data: {
          totalUsers: devicesSnapshot.size,
          activeUsers: {
            last24h: active24h,
            last7d: active7d,
            last30d: active30d,
          },
          notificationStats: {
            total: notifSuccess + notifFail,
            success: notifSuccess,
            fail: notifFail,
          },
          platformDistribution,
          appVersionDistribution,
          brandDistribution,
          registrationTrend,
        },
      });
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      res.status(500).json({
        success: false,
        message: `Failed to fetch analytics: ${errorMessage}`,
      });
    }
  });
});

// ==================== NOTIFICATION HISTORY ====================

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
