# CoCounsel Web Interface - Setup Guide

## Overview
This is a modern, responsive web interface for your CoCounsel Legal Research Agent. Users can submit legal queries and view formatted results in real-time.

## Features

✅ **Clean, Professional Design**
- Gradient purple theme
- Responsive layout (works on mobile, tablet, desktop)
- Split-screen view: query form on left, results on right

✅ **User-Friendly Form**
- Legal query text area
- Jurisdiction dropdown (all 50 states + federal)
- Practice area selection
- Example queries that populate the form on click

✅ **Real-Time Results**
- Loading spinner during research
- Formatted memo display
- Link to full Google Doc
- Error handling with helpful messages

✅ **Example Queries**
- Pre-populated examples for quick testing
- Covers different practice areas
- Click to auto-fill the form

## Setup Instructions

### Step 1: Get Your Webhook URL

1. Go to your n8n workflow: **CoCounsel Legal Research Agent**
2. Click on the **"Chat Trigger"** or **"Webhook"** node at the start
3. Copy the webhook URL (should look like: `https://sbray205.app.n8n.cloud/webhook/YOUR_WEBHOOK_ID`)

### Step 2: Update the HTML File

1. Open `cocounsel-interface.html` in a text editor
2. Find this line (around line 502):
   ```javascript
   const WEBHOOK_URL = 'https://sbray205.app.n8n.cloud/webhook/YOUR_WEBHOOK_ID';
   ```
3. Replace `YOUR_WEBHOOK_ID` with your actual webhook ID
4. Save the file

### Step 3: Deploy the Interface

**Option A: Simple File Hosting**
- Upload `cocounsel-interface.html` to any web hosting service
- Or open it directly in a browser (file:// URL)

**Option B: GitHub Pages (Free)**
1. Create a GitHub repository
2. Upload `cocounsel-interface.html` and rename it to `index.html`
3. Enable GitHub Pages in repository settings
4. Access at: `https://yourusername.github.io/reponame`

**Option C: Netlify/Vercel (Free)**
1. Create account on Netlify or Vercel
2. Drag and drop the HTML file
3. Get instant deployment URL

**Option D: Your Own Server**
- Upload to your web server via FTP/SFTP
- Works with Apache, Nginx, or any static file server

### Step 4: Configure n8n Webhook Response

Your n8n workflow must return a JSON response with this structure:

```json
{
  "memo": "LEGAL RESEARCH MEMORANDUM\n\nSession ID: ...",
  "documentUrl": "https://docs.google.com/document/d/..."
}
```

**OR:**

```json
{
  "content": "LEGAL RESEARCH MEMORANDUM\n\nSession ID: ...",
  "documentUrl": "https://docs.google.com/document/d/..."
}
```

The interface will look for either `memo` or `content` field for the main text.

## Testing

### Test Query Example:
```
Query: A software vendor failed to deliver promised features for 6 months despite repeated requests. The contract states delivery within 90 days. Can my client terminate the contract and recover damages?

Jurisdiction: California
Practice Area: contract law
```

Expected result: Full legal memorandum displayed with link to Google Doc.

## Troubleshooting

### "Failed to complete research" Error
- **Check webhook URL**: Make sure it's correct in the HTML file
- **CORS issues**: If running locally (file:// URL), try uploading to a web server
- **n8n workflow**: Make sure the workflow is active and webhook is listening

### No Results Displayed
- **Check response format**: n8n must return JSON with `memo` or `content` field
- **Check console**: Open browser DevTools (F12) → Console tab for errors

### Loading Never Completes
- **Timeout**: Research taking too long (>60 seconds)
- **n8n error**: Check n8n execution logs for failures
- **Network**: Check if webhook endpoint is reachable

## Customization

### Change Colors
Find the gradient in the CSS (line 13):
```css
background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
```

### Change Button Style
Find `.btn` in CSS (line 132) and modify colors/styling

### Add More Practice Areas
Find the `practiceArea` select dropdown (line 331) and add more options

### Modify Form Fields
Add new fields in the form section (line 268+) and update the JavaScript to include them in `formData` (line 496)

## Security Notes

⚠️ **Important Security Considerations:**

1. **No Authentication**: This interface has no login/auth system
   - Anyone with the URL can submit queries
   - Consider adding authentication if needed

2. **Rate Limiting**: No built-in rate limiting
   - Consider adding rate limiting in n8n or at server level
   - Prevent abuse of your API

3. **Input Validation**: Basic browser validation only
   - Add server-side validation in n8n workflow
   - Sanitize user inputs

4. **HTTPS**: Always deploy over HTTPS
   - Protects data in transit
   - Required for production use

## Files Included

- `cocounsel-interface.html` - Complete standalone interface
- `SETUP.md` - This setup guide

## Support

If you encounter issues:
1. Check browser console (F12) for JavaScript errors
2. Check n8n execution logs for workflow errors
3. Verify webhook URL is correct and workflow is active
4. Test webhook directly with curl/Postman first

## Next Steps

### Enhancements You Could Add:

1. **User Authentication**
   - Add login system
   - Track user queries
   - Usage limits per user

2. **Query History**
   - Save past queries in browser localStorage
   - Allow users to view/resubmit previous queries

3. **Export Options**
   - Download as PDF
   - Email results
   - Copy to clipboard

4. **Advanced Features**
   - Follow-up questions
   - Citation links
   - Related queries suggestions

5. **Analytics**
   - Track popular practice areas
   - Monitor average research time
   - User feedback system

## License

Free to use and modify for your legal research needs.
