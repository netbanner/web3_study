import React, { useState } from 'react';
import axios from 'axios';

const sessionId = Math.random().toString(36).substring(2, 10);

export default function App() {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState("");

  const handleSubmit = async (e) => {
    const res = await axios.post("http://localhost:3001/api/chat", {
      sessionId,
      message: input,
    });
    setMessages([...messages, { role: "user", content: input }, { role: "ai", content: res.data.reply }]);
 
    if (res.data.shareUrl) {
      window.open(res.data.shareUrl,"_blank");
    }
       setInput("");
  };

  return (
    <div>
      <h1>AI Agent App</h1>
      <div>
        {messages.map((message, index) => (
          <div key={index}>
            <p>{message.role}: {message.content}</p>
          </div>
        ))}
      </div>
      
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
        />
        <button onClick={handleSubmit}>Send</button>
 
    </div>
  );  
}