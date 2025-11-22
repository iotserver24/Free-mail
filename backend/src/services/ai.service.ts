import OpenAI from "openai";
import type { Stream } from "openai/streaming";
import { config } from "../config";

/**
 * AI Service for email intelligence
 * Supports any OpenAI SDK-compatible API
 */
class AIService {
    private client: OpenAI | null = null;

    constructor() {
        // Check if AI is enabled in config
        if (!config.ai.enabled) {
            console.log("ℹ️  AI Service: Disabled via AI_ENABLED config");
            return;
        }

        if (config.ai.apiKey) {
            this.client = new OpenAI({
                baseURL: config.ai.baseUrl,
                apiKey: config.ai.apiKey,
            });
            console.log(`✅ AI Service: Initialized with model ${config.ai.model}`);
        } else {
            console.warn("⚠️  AI Service: No API key provided. AI features will be disabled.");
        }
    }

    /**
     * Check if AI service is available
     */
    isAvailable(): boolean {
        return config.ai.enabled && this.client !== null;
    }

    /**
     * Generate AI completion
     */
    private async complete(systemPrompt: string, userPrompt: string): Promise<string> {
        if (!this.client) {
            throw new Error("AI service is not available. Please configure OPENAI_API_KEY.");
        }

        const response = await this.client.chat.completions.create({
            model: config.ai.model,
            max_tokens: config.ai.maxTokens,
            messages: [
                { role: "system", content: systemPrompt },
                { role: "user", content: userPrompt },
            ],
        });

        return response.choices[0]?.message?.content?.trim() || "";
    }

    /**
     * 1. SMART EMAIL COMPOSITION
     */

    /**
     * Generate email from brief instructions
     * Example: "Write a professional email asking for a meeting next week"
     */
    async generateEmail(prompt: string, context?: string): Promise<{ subject: string; body: string }> {
        const systemPrompt = `You are an intelligent email writing assistant. Generate professional, clear, and concise emails.
Return your response in JSON format with "subject" and "body" fields.`;

        const userPrompt = context
            ? `Context: ${context}\n\nGenerate an email: ${prompt}`
            : `Generate an email: ${prompt}`;

        const result = await this.complete(systemPrompt, userPrompt);

        try {
            return JSON.parse(result);
        } catch {
            // Fallback if AI doesn't return valid JSON
            return {
                subject: "Email Request",
                body: result,
            };
        }
    }

    /**
     * Generate email with streaming support (for real-time display)
     * Uses conversation context and outputs in XML format
     */
    async generateEmailStream(
        topic: string,
        conversationContext?: Array<{ role: string; content: string; timestamp?: string }>,
        xmlTemplate?: string
    ): Promise<Stream<OpenAI.Chat.Completions.ChatCompletionChunk>> {
        if (!this.client) {
            throw new Error("AI service is not available. Please configure OPENAI_API_KEY.");
        }

        // Build context from conversation history
        let contextText = "";
        if (conversationContext && conversationContext.length > 0) {
            contextText = "\n\nPrevious conversation:\n";
            conversationContext.forEach((msg, idx) => {
                contextText += `[${msg.timestamp || idx + 1}] ${msg.role}: ${msg.content}\n`;
            });
        }

        // Build XML template instructions
        let xmlInstructions = "";
        if (xmlTemplate) {
            xmlInstructions = `\n\nUse this XML template structure:\n${xmlTemplate}\n\nFill in the template with appropriate content.`;
        } else {
            xmlInstructions = `\n\nFormat your response as XML with this structure:
<email>
  <subject>Email subject here</subject>
  <body>
    <p>Email body paragraphs here</p>
  </body>
  <metadata>
    <tone>professional|casual|formal</tone>
    <priority>high|medium|low</priority>
  </metadata>
</email>`;
        }

        const systemPrompt = `You are an intelligent email writing assistant. You write professional, clear, and contextually appropriate emails.

${contextText}

Instructions:
1. Write an email about: "${topic}"
2. Consider the conversation context above when crafting the email
3. Return ONLY valid XML - no markdown, no explanations
4. Make the email natural and contextually appropriate
${xmlInstructions}`;

        const userPrompt = `Write an email about: ${topic}`;

        // Stream the response
        const stream = await this.client.chat.completions.create({
            model: config.ai.model,
            max_tokens: config.ai.maxTokens,
            messages: [
                { role: "system", content: systemPrompt },
                { role: "user", content: userPrompt },
            ],
            stream: true,
        });

        return stream;
    }

    /**
     * Generate smart reply suggestions
     */
    async generateReplies(
        emailSubject: string,
        emailBody: string,
        tone: "short" | "detailed" | "formal" | "casual" = "short"
    ): Promise<string[]> {
        const systemPrompt = `You are an email reply assistant. Generate ${tone} email replies.
Return 3 different reply options as a JSON array of strings.`;

        const userPrompt = `Subject: ${emailSubject}\n\nBody: ${emailBody}\n\nGenerate ${tone} replies.`;

        const result = await this.complete(systemPrompt, userPrompt);

        try {
            return JSON.parse(result);
        } catch {
            return [result];
        }
    }

    /**
     * Rewrite email with different tone/style
     */
    async rewriteEmail(emailBody: string, instruction: string): Promise<string> {
        const systemPrompt = `You are an email editing assistant. Rewrite emails according to user instructions while preserving the core message.`;
        const userPrompt = `Original email:\n${emailBody}\n\nInstruction: ${instruction}`;

        return await this.complete(systemPrompt, userPrompt);
    }

    /**
     * 2. EMAIL ANALYSIS & UNDERSTANDING
     */

    /**
     * Summarize email content
     */
    async summarizeEmail(emailBody: string, maxLength: "short" | "medium" = "short"): Promise<string> {
        const systemPrompt = `You are an email summarization assistant. Create ${maxLength === "short" ? "1-2 sentence" : "3-5 sentence"} summaries.`;
        const userPrompt = `Summarize this email:\n\n${emailBody}`;

        return await this.complete(systemPrompt, userPrompt);
    }

    /**
     * Extract action items from email
     */
    async extractActionItems(emailBody: string): Promise<string[]> {
        const systemPrompt = `Extract action items, tasks, and to-dos from emails. Return as a JSON array of strings.`;
        const userPrompt = `Extract action items from:\n\n${emailBody}`;

        const result = await this.complete(systemPrompt, userPrompt);

        try {
            return JSON.parse(result);
        } catch {
            // If not JSON, split by newlines
            return result.split("\n").filter((line) => line.trim().length > 0);
        }
    }

    /**
     * Categorize email
     */
    async categorizeEmail(
        subject: string,
        body: string
    ): Promise<{ category: string; priority: "high" | "medium" | "low"; isUrgent: boolean }> {
        const systemPrompt = `Analyze emails and categorize them. Categories: work, personal, bills, newsletters, promotions, social, other.
Also determine priority (high/medium/low) and urgency (true/false).
Return as JSON with fields: category, priority, isUrgent`;

        const userPrompt = `Subject: ${subject}\n\nBody: ${body}`;

        const result = await this.complete(systemPrompt, userPrompt);

        try {
            return JSON.parse(result);
        } catch {
            return {
                category: "other",
                priority: "medium",
                isUrgent: false,
            };
        }
    }

    /**
     * Detect sentiment
     */
    async analyzeSentiment(
        emailBody: string
    ): Promise<{ sentiment: "positive" | "neutral" | "negative"; confidence: number }> {
        const systemPrompt = `Analyze the sentiment of emails. Return JSON with "sentiment" (positive/neutral/negative) and "confidence" (0-1).`;
        const userPrompt = emailBody;

        const result = await this.complete(systemPrompt, userPrompt);

        try {
            return JSON.parse(result);
        } catch {
            return {
                sentiment: "neutral",
                confidence: 0.5,
            };
        }
    }

    /**
     * 3. SMART SEARCH & DISCOVERY
     */

    /**
     * Convert natural language query to search terms
     */
    async naturalLanguageSearch(query: string): Promise<string[]> {
        const systemPrompt = `Convert natural language email search queries into search keywords. Return as JSON array of strings.`;
        const userPrompt = `Query: ${query}`;

        const result = await this.complete(systemPrompt, userPrompt);

        try {
            return JSON.parse(result);
        } catch {
            return [query];
        }
    }

    /**
     * 4. TRANSLATION
     */

    /**
     * Translate email to another language
     */
    async translateEmail(emailBody: string, targetLanguage: string): Promise<string> {
        const systemPrompt = `You are a professional translator. Translate emails accurately while preserving tone and formality.`;
        const userPrompt = `Translate to ${targetLanguage}:\n\n${emailBody}`;

        return await this.complete(systemPrompt, userPrompt);
    }

    /**
     * 5. AGENTIC ACTIONS
     */

    /**
     * Decide if email should be auto-archived
     */
    async shouldAutoArchive(
        subject: string,
        body: string,
        userPreferences?: string
    ): Promise<{ shouldArchive: boolean; reason: string }> {
        const systemPrompt = `Analyze if an email should be automatically archived based on content and user preferences.
Return JSON with "shouldArchive" (boolean) and "reason" (string).`;

        const userPrompt = userPreferences
            ? `User preferences: ${userPreferences}\n\nSubject: ${subject}\n\nBody: ${body}`
            : `Subject: ${subject}\n\nBody: ${body}`;

        const result = await this.complete(systemPrompt, userPrompt);

        try {
            return JSON.parse(result);
        } catch {
            return {
                shouldArchive: false,
                reason: "Unable to determine",
            };
        }
    }

    /**
     * Generate auto-reply for simple emails
     */
    async generateAutoReply(emailSubject: string, emailBody: string): Promise<string | null> {
        const systemPrompt = `Determine if an email needs a simple auto-reply (e.g., acknowledgment, out of office).
If yes, generate a brief professional reply. If no auto-reply is needed, return "null".`;

        const userPrompt = `Subject: ${emailSubject}\n\nBody: ${emailBody}`;

        const result = await this.complete(systemPrompt, userPrompt);

        return result === "null" ? null : result;
    }

    /**
     * 6. SPAM & SECURITY
     */

    /**
     * Detect if email is spam/phishing
     */
    async detectSpam(
        subject: string,
        body: string,
        senderEmail: string
    ): Promise<{ isSpam: boolean; confidence: number; reason: string }> {
        const systemPrompt = `Analyze emails for spam and phishing indicators. Return JSON with "isSpam" (boolean), "confidence" (0-1), and "reason" (string).`;
        const userPrompt = `From: ${senderEmail}\nSubject: ${subject}\n\nBody: ${body}`;

        const result = await this.complete(systemPrompt, userPrompt);

        try {
            return JSON.parse(result);
        } catch {
            return {
                isSpam: false,
                confidence: 0,
                reason: "Unable to analyze",
            };
        }
    }
}

// Singleton instance
export const aiService = new AIService();
