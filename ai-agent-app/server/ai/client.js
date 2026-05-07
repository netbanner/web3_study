import axios from "axios";

import { AI_PROVIDERS, TIMEOUT, MAX_RETRIES } from "./config.js";

export async function chatCompletion(messages, options = {}) {
  const { temperature = 0.7 } = options;

  let lastError = null;

  for (const provider of AI_PROVIDERS) {
    for (const model of provider.models) {
      for (let i = 0; i < MAX_RETRIES; i++) {
        try {
          console.log(
            `🚀 ${provider.name} | model=${model} | try=${i + 1}`
          );

          const res = await axios.post(
            `${provider.baseURL}/chat/completions`, 
            {
              model,
              messages,
              temperature
            },
            {
              headers: {
                "Content-Type": "application/json",
               Authorization: `Bearer ${provider.apiKey.trim()}`
              },
              timeout: TIMEOUT
            }
          );

          // ✅ 更严格解析
          const content =
            res.data?.choices?.[0]?.message?.content;

          if (!content) {
            console.error("⚠️ empty response:", res.data);
            throw new Error("Empty response from AI");
          }

          console.log(`✅ success: ${provider.name}:${model}`);
          return content;

        } catch (err) {
          lastError = err;

          console.error(
            `❌ fail ${provider.name}:${model} try=${i + 1}`,
            err.response?.data || err.message
          );
        }
      }
    }
  }

  throw new Error(
    `All providers failed: ${lastError?.message || "unknown"}`
  );
}