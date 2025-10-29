const puppeteer = require('puppeteer');

class PuterAIHandler {
  constructor() {
    this.browser = null;
    this.page = null;
  }

  async initialize() {
    if (!this.browser) {
      this.browser = await puppeteer.launch({
        headless: 'new',
        args: [
          '--no-sandbox',
          '--disable-setuid-sandbox',
          '--disable-dev-shm-usage',
          '--disable-accelerated-2d-canvas',
          '--no-first-run',
          '--no-zygote',
          '--disable-gpu'
        ]
      });
      
      this.page = await this.browser.newPage();
      
      // Inject Puter.js and setup
      await this.page.goto('about:blank');
      await this.page.addScriptTag({ url: 'https://js.puter.com/v2/' });
      
      // Wait for puter to load
      await this.page.waitForFunction(() => typeof puter !== 'undefined', { timeout: 10000 });
    }
  }

  async chat(message, model = 'claude-sonnet-4', stream = false) {
    await this.initialize();

    return await this.page.evaluate(async (msg, mdl, strm) => {
      try {
        if (strm) {
          // Streaming response
          const response = await puter.ai.chat(msg, { model: mdl, stream: true });
          let fullResponse = '';
          
          for await (const part of response) {
            const text = part?.text || '';
            fullResponse += text;
            // In a real scenario, you'd want to send chunks back
          }
          
          return { 
            message: fullResponse,
            usage: { input_tokens: 0, output_tokens: 0 } // Puter doesn't provide token counts
          };
        } else {
          // Non-streaming response
          const response = await puter.ai.chat(msg, { model: mdl });
          return {
            message: response.message.content[0].text,
            usage: { input_tokens: 0, output_tokens: 0 }
          };
        }
      } catch (error) {
        throw new Error(`Puter.js error: ${error.message}`);
      }
    }, message, model, stream);
  }

  async close() {
    if (this.browser) {
      await this.browser.close();
      this.browser = null;
      this.page = null;
    }
  }
}

const handler = new PuterAIHandler();

// Handle graceful shutdown
process.on('SIGINT', async () => {
  await handler.close();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await handler.close();
  process.exit(0);
});

module.exports = {
  puterAIHandler: async (message, model, stream = false, onChunk = null) => {
    return await handler.chat(message, model, stream);
  }
};
