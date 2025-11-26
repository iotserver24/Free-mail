import admin from "firebase-admin";
import path from "path";

// Initialize Firebase Admin SDK
// Try environment variables first (for production/deployment)
const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');
const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
const projectId = process.env.FIREBASE_PROJECT_ID;

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
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccountPath),
        });
        console.log("Firebase Admin SDK initialized from key file");
    }
} catch (error) {
    console.error("Failed to initialize Firebase Admin SDK:", error);
}

export const messaging = admin.messaging();

export async function sendNewEmailNotification(token: string, title: string, body: string) {
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
