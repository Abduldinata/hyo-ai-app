# Hyo AI - Trending API Server (FREE VERSION) 🆓

Server agregator trending topics yang mengumpulkan data dari berbagai sumber **GRATIS** (NewsAPI, CNN Indonesia, Detik.com, GetDayTrends, Wikimedia) menggunakan **web scraping** dan mengembalikan unified trending data untuk Hyo AI.

**✨ 100% FREE - Tidak ada API berbayar!**

## 🚀 Quick Start

### 1. Install Dependencies

```bash
npm install
```

Atau dengan yarn:
```bash
yarn install
```

### 2. Setup API Keys

Copy `.env.example` ke `.env`:
```bash
copy .env.example .env
```

Edit `.env` dan isi API keys Anda (opsional):
```env
PORT=3000

# NewsAPI (Optional - https://newsapi.org/register)
# Leave blank to use scraping only
NEWSAPI_KEY=your_newsapi_key_here_or_leave_blank
```

**CATATAN:** NewsAPI adalah opsional! Server akan tetap berjalan dengan scraping saja jika tidak ada API key.

### 3. Run Server

Development mode (auto-reload):
```bash
npm run dev
```

Production mode:
```bash
npm start
```

Server akan running di `http://localhost:3000`

## 📡 API Endpoints

### GET /trending

Mendapatkan trending data dari semua source.

**Query Parameters:**
- `geo` - Geographic region (default: `ID`)
  - `ID` - Indonesia
  - `US` - United States
  - `GB` - United Kingdom
  - `JP` - Japan
- `lang` - Language code (default: `id`)
  - `id` - Indonesian
  - `en` - English
  - `ja` - Japanese
- `from` - Start date (ISO format, default: 7 days ago)
- `to` - End date (ISO format, default: today)
- `limit` - Max items to return (default: `20`)

**Example Request:**
```bash
curl "http://localhost:3000/trending?geo=ID&lang=id&limit=10"
```

**Example Response:**
```json
{
  "meta": {
    "timestamp": "2026-02-18T12:34:56.789Z",
    "params": {
      "geo": "ID",
      "lang": "id",
      "limit": 10
    },
    "total_items": 10,
    "sources": {
      "newsapi": 5,
      "indonesia_news": 8,
      "social_trends": 10,
      "wikimedia": 10
    }
  },
  "items": [
    {
      "id": "abc123...",
      "category": "social",
      "platform": "X/Twitter",
      "entity_type": "topic",
      "title": "#TrendingTopic",
      "description": "Trending topic with 50000 tweets",
      "url": "https://twitter.com/search?q=%23TrendingTopic",
      "media": [],
      "metrics": {
        "tweet_count": 50000
      },
      "score": {
        "viral": 85.3,
        "confidence": 0.85,
        "engagement_rate": 0.92
      },
      "provenance": {
        "fetched_at": "2026-02-18T12:34:56.789Z",
        "source_api": "twitter",
        "dedup_key": "..."
      }
    }
  ],
  "hyo": {
    "emotion": "happy",
    "lang": "id",
    "text": "Wah, lagi rame banget nih tentang \"#TrendingTopic\"! Viral score-nya 85.3/100 lho~ 🔥"
  }
}
```

### GET /health

Health check endpoint untuk monitoring.

**Example:**
```bash
curl http://localhost:3000/health
```

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2026-02-18T12:34:56.789Z",
  "api_keys": {
    "newsapi": true
  },
  "scraping": {
    "indonesia_news": true,
    "social_trends": true,
    "wikimedia": true
  }
}
```

## 🔑 Data Sources (Semua GRATIS!)

### NewsAPI (Optional)
1. Daftar di https://newsapi.org/register
2. Free tier: 100 requests/day, 7 days historical data
3. Copy API key ke `.env`
4. **Opsional** - server tetap jalan tanpa ini!

### CNN Indonesia Scraping (✓ Free)
- Source: https://www.cnnindonesia.com/terpopuler
- Method: Web scraping dengan Cheerio
- Data: Berita paling populer hari ini
- **Tidak perlu API key!**

### Detik.com Scraping (✓ Free)
- Source: https://www.detik.com/terpopuler
- Method: Web scraping dengan Cheerio
- Data: Berita trending Indonesia
- **Tidak perlu API key!**

### GetDayTrends Scraping (✓ Free)
- Source: https://getdaytrends.com/indonesia/
- Method: Web scraping dengan Cheerio
- Data: Twitter trending topics untuk Indonesia
- **Tidak perlu API key!**

### Wikimedia Pageviews (✓ Free)
- Source: https://wikimedia.org/api/rest_v1/
- Method: Public REST API
- Data: Artikel Wikipedia paling banyak dilihat
- **Tidak perlu API key!**

### Wikimedia Pageviews
Tidak perlu API key - public API! ✨

## 🔧 Integration dengan Flutter App

Update `assets/context.json` di Flutter project:

```json
{
  "context_url": "http://localhost:3000/trending?geo=ID&lang=id&limit=20",
  "context_limit": 8,
  "context_categories": ["social", "news"],
  "use_hyo_response": true
}
```

**NOTES:**
- Untuk production, ganti `localhost:3000` dengan domain server Anda
- `context_limit` mengontrol berapa item yang ditampilkan ke AI
- `context_categories` filter hanya social/news/knowledge
- `use_hyo_response` agar Hyo auto-reply saat keyword trending

## 📊 Data Flow

```
NewsAPI (opt) ──┐
                │
CNN Indonesia ──├─> Server.js ──> Dedup ──> Clustering ──> Scoring ──> JSON Response
(scraping)      │                                                            │
                ├────────────────────────────────────────────────────────────┬
Detik.com    ───┤                                                            │
(scraping)      ├────────────────────────────────────────────────────────────┤
                │                                                            v
GetDayTrends ───┤                                                      Flutter App
(scraping)      │                                                        (Hyo AI)
                │
Wikimedia ──────┘
(Public API)
```

## 🎯 Features

- ✅ 🆓 **100% FREE** - Tidak ada API berbayar!
- ✅ Multi-source scraping (CNN Indonesia, Detik, GetDayTrends)
- ✅ Smart deduplication (canonical URL + title hashing)
- ✅ Article clustering (mentions_24h calculation)
- ✅ Viral scoring algorithm (log-normalized, recency-weighted):
  - Rank-based scoring untuk trending topics
  - View count untuk Wikipedia articles
  - Mention clustering untuk berita
- ✅ Category filtering (social/news/knowledge)
- ✅ Auto-generated Hyo responses with emotion
- ✅ Trilingual support (Indonesian, English, Japanese)
- ✅ CORS enabled for Flutter web
- ✅ Timeout protection (5-8s per source)
- ✅ Fallback system jika scraping gagal

## 🐛 Troubleshooting

**Port 3000 sudah digunakan:**
```bash
# Edit .env dan ganti PORT
PORT=8080
```

**Scraping tidak menghasilkan data:**
- Check konsol untuk error messages
- Coba increase timeout di code (default: 5-8s)
- Beberapa website mungkin block scraping - gunakan fallback Wikimedia
- Check /health endpoint untuk status

**No trending data:**
- Wikimedia always works (public API)
- CNN Indonesia & Detik kadang berubah struktur HTML
- GetDayTrends adalah fallback untuk trending topics
- NewsAPI optional - bisa jalan tanpa ini

## ⚖️ Legal & Ethics

**PENTING - Scraping Guidelines:**
- ✅ CNN Indonesia, Detik: Scraping dari halaman publik terpopuler
- ✅ GetDayTrends: Agregator publik untuk trending topics
- ✅ Wikimedia: Public REST API (tidak perlu permission)
- ⚠️ Respek robots.txt dan Terms of Service masing-masing website
- ⚠️ Gunakan timeout yang wajar (5-8 detik)
- ⚠️ Jangan overload server dengan request berlebihan
- ⚠️ For production use, pertimbangkan caching (10-60 menit)

## 📝 License

MIT - Free to use!

---

**Made with ❤️ for Hyo AI**
