# Orchestrator Learnings

## 2025-06-18 - Project Management & Agent Oversight

### Discovery: Importance of Web Research

- **Issue**: Developer spent 2+ hours trying to solve JWT multiline environment variable issue in Convex
- **Mistake**: As PM, I didn't suggest web research until prompted by the user
- **Learning**: Should ALWAYS suggest web research after 10 minutes of failed attempts
- **Solution**: Added "Web Research is Your Friend" section to global CLAUDE.md
- **Impact**: Web search immediately revealed the solution (replace newlines with spaces)

### Insight: Reading Error Messages Carefully

- **Issue**: Developer spent time on base64 decoding when the real error was "Missing environment variable JWT_PRIVATE_KEY"
- **Learning**: Always verify the actual error before implementing complex solutions
- **Pattern**: Developers often over-engineer solutions without checking basic assumptions
- **PM Action**: Ask "What's the EXACT error message?" before approving solution approaches

### Project Manager Best Practices

- **Be Firm but Constructive**: When developer was coding without documenting, had to insist on LEARNINGS.md creation
- **Status Reports**: Direct questions get better results than open-ended "how's it going?"
- **Escalation Timing**: If 3 approaches fail, immediately suggest different strategy
- **Documentation First**: Enforce documentation BEFORE continuing to code when stuck

### Communication Patterns That Work

- **Effective**: "STOP. Give me status: 1) X fixed? YES/NO 2) Current error?"
- **Less Effective**: "How's the authentication coming along?"
- **Key**: Specific, numbered questions force clear responses

### Reminder System

- **Discovery**: User reminded me to set check-in reminders before ending conversations
- **Implementation**: Use schedule-with-note.sh with specific action items
- **Best Practice**: Always schedule follow-up with concrete next steps, not vague "check progress"

## 2025-06-17 - Agent System Design

### Multi-Agent Coordination

- **Challenge**: Communication complexity grows exponentially (n²) with more agents
- **Solution**: Hub-and-spoke model with PM as central coordinator
- **Key Insight**: Structured communication templates reduce ambiguity and overhead

### Agent Lifecycle Management

- **Learning**: Need clear distinction between permanent and temporary agents
- **Solution**: Implement proper logging before terminating agents
- **Directory Structure**: agent_logs/permanent/ and agent_logs/temporary/

### Quality Assurance

- **Principle**: PMs must be "meticulous about testing and verification"
- **Implementation**: Verification checklists, no shortcuts, track technical debt
- **Key**: Trust but verify - always check actual implementation

## Common Pitfalls to Avoid

1. **Not Using Available Tools**: Web search, documentation, community resources
2. **Circular Problem Solving**: Trying same approach repeatedly without stepping back
3. **Missing Context**: Not checking other tmux windows for error details
4. **Poor Time Management**: Not setting time limits on debugging attempts
5. **Incomplete Handoffs**: Not documenting solutions for future agents

## Orchestrator-Specific Insights

- **Stay High-Level**: Don't get pulled into implementation details
- **Pattern Recognition**: Similar issues across projects (auth, env vars, etc.)
- **Cross-Project Knowledge**: Use insights from one project to help another
- **Proactive Monitoring**: Check multiple windows to spot issues early

## 2025-06-18 - Later Session - Authentication Success Story

### Effective PM Intervention

- **Situation**: Developer struggling with JWT authentication for 3+ hours
- **Key Action**: Sent direct encouragement when I saw errors were resolved
- **Result**: Motivated developer to document learnings properly
- **Lesson**: Timely positive feedback is as important as corrective guidance

### Cross-Window Intelligence

- **Discovery**: Can monitor server logs while developer works
- **Application**: Saw JWT_PRIVATE_KEY error was resolved before developer noticed
- **Value**: Proactive encouragement based on real-time monitoring
- **Best Practice**: Always check related windows (servers, logs) for context

### Documentation Enforcement

- **Challenge**: Developers often skip documentation when solution works
- **Solution**: Send specific reminders about what to document
- **Example**: Listed exact items to include in LEARNINGS.md
- **Impact**: Ensures institutional knowledge is captured

### Claude Plan Mode Discovery

- **Feature**: Claude has a plan mode activated by Shift+Tab+Tab
- **Key Sequence**: Hold Shift, press Tab, press Tab again, release Shift
- **Critical Step**: MUST verify "⏸ plan mode on" appears - may need multiple attempts
- **Tmux Implementation**: `tmux send-keys -t session:window S-Tab S-Tab`
- **Verification**: `tmux capture-pane | grep "plan mode on"`
- **Troubleshooting**: If not activated, send additional S-Tab until confirmed
- **User Correction**: User had to manually activate it for me initially
- **Use Case**: Activated plan mode for complex password reset implementation
- **Best Practice**: Always verify activation before sending planning request
- **Key Learning**: Plan mode forces thoughtful approach before coding begins

## 2025-11-11 - Agent Startup Reliability Issues

### Problem: Messages Not Sending to New Agents

**Issue**: When orchestrator created PM and PM created Developer, messages weren't being properly delivered:

1. Enter key wasn't being pressed after sending briefing
2. Commands like `echo` were sent instead of actually starting Claude

**Root Causes**:

1. **Timing Issues**: `sleep 5` is not always enough for Claude to fully initialize
2. **Script Misuse**: Using `send-claude-message.sh` before Claude was actually running
3. **No Verification**: Not checking if Claude started before sending messages
4. **Manual Commands**: Using `tmux send-keys` with manual timing instead of helper scripts

**Solutions Implemented**:

1. Created dedicated `start-claude-agent.sh` script that:
   - Starts Claude
   - Waits with verification (7 seconds)
   - Optionally sends initial message
   - Reports success/failure clearly
2. Updated `send-claude-message.sh` to:
   - Check if Claude is running before sending messages
   - Exit with helpful error if Claude not detected
   - Suggest using `start-claude-agent.sh` to start Claude first
3. Updated CLAUDE.md with clear workflows and anti-patterns
4. Added Orchestrator Agent Creation Checklist for verification

**Best Practice Going Forward**:

- Always use `start-claude-agent.sh` when creating new agents
- Never manually send `claude` command followed by immediate messaging
- Verify agent startup before considering task complete
- Orchestrator should check window contents after agent creation
- PMs creating developers should also use `start-claude-agent.sh`

**Key Insight**: The separation of concerns is critical:

- `start-claude-agent.sh` = Start Claude and optionally send initial message
- `send-claude-message.sh` = Send messages to already-running Claude agents

## 2025-11-10 - Testing and Script Improvements

### Test-Driven Bash Development

- **Discovery**: Testing bash scripts requires special approaches
- **Solution**: Created simple test suites without external dependencies
- **Key Patterns**:
  - Use `--test-mode` flags to enable testing without side effects
  - Test file creation separately from execution
  - Use very short sleep durations for scheduling tests (0.033 minutes = ~2 seconds)
  - Clean up all tmux sessions with trap EXIT
  - Use unique session names with $$ to avoid conflicts

### Tmux Message Sending Issues

- **Issue**: Complex commands with exclamation marks and pipes were being incorrectly parsed
- **Root Cause**: Shell escaping issues in nohup bash -c commands
- **Solution**: Simplified the scheduled command to just `cat "$NOTE_FILE"`
- **Learning**: Keep scheduled commands simple; complex orchestration can happen elsewhere
- **Impact**: More reliable scheduling with fewer edge cases

### Test Organization

- **Pattern**: Created `tests/` directory for all test scripts
- **Naming**: Use hyphens instead of underscores (`test-script-name.sh`)
- **Structure**: Each test suite has setup, teardown, pass/fail helpers
- **Output**: Color-coded results (green ✓, red ✗) for quick scanning
- **Coverage**: Test both happy path and edge cases (default args, custom args, multiple simultaneous schedules)

### Script Interface Design

- **Best Practice**: Add `--test-mode` flags for testability
- **Benefit**: Allows verification without creating background processes
- **Implementation**: Filter flags from args array before parsing positionals
- **Documentation**: Update all docs when adding new flags or changing behavior

```

## 2025-11-13 - PM Role Boundary Violations

### Problem: PM Attempting Implementation Work

**Issue**: PM tried to create project structure directories instead of delegating to Developer

**Violation**: As PM, I attempted to run `mkdir -p src/chord_predictor config data/{raw,processed} logs tests`

**Root Cause**: Eager to help but forgot role boundaries defined in CLAUDE.md

**Correct Approach**:
- PM responsibility is coordination and quality standards, NOT implementation
- Developer is responsible for setting up project structure
- PM should delegate and verify, not implement

**Learning**: PMs must stick to coordination role:
- ✅ Create and brief subordinate agents
- ✅ Monitor progress and quality
- ✅ Report to Orchestrator
- ❌ Create directories, write code, or implement solutions

**Prevention**: Before taking any action, ask "Is this implementation work?" If yes, delegate to Developer.

**User Correction**: User correctly intervened to prevent role violation and ensure proper documentation.

```
