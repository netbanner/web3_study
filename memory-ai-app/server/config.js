import dotenv from "dotenv";
import e from "express";
dotenv.config();
if (!process.env.OPENAI_API_KEY) {
  throw new Error("Missing OPENAI_API_KEY");
}
const apiKey = process.env.OPENAI_API_KEY;

export const AI_PROVIDERS = [
  {
    name: "OpenAI",
    models: ["gpt-4.1-mini"],
    baseURL: process.env.OPENAI_BASE_URL || "https://api.openai.com/v1",
    apiKey: process.env.OPENAI_API_KEY,
  },
];
export const TIMEOUT = 15000;
export const MAX_RETRIES = 2;
