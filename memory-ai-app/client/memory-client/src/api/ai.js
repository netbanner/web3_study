const AI_URL = "http://localhost:3000/api"; 


export async function askQuestion(input) {
  const response = await fetch(`${AI_URL}/question`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ input })
  });
  return response.json();
}

export async function submitAnswer(input) {
  const response = await fetch(`${AI_URL}/answer`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ input })
  });
  return response.json();
}

export async function rewriteMemory(text) {
  const response = await fetch(`${AI_URL}/rewrite`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ text })
  });
  return response.json();
}