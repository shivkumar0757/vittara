# MCP Server Setup Guide

Connect Vittara to Claude Desktop (or any MCP-compatible AI client) so you can ask questions about your finances in natural language.

## How It Works

Vittara runs an embedded MCP (Model Context Protocol) server. You generate a token in Settings, paste it into your AI client config, and your AI assistant can then read and write your financial data through conversation.

**Endpoints (once app is running):**
- SSE: `http://your-vittara-url/mcp/sse`
- Messages: `http://your-vittara-url/mcp/messages`

---

## Step 1 — Generate an MCP Token

1. Open Vittara → Settings → API Key
2. Scroll to the **AI Assistant (MCP)** section
3. Click **Generate MCP Token**
4. Copy the token — it is only shown once

---

## Step 2 — Configure Claude Desktop

Open your Claude Desktop config file:

```
~/Library/Application Support/Claude/claude_desktop_config.json
```

Add or merge this block (replace `TOKEN_HERE` and the URL):

```json
{
  "mcpServers": {
    "vittara": {
      "url": "http://localhost:3000/mcp/sse",
      "headers": {
        "Authorization": "Bearer TOKEN_HERE"
      }
    }
  }
}
```

For a deployed instance, replace `localhost:3000` with your actual domain.

**Save the file and restart Claude Desktop.**

---

## Step 3 — Verify It Works

Ask Claude Desktop:

> "What accounts do I have and what are their balances?"

Claude will call the `get_accounts` tool and return your real account data.

---

## Step 4 — Test Without Claude Desktop (MCP Inspector)

You can verify the MCP server directly using the MCP Inspector CLI:

```bash
# Start Vittara first
bin/dev

# In a new terminal, run the inspector
npx @modelcontextprotocol/inspector http://localhost:3000/mcp/sse \
  --header "Authorization: Bearer YOUR_TOKEN_HERE"
```

The inspector shows all available tools and lets you call them manually.

---

## Available Tools

### Read Tools
| Tool | What it does |
|------|-------------|
| `get_financial_overview` | Net worth + assets/liabilities + this month income/expenses |
| `get_accounts` | All accounts with balances |
| `get_net_worth` | Net worth breakdown |
| `get_transactions` | Transactions with filters (account, date range, limit) |
| `get_categories` | Spending categories |

### Write Tools
| Tool | What it does |
|------|-------------|
| `create_transaction` | Log a new transaction |
| `update_transaction` | Edit an existing transaction |
| `create_account` | Add Depository, Investment, Crypto, OtherAsset, OtherLiability |
| `create_loan_account` | Add a loan (mortgage, auto, personal) |
| `create_credit_card_account` | Add a credit card |

---

## Security Notes

- Each MCP token is scoped to one user/family — no cross-family access
- Token has `read_write` scope — it can read and write data
- Revoke the token anytime from Settings → API Key → AI Assistant (MCP)
- Write tools ask Claude to confirm with you before executing (via tool description)
