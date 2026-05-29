module.exports = async function handler(req, res) {
  // 设置跨域 CORS
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, x-app-version"); // 👈 必须允许 x-app-version 通过

  if (req.method === "OPTIONS") {
    return res.status(200).end();
  }

  // 🔒 拒绝旧 APK（没有版本 header 或者版本不对的请求全部拒绝）
  if (req.headers['x-app-version'] !== '2.0.0') {
    return res.status(403).json({ error: "请更新 App 才能继续使用" });
  }

  if (req.method !== "POST") {
    return res.status(405).json({ error: "Only POST allowed" });
  }

  try {
    const { prompt } = req.body;

    if (!prompt) {
      return res.status(400).json({ error: "Missing prompt" });
    }

    const apiKey = process.env.GEMINI_API_KEY;

    if (!apiKey) {
      return res.status(500).json({
        error: "Missing GEMINI_API_KEY in Vercel Environment Variables"
      });
    }

    // 调用 Google Gemini 接口 (已修正为 gemini-1.5-flash)
    const geminiRes = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          contents: [
            {
              parts: [{ text: prompt }]
            }
          ]
        })
      }
    );

    const data = await geminiRes.json();

    if (!geminiRes.ok) {
      // 捕获 Gemini 的报错并返回给前端
      return res.status(geminiRes.status).json(data);
    }

    const text =
      data?.candidates?.[0]?.content?.parts?.[0]?.text ||
      "No response from Gemini.";

    return res.status(200).json({ text });
  } catch (error) {
    console.error("Vercel 执行错误:", error);
    return res.status(500).json({
      error: "Server error",
      detail: error.message
    });
  }
};