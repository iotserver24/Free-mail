/**
 * Cloudflare Worker for Email Routing
 * This worker receives emails from Cloudflare Email Routing and forwards them to your backend API
 * 
 * Setup:
 * 1. Deploy this worker to Cloudflare Workers
 * 2. In Email Routing, set the action to "Send to a Worker"
 * 3. Select this worker
 */

export default {
  async email(message, env, ctx) {
    // Get configuration from environment variables
    const BACKEND_URL = env.BACKEND_URL || 'https://your-backend-url.com';
    const WEBHOOK_SECRET = env.WEBHOOK_SECRET || 'super-secret';
    const WEBHOOK_PATH = env.WEBHOOK_PATH || '/api/webhooks/cloudflare';

    try {
      // Get the raw email content
      // message.raw returns a ReadableStream, convert it to string
      const rawEmailStream = message.raw;
      const rawEmailArray = await new Response(rawEmailStream).arrayBuffer();
      const rawEmail = new TextDecoder().decode(rawEmailArray);
      
      // Convert to base64 for JSON transmission
      const base64Email = btoa(rawEmail);

      // Forward to your backend API
      const response = await fetch(`${BACKEND_URL}${WEBHOOK_PATH}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Webhook-Secret': WEBHOOK_SECRET,
        },
        body: JSON.stringify({
          rawEmail: base64Email,
        }),
      });

      // Log the response for debugging
      console.log(`Email from ${message.from} forwarded. Status: ${response.status}`);

      if (!response.ok) {
        const errorText = await response.text();
        console.error(`Backend error: ${errorText}`);
        // Still return success to Cloudflare to prevent retries
        // You can adjust this behavior if needed
      }

      return new Response('OK', { status: 200 });
    } catch (error) {
      console.error('Error processing email:', error);
      // Return success to prevent Cloudflare from retrying
      // Adjust this if you want Cloudflare to retry on errors
      return new Response('Error processing email', { status: 500 });
    }
  },
};

