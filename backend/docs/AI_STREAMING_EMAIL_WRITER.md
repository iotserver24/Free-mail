# 🌊 AI Streaming Email Writer

## Overview

This feature allows real-time streaming of AI-generated emails with:
- **Conversation Context**: AI considers previous messages in the thread
- **XML Format**: Structured output in XML format
- **Custom Templates**: Support for custom XML templates
- **Real-time Streaming**: Users see the AI "thinking" and writing in real-time

---

## API Endpoint

**Endpoint**: `POST /api/ai/generate-email-stream`

**Content-Type**: Uses Server-Sent Events (SSE) for streaming

---

## Request Body

```typescript
{
  topic: string;  // Required - What the email should be about
  conversationContext?: Array<{
    role: string;       // e.g., "user", "assistant", "system"
    content: string;    // The message content
    timestamp?: string; // Optional timestamp
  }>;
  xmlTemplate?: string; // Optional custom XML template
}
```

###  Example Request

```typescript
{
  "topic": "Request for project deadline extension",
  "conversationContext": [
    {
      "role": "user",
      "content": "Hey team, how's the project going?",
      "timestamp": "2025-11-20T10:00:00Z"
    },
    {
      "role": "assistant",
      "content": "The project is progressing well, but we're a bit behind schedule.",
      "timestamp": "2025-11-20T10:05:00Z"
    }
  ],
  "xmlTemplate": null  // Will use default template
}
```

---

## Response (Stream)

The response is streamed as Server-Sent Events (SSE). Each event contains:

```typescript
// Content chunks (multiple events)
data: {"content": "<email>"}
data: {"content": "\n  <subject>"}
data: {"content": "Request for Project Deadline Extension"}
data: {"content": "</subject>\n  <body>"}
...

// Completion event (final event)
data: {"done": true}
```

---

## Default XML Template

If no `xmlTemplate` is provided, the AI uses this structure:

```xml
<email>
  <subject>Email subject here</subject>
  <body>
    <p>Email body paragraphs here</p>
  </body>
  <metadata>
    <tone>professional|casual|formal</tone>
    <priority>high|medium|low</priority>
  </metadata>
</email>
```

---

## Custom XML Template Example

You can provide your own template:

```xml
<message>
  <to>recipient@example.com</to>
  <subject>{{ subject }}</subject>
  <content>
    <greeting>{{ greeting }}</greeting>
    <main_body>{{ content }}</main_body>
    <closing>{{ closing }}</closing>
  </content>
  <signature>
    <name>Your Name</name>
    <title>Your Title</title>
  </signature>
</message>
```

---

## Frontend Implementation

### Using EventSource (Browser API)

```typescript
async function streamEmail(topic: string, context: any[]) {
  return new Promise((resolve, reject) => {
    let fullEmail = "";
    
    // Make the POST request to get the stream
    fetch('/api/ai/generate-email-stream', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      credentials: 'include',
      body: JSON.stringify({
        topic,
        conversationContext: context,
      }),
    })
    .then(response => {
      const reader = response.body.getReader();
      const decoder = new TextDecoder();

     function readStream() {
        reader.read().then(({ done, value }) => {
          if (done) {
            resolve(fullEmail);
            return;
          }

          const chunk = decoder.decode(value);
          const lines = chunk.split('\n');

          lines.forEach(line => {
            if (line.startsWith('data: ')) {
              const data = JSON.parse(line.slice(6));
              
              if (data.content) {
                fullEmail += data.content;
                // Update UI in real-time
                updateEmailDisplay(fullEmail);
              } else if (data.done) {
                resolve(fullEmail);
              } else if (data.error) {
                reject(new Error(data.error));
              }
            }
          });

          readStream();
        });
      }

      readStream();
    })
    .catch(reject);
  });
}

// Update UI function
function updateEmailDisplay(content: string) {
  const emailPreview = document.getElementById('email-preview');
  if (emailPreview) {
    emailPreview.innerText = content;
  }
}
```

### Vue/Nuxt Example

```vue
<template>
  <div>
    <textarea v-model="topic" placeholder="What do you want to write about?" />
    <button @click="generateEmail">✨ Write with AI</button>
    
    <div class="email-preview">
      <div v-if="isStreaming" class="streaming-indicator">
        🤔 AI is thinking...
      </div>
      <pre>{{ streamedEmail }}</pre>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';

const topic = ref('');
const streamedEmail = ref('');
const isStreaming = ref(false);

async function generateEmail() {
  streamedEmail.value = '';
  isStreaming.value = true;

  try {
    const response = await fetch('/api/ai/generate-email-stream', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
      body: JSON.stringify({ topic: topic.value }),
    });

    const reader = response.body!.getReader();
    const decoder = new TextDecoder();

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      const chunk = decoder.decode(value);
      const lines = chunk.split('\n');

      lines.forEach(line => {
        if (line.startsWith('data: ')) {
          const data = JSON.parse(line.slice(6));
          if (data.content) {
            streamedEmail.value += data.content;
          } else if (data.done) {
            isStreaming.value = false;
          }
        }
      });
    }
  } catch (error) {
    console.error('Streaming error:', error);
    isStreaming.value = false;
  }
}
</script>

<style scoped>
.email-preview {
  background: #f5f5f5;
  padding: 20px;
  border-radius: 8px;
  margin-top: 20px;
  min-height: 200px;
}

.streaming-indicator {
  color: #666;
  font-style: italic;
  margin-bottom: 10px;
  animation: pulse 1.5s ease-in-out infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}
</style>
```

---

## How It Works

1. **User provides topic** and optional conversation context
2. **AI analyzes context** from previous messages
3. **Generates email** in XML format
4. **Streams response** token by token in real-time
5. **Frontend displays** each chunk as it arrives
6. **User sees** the AI "thinking" and writing

---

## Example Use Cases

### 1. Reply to Email Thread

```typescript
{
  "topic": "Confirm the meeting time",
  "conversationContext": [
    {
      "role": "sender",
      "content": "Can we meet next Tuesday at 2 PM?"
    }
  ]
}
```

**AI Output**:
```xml
<email>
  <subject>Re: Meeting Confirmation</subject>
  <body>
    <p>Hi [Name],</p>
    <p>Tuesday at 2 PM works perfectly for me. I'll send a calendar invite shortly.</p>
    <p>Looking forward to our meeting!</p>
  </body>
  <metadata>
    <tone>professional</tone>
    <priority>medium</priority>
  </metadata>
</email>
```

### 2. Follow-up Email

```typescript
{
  "topic": "Follow up on proposal submission",
  "conversationContext": [
    {
      "role": "user",
      "content": "I sent the proposal last week"
    }
  ]
}
```

### 3. Custom Format

```typescript
{
  "topic": "Thank you for the interview",
  "xmlTemplate": `
<email>
  <header>
    <date>{{ current_date }}</date>
    <to>{{ recipient }}</to>
  </header>
  <body>{{ content }}</body>
  <footer>
    <signature>{{ user_signature }}</signature>
  </footer>
</email>`
}
```

---

## Benefits

✅ **Real-time Feedback**: Users see the AI working
✅ **Context-Aware**: Considers previous conversation
✅ **Structured Output**: XML format for easy parsing
✅ **Customizable**: Support for custom templates
✅ **Better UX**: No waiting for complete response

---

## Error Handling

If an error occurs:

```typescript
data: {"error": "Failed to generate email"}
```

Handle it in your frontend:

```typescript
if (data.error) {
  console.error('AI Error:', data.error);
  showErrorMessage(data.error);
  isStreaming.value = false;
}
```

---

## Testing

### cURL Example

```bash
curl -X POST http://localhost:4000/api/ai/generate-email-stream \
  -H "Content-Type: application/json" \
  -H "Cookie: connect.sid=YOUR_SESSION_COOKIE" \
  -d '{
    "topic": "Request for time off next week"
  }' \
  --no-buffer
```

---

## Performance Tips

1. **Debounce requests**: Don't send too many at once
2. **Cancel previous streams**: If user changes topic mid-stream
3. **Buffer chunks**: Collect small chunks before updating UI
4. **Parse XML**: Use DOMParser to extract subject/body from final XML

---

## Next Steps

### Extract Subject & Body from XML

```typescript
function parseEmailXML(xmlString: string) {
  const parser = new DOMParser();
  const doc = parser.parseFromString(xmlString, 'text/xml');
  
  return {
    subject: doc.querySelector('subject')?.textContent || '',
    body: doc.querySelector('body')?.innerHTML || '',
    tone: doc.querySelector('metadata tone')?.textContent || '',
    priority: doc.querySelector('metadata priority')?.textContent || '',
  };
}
```

### Auto-fill Composer

```typescript
const email = parseEmailXML(streamedEmail.value);
composerSubject.value = email.subject;
composerBody.value = email.body;
```

---

🎉 **You now have a real-time AI email writer!** 🚀
