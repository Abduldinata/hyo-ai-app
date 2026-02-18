require('dotenv').config();
const express = require('express');
const axios = require('axios');
const crypto = require('crypto');
const cheerio = require('cheerio');
const { spawn } = require('child_process');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// API Keys from .env
const NEWSAPI_KEY = process.env.NEWSAPI_KEY;

// Helper: Generate hash for deduplication
function generateHash(str) {
  return crypto.createHash('sha1').update(str.toLowerCase()).digest('hex');
}

// Helper: Normalize URL for canonical comparison
function canonicalUrl(url) {
  if (!url) return '';
  try {
    const u = new URL(url);
    // Remove www, trailing slash, query params for comparison
    return u.hostname.replace(/^www\./, '') + u.pathname.replace(/\/$/, '');
  } catch {
    return url.toLowerCase();
  }
}

// Helper: Normalize title (remove extra spaces, lowercase)
function normalizeTitle(title) {
  if (!title) return '';
  return title.toLowerCase().replace(/\s+/g, ' ').trim();
}

// Fetch from NewsAPI
async function fetchNewsApi(params) {
  if (!NEWSAPI_KEY) return [];
  
  const { geo = 'ID', lang = 'id', from, to, limit = 20 } = params;
  
  try {
    const response = await axios.get('https://newsapi.org/v2/everything', {
      params: {
        apiKey: NEWSAPI_KEY,
        q: 'trending OR viral OR populer',
        language: lang,
        from: from || new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
        to: to || new Date().toISOString().split('T')[0],
        sortBy: 'popularity',
        pageSize: limit
      },
      timeout: 5000
    });

    return response.data.articles.map(article => ({
      source: 'newsapi',
      category: 'news',
      platform: article.source.name || 'NewsAPI',
      entity_type: 'article',
      title: article.title,
      description: article.description,
      url: article.url,
      media: article.urlToImage ? [{ type: 'image', url: article.urlToImage }] : [],
      author: article.author,
      published_at: article.publishedAt,
      raw_data: article
    }));
  } catch (error) {
    console.error('NewsAPI error:', error.message);
    return [];
  }
}

// Fetch from Indonesia Local News (CNN Indonesia, Detik, Kompas)
async function fetchIndonesiaNews(params) {
  const { limit = 10 } = params;
  const items = [];
  
  try {
    // CNN Indonesia - Most Popular
    const cnnResponse = await axios.get('https://www.cnnindonesia.com/terpopuler', {
      timeout: 5000,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      }
    });
    
    const $ = cheerio.load(cnnResponse.data);
    $('.media__list .media__link').slice(0, 5).each((i, el) => {
      const title = $(el).find('.media__title').text().trim();
      const url = $(el).attr('href');
      if (title && url) {
        items.push({
          source: 'cnn_indonesia',
          category: 'news',
          platform: 'CNN Indonesia',
          entity_type: 'article',
          title: title,
          description: 'Popular news from CNN Indonesia',
          url: url.startsWith('http') ? url : `https://www.cnnindonesia.com${url}`,
          media: [],
          published_at: new Date().toISOString(),
          raw_data: { source: 'cnn_indonesia' }
        });
      }
    });
  } catch (error) {
    console.error('CNN Indonesia scraping error:', error.message);
  }
  
  try {
    // Detik.com - Most Popular
    const detikResponse = await axios.get('https://www.detik.com/terpopuler', {
      timeout: 5000,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      }
    });
    
    const $$ = cheerio.load(detikResponse.data);
    $$('.list-content article').slice(0, 5).each((i, el) => {
      const title = $$(el).find('h3').text().trim() || $$(el).find('h2').text().trim();
      const url = $$(el).find('a').attr('href');
      if (title && url) {
        items.push({
          source: 'detik',
          category: 'news',
          platform: 'Detik.com',
          entity_type: 'article',
          title: title,
          description: 'Popular news from Detik.com',
          url: url,
          media: [],
          published_at: new Date().toISOString(),
          raw_data: { source: 'detik' }
        });
      }
    });
  } catch (error) {
    console.error('Detik scraping error:', error.message);
  }
  
  return items.slice(0, limit);
}

// Scrape trending topics from public aggregators
async function scrapeSocialTrends(params) {
  const { geo = 'ID', limit = 10 } = params;
  const items = [];
  
  try {
    // GetDayTrends.com - Free trending aggregator
    const country = geo === 'ID' ? 'indonesia' : 'indonesia';
    const response = await axios.get(`https://getdaytrends.com/${country}/`, {
      timeout: 8000,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      }
    });
    
    const $ = cheerio.load(response.data);
    
    // Extract trending topics
    $('.trend-card__list li, .trend-card a, table.table tr').slice(0, limit).each((i, el) => {
      const text = $(el).text().trim();
      const link = $(el).find('a').attr('href') || $(el).attr('href');
      
      if (text && text.length > 2 && text.length < 100) {
        // Extract hashtag or topic name
        const title = text.replace(/^\d+\.?\s*/, '').replace(/\s+\d+.*$/, '').trim();
        if (title) {
          items.push({
            source: 'getdaytrends',
            category: 'social',
            platform: 'Twitter Trends',
            entity_type: 'topic',
            title: title,
            description: `Trending in ${geo}`,
            url: link && link.includes('twitter.com') ? link : `https://twitter.com/search?q=${encodeURIComponent(title)}`,
            metrics: {
              rank: i + 1
            },
            raw_data: { source: 'getdaytrends' }
          });
        }
      }
    });
  } catch (error) {
    console.error('GetDayTrends scraping error:', error.message);
  }
  
  // Fallback: Generate from Wikimedia trending
  if (items.length === 0) {
    try {
      const wikiItems = await fetchWikiPageviews({ ...params, limit: 5 });
      wikiItems.forEach(item => {
        items.push({
          source: 'wikimedia_fallback',
          category: 'social',
          platform: 'Trending Topics',
          entity_type: 'topic',
          title: item.title,
          description: `Trending: ${item.description}`,
          url: item.url,
          metrics: item.metrics,
          raw_data: { source: 'wikimedia_fallback' }
        });
      });
    } catch (error) {
      console.error('Wikimedia fallback error:', error.message);
    }
  }
  
  return items.slice(0, limit);
}

// Fetch from Wikimedia Pageviews API
async function fetchWikiPageviews(params) {
  const { lang = 'id', limit = 10 } = params;
  
  try {
    // Get yesterday's date in YYYYMMDD format
    const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const dateStr = yesterday.toISOString().split('T')[0].replace(/-/g, '');
    
    const response = await axios.get(
      `https://wikimedia.org/api/rest_v1/metrics/pageviews/top/${lang}.wikipedia/all-access/${dateStr.slice(0,4)}/${dateStr.slice(4,6)}/${dateStr.slice(6,8)}`,
      { timeout: 5000 }
    );

    return (response.data.items[0]?.articles || []).slice(0, limit).map(article => ({
      source: 'wikimedia',
      category: 'knowledge',
      platform: 'Wikipedia',
      entity_type: 'article',
      title: decodeURIComponent(article.article).replace(/_/g, ' '),
      description: `${article.views.toLocaleString()} views yesterday`,
      url: `https://${lang}.wikipedia.org/wiki/${article.article}`,
      metrics: {
        views_24h: article.views,
        rank: article.rank
      },
      raw_data: article
    }));
  } catch (error) {
    console.error('Wikimedia API error:', error.message);
    return [];
  }
}

// Enrich and finalize items (dedup, clustering, scoring)
function enrichAndFinalize(rawItems, params) {
  const seenHashes = new Set();
  const items = [];
  
  // Deduplication by canonical URL + title
  for (const item of rawItems) {
    const canonical = canonicalUrl(item.url);
    const titleNorm = normalizeTitle(item.title);
    const key = generateHash(canonical + titleNorm);
    
    if (!seenHashes.has(key)) {
      seenHashes.add(key);
      items.push({
        ...item,
        canonical_key: key
      });
    }
  }
  
  // Clustering: Group news articles by similar title + domain
  const clusters = {};
  for (const item of items) {
    if (item.entity_type === 'article' && item.category === 'news') {
      const domain = canonicalUrl(item.url).split('/')[0];
      const titleWords = normalizeTitle(item.title).split(' ').slice(0, 5).join(' ');
      const clusterKey = generateHash(domain + titleWords);
      
      if (!clusters[clusterKey]) {
        clusters[clusterKey] = [];
      }
      clusters[clusterKey].push(item);
    }
  }
  
  // Add mentions_24h for clustered articles
  for (const item of items) {
    if (item.entity_type === 'article' && item.category === 'news') {
      const domain = canonicalUrl(item.url).split('/')[0];
      const titleWords = normalizeTitle(item.title).split(' ').slice(0, 5).join(' ');
      const clusterKey = generateHash(domain + titleWords);
      
      if (clusters[clusterKey]) {
        item.mentions_24h = clusters[clusterKey].length;
      }
    }
  }
  
  // Score all items
  const scoredItems = items.map(item => scoreItem(item));
  
  // Sort by viral score
  scoredItems.sort((a, b) => b.score.viral - a.score.viral);
  
  // Apply limit
  const limit = params.limit || 20;
  return scoredItems.slice(0, limit);
}

// Viral scoring algorithm
function scoreItem(item) {
  let viral = 0;
  let confidence = 0.5;
  let engagement_rate = 0;
  
  // Base score from metrics
  const metrics = item.metrics || {};
  
  if (metrics.tweet_count) {
    // Twitter: Log-normalized tweet count
    viral = Math.min(100, Math.log10(metrics.tweet_count + 1) * 20);
    confidence = 0.85;
    engagement_rate = viral / 100;
  } else if (metrics.view_count) {
    // Video platforms: Log-normalized view count
    viral = Math.min(100, Math.log10(metrics.view_count + 1) * 12);
    confidence = 0.8;
    const total_engagement = (metrics.like_count || 0) + (metrics.comment_count || 0) + (metrics.share_count || 0);
    engagement_rate = metrics.view_count > 0 ? Math.min(1, total_engagement / metrics.view_count) : 0;
  } else if (metrics.like_count && metrics.comments_count !== undefined) {
    // Social posts: Engagement-based scoring
    const total_engagement = (metrics.like_count || 0) + (metrics.comments_count || 0);
    viral = Math.min(100, Math.log10(total_engagement + 1) * 18);
    confidence = 0.75;
    engagement_rate = Math.min(1, total_engagement / 10000);
  } else if (metrics.views_24h) {
    // Wikipedia: Log-normalized views
    viral = Math.min(100, Math.log10(metrics.views_24h + 1) * 15);
    confidence = 0.75;
    engagement_rate = viral / 100;
  } else if (metrics.rank) {
    // Scraped trending: Rank-based scoring (higher rank = higher score)
    viral = Math.max(30, 100 - (metrics.rank * 5)); // Rank 1 = 95, Rank 10 = 50
    confidence = 0.65;
    engagement_rate = viral / 100;
  } else if (item.mentions_24h) {
    // News: Mentions-based scoring
    viral = Math.min(100, item.mentions_24h * 10);
    confidence = 0.7;
    engagement_rate = Math.min(1, item.mentions_24h / 20);
  } else {
    // Fallback: Medium baseline for scraped content
    viral = Math.random() * 30 + 40; // 40-70 range (higher than news baseline)
    confidence = 0.5;
    engagement_rate = 0.5;
  }
  
  // Recency weighting
  if (item.published_at) {
    const age = (Date.now() - new Date(item.published_at).getTime()) / (1000 * 60 * 60); // hours
    const recencyBoost = Math.max(0, 1 - age / 168); // Decay over 7 days
    viral = viral * (0.7 + 0.3 * recencyBoost); // 70-100% of original score
  }
  
  // Provenance tracking
  const provenance = {
    fetched_at: new Date().toISOString(),
    source_api: item.source,
    dedup_key: item.canonical_key
  };
  
  return {
    id: generateHash(item.url + item.title + Date.now()),
    category: item.category,
    platform: item.platform,
    entity_type: item.entity_type,
    title: item.title,
    description: item.description,
    url: item.url,
    media: item.media || [],
    author: item.author,
    published_at: item.published_at,
    metrics: {
      ...metrics,
      mentions_24h: item.mentions_24h
    },
    score: {
      viral: Math.round(viral * 10) / 10,
      confidence: Math.round(confidence * 100) / 100,
      engagement_rate: Math.round(engagement_rate * 100) / 100
    },
    provenance
  };
}

// Generate Hyo response based on top trends
function generateHyoResponse(items, params) {
  const { lang = 'id' } = params;
  
  if (items.length === 0) {
    return {
      emotion: 'neutral',
      lang: lang,
      text: lang === 'id' 
        ? 'Hmm, aku gak nemu trending topic yang menarik nih...'
        : 'Hmm, I couldn\'t find any interesting trending topics...'
    };
  }
  
  const top = items[0];
  const emotions = ['happy', 'excited', 'curious'];
  const emotion = emotions[Math.floor(Math.random() * emotions.length)];
  
  let text;
  if (lang === 'id') {
    text = `Wah, lagi rame banget nih tentang "${top.title}"! Viral score-nya ${top.score.viral}/100 lho~ 🔥`;
  } else if (lang === 'en') {
    text = `Wow, "${top.title}" is trending hard right now! Viral score ${top.score.viral}/100~ 🔥`;
  } else if (lang === 'ja') {
    text = `うわー、"${top.title}"が超話題になってるよ！バイラルスコア${top.score.viral}/100だって〜 🔥`;
  } else {
    text = `Trending: "${top.title}" (Viral: ${top.score.viral}/100)`;
  }
  
  return { emotion, lang, text };
}

// Main endpoint: /trending
app.get('/trending', async (req, res) => {
  try {
    const params = {
      geo: req.query.geo || 'ID',
      lang: req.query.lang || 'id',
      from: req.query.from,
      to: req.query.to,
      limit: parseInt(req.query.limit) || 20
    };
    
    console.log('Fetching trending data with params:', params);
    
    // Fetch from all sources in parallel
    const [newsApiItems, idNewsItems, socialTrends, wikiItems] = await Promise.all([
      fetchNewsApi(params),
      fetchIndonesiaNews(params),
      scrapeSocialTrends(params),
      fetchWikiPageviews(params)
    ]);
    
    // Combine all items
    const allItems = [
      ...newsApiItems,
      ...idNewsItems,
      ...socialTrends,
      ...wikiItems
    ];
    
    console.log(`Fetched ${allItems.length} raw items from ${[newsApiItems.length, idNewsItems.length, socialTrends.length, wikiItems.length].join(', ')}`);
    
    // Enrich, deduplicate, cluster, score
    const items = enrichAndFinalize(allItems, params);
    
    // Generate Hyo's response
    const hyo = generateHyoResponse(items, params);
    
    // Build response
    const response = {
      meta: {
        timestamp: new Date().toISOString(),
        params: params,
        total_items: items.length,
        sources: {
          newsapi: newsApiItems.length,
          indonesia_news: idNewsItems.length,
          social_trends: socialTrends.length,
          wikimedia: wikiItems.length
        }
      },
      items: items,
      hyo: hyo
    };
    
    res.json(response);
    
  } catch (error) {
    console.error('Trending endpoint error:', error);
    res.status(500).json({
      error: 'Failed to fetch trending data',
      message: error.message
    });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    api_keys: {
      newsapi: !!NEWSAPI_KEY
    },
    scraping: {
      indonesia_news: true,
      social_trends: true,
      wikimedia: true
    }
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`\n🚀 Hyo AI Trending API Server (FREE VERSION)`);
  console.log(`📡 Running on http://localhost:${PORT}`);
  console.log(`\n🔑 API Keys configured:`);
  console.log(`   NewsAPI: ${NEWSAPI_KEY ? '✓' : '✗'}`);
  console.log(`\n🌐 Scraping sources:`);
  console.log(`   ✓ CNN Indonesia (most popular)`);
  console.log(`   ✓ Detik.com (most popular)`);
  console.log(`   ✓ GetDayTrends (social trends)`);
  console.log(`   ✓ Wikimedia Pageviews (trending articles)`);
  console.log(`\n📊 Endpoints:`);
  console.log(`   GET /trending?geo=ID&lang=id&limit=20`);
  console.log(`   GET /health`);
  console.log(`\n💡 Example: http://localhost:${PORT}/trending?geo=ID&lang=id&limit=10\n`);
  
  // Auto-start VoiceVox only when explicitly enabled
  if (process.env.AUTO_START_VOICEVOX === '1') {
    // (auto-start VoiceVox dihapus, jalankan manual jika perlu)
  }
});


