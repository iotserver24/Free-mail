# How File Attachments Work in Free-Mail

## Overview

Free-Mail handles file attachments in two directions:
1. **Sending attachments** (outbound emails)
2. **Receiving attachments** (inbound emails)

## 📤 Sending Attachments (Outbound)

### Frontend Process (Direct Upload to Catbox)

1. **User selects files** in the Composer component
2. **File size validation**:
   - Each file is checked against 25MB limit
   - Files exceeding limit are rejected with an error message
3. **Direct upload to Catbox**:
   - Files are uploaded directly to Catbox API from the browser
   - Uses FormData with `reqtype="fileupload"` and `fileToUpload` field
   - Catbox API endpoint: `https://catbox.moe/user/api.php`
   - No base64 encoding needed - files sent as binary data

```javascript
// From api.ts - uploadFileToCatbox()
const formData = new FormData();
formData.append("reqtype", "fileupload");
formData.append("fileToUpload", file);

const response = await fetch("https://catbox.moe/user/api.php", {
  method: "POST",
  body: formData,
});
```

4. **Catbox returns URL**:
   - Successful upload returns a direct URL (e.g., `https://files.catbox.moe/abc123.jpg`)
   - URL is stored in the attachment object
   - Upload status is tracked (uploading, success, error)

5. **Sent to backend** via API:
   - Only URLs are sent to backend (not file data)
   - Each attachment has: `filename`, `url` (Catbox URL), `contentType`
   - Much smaller payload size (just URLs, not file contents)

### Backend Process

1. **Receives attachment URLs** in `/api/messages` POST endpoint
2. **Downloads files from Catbox**:
   ```typescript
   const response = await axios.get<ArrayBuffer>(item.url, { responseType: "arraybuffer" });
   const content = Buffer.from(response.data);
   ```
3. **Sends via Brevo SMTP**:
   - Attachments are attached to the email using Nodemailer
   - Brevo handles the actual email delivery with attachments
4. **Stores attachment metadata** in database:
   - After sending, attachment records are created
   - Links attachments to the message ID
   - Stores filename, MIME type, size, and Catbox URL

## 📥 Receiving Attachments (Inbound)

### Email Reception Flow

1. **Email arrives** via Cloudflare Email Routing
2. **Cloudflare Worker** forwards raw email to backend webhook
3. **Backend parses email** using `mailparser` library:
   ```typescript
   const parsed = await simpleParser(rawEmail);
   const attachments = parsed.attachments; // Array of Attachment objects
   ```

### Attachment Processing

1. **Each attachment is processed**:
   - Filename extracted
   - Content (Buffer) extracted
   - MIME type determined
   - Size calculated

2. **Uploaded to Catbox** (external file hosting):
   ```typescript
   const url = await uploadBufferToCatbox(filename, buffer);
   ```
   - Catbox is a free file hosting service
   - Returns a public URL for the file
   - Files are stored permanently on Catbox servers

3. **Metadata stored in database**:
   - Attachment record created with:
     - `message_id` (links to the message)
     - `filename`
     - `mimetype`
     - `size_bytes`
     - `url` (Catbox URL)

4. **Message created** with attachment references

### Displaying Attachments

- Attachments are shown in the MessageViewer component
- Each attachment displays as a clickable link
- Clicking opens the Catbox URL in a new tab
- Shows filename and file size

## 🔧 Technical Details

### Attachment Storage

**Outbound (Sent)**:
- Files are sent directly via SMTP (Brevo)
- No permanent storage on our servers
- Metadata stored in database for reference

**Inbound (Received)**:
- Files are uploaded to **Catbox** (https://catbox.moe)
- Catbox provides permanent file hosting
- URLs are stored in database
- Files remain accessible via Catbox URLs

### File Size Limits

- **Frontend**: 
  - Hard limit: **25MB per file** (enforced before upload)
  - Browser memory limits apply (typically 100-500MB total)
- **Backend**: 
  - Express body parser limit: **25MB** (for attachment URLs, not file data)
  - Since only URLs are sent, this is more than sufficient
- **Brevo SMTP**: Has its own limits (check Brevo documentation)
- **Catbox**: 
  - Free tier: Check [Catbox documentation](https://catbox.moe/tools.php)
  - Files are stored permanently on Catbox servers

### Supported File Types

- **All file types** are supported
- MIME type is detected automatically
- No file type restrictions (handled by email standards)

## 📋 Database Schema

```typescript
interface AttachmentRecord {
  id: string;
  message_id: string;
  filename: string;
  mimetype: string;
  size_bytes: number;
  url: string; // Catbox URL for received attachments
  created_at: string;
}
```

## 🔄 Complete Flow Diagram

### Sending:
```
User selects file (max 25MB)
  ↓
Frontend: Upload directly to Catbox
  ↓
Catbox: Returns public URL
  ↓
Frontend: Store URL in attachment object
  ↓
API: POST /api/messages (with Catbox URLs only)
  ↓
Backend: Download files from Catbox URLs
  ↓
Backend: Convert to Buffer
  ↓
Brevo SMTP: Send email with attachment
  ↓
Database: Store attachment metadata with Catbox URL
```

### Receiving:
```
Email arrives (Cloudflare)
  ↓
Worker: Forward to webhook
  ↓
Backend: Parse email (mailparser)
  ↓
Extract attachments
  ↓
Upload each to Catbox
  ↓
Database: Store attachment records with URLs
  ↓
Frontend: Display as clickable links
```

## 🛠️ Configuration

### Catbox API
- Configured in `backend/.env`: `CATBOX_API_URL`
- Default: `https://catbox.moe/user/api.php`
- No API key required for basic usage

### Brevo SMTP
- Configured in `backend/.env`:
  - `BREVO_SMTP_HOST`
  - `BREVO_SMTP_PORT`
  - `BREVO_SMTP_USER`
  - `BREVO_SMTP_PASS`

## 💡 Notes

1. **Catbox URLs are permanent** - files won't be deleted automatically
2. **Frontend upload is more efficient** - no base64 encoding overhead (~33% size reduction)
3. **Smaller API payloads** - only URLs sent to backend, not file contents
4. **25MB per file limit** - enforced on frontend before upload
5. **Upload progress** - users see "Uploading..." status for each file
6. **Error handling** - failed uploads are clearly marked with error messages
7. **Security**: All file types are accepted - consider adding validation for production
8. **Storage costs**: Catbox is free but has limits - consider alternatives for production
9. **CORS**: Catbox API supports CORS, allowing direct browser uploads

## 🔐 Security Considerations

- **File validation**: Currently accepts all file types
- **Virus scanning**: Not implemented (consider adding)
- **Size limits**: Should be enforced on both frontend and backend
- **Access control**: Catbox URLs are public - consider private storage for sensitive files

