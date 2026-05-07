import { useState } from "react";

import Topbar from "./components/Topbar";

import InputSidebar from "./components/InputSidebar";

import Editor from "./components/Editor";

import Toolbar from "./components/Toolbar";

import {
  askQuestion,
  submitAnswer,
  rewriteMemory,
} from "./api/ai";

export default function App() {
  const [input, setInput] =
    useState("");

  const [questions, setQuestions] =
    useState("");

  const [content, setContent] =
    useState("");

  async function handleAsk() {
    const data =
      await askQuestion(input);

    setQuestions(
      data.questions ||
        data.result
    );
  }

  async function handleGenerate() {
    const data =
      await submitAnswer(input);

    setContent(data.result);
  }

  async function handleRewrite() {
    const selection =
      window.getSelection().toString();

    if (!selection) return;

    const data =
      await rewriteMemory(
        selection
      );

    setContent(
      content.replace(
        selection,
        data.result
      )
    );
  }

  return (
    <div className="app-layout">

      {/* 左侧 */}
      <aside className="sidebar">

        <InputSidebar
          input={input}
          setInput={setInput}
          questions={questions}
          onAsk={handleAsk}
          onGenerate={handleGenerate}
        />

      </aside>

      {/* 右侧 */}
      <main className="editor-layout">

        <Topbar />

        <div className="editor-scroll">

          <div className="editor-card">

            <Toolbar
              onRewrite={
                handleRewrite
              }
            />

            <Editor
              content={content}
              setContent={setContent}
            />

          </div>

        </div>

      </main>

    </div>
  );
}