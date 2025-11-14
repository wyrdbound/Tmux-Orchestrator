# Quick Reference: Agent Management

## Starting a New Agent

```bash
# 1. Create tmux window
tmux new-window -t session -n "Agent-Name" -c "/path/to/project"

# 2. Start Claude with briefing
./start-claude-agent.sh session:window "Agent briefing message here"

# 3. Verify it started
./check-claude-running.sh session:window && echo "✓ Claude is running" || echo "✗ Claude is not running"
```

## Sending Messages to Running Agents

```bash
# Send a message to an already-running Claude agent
./send-claude-message.sh session:window "Your message here"
```

## Common Workflows

### Orchestrator Creates PM

```bash
tmux new-window -t project -n "PM" -c "/path/to/project"
./start-claude-agent.sh project:1 "You are the Project Manager for this project. Responsibilities: Quality, Testing, Coordination."
```

### PM Creates Developer

```bash
tmux new-window -t project -n "Developer" -c "/path/to/project"
./start-claude-agent.sh project:2 "You are the Developer. Check codebase, start dev server, work on issues."
```

### Orchestrator Sends Status Request

```bash
./send-claude-message.sh project:1 "STATUS UPDATE: Please provide progress report"
```

### PM Coordinates with Developer

```bash
./send-claude-message.sh project:2 "Please run the test suite and report results"
```

## Troubleshooting

### Error: "Claude does not appear to be running"

**Solution**: Use `start-claude-agent.sh` to start Claude first

```bash
./start-claude-agent.sh session:window
```

### Error: "Window does not exist"

**Solution**: Create the window first

```bash
tmux new-window -t session -n "window-name" -c "/path"
```

### Agent Not Responding

**Solution**: Check if Claude is actually running

```bash
./check-claude-running.sh session:window
# Or to see details:
tmux capture-pane -t session:window -p | tail -20
```

## Anti-Patterns (Don't Do This!)

❌ **Manually sending commands**

```bash
tmux send-keys -t session:0 "claude" Enter
sleep 5
tmux send-keys -t session:0 "message"
tmux send-keys -t session:0 Enter
```

✅ **Use the helper script instead**

```bash
./start-claude-agent.sh session:0 "message"
```

## Verification Checklist

After creating an agent:

- [ ] Window exists
- [ ] Claude started successfully
- [ ] Briefing message was delivered
- [ ] Agent responded (or will respond soon)
- [ ] No errors in window output

## Quick Commands

```bash
# List all tmux sessions
tmux ls

# List windows in a session
tmux list-windows -t session

# Check what's in a window
tmux capture-pane -t session:window -p | tail -30

# Kill a window
tmux kill-window -t session:window

# Rename a window
tmux rename-window -t session:window "New-Name"
```

## Script Locations

- `start-claude-agent.sh` - Start Claude in a tmux window
- `send-claude-message.sh` - Send message to running Claude
- `check-claude-running.sh` - Check if Claude is running in a window
- `schedule-with-note.sh` - Schedule future reminders

## Getting Help

- See `CLAUDE.md` for detailed documentation
- See `LEARNINGS.md` for lessons learned
- Run `./tests/test-all.sh` to verify everything works
