export default function InputSidebar({
  input,
  setInput,
  onAsk,
  onGenerate,
  questions,
}) {
  return (
    <div>
      <h2>记忆输入</h2>

      <textarea
        rows={7}
        placeholder="写下一段记忆..."
        value={input}
        onChange={(e) =>
          setInput(e.target.value)
        }
      />

      <button onClick={onAsk}>
        AI提问
      </button>

      <button onClick={onGenerate}>
        生成故事
      </button>

      <div className="ai-card">
        <h4>AI的问题</h4>

        <pre>{questions}</pre>
      </div>
    </div>
  );
}