import express, { Router } from "express";
import { aiService } from "../services/ai.service";

const router: Router = express.Router();

/**
 * Check if AI service is available
 */
router.get("/status", (req, res) => {
    res.json({
        available: aiService.isAvailable(),
        message: aiService.isAvailable()
            ? "AI service is ready"
            : "AI service is not configured. Please set AI_API_KEY in environment variables.",
    });
});

/**
 * EMAIL COMPOSITION
 */

// Generate email from prompt
router.post("/generate-email", async (req, res) => {
    try {
        const { prompt, context } = req.body;

        if (!prompt) {
            return res.status(400).json({ error: "Prompt is required" });
        }

        const result = await aiService.generateEmail(prompt, context);
        res.json(result);
    } catch (error: any) {
        console.error("AI generate email error:", error);
        res.status(500).json({ error: error.message || "Failed to generate email" });
    }
});

// Generate email with streaming (with conversation context and XML format)
router.post("/generate-email-stream", async (req, res) => {
    try {
        const { topic, conversationContext, xmlTemplate } = req.body;

        if (!topic) {
            return res.status(400).json({ error: "Topic is required" });
        }

        // Set headers for Server-Sent Events (SSE)
        res.setHeader("Content-Type", "text/event-stream");
        res.setHeader("Cache-Control", "no-cache");
        res.setHeader("Connection", "keep-alive");

        const stream = await aiService.generateEmailStream(topic, conversationContext, xmlTemplate);

        // Stream the response chunks
        for await (const chunk of stream) {
            const content = chunk.choices[0]?.delta?.content || "";
            if (content) {
                // Send as Server-Sent Event
                res.write(`data: ${JSON.stringify({ content })}\n\n`);
            }
        }

        // Send completion event
        res.write(`data: ${JSON.stringify({ done: true })}\n\n`);
        res.end();
    } catch (error: any) {
        console.error("AI generate email stream error:", error);
        res.write(`data: ${JSON.stringify({ error: error.message || "Failed to generate email" })}\n\n`);
        res.end();
    }
});

// Generate reply suggestions
router.post("/generate-replies", async (req, res) => {
    try {
        const { subject, body, tone = "short" } = req.body;

        if (!subject || !body) {
            return res.status(400).json({ error: "Subject and body are required" });
        }

        const replies = await aiService.generateReplies(subject, body, tone);
        res.json({ replies });
    } catch (error: any) {
        console.error("AI generate replies error:", error);
        res.status(500).json({ error: error.message || "Failed to generate replies" });
    }
});

// Rewrite email
router.post("/rewrite-email", async (req, res) => {
    try {
        const { body, instruction } = req.body;

        if (!body || !instruction) {
            return res.status(400).json({ error: "Body and instruction are required" });
        }

        const rewritten = await aiService.rewriteEmail(body, instruction);
        res.json({ rewritten });
    } catch (error: any) {
        console.error("AI rewrite email error:", error);
        res.status(500).json({ error: error.message || "Failed to rewrite email" });
    }
});

/**
 * EMAIL ANALYSIS
 */

// Summarize email
router.post("/summarize", async (req, res) => {
    try {
        const { body, maxLength = "short" } = req.body;

        if (!body) {
            return res.status(400).json({ error: "Email body is required" });
        }

        const summary = await aiService.summarizeEmail(body, maxLength);
        res.json({ summary });
    } catch (error: any) {
        console.error("AI summarize error:", error);
        res.status(500).json({ error: error.message || "Failed to summarize email" });
    }
});

// Extract action items
router.post("/extract-actions", async (req, res) => {
    try {
        const { body } = req.body;

        if (!body) {
            return res.status(400).json({ error: "Email body is required" });
        }

        const actionItems = await aiService.extractActionItems(body);
        res.json({ actionItems });
    } catch (error: any) {
        console.error("AI extract actions error:", error);
        res.status(500).json({ error: error.message || "Failed to extract action items" });
    }
});

// Categorize email
router.post("/categorize", async (req, res) => {
    try {
        const { subject, body } = req.body;

        if (!subject || !body) {
            return res.status(400).json({ error: "Subject and body are required" });
        }

        const result = await aiService.categorizeEmail(subject, body);
        res.json(result);
    } catch (error: any) {
        console.error("AI categorize error:", error);
        res.status(500).json({ error: error.message || "Failed to categorize email" });
    }
});

// Analyze sentiment
router.post("/analyze-sentiment", async (req, res) => {
    try {
        const { body } = req.body;

        if (!body) {
            return res.status(400).json({ error: "Email body is required" });
        }

        const result = await aiService.analyzeSentiment(body);
        res.json(result);
    } catch (error: any) {
        console.error("AI sentiment analysis error:", error);
        res.status(500).json({ error: error.message || "Failed to analyze sentiment" });
    }
});

/**
 * SEARCH & DISCOVERY
 */

// Natural language search
router.post("/search", async (req, res) => {
    try {
        const { query } = req.body;

        if (!query) {
            return res.status(400).json({ error: "Search query is required" });
        }

        const keywords = await aiService.naturalLanguageSearch(query);
        res.json({ keywords });
    } catch (error: any) {
        console.error("AI search error:", error);
        res.status(500).json({ error: error.message || "Failed to process search query" });
    }
});

/**
 * TRANSLATION
 */

// Translate email
router.post("/translate", async (req, res) => {
    try {
        const { body, targetLanguage } = req.body;

        if (!body || !targetLanguage) {
            return res.status(400).json({ error: "Body and target language are required" });
        }

        const translated = await aiService.translateEmail(body, targetLanguage);
        res.json({ translated });
    } catch (error: any) {
        console.error("AI translate error:", error);
        res.status(500).json({ error: error.message || "Failed to translate email" });
    }
});

/**
 * AGENTIC ACTIONS
 */

// Check if should auto-archive
router.post("/should-archive", async (req, res) => {
    try {
        const { subject, body, userPreferences } = req.body;

        if (!subject || !body) {
            return res.status(400).json({ error: "Subject and body are required" });
        }

        const result = await aiService.shouldAutoArchive(subject, body, userPreferences);
        res.json(result);
    } catch (error: any) {
        console.error("AI auto-archive check error:", error);
        res.status(500).json({ error: error.message || "Failed to check auto-archive" });
    }
});

// Generate auto-reply
router.post("/auto-reply", async (req, res) => {
    try {
        const { subject, body } = req.body;

        if (!subject || !body) {
            return res.status(400).json({ error: "Subject and body are required" });
        }

        const reply = await aiService.generateAutoReply(subject, body);
        res.json({ reply });
    } catch (error: any) {
        console.error("AI auto-reply error:", error);
        res.status(500).json({ error: error.message || "Failed to generate auto-reply" });
    }
});

/**
 * SPAM & SECURITY
 */

// Detect spam/phishing
router.post("/detect-spam", async (req, res) => {
    try {
        const { subject, body, senderEmail } = req.body;

        if (!subject || !body || !senderEmail) {
            return res.status(400).json({ error: "Subject, body, and sender email are required" });
        }

        const result = await aiService.detectSpam(subject, body, senderEmail);
        res.json(result);
    } catch (error: any) {
        console.error("AI spam detection error:", error);
        res.status(500).json({ error: error.message || "Failed to detect spam" });
    }
});

export default router;
