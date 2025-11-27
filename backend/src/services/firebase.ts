import admin from "firebase-admin";
import path from "path";

// Initialize Firebase Admin SDK
// Try environment variables first (for production/deployment)
let privateKey = process.env.FIREBASE_PRIVATE_KEY;
if (privateKey) {
    // Remove surrounding quotes if present
    if (privateKey.startsWith('"') && privateKey.endsWith('"')) {
        privateKey = privateKey.slice(1, -1);
    }
    // Replace literal \n with actual newlines
    privateKey = privateKey.replace(/\\n/g, '\n');

    console.log("Debug: Private Key length:", privateKey.length);
    console.log("Debug: Private Key start:", privateKey.substring(0, 50));
    console.log("Debug: Private Key contains newline:", privateKey.includes('\n'));
}

const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
const projectId = process.env.FIREBASE_PROJECT_ID;

let messaging: admin.messaging.Messaging | null = null;

try {
    if (privateKey && clientEmail && projectId) {
        admin.initializeApp({
            credential: admin.credential.cert({
                projectId,
                clientEmail,
                privateKey,
            }),
        });
        console.log("Firebase Admin SDK initialized from environment variables");
    } else {
        // Fallback to key file
        const serviceAccountPath = path.resolve(__dirname, "../../free-mail-44517-firebase-adminsdk-fbsvc-11f18455b9.json");
        // Check if file exists before trying to use it
        const fs = require('fs');
        if (fs.existsSync(serviceAccountPath)) {
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccountPath),
            });
            console.log("Firebase Admin SDK initialized from key file");
        } else {
            console.warn("Firebase key file not found and environment variables missing. Notifications will be disabled.");
        }
    }

    // Only initialize messaging if app is initialized
    if (admin.apps.length > 0) {
        messaging = admin.messaging();
    }
} catch (error) {
    console.error("Failed to initialize Firebase Admin SDK:", error);
}

export { messaging };

export async function sendNewEmailNotification(token: string, title: string, body: string) {
    if (!messaging) {
        console.warn("Firebase Messaging not initialized. Skipping notification.");
        return;
    }
    try {
        await messaging.send({
            token,
            notification: {
                title,
                body,
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "high_importance_channel", // Make sure this matches frontend
                },
            },
            data: {
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                type: "new_email",
            },
        });
        console.log("Notification sent successfully to token:", token);
    } catch (error) {
        console.error("Error sending notification:", error);
    }
}
