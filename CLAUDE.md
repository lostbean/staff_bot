# Claude Instructions for StaffBot Development

## Project Overview
StaffBot is an Elixir Phoenix application that provides AI-powered code review for GitHub pull requests. The application uses the Reactor pattern for composable, reusable workflow steps and Mimic for testing.

## Key Architecture Patterns

### Reactor Pattern Implementation
- **Purpose**: Create composable, reusable workflow steps for GitHub AI review processes
- **Location**: `lib/github/steps/` and `lib/github/*_reactor.ex`
- **Step Modules**: Each step implements `use Reactor.Step` with `run/3` function signature
- **Static Values**: Use `argument(:key, value("static_string"))` for static arguments in DSL
- **Dependencies**: Use `argument(:key, result(:previous_step))` and `argument(:key, input(:input_name))`

### Log stacktrace
Make sure to log stacktraces from unexpected errors by adding `rescue` at the of the implemented Step callbacks. For example:
```elixir
  @impl Reactor.Step
  def run(%{rules: rules, code: code}, _context, _step) do
      # Some logic here
  rescue
    e ->
      Exception.format(:error, e, __STACKTRACE__) |> Logger.warning()
      {:error, e}
  end
```

### Current Reactor Workflows
2. **EnhancedAiWorkflowReactor**: Complete workflow with status updates and commenting

### Step Modules (Reusable Components)
- **FetchRulesStep**: Fetches AI code review rules from GitHub repository
- **GenerateAiResponseStep**: Generates AI responses using Gemini 2.0 Flash model
- **FormatAiResponseStep**: Formats AI responses into markdown comments
- **PostCommentStep**: Posts comments to GitHub PRs/issues
- **UpdatePRStatusStep**: Updates PR status checks (pending/success/failure/error)

## Testing Guidelines

### Mimic Usage Patterns
```elixir
# In test files, always use:
import Mimic
setup :verify_on_exit!
setup :set_mimic_from_context  # NOT set_mimic_global (disables async)

# In test_helper.exs:
Mimic.copy(StaffBot.GitHub.API)
Mimic.copy(Instructor)

# Correct expect syntax:
expect(Module, :function_name, fn args -> result end)
expect(Module, :function_name, num_calls, fn args -> result end)

# NOT: Module |> expect(:function_name, fn -> end)
```

### Step Module Testing
- All step modules use `run/3` signature: `run(args, context, step)`
- Test both success and error cases
- Mock external API calls (GitHub API, Instructor.chat_completion)
- Use proper argument structure for step inputs
- Prefix unused variables with underscore to avoid compilation warnings

### Test Output and Logging
- **Clean Output**: Logger level set to `:critical` in test environment
- **Log Capture**: Avoid `capture_log/1` assertions when using high log level thresholds
- **Test Design**: Focus on behavior verification rather than log message validation

### Mimic Test Failures
- Use `set_mimic_from_context` not `set_mimic_global`
- Ensure `Mimic.copy()` called in test_helper.exs
- Use correct `expect(Module, :function, fn -> end)` syntax
- Check that number of expected calls matches actual calls

## Development Commands

### Testing
```bash
mix test                           # Run all tests
mix test test/github/steps/        # Run step tests only
mix test --failed                  # Run only failed tests
```

### Compilation
```bash
mix compile --force               # Force recompilation
mix compile --warnings-as-errors  # Catch warnings
```

### Dependencies
```bash
mix deps.get                      # Install dependencies
mix hex.info <package>            # Check latest package version
```

## Key Dependencies
- **reactor**: `~> 0.15.4` - Workflow orchestration
- **mimic**: `~> 1.12` - Mocking for tests (test env only)
- **instructor**: `~> 0.1.0` - AI response generation
- **phoenix**: `~> 1.7.21` - Web framework

## GitHub Integration

### Webhook Handler
- **Location**: `lib/staff_bot_web/controllers/webhook_controller.ex`
- **Current**: Uses `EnhancedAiWorkflowReactor` for complete PR review workflow
- **Flow**: PR event → fetch rules → AI analysis → post comment → update status

### API Module
- **Location**: `lib/github/api.ex`
- **Functions**: `get/2`, `post/3` for GitHub API interactions
- **Authentication**: Uses JWT tokens from GitHub App installation

### GitHub API Integration
- All API calls go through `StaffBot.GitHub.API` module
- Use installation tokens from JWT generation
- Handle rate limiting and error responses appropriately

## Environment Variables
- `GITHUB_SECRET`: GitHub webhook secret (optional for development)
- Database: SQLite with Ecto

## Recent Enhancements
- ✅ Migrated from Mox to Mimic for testing
- ✅ Created reusable step modules for GitHub operations
- ✅ Implemented complete AI review workflow with status updates
- ✅ Enhanced webhook controller with proper error handling
- ✅ Comprehensive test coverage for all step modules
- ✅ Configured clean test output with minimal logging noise
