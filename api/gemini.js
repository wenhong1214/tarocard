const { Redis } = require("@upstash/redis");
const { Ratelimit } = require("@upstash/ratelimit");

// 初始化 Redis（仅在环境变量配置时生效）
const redis = (process.env.UPSTASH_REDIS_REST_URL) 
  ? new Redis({
      url: process.env.UPSTASH_REDIS_REST_URL,
      token: process.env.UPSTASH_REDIS_REST_TOKEN,
    }) 
  : null;

// 设置频率限制：每个 IP 每分钟最多 5 次请求 (滑动窗口)
const ratelimit = redis 
  ? new Ratelimit({
      redis: redis,
      limiter: Ratelimit.slidingWindow(5, "1 m"), 
    })
  : null;

module.exports = async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, x-app-version");

  if (req.method === "OPTIONS") {
    return res.status(200).end();
  }

  // 🔒 1. 拒绝旧 APK（没有正确版本 header 的请求全部拒绝）
  if (req.headers['x-app-version'] !== '2.0.0') {
    return res.status(403).json({ error: "请更新 App 才能继续使用" });
  }

  if (req.method !== "POST") {
    return res.status(405).json({ error: "Only POST allowed" });
  }

  try {
    // 🔒 2. 防刷机制（基于真实 IP 的 Rate Limiting）
    if (ratelimit) {
      // 在 Vercel 中，用户的真实 IP 藏在这个 Header 里
      const ip = req.headers["x-forwarded-for"] || req.connection.remoteAddress || "anonymous";
      const { success } = await ratelimit.limit(ip);
      
      if (!success) {
        return res.status(429).json({ error: "占卜请求过于频繁，请等待一分钟后再试。" });
      }
    }

    const { prompt } = req.body;
    if (!prompt) {
      return res.status(400).json({ error: "Missing prompt" });
    }

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      return res.status(500).json({ error: "Missing GEMINI_API_KEY" });
    }

    // 调用 Gemini API...
    const geminiRes = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }]
        })
      }
    );

    const data = await geminiRes.json();
    if (!geminiRes.ok) return res.status(geminiRes.status).json(data);

    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text || "No response from Gemini.";
    return res.status(200).json({ text });

  } catch (error) {
    return res.status(500).json({
      error: "Server error",
      detail: error.message
    });
  }
};