const express = require('express');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

// OpenAI-compatible chat endpoint
app.post('/v1/chat/completions', async (req, res) => {
  try {
    const { messages, model = "claude-sonnet-4" } = req.body;
    
    const response = await fetch('https://api.puter.com/v2/ai/chat', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        messages,
        model,
        stream: false
      })
    });
    
    const data = await response.json();
    
    // Convert to OpenAI format
    res.json({
      id: "chatcmpl-" + Date.now(),
      object: "chat.completion",
      created: Math.floor(Date.now() / 1000),
      model: model,
      choices: [{
        index: 0,
        message: {
          role: "assistant",
          content: data.message.content[0].text
        },
        finish_reason: "stop"
      }]
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
