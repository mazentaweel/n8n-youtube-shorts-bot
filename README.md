# 🤖 YouTube Shorts Faceless Video Bot

Fully automated n8n workflow that generates and publishes faceless YouTube Shorts every 8 hours — zero manual work required.

---

## 🔄 How It Works

1. **Triggers every 8 hours** via n8n scheduler
2. **Fetches latest cybersecurity news** from The Hacker News RSS feed
3. **Filters already-processed articles** using URL hashing to avoid duplicates
4. **Generates a video script** using Groq AI (LLaMA) via API
5. **Converts script to voiceover** using Microsoft edge-tts (Jenny Neural voice)
6. **Fetches B-roll footage** from Pexels API (portrait/vertical videos)
7. **Assembles the final video** using FFmpeg via SSH to Linux server
8. **Generates a thumbnail** using ImageMagick
9. **Uploads to YouTube** automatically via YouTube Data API
10. **Sends Telegram notification** on completion
11. **Cleans up temp files** from the server

---

## 🛠️ Tech Stack

| Tool | Purpose |
|------|---------|
| n8n | Workflow automation engine |
| Groq API (LLaMA) | AI script generation |
| Microsoft edge-tts | Text-to-speech voiceover |
| Pexels API | Free B-roll video footage |
| FFmpeg | Video assembly and encoding |
| ImageMagick | Thumbnail generation |
| YouTube Data API | Video upload |
| Telegram Bot API | Completion notifications |
| Linux server (SSH) | Processing backend |

---

## 📋 Requirements

- n8n instance (self-hosted)
- Linux server accessible via SSH
- Groq API key (free tier available)
- Pexels API key (free)
- YouTube Data API credentials
- edge-tts installed on Linux server (`pip install edge-tts`)
- FFmpeg installed on Linux server

---

## 🚀 Setup

1. Import `workflow.json` into your n8n instance
2. Configure credentials:
   - SSH Private Key (for Linux server access)
   - Pexels API key
   - Groq API key
   - YouTube OAuth2
   - Telegram Bot token
3. Update the `YOUR_USERNAME` paths in SSH nodes to match your Linux username
4. Place your `assemble_video.sh` script on the Linux server at `/home/YOUR_USERNAME/`
5. Activate the workflow

---

## ⚠️ Notes

- All API keys and credentials have been removed from this file
- Replace all `YOUR_*` placeholders with your actual values in n8n credentials
- The workflow includes duplicate detection — each article URL is hashed and stored to prevent reprocessing
