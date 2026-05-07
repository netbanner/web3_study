import dotenv from "dotenv";

dotenv.config(); // 👈 放这里（关键）

const apiKey = process.env.OPENAI_API_KEY;

export const AI_PROVIDERS = [{
    models: ["gpt-4.1-mini"],
    name: "OpenAI",
    baseURL: "https://apis.itedus.cn/v1",
    apiKey: apiKey
}];
export const TIMEOUT = 15000;
export const MAX_RETRIES = 2;
