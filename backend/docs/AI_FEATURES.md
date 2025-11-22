# 🤖 AI Features - Free-mail

This document outlines all the AI-powered features available in Free-mail using agentic AI capabilities.

## 🔧 Configuration

Add these environment variables to your `.env` file:

```bash
# AI CONFIGURATION (OpenAI SDK Format)
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_API_KEY=your-api-key-here
OPENAI_MODEL=gpt-4o-mini
OPENAI_MAX_TOKENS=2000
```

**Note**: `OPENAI_BASE_URL` can point to any OpenAI-compatible API (OpenAI, Azure OpenAI, local LLMs, etc.)

---

## 📋 Available AI Features

### 1. **Smart Email Composition** ✍️

#### Generate Email from Prompt
**Endpoint**: `POST /api/ai/generate-email`

Generate complete emails from brief instructions.

```json
{
  "prompt": "Write a professional email asking for a meeting next week",
  "context": "optional context about the project"
}
```

**Response**:
```json
{
  "subject": "Meeting Request - Next Week",
  "body": "Dear [Name],\n\nI hope this email finds you well..."
}
```

**Use Cases**:
- Voice-to-email (dictate and AI writes professionally)
- Quick email drafting
- Template generation

---

#### Generate Smart Replies
**Endpoint**: `POST /api/ai/generate-replies`

Get 3 contextual reply suggestions.

```json
{
  "subject": "Project Update",
  "body": "Can we schedule a meeting tomorrow?",
  "tone": "short" // or "detailed", "formal", "casual"
}
```

**Response**:
```json
{
  "replies": [
    "Yes, I'm available tomorrow afternoon. What time works for you?",
    "Tomorrow works! Let's meet at 2 PM.",
    "I can meet tomorrow. Please send a calendar invite."
  ]
}
```

---

#### Rewrite Email
**Endpoint**: `POST /api/ai/rewrite-email`

Improve or change the tone of an email.

```json
{
  "body": "hey can u send me the file asap?",
  "instruction": "make it more professional and polite"
}
```

**Response**:
```json
{
  "rewritten": "Dear [Name],\n\nI hope you're doing well. When you have a chance, could you please send me the file at your earliest convenience?\n\nThank you!"
}
```

**Use Cases**:
- Fix grammar and spelling
- Adjust formality
- Make it more concise
- Change tone (friendly → formal, etc.)

---

### 2. **Email Analysis & Understanding** 📊

#### Summarize Email
**Endpoint**: `POST /api/ai/summarize`

Get a concise summary of long emails.

```json
{
  "body": "Long email content...",
  "maxLength": "short" // or "medium"
}
```

**Response**:
```json
{
  "summary": "Project deadline extended to next Friday. Team needs to submit reports by Wednesday."
}
```

---

#### Extract Action Items
**Endpoint**: `POST /api/ai/extract-actions`

Pull out tasks, deadlines, and to-dos.

```json
{
  "body": "Please review the document and submit your feedback by Friday. Also schedule a meeting with the team next week."
}
```

**Response**:
```json
{
  "actionItems": [
    "Review document",
    "Submit feedback by Friday",
    "Schedule team meeting next week"
  ]
}
```

---

#### Categorize Email
**Endpoint**: `POST /api/ai/categorize`

Auto-categorize and prioritize emails.

```json
{
  "subject": "Invoice #1234",
  "body": "Please find attached your invoice..."
}
```

**Response**:
```json
{
  "category": "bills",
  "priority": "medium",
  "isUrgent": false
}
```

**Categories**: work, personal, bills, newsletters, promotions, social, other

---

#### Analyze Sentiment
**Endpoint**: `POST /api/ai/analyze-sentiment`

Detect if an email is positive, neutral, or negative.

```json
{
  "body": "I'm extremely disappointed with the service..."
}
```

**Response**:
```json
{
  "sentiment": "negative",
  "confidence": 0.92
}
```

**Use Cases**:
- Flag angry/urgent emails
- Prioritize customer complaints
- Detect praise/appreciation

---

### 3. **Smart Search & Discovery** 🔍

#### Natural Language Search
**Endpoint**: `POST /api/ai/search`

Convert questions to search keywords.

```json
{
  "query": "Show me all emails about the project deadline from last month"
}
```

**Response**:
```json
{
  "keywords": ["project", "deadline", "last month", "schedule"]
}
```

---

### 4. **Translation** 🌍

#### Translate Email
**Endpoint**: `POST /api/ai/translate`

Translate emails to any language.

```json
{
  "body": "Hello, how are you?",
  "targetLanguage": "Spanish"
}
```

**Response**:
```json
{
  "translated": "Hola, ¿cómo estás?"
}
```

---

### 5. **Agentic Actions** 🚀

These features allow the AI to make decisions and take actions autonomously.

#### Auto-Archive Decision
**Endpoint**: `POST /api/ai/should-archive`

AI decides if an email should be automatically archived.

```json
{
  "subject": "Newsletter - Daily Updates",
  "body": "Here's today's newsletter...",
  "userPreferences": "Archive all newsletters automatically"
}
```

**Response**:
```json
{
  "shouldArchive": true,
  "reason": "Newsletter matches user's auto-archive preferences"
}
```

**Use Cases**:
- Auto-cleanup of newsletters
- Archive read receipts
- Remove promotional emails

---

#### Generate Auto-Reply
**Endpoint**: `POST /api/ai/auto-reply`

AI generates automatic replies for simple emails.

```json
{
  "subject": "Received your package",
  "body": "Your package has been delivered."
}
```

**Response**:
```json
{
  "reply": "Thank you for confirming the delivery!"
}
```

**Use Cases**:
- Auto-acknowledge delivery confirmations
- Out-of-office responses
- Thank you replies

---

### 6. **Spam & Security** 🛡️

#### Detect Spam/Phishing
**Endpoint**: `POST /api/ai/detect-spam`

AI-powered spam and phishing detection.

```json
{
  "subject": "You've won $1,000,000!",
  "body": "Click here to claim your prize...",
  "senderEmail": "suspicious@domain.xyz"
}
```

**Response**:
```json
{
  "isSpam": true,
  "confidence": 0.95,
  "reason": "Contains typical phishing indicators: suspicious links, unrealistic claims, unknown sender"
}
```

---

## 🎯 Frontend Integration Ideas

### UI Components to Build:

1. **AI Compose Button** - In email composer
   - "✨ Write with AI" button
   - Text prompt → full email

2. **Smart Reply Buttons** - In message viewer
   - Show 3 quick reply options
   - One-click to send

3. **Summarize Badge** - On long emails
   - "📄 TL;DR" button
   - Show summary in tooltip

4. **Action Items Panel** - Sidebar widget
   - Extract to-dos from all emails
   - Check off completed items

5. **AI Search Bar** - Enhanced search
   - Natural language queries
   - "Find emails about X from Y"

6. **Tone Adjuster** - In composer
   - Slider: Casual ↔ Formal
   - Rewrite button

7. **Translation Button** - On emails
   - 🌍 icon → dropdown of languages

8. **Smart Labels** - Auto-categorization
   - AI suggests labels/folders
   - Auto-organize inbox

9. **Priority Inbox** - Smart filtering
   - Urgent emails at top
   - AI-powered sorting

10. **Spam Shield** - Security indicator
    - Red badge on suspicious emails
    - Warning before clicking links

---

## 🔌 Example Frontend Usage

```typescript
// In your Vue/Nuxt app
const aiApi = {
  generateEmail: async (prompt: string) => {
    const res = await fetch('/api/ai/generate-email', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ prompt }),
    });
    return res.json();
  },

  summarize: async (emailBody: string) => {
    const res = await fetch('/api/ai/summarize', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ body: emailBody }),
    });
    return res.json();
  },

  getReplies: async (subject: string, body: string) => {
    const res = await fetch('/api/ai/generate-replies', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ subject, body, tone: 'short' }),
    });
    return res.json();
  },
};
```

---

## 🚀 Advanced Agentic Features (Future)

Since you mentioned it's **agentic**, here are advanced features you could build:

1. **Email Automation**
   - AI monitors inbox
   - Auto-replies to specific types
   - Auto-forwards to team members

2. **Smart Scheduling**
   - Extract meeting requests
   - Auto-schedule based on calendar
   - Send confirmations

3. **Follow-up Reminders**
   - "Remind me if no reply in 3 days"
   - AI sends gentle follow-ups

4. **Bulk Actions**
   - "Archive all newsletters from last month"
   - "Delete all promotional emails"

5. **Email Insights**
   - "Who emails me most?"
   - "Average response time?"
   - Analytics dashboard

6. **Custom Workflows**
   - If email contains "urgent" → notify immediately
   - If from boss → mark as priority
   - If invoice → forward to accounting

---

## 📊 API Status

Check if AI is available:

```bash
GET /api/ai/status
```

Response:
```json
{
  "available": true,
  "message": "AI service is ready"
}
```

---

## 🔐 Security Notes

- All AI endpoints require authentication (`requireAuth` middleware)
- API keys are never exposed to frontend
- Emails are only processed, never stored by AI service
- Use HTTPS in production

---

## 💡 Tips

1. **Model Choice**: `gpt-4o-mini` is fast and cheap. Use `gpt-4o` for better quality.
2. **Max Tokens**: Increase for longer emails
3. **Rate Limiting**: Consider adding rate limits for AI endpoints
4. **Caching**: Cache common summaries/translations
5. **Error Handling**: Always have fallbacks if AI fails

---

## 🎉 Getting Started

1. Add API key to `.env`
2. Backend detects AI automatically  
3. Start building frontend features!
4. Test with `/api/ai/status`

**That's it!** Your email client now has superpowers! 🚀
