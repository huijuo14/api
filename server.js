const express = require('express');
const cors = require('cors');
require('dotenv').config();
const { puterAIHandler } = require('./puter-handler');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/', (req, res) => {
  res.json({ 
    message: 'Claude API Server is running!',
    endpoints: {
      chat: 'POST /api/chat',
      models: 'GET /api/models'
    },
    usage: 'Send a POST request to /api/chat with { "message": "your message", "model": "claude-sonnet-4" }'
  });
});

// Get available models
app.get('/api/models', (req, res) => {
  res.json({
    models: [
      'claude-sonnet-4',
      'claude-opus-4', 
      'claude-opus-4-1',
      'claude-sonnet-4-5',
      'claude-3-7-sonnet',
      'claude-3-7-opus'
    ],
    default: 'claude-sonnet-4'
  });
});

// Chat endpoint
app.post('/api/chat', async (req, res) => {
  try {
    const { message, model = 'claude-sonnet-4', stream = false } = req.body;

    if (!message) {
      return res.status(400).json({ error: 'Message is required' });
    }

    console.log(`Processing request: ${message.substring(0, 50)}...`);

    const response = await puterAIHandler(message, model, stream);
    
    res.json({
      success: true,
      model,
      message: response.message,
      usage: response.usage,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
});

// Streaming chat endpoint
app.post('/api/chat/stream', async (req, res) => {
  try {
    const { message, model = 'claude-sonnet-4' } = req.body;

    if (!message) {
      return res.status(400).json({ error: 'Message is required' });
    }

    res.setHeader('Content-Type', 'text/plain; charset=utf-8');
    res.setHeader('Transfer-Encoding', 'chunked');

    await puterAIHandler(message, model, true, (chunk) => {
      res.write(chunk);
    });

    res.end();

  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: error.message });
  }
});

app.listen(PORT, () => {
  console.log(`🚀 Claude API Server running on port ${PORT}`);
  console.log(`📚 API Documentation: http://localhost:${PORT}`);
});
