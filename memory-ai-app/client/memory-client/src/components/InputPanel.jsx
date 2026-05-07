export default function InputPanel({
  input,
  setInput,
  questions,
  onAsk,
  onGenerate,
}) {
  return (
    <div>
      <textarea
        rows={4}
        placeholder="写下一段记忆..."
        value={input}
        onChange={(e) => setInput(e.target.value)}
      />

      <button onClick={onAsk}>AI提问</button>

      <button onClick={onGenerate}>生成故事</button>

      <pre>{questions}</pre>
    </div>
  );
}