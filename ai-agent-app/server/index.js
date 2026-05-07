import express from "express";
import cors from "cors";
import { v4 as uuidv4 } from "uuid";
import { sessions, pages } from "./store.js";
import { chatCompletion } from "./ai/client.js";

const app = express();
app.use(cors());
app.use(express.json());

/**
 * 多轮 Agent Chat
 */
app.post("/api/chat", async (req, res) => {
  try {
    const { sessionId, message } = req.body;

    console.log("📩 message:", message);

    if (!sessions[sessionId]) {
      sessions[sessionId] = {
        messages: [],
        state: "INIT"
      };
    }

    const session = sessions[sessionId];
    session.messages.push({ role: "user", content: message });

    // 🤖 Planner
    const reply = await chatCompletion([
      {
        role: "system",
        content: `
你是AI网页规划Agent：
- 信息不够 → 提问
- 信息够 → 返回 {"ready": true}
        `
      },
      ...session.messages
    ]);

    // ❌ 还需要补信息
    if (!reply.includes("ready")) {
      return res.json({ reply });
    }

    // 🤖 Generator
    const markdown = await chatCompletion([
      {
        role: "system",
        content: "生成一个结构清晰的Markdown网页"
      },
      ...session.messages
    ]);

    // HTML 渲染
    const html = `
    <html>
    <head>
      <meta charset="UTF-8"/>
      <style>
        body {
          font-family: Arial;
          max-width: 800px;
          margin: auto;
          padding: 40px;
        }
      </style>
    </head>
    <body>
      <div id="app"></div>
      <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
      <script>
        document.getElementById("app").innerHTML =
          marked.parse(\`${markdown.replace(/`/g, "\\`")}\`);
      </script>
    </body>
    </html>
    `;

    const pageId = uuidv4().slice(0, 8);
    pages[pageId] = html;

    res.json({
      reply: "页面已生成",
      shareUrl: `http://localhost:3001/api/p/${pageId}`
    });

  } catch (e) {
    console.error("🔥 ERROR:", e);

    res.status(500).json({
      error: "AI服务暂时不可用"
    });
  }
});

/**
 * 分享页面
 */
app.get("/api/p/:id", (req, res) => {
  const page = pages[req.params.id];

  if (!page) {
    return res.status(404).send("页面不存在");
  }

  res.send(page);
});

/**
 * 健康检查（部署用）
 */
app.get("/", (req, res) => {
  res.send("AI Agent Server Running");
});

app.listen(3001, () => {
  console.log("🚀 Server running on http://localhost:3001");
});