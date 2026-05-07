import express from "express";
import cors from "cors";
import { chatCompletion } from "./ai.js";

const app = express();
app.use(cors());
app.use(express.json());

app.post("/api/question", async (req, res) => {
  const { input } = req.body;
  const result = await chatCompletion([
    { role: "user", content: `你是记忆采访者，请提出4个具体问题：${input}` },
  ]);
 res.json({ questions: result });
});

app.post("/api/answer", async (req, res) => {
  const { input ,answers} = req.body;
  const result = await chatCompletion(
    [
      {
        role: "user",
        content: `
你是口述历史记录者：

输入：${input}
补充：${answers}

写成真实记忆：
- 多细节
- 不要像作文
- 用第一人称
`,
      },
    ],
    { temperature: 0.85 }
  );
    res.json({ result });
});


// ✨ 改写
app.post("/api/rewrite", async (req, res) => {
  const { text } = req.body;

  const result = await chatCompletion([
    {
      role: "user",
      content: `改写这段为真实记忆表达：${text}`
    }
  ], { temperature: 0.9 });

  res.json({ result });
});

app.listen(3000, () => {
  console.log("🚀 http://localhost:3000");
});