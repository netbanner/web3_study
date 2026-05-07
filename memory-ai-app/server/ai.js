import axios from "axios";
import crypto from "crypto";
import { AI_PROVIDERS, TIMEOUT, MAX_RETRIES } from "./config.js";
import { getCache, setCache } from "./cache.js";

function getCacheKey(messages) {
  return crypto.createHash("md5").update(JSON.stringify(messages)).digest("hex");
}

export async function chatCompletion(messages, options = {}) {
  const { temperature = 0.7 } = options;
  const cacheKey = getCacheKey(messages);
  const cached = getCache(cacheKey);
  if (cached) {
    console.log("⚡ cache hit");
    return cached;
  }
  let lastError = null;
  const requestId = Date.now();
  for (const provider of AI_PROVIDERS) {
    for (const model of provider.models) {
      for (let i = 0; i < MAX_RETRIES; i++) {
        try {
          console.log(
            `🚀 [${requestId}] ${provider.name}:${model} try=${i + 1}`
          );

          const res = await axios.post(
            `${provider.baseURL}/chat/completions`,
            {
              model,
              messages,
              temperature,
            },
            {
              headers: {
                Authorization: `Bearer ${provider.apiKey.trim()}`,
              },
              timeout: TIMEOUT,
            }
          );

          const content = res.data?.choices?.[0]?.message?.content;

          if (!content) throw new Error("Empty response");

          console.log(`✅ success`);

          setCache(cacheKey, content);
          return content;

        } catch (err) {
          lastError = err;
          const status = err.response?.status;

          console.error("❌ error", status, err.message);

          if (status === 401) throw new Error("API Key invalid");

          if (status === 429) {
            await new Promise(r => setTimeout(r, 1000 * (i + 1)));
          }
        }
      }
    }
  }

  throw new Error(lastError?.message || "AI failed");
}   
