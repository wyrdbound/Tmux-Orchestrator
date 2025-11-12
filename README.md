![Orchestrator Hero](/Orchestrator.png)

**Run AI agents 24/7 while you sleep** - The Tmux Orchestrator enables Claude agents to work autonomously, schedule their own check-ins, and coordinate across multiple projects without human intervention.

## 🤖 Key Capabilities & Autonomous Features

- **Self-trigger** - Agents schedule their own check-ins and continue work autonomously
- **Coordinate** - Project managers assign tasks to engineers across multiple codebases
- **Persist** - Work continues even when you close your laptop
- **Scale** - Run multiple teams working on different projects simultaneously

## 🏗️ Architecture

The Tmux Orchestrator uses a three-tier hierarchy to overcome context window limitations:

```
┌─────────────┐
│ Orchestrator│ ← You interact here
└──────┬──────┘
       │ Monitors & coordinates
       ▼
┌─────────────┐     ┌─────────────┐
│  Project    │     │  Project    │
│  Manager 1  │     │  Manager 2  │ ← Assign tasks, enforce specs
└──────┬──────┘     └──────┬──────┘
       │                   │
       ▼                   ▼
┌─────────────┐     ┌─────────────┐
│ Engineer 1  │     │ Engineer 2  │ ← Write code, fix bugs
└─────────────┘     └─────────────┘
```

### Why Separate Agents?

- **Limited context windows** - Each agent stays focused on its role
- **Specialized expertise** - PMs manage, engineers code
- **Parallel work** - Multiple engineers can work simultaneously
- **Better memory** - Smaller contexts mean better recall

## 📸 Examples in Action

### Project Manager Coordination

![Initiate Project Manager](Examples/Initiate%20Project%20Manager.png)
_The orchestrator creating and briefing a new project manager agent_

### Status Reports & Monitoring

![Status Reports](Examples/Status%20reports.png)
_Real-time status updates from multiple agents working in parallel_

### Tmux Communication

![Reading TMUX Windows and Sending Messages](Examples/Reading%20TMUX%20Windows%20and%20Sending%20Messages.png)
_How agents communicate across tmux windows and sessions_

### Project Completion

![Project Completed](Examples/Project%20Completed.png)
_Successful project completion with all tasks verified and committed_

## 🎯 Quick Start

### Option 1: Basic Setup (Single Project)

```bash
# 1. Create a project spec
cat > project_spec.md << 'EOF'
PROJECT: My Web App
GOAL: Add user authentication system
CONSTRAINTS:
- Use existing database schema
- Follow current code patterns
- Commit every 30 minutes
- Write tests for new features

DELIVERABLES:
1. Login/logout endpoints
2. User session management
3. Protected route middleware
EOF

# 2. Start tmux session
tmux new-session -s my-project

# 3. Start project manager in window 0
claude

# 4. Give PM the spec and let it create an engineer
"You are a Project Manager. Read project_spec.md and create an engineer
in window 1 to implement it. Schedule check-ins every 30 minutes."

# 5. Schedule orchestrator check-in
./schedule-with-note.sh 30 "Check PM progress on auth system"
```

### Option 2: Full Orchestrator Setup

```bash
# Start the orchestrator
tmux new-session -s orchestrator
claude

# Give it your projects
"You are the Orchestrator. Set up project managers for:
1. Frontend (React app) - Add dashboard charts
2. Backend (FastAPI) - Optimize database queries
Schedule yourself to check in every hour."
```

## ✨ Key Features

### 🔄 Self-Scheduling Agents

Agents can schedule their own check-ins using:

```bash
./schedule-with-note.sh 30 "Continue dashboard implementation"
```

### 👥 Multi-Agent Coordination

- Project managers communicate with engineers
- Orchestrator monitors all project managers
- Cross-project knowledge sharing

### 💾 Automatic Git Backups

- Commits every 30 minutes of work
- Tags stable versions
- Creates feature branches for experiments

### 📊 Real-Time Monitoring

- See what every agent is doing
- Intervene when needed
- Review progress across all projects

## 📋 Best Practices

### Writing Effective Specifications

```markdown
PROJECT: E-commerce Checkout
GOAL: Implement multi-step checkout process

CONSTRAINTS:

- Use existing cart state management
- Follow current design system
- Maximum 3 API endpoints
- Commit after each step completion

DELIVERABLES:

1. Shipping address form with validation
2. Payment method selection (Stripe integration)
3. Order review and confirmation page
4. Success/failure handling

SUCCESS CRITERIA:

- All forms validate properly
- Payment processes without errors
- Order data persists to database
- Emails send on completion
```

### Git Safety Rules

1. **Before Starting Any Task**

   ```bash
   git checkout -b feature/[task-name]
   git status  # Ensure clean state
   ```

2. **Every 30 Minutes**

   ```bash
   git add -A
   git commit -m "Progress: [what was accomplished]"
   ```

3. **When Task Completes**
   ```bash
   git tag stable-[feature]-[date]
   git checkout main
   git merge feature/[task-name]
   ```

## 🚨 Common Pitfalls & Solutions

| Pitfall             | Consequence                 | Solution                       |
| ------------------- | --------------------------- | ------------------------------ |
| Vague instructions  | Agent drift, wasted compute | Write clear, specific specs    |
| No git commits      | Lost work, frustrated devs  | Enforce 30-minute commit rule  |
| Too many tasks      | Context overload, confusion | One task per agent at a time   |
| No specifications   | Unpredictable results       | Always start with written spec |
| Missing checkpoints | Agents stop working         | Schedule regular check-ins     |

## 🛠️ How It Works

### The Magic of Tmux

Tmux (terminal multiplexer) is the key enabler because:

- It persists terminal sessions even when disconnected
- Allows multiple windows/panes in one session
- Claude runs in the terminal, so it can control other Claude instances
- Commands can be sent programmatically to any window

### 💬 Simplified Agent Communication

We provide helper scripts for reliable agent communication and management:

```bash
# Check if Claude is running in a window
./check-claude-running.sh session:window
# Returns: exit code 0 if running, 1 if not, 2 for errors

# Start a new Claude agent with optional briefing
./start-claude-agent.sh session:window "You are the PM for this project..."

# Send message to a running Claude agent
./send-claude-message.sh session:window "Your message here"
```

**Examples:**

```bash
# Verify Claude is running before sending a message
./check-claude-running.sh frontend:0 && echo "✓ Ready" || echo "✗ Not running"

# Create a new PM agent
tmux new-window -t project -n "PM" -c "/path/to/project"
./start-claude-agent.sh project:1 "You are the Project Manager. Review the codebase and create a developer in window 2."

# Send status request
./send-claude-message.sh backend:1 "STATUS UPDATE: What's your progress on the API endpoints?"
```

These scripts handle all timing complexities and verification automatically, making agent communication reliable and consistent.

### Scheduling Check-ins

```bash
# Schedule with specific, actionable notes
./schedule-with-note.sh 30 "Review auth implementation, assign next task" "session:0"
./schedule-with-note.sh 60 "Check test coverage, merge if passing" "session:1"
./schedule-with-note.sh 120 "Full system check, rotate tasks if needed" "session:2"

# Test scheduling (useful for debugging)
./schedule-with-note.sh 5 "Test note" "session:0" --test-mode
```

**Important**: The orchestrator needs to know which tmux window it's running in to schedule its own check-ins correctly. If scheduling isn't working, verify the orchestrator knows its current window with:

```bash
echo "Current window: $(tmux display-message -p "#{session_name}:#{window_index}")"
```

### 🧪 Running Tests

Verify all core functionality is working correctly:

```bash
# Run the complete test suite
./tests/test-all.sh

# Run individual test files
./tests/test-check-claude-running.sh  # Claude detection
./tests/test-send-claude-message.sh   # Message sending
./tests/test-schedule-with-note.sh    # Scheduling
./tests/test-start-claude-agent.sh    # Agent startup
./tests/test-integration.sh           # Full workflow
```

The test suite validates:

- Claude detection using process inspection
- Message sending functionality between tmux windows
- Scheduling system with note creation
- Agent startup and verification
- Error handling and edge cases
- Multi-session coordination

All tests should pass before deploying agents to ensure reliable operation.

## 🎓 Advanced Usage

### Multi-Project Orchestration

```bash
# Start orchestrator
tmux new-session -s orchestrator

# Create project managers for each project
tmux new-window -n frontend-pm
tmux new-window -n backend-pm
tmux new-window -n mobile-pm

# Each PM manages their own engineers
# Orchestrator coordinates between PMs
```

### Cross-Project Intelligence

The orchestrator can share insights between projects:

- "Frontend is using /api/v2/users, update backend accordingly"
- "Authentication is working in Project A, use same pattern in Project B"
- "Performance issue found in shared library, fix across all projects"

## 📚 Core Files

### Helper Scripts

- `check-claude-running.sh` - Verify if Claude is running in a tmux window
- `start-claude-agent.sh` - Start Claude agent with optional briefing
- `send-claude-message.sh` - Send messages to running Claude agents
- `schedule-with-note.sh` - Self-scheduling functionality with `--test-mode`

### Utilities

- `tmux_utils.py` - Tmux interaction utilities

### Documentation

- `CLAUDE.md` - Complete agent behavior instructions and workflows
- `LEARNINGS.md` - Accumulated knowledge base and lessons learned
- `QUICK_REFERENCE.md` - Quick reference guide for common operations

### Tests

- `tests/test-all.sh` - Run all test suites with summary reporting
- `tests/test-check-claude-running.sh` - Tests for Claude detection
- `tests/test-send-claude-message.sh` - Tests for message sending
- `tests/test-schedule-with-note.sh` - Tests for scheduling
- `tests/test-start-claude-agent.sh` - Tests for agent startup
- `tests/test-integration.sh` - Integration tests for full workflow
- `tests/mock-claude.sh` - Mock Claude for testing

## 🤝 Contributing & Optimization

The orchestrator evolves through community discoveries and optimizations. When contributing:

1. Document new tmux commands and patterns in CLAUDE.md
2. Share novel use cases and agent coordination strategies
3. Submit optimizations for claudes synchronization
4. Keep command reference up-to-date with latest findings
5. Test improvements across multiple sessions and scenarios

Key areas for enhancement:

- Agent communication patterns
- Cross-project coordination
- Novel automation workflows

## 📄 License

MIT License - Use freely but wisely. Remember: with great automation comes great responsibility.

---

_"The tools we build today will program themselves tomorrow"_ - Alan Kay, 1971
