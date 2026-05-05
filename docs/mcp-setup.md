# MCP Server Setup Guide

Connect Vittara to Claude Desktop, Cursor, or Claude's Custom Connector so you can ask questions about your finances in natural language.

## How It Works

Vittara runs an embedded MCP (Model Context Protocol) server using the [official MCP Ruby SDK](https://github.com/modelcontextprotocol/ruby-sdk). It supports **Streamable HTTP** transport — a single endpoint where each request is a stateless POST.

**Endpoint (once app is running):**
- `http://your-vittara-url/mcp`

Two authentication methods are supported:
- **Bearer token** (for Claude Desktop / Cursor) — generate a token in Settings
- **OAuth 2.0** (for Claude Custom Connector) — users authorize via the OAuth consent screen

---

## Option A — Bearer Token (Claude Desktop / Cursor)

### Step 1 — Generate an MCP Token

1. Open Vittara → Settings → API Key
2. Scroll to the **AI Assistant (MCP)** section
3. Click **Generate MCP Token**
4. Copy the token — it is only shown once

---

### Step 2 — Configure Claude Desktop

Open your Claude Desktop config file:

```
~/Library/Application Support/Claude/claude_desktop_config.json
```

Claude Desktop connects via stdio, so it needs `mcp-remote` as a bridge (installed automatically via npx). Add or merge this block (replace `TOKEN_HERE` and the URL):

```json
{
  "mcpServers": {
    "vittara": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "http://localhost:3000/mcp",
        "--header",
        "Authorization:Bearer TOKEN_HERE"
      ]
    }
  }
}
```

For a deployed instance, replace `localhost:3000` with your actual domain.

**Save the file and restart Claude Desktop.**

### Step 2 (alternative) — Configure Cursor / VS Code

Cursor and VS Code MCP extensions support HTTP directly. Add to `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "vittara": {
      "url": "http://localhost:3000/mcp",
      "headers": {
        "Authorization": "Bearer TOKEN_HERE"
      }
    }
  }
}
```

---

### Step 3 — Verify It Works

Ask Claude Desktop:

> "What accounts do I have and what are their balances?"

Claude will call the `get_accounts` tool and return your real account data.

---

### Step 4 — Test Without Claude Desktop (MCP Inspector)

You can verify the MCP server directly using the MCP Inspector CLI:

```bash
# Start Vittara first
bin/dev

# In a new terminal, run the inspector
npx @modelcontextprotocol/inspector http://localhost:3000/mcp \
  --header "Authorization: Bearer YOUR_TOKEN_HERE"
```

The inspector shows all available tools and lets you call them manually.

---

## Option B — OAuth (Claude Custom Connector)

Claude's Custom Connector uses OAuth 2.0 — users click "Connect" on claude.ai and authorize without pasting tokens.

### Step 1 — Create a Doorkeeper Application

1. Go to `/oauth/applications` (requires `super_admin` role)
2. Create a new application:
   - **Name:** Claude Connector
   - **Redirect URI:**
     ```
     https://claude.ai/api/mcp/auth_callback
     https://claude.com/api/mcp/auth_callback
     ```
   - **Confidential:** checked
   - **Scopes:** `read read_write`
3. Copy the **Client ID** and **Client Secret**

### Step 2 — Add the Connector in Claude

On claude.ai → Settings → Connectors → Add Custom Connector:

- **MCP URL:** `https://your-vittara-url/mcp`
- **Client ID:** (from Step 1)
- **Client Secret:** (from Step 1)

### Step 3 — Authorize

Click **Connect**. You'll be redirected to Vittara to log in and authorize. After authorizing, Claude can call tools on your behalf.

**OAuth discovery endpoints (used automatically by Claude):**
- `/.well-known/oauth-authorization-server` — RFC 8414 metadata
- `/.well-known/oauth-protected-resource` — RFC 9728 metadata

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
| `get_tags` | List all tags (id, name, color) for the family |

### Write Tools (requires `read_write` scope)
| Tool | What it does |
|------|-------------|
| `create_transaction` | Log a new transaction |
| `update_transaction` | Edit an existing transaction |
| `create_transfer` | Move money between accounts. Auto-classifies as CC payment, loan/EMI payment, or regular transfer based on destination account type. |
| `create_tag` | Create a tag (name + optional color). Tag IDs can be attached to transactions via `tag_ids`. |
| `create_account` | Add Depository, Investment, Crypto, OtherAsset, OtherLiability |
| `create_loan_account` | Add a loan (mortgage, auto, personal) |
| `create_credit_card_account` | Add a credit card |

---

## Security Notes

- Each MCP token is scoped to one user/family — no cross-family access
- Bearer tokens have `read_write` scope — they can read and write data
- OAuth tokens are scoped at authorization time (`read` or `read_write`)
- Revoke Bearer tokens anytime from Settings → API Key → AI Assistant (MCP)
- Revoke OAuth tokens from `/oauth/authorized_applications`
- Write tools ask Claude to confirm with you before executing (via tool description)
