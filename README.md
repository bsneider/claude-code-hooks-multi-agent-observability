# Multi-Agent Observability System V2

This revised system provides a professional-grade, real-time monitoring solution for Claude Code agents. It leverages Claude Code's **native OpenTelemetry (OTel) integration** for quantitative metrics and logs, while reserving hooks for powerful, qualitative event-driven enhancements.

This V2 architecture corrects the critical flaws of the original approach by eliminating inefficient, per-event LLM calls and capturing far richer data directly from the agent's core. You can watch the [full breakdown of the original system here](https://youtu.be/9ijnN985O_c) and watch the latest enhancement where we compare Haiku 4.5 and Sonnet 4.5 [here](https://youtu.be/aA9KP7QIQvM).

## 🎯 Overview

This system provides complete observability into Claude Code agent behavior through two complementary pipelines:

1. **Quantitative Observability (The Core)**: Native OpenTelemetry integration captures metrics, logs, token counts, API costs, and request latencies
2. **Qualitative Events (The Enhancement)**: Hook-based system captures rich, context-aware events like session transcripts and high-value qualitative data

<img src="images/app.png" alt="Multi-Agent Observability Dashboard" style="max-width: 800px; width: 100%;">

## 🏗️ V2 Architecture

The system is now split into two complementary data pipelines:

**1. Quantitative Observability (The Core):** For metrics and logs.
```
Claude Code → OpenTelemetry Collector → Prometheus (Metrics) & Loki (Logs) → Grafana
```

**2. Qualitative Events (The Enhancement):** For rich, context-aware events.
```
Claude Code Hooks → Python Scripts → Bun Server → SQLite → WebSocket → Vue Client
```

![Agent Data Flow Animation](images/AgentDataFlowV2.gif)

## ✨ Key Improvements in V2

- **⚡ Extreme Efficiency:** By removing the LLM summarizer from the hooks, the system is now orders of magnitude faster and cheaper. A simple `ls` command no longer triggers two expensive API calls.
- **📊 Richer Data:** The native OTel pipeline captures critical data unavailable to hooks, including **token counts, API costs, request latencies, and cache usage.**
- **🛠️ Correct Use of Hooks:** Hooks are now used for their intended purpose: providing deterministic control, capturing high-value qualitative data (like full session transcripts), and triggering real-time notifications (e.g., TTS).
- **📈 Industry-Standard Tooling:** V2 is built on a standard, robust observability stack (OTel, Prometheus, Grafana, Loki) that is scalable and widely used in production environments.
- **🚀 One-Command Setup:** The entire observability stack, including the frontend and backend, is now orchestrated with a single `docker-compose up` command.

## 🚀 Quick Start

**Prerequisites:**
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
- [Docker and Docker Compose](https://docs.docker.com/get-docker/)

**1. Configure Environment Variables**

Create a `.env` file in the project root and add your Anthropic API key. This will be used by both Claude Code and the hook scripts.

```bash
# .env
ANTHROPIC_API_KEY="sk-ant-..."
CLAUDE_CODE_ENABLE_TELEMETRY=1
OTEL_METRICS_EXPORTER=otlp
OTEL_LOGS_EXPORTER=otlp
OTEL_EXPORTER_OTLP_PROTOCOL=grpc
OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4317"
OTEL_LOG_USER_PROMPTS=1 # Set to 1 to log full prompt text
```

**2. Launch the System**

Start the entire observability stack, including the Vue frontend and Bun backend:

```bash
docker-compose up --build
```

**3. Set Up Claude Code Hooks**

Copy the improved `.claude` directory to any project you want to monitor:

```bash
cp -R .claude /path/to/your/project/
```
*Note: The hook scripts have been updated to remove the inefficient LLM summarizer.*

**4. Start Coding!**

Run Claude Code in the configured project directory. Your terminal must have the environment variables from Step 1 loaded (you can `source .env` or add them to your shell profile).

- **View Metrics & Logs:** Open Grafana at [**http://localhost:3000**](http://localhost:3000) (user: `admin`, pass: `admin`). The Claude Code dashboard will be pre-installed.
- **View Qualitative Events:** Open the Vue app at [**http://localhost:5173**](http://localhost:5173).

## 🔧 Component Details

### Observability Core (Docker Compose)

- **OTel Collector:** Receives OTel data from Claude Code and exports it to Prometheus and Loki.
- **Prometheus:** Stores all quantitative metrics (costs, token counts, etc.).
- **Loki:** Stores all logs and event data (API requests, tool usage, etc.).
- **Grafana:** Visualizes all data from Prometheus and Loki in a pre-built dashboard.

### Qualitative Event System (Hooks + Vue App)

The original application now serves a more focused, powerful purpose.

- **Hooks (`.claude/hooks`):**
  - No longer calls an LLM on every event.
  - The `stop.py` hook now captures the **entire chat transcript** at the end of a session, providing invaluable qualitative context.
  - The `notification.py` hook remains for real-time TTS alerts.
- **Bun Server & Vue Client:**
  - The Vue app now visualizes a stream of high-signal events like session completions (with full transcripts) and user notifications, complementing the quantitative data in Grafana.

## 📋 Setup Requirements (Alternative to Docker)

If you prefer to run the components individually without Docker:

- **[Claude Code](https://docs.anthropic.com/en/docs/claude-code)** - Anthropic's official CLI for Claude
- **[Astral uv](https://docs.astral.sh/uv/)** - Fast Python package manager (required for hook scripts)
- **[Bun](https://bun.sh/)**, **npm**, or **yarn** - For running the server and client
- **Anthropic API Key** - Set as `ANTHROPIC_API_KEY` environment variable
- **OpenAI API Key** (optional) - For multi-model support with just-prompt MCP tool
- **ElevenLabs API Key** (optional) - For audio features

### Configure .claude Directory

To setup observability in your repo, we need to copy the .claude directory to your project root.

To integrate the observability hooks into your projects:

1. **Copy the entire `.claude` directory to your project root:**
   ```bash
   cp -R .claude /path/to/your/project/
   ```

2. **Update the `settings.json` configuration:**
   
   Open `.claude/settings.json` in your project and modify the `source-app` parameter to identify your project:
   
   ```json
   {
     "hooks": {
       "PreToolUse": [{
         "matcher": "",
         "hooks": [
           {
             "type": "command",
             "command": "uv run .claude/hooks/pre_tool_use.py"
           },
           {
             "type": "command",
             "command": "uv run .claude/hooks/send_event.py --source-app YOUR_PROJECT_NAME --event-type PreToolUse"
           }
         ]
       }],
       "PostToolUse": [{
         "matcher": "",
         "hooks": [
           {
             "type": "command",
             "command": "uv run .claude/hooks/post_tool_use.py"
           },
           {
             "type": "command",
             "command": "uv run .claude/hooks/send_event.py --source-app YOUR_PROJECT_NAME --event-type PostToolUse"
           }
         ]
       }]
       // ... (similar patterns for Notification, Stop, SubagentStop, PreCompact, SessionStart, SessionEnd)
     }
   }
   ```
   
   Replace `YOUR_PROJECT_NAME` with a unique identifier for your project (e.g., `my-api-server`, `react-app`, etc.).

3. **Ensure the observability server is running:**
   ```bash
   # From the observability project directory (this codebase)
   ./scripts/start-system.sh
   ```

Now your project will send events to the observability system whenever Claude Code performs actions.

## 🚀 Alternative Quick Start (Without Docker)

You can also run the system without Docker by starting components individually:

```bash
# 1. Start both server and client
./scripts/start-system.sh

# 2. Open http://localhost:5173 in your browser

# 3. Open Claude Code and run the following command:
Run git ls-files to understand the codebase.

# 4. Watch events stream in the client

# 5. Copy the .claude folder to other projects you want to emit events from.
cp -R .claude <directory of your codebase you want to emit events from>
```

## 📁 Project Structure

```
claude-code-hooks-multi-agent-observability/
│
├── observability/           # OpenTelemetry & Grafana configuration
│   ├── otel-collector-config.yml   # OTel Collector configuration
│   ├── prometheus.yml              # Prometheus scrape configuration
│   └── grafana/
│       └── provisioning/
│           ├── datasources/        # Grafana datasources (Prometheus, Loki)
│           └── dashboards/         # Pre-built Claude Code dashboard
│
├── apps/                    # Application components
│   ├── server/             # Bun TypeScript server
│   │   ├── src/
│   │   │   ├── index.ts    # Main server with HTTP/WebSocket endpoints
│   │   │   ├── db.ts       # SQLite database management & migrations
│   │   │   └── types.ts    # TypeScript interfaces
│   │   ├── Dockerfile      # Docker container for server
│   │   ├── package.json
│   │   └── events.db       # SQLite database (gitignored)
│   │
│   └── client/             # Vue 3 TypeScript client
│       ├── src/
│       │   ├── App.vue     # Main app with theme & WebSocket management
│       │   ├── components/
│       │   │   ├── EventTimeline.vue      # Event list with auto-scroll
│       │   │   ├── EventRow.vue           # Individual event display
│       │   │   ├── FilterPanel.vue        # Multi-select filters
│       │   │   ├── ChatTranscriptModal.vue # Chat history viewer
│       │   │   ├── StickScrollButton.vue  # Scroll control
│       │   │   └── LivePulseChart.vue     # Real-time activity chart
│       │   ├── composables/
│       │   │   ├── useWebSocket.ts        # WebSocket connection logic
│       │   │   ├── useEventColors.ts      # Color assignment system
│       │   │   ├── useChartData.ts        # Chart data aggregation
│       │   │   └── useEventEmojis.ts      # Event type emoji mapping
│       │   ├── utils/
│       │   │   └── chartRenderer.ts       # Canvas chart rendering
│       │   └── types.ts    # TypeScript interfaces
│       ├── Dockerfile      # Docker container for client
│       ├── .env.sample     # Environment configuration template
│       └── package.json
│
├── .claude/                # Claude Code integration
│   ├── hooks/             # Hook scripts (Python with uv)
│   │   ├── send_event.py  # Universal event sender (no LLM summarizer)
│   │   ├── pre_tool_use.py    # Tool validation & blocking
│   │   ├── post_tool_use.py   # Result logging
│   │   ├── notification.py    # User interaction events
│   │   ├── user_prompt_submit.py # User prompt logging & validation
│   │   ├── stop.py           # Session completion
│   │   └── subagent_stop.py  # Subagent completion
│   │
│   └── settings.json      # Hook configuration (V2 - no --summarize flag)
│
├── docker-compose.yml     # Orchestrates entire observability stack
├── scripts/               # Utility scripts
│   ├── start-system.sh   # Launch server & client (non-Docker)
│   ├── reset-system.sh   # Stop all processes
│   └── test-system.sh    # System validation
│
└── logs/                 # Application logs (gitignored)
```

## 🔧 Component Details

### 1. Hook System (`.claude/hooks/`) - V2 Improvements

> If you want to master claude code hooks watch [this video](https://github.com/disler/claude-code-hooks-mastery)

The hook system intercepts Claude Code lifecycle events. **V2 improvements remove the inefficient LLM summarizer:**

- **`send_event.py`**: Core script that sends event data to the observability server
  - **V2 Change:** Removed `--summarize` flag and LLM summarization calls
  - Supports `--add-chat` flag for including conversation history
  - Validates server connectivity before sending
  - Handles all event types with proper error handling
  - Significantly faster and more efficient

- **Event-specific hooks**: Each implements validation and data extraction
  - `pre_tool_use.py`: Blocks dangerous commands, validates tool usage
  - `post_tool_use.py`: Captures execution results and outputs
  - `notification.py`: Tracks user interaction points
  - `user_prompt_submit.py`: Logs user prompts, supports validation (v1.0.54+)
  - `stop.py`: Records session completion with optional chat history (most valuable qualitative event)
  - `subagent_stop.py`: Monitors subagent task completion
  - `pre_compact.py`: Tracks context compaction operations (manual/auto)
  - `session_start.py`: Logs session start, can load development context
  - `session_end.py`: Logs session end, saves session statistics

### 2. Server (`apps/server/`)

Bun-powered TypeScript server with real-time capabilities:

- **Database**: SQLite with WAL mode for concurrent access
- **Endpoints**:
  - `POST /events` - Receive events from agents
  - `GET /events/recent` - Paginated event retrieval with filtering
  - `GET /events/filter-options` - Available filter values
  - `WS /stream` - Real-time event broadcasting
- **Features**:
  - Automatic schema migrations
  - Event validation
  - WebSocket broadcast to all clients
  - Chat transcript storage

### 3. Client (`apps/client/`)

Vue 3 application with real-time visualization:

- **Visual Design**:
  - Dual-color system: App colors (left border) + Session colors (second border)
  - Gradient indicators for visual distinction
  - Dark/light theme support
  - Responsive layout with smooth animations

- **Features**:
  - Real-time WebSocket updates
  - Multi-criteria filtering (app, session, event type)
  - Live pulse chart with session-colored bars and event type indicators
  - Time range selection (1m, 3m, 5m) with appropriate data aggregation
  - Chat transcript viewer with syntax highlighting
  - Auto-scroll with manual override
  - Event limiting (configurable via `VITE_MAX_EVENTS_TO_DISPLAY`)

- **Live Pulse Chart**:
  - Canvas-based real-time visualization
  - Session-specific colors for each bar
  - Event type emojis displayed on bars
  - Smooth animations and glow effects
  - Responsive to filter changes

## 🔄 Data Flow

**V2 Architecture uses two complementary pipelines:**

### Quantitative Pipeline (OTel)
1. **Event Generation**: Claude Code executes actions and generates telemetry
2. **Native Export**: Claude Code sends metrics and logs via OpenTelemetry
3. **Collection**: OTel Collector receives data via gRPC/HTTP
4. **Storage**: Prometheus stores metrics, Loki stores logs
5. **Visualization**: Grafana queries and displays data in real-time dashboards

### Qualitative Pipeline (Hooks)
1. **Event Generation**: Claude Code executes an action (tool use, notification, etc.)
2. **Hook Activation**: Corresponding hook script runs based on `settings.json` configuration
3. **Data Collection**: Hook script gathers context (tool name, inputs, outputs, session ID)
4. **Transmission**: `send_event.py` sends JSON payload to server via HTTP POST (no LLM summarization in V2)
5. **Server Processing**:
   - Validates event structure
   - Stores in SQLite with timestamp
   - Broadcasts to WebSocket clients
6. **Client Update**: Vue app receives event and updates timeline in real-time

## 🎨 Event Types & Visualization

| Event Type       | Emoji | Purpose                | Color Coding  | Special Display                       |
| ---------------- | ----- | ---------------------- | ------------- | ------------------------------------- |
| PreToolUse       | 🔧     | Before tool execution  | Session-based | Tool name & details                   |
| PostToolUse      | ✅     | After tool completion  | Session-based | Tool name & results                   |
| Notification     | 🔔     | User interactions      | Session-based | Notification message                  |
| Stop             | 🛑     | Response completion    | Session-based | Summary & chat transcript             |
| SubagentStop     | 👥     | Subagent finished      | Session-based | Subagent details                      |
| PreCompact       | 📦     | Context compaction     | Session-based | Compaction details                    |
| UserPromptSubmit | 💬     | User prompt submission | Session-based | Prompt: _"user message"_ (italic)     |
| SessionStart     | 🚀     | Session started        | Session-based | Session source (startup/resume/clear) |
| SessionEnd       | 🏁     | Session ended          | Session-based | End reason (clear/logout/exit/other)  |

### UserPromptSubmit Event (v1.0.54+) - V2 Changes

The `UserPromptSubmit` hook captures every user prompt before Claude processes it. In the UI:
- Displays as `Prompt: "user's message"` in italic text
- Shows the actual prompt content inline (truncated to 100 chars)
- **V2 Change:** No longer shows AI-generated summaries (removed for efficiency)
- Useful for tracking user intentions and conversation flow

## 🔌 Integration

### For New Projects

1. Copy the event sender:
   ```bash
   cp .claude/hooks/send_event.py YOUR_PROJECT/.claude/hooks/
   ```

2. Add to your `.claude/settings.json`:
   ```json
   {
     "hooks": {
       "PreToolUse": [{
         "matcher": ".*",
         "hooks": [{
           "type": "command",
           "command": "uv run .claude/hooks/send_event.py --source-app YOUR_APP --event-type PreToolUse"
         }]
       }]
     }
   }
   ```

### For This Project

Already integrated! Hooks run both validation and observability:
```json
{
  "type": "command",
  "command": "uv run .claude/hooks/pre_tool_use.py"
},
{
  "type": "command", 
  "command": "uv run .claude/hooks/send_event.py --source-app cc-hooks-v2 --event-type PreToolUse"
}
```

Note: V2 has removed the `--summarize` flag for improved efficiency.

## 🧪 Testing

```bash
# System validation
./scripts/test-system.sh

# Manual event test
curl -X POST http://localhost:4000/events \
  -H "Content-Type: application/json" \
  -d '{
    "source_app": "test",
    "session_id": "test-123",
    "hook_event_type": "PreToolUse",
    "payload": {"tool_name": "Bash", "tool_input": {"command": "ls"}}
  }'
```

## ⚙️ Configuration

### Environment Variables

Copy `.env.sample` to `.env` in the project root and fill in your API keys:

**Application Root** (`.env` file):
- `ANTHROPIC_API_KEY` – Anthropic Claude API key (required)
- `ENGINEER_NAME` – Your name (for logging/identification)
- `GEMINI_API_KEY` – Google Gemini API key (optional)
- `OPENAI_API_KEY` – OpenAI API key (optional)
- `ELEVEN_API_KEY` – ElevenLabs API key (optional)

**V2 OpenTelemetry Configuration** (`.env` file):
- `CLAUDE_CODE_ENABLE_TELEMETRY=1` – Enable Claude Code telemetry
- `OTEL_METRICS_EXPORTER=otlp` – Use OTLP for metrics
- `OTEL_LOGS_EXPORTER=otlp` – Use OTLP for logs
- `OTEL_EXPORTER_OTLP_PROTOCOL=grpc` – Use gRPC protocol
- `OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4317"` – OTel Collector endpoint
- `OTEL_LOG_USER_PROMPTS=1` – Log full prompt text (set to 0 to disable)

**Client** (`.env` file in `apps/client/.env`):
- `VITE_MAX_EVENTS_TO_DISPLAY=100` – Maximum events to show (removes oldest when exceeded)

### Server Ports

- **Server**: `4000` (HTTP/WebSocket for qualitative events)
- **Client**: `5173` (Vite dev server)
- **Grafana**: `3000` (Observability dashboard)
- **Prometheus**: `9090` (Metrics storage)
- **Loki**: `3100` (Log storage)
- **OTel Collector**: `4317` (gRPC), `4318` (HTTP)

## 🛡️ Security Features

- Blocks dangerous commands (`rm -rf`, etc.)
- Prevents access to sensitive files (`.env`, private keys)
- Validates all inputs before execution
- No external dependencies for core functionality

## 📊 Technical Stack

**V2 Observability Stack:**
- **OpenTelemetry Collector**: Receives and processes telemetry data
- **Prometheus**: Time-series database for metrics
- **Loki**: Log aggregation system
- **Grafana**: Unified visualization and dashboards

**Original Application:**
- **Server**: Bun, TypeScript, SQLite
- **Client**: Vue 3, TypeScript, Vite, Tailwind CSS
- **Hooks**: Python 3.8+, Astral uv, TTS (ElevenLabs or OpenAI - optional)
- **Communication**: HTTP REST, WebSocket

**Orchestration:**
- **Docker Compose**: One-command deployment of entire stack

## 🔧 Troubleshooting

### Hook Scripts Not Working

If your hook scripts aren't executing properly, it might be due to relative paths in your `.claude/settings.json`. Claude Code documentation recommends using absolute paths for command scripts.

**Solution**: Use the custom Claude Code slash command to automatically convert all relative paths to absolute paths:

```bash
# In Claude Code, simply run:
/convert_paths_absolute
```

This command will:
- Find all relative paths in your hook command scripts
- Convert them to absolute paths based on your current working directory
- Create a backup of your original settings.json
- Show you exactly what changes were made

This ensures your hooks work correctly regardless of where Claude Code is executed from.

## Master AI **Agentic Coding**
> And prepare for the future of software engineering

Learn tactical agentic coding patterns with [Tactical Agentic Coding](https://agenticengineer.com/tactical-agentic-coding?y=cchobvwh45)

Follow the [IndyDevDan YouTube channel](https://www.youtube.com/@indydevdan) to improve your agentic coding advantage.

