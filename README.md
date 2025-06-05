# StaffBot 🤖

An intelligent AI-powered code review bot for GitHub pull requests, built with Elixir and Phoenix. StaffBot automatically analyzes your code changes and provides thoughtful feedback using advanced AI models.

Originally forked from [jump_bot](https://github.com/Git002/jump_bot), then rebuilt from scratch while preserving core logic concepts.

## ✨ Features

- **🔍 Automated Code Review**: Intelligent analysis of pull request changes using Gemini 2.0 Flash
- **📋 Custom Review Rules**: Repository-specific review guidelines via `.staff_bot_rules.md` 
- **🔄 Reactor Workflow**: Composable, reusable workflow steps for reliable processing
- **📊 Status Updates**: Real-time PR status checks (pending/success/failure/error)
- **🏗️ Modular Architecture**: Extensible step-based system for easy customization
- **💬 GitHub Integration**: Seamless webhook-driven PR comment posting
- **🔐 Secure**: JWT-based GitHub App authentication with signature verification

## 🏗️ Architecture

StaffBot uses the **Reactor pattern** for orchestrating AI workflows through composable steps:

### Core Workflow (`EnhancedAiWorkflowReactor`)
1. **Fetch Rules** → Repository-specific review guidelines
2. **Generate AI Response** → Gemini 2.0 Flash analysis with retry logic  
3. **Format Response** → Markdown-formatted comments
4. **Post Comment** → GitHub PR integration
5. **Update Status** → Success/failure PR status checks

### Reusable Step Modules
- `FetchRulesStep` - Retrieves `.staff_bot_rules.md` from repository
- `GenerateAiResponseStep` - AI-powered code analysis 
- `FormatAiResponseStep` - Comment formatting
- `PostCommentStep` - GitHub API integration
- `UpdatePRStatusStep` - PR status management

## 🚀 Quick Start

### Prerequisites
- Elixir 1.14+
- Phoenix 1.7+
- GitHub App with webhook permissions

### Installation

```bash
# Clone and setup
git clone <repository-url>
cd staff_bot
mix setup

# Start the development server
mix phx.server
```

Visit [`localhost:8008`](http://localhost:8008) to verify the server is running.

### GitHub App Setup

1. **Create GitHub App** at https://github.com/settings/apps
2. **Configure permissions**:
   - Contents: Read
   - Pull requests: Write  
   - Checks: Write
3. **Enable webhook events**: `pull_request`, `installation`
4. **Set webhook URL**: `https://your-domain.com/api/webhook`
5. **Generate and download private key**
6. **Install app** on target repositories

### Environment Variables

```bash
# Required
SECRET_KEY_BASE=your_secret_key_base      # Generate with: mix phx.gen.secret
GITHUB_APP_ID=your_github_app_id
GITHUB_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----\n...\n-----END RSA PRIVATE KEY-----"
GEMINI_API_KEY=your_gemini_api_key

# Optional
GITHUB_SECRET=your_webhook_secret         # For webhook signature verification
PHX_SERVER=true                          # For production deployment
```

## 📝 Repository Configuration

Create a `.staff_bot_rules.md` file in your repository root to customize review behavior:

```markdown
# Code Review Guidelines

## Focus Areas
- Security vulnerabilities
- Performance optimizations  
- Code style consistency
- Test coverage

## Ignore Patterns
- Documentation updates
- Minor formatting changes
```

## 🧪 Testing

```bash
# Run all tests
mix test

# Run specific test suites
mix test test/github/steps/        # Step module tests
mix test --failed                  # Re-run failed tests

# Force recompilation
mix compile --force
```

### Testing Framework
- **Mimic**: Mock external dependencies (GitHub API, AI services)
- **ExUnit**: Standard Elixir testing framework
- **Clean Output**: Logger set to `:critical` for noise-free test runs

## 🚀 Deployment

### Fly.io (Recommended)

Cost-optimized configuration: ~$1.94/month idle, ~$5-10/month with light usage.

```bash
# Install and authenticate
fly auth login

# Create app and volume
fly apps create staff-bot
fly volumes create staff_bot_data --region iad --size 1

# Set environment variables
fly secrets set SECRET_KEY_BASE="$(mix phx.gen.secret)"
fly secrets set GITHUB_APP_ID="your_app_id"
fly secrets set GITHUB_PRIVATE_KEY="your_private_key"
fly secrets set GEMINI_API_KEY="your_api_key"
fly secrets set PHX_SERVER="true"

# Deploy
fly deploy
```

### Other Platforms
StaffBot is containerized and can deploy to any container platform supporting SQLite persistence.

## 🔧 Development

### Key Dependencies
- `reactor` - Workflow orchestration
- `instructor` - AI response generation  
- `mimic` - Testing mocks
- `phoenix` - Web framework
- `ecto_sqlite3` - Database layer

### Development Commands
```bash
mix deps.get                      # Install dependencies
mix compile --warnings-as-errors  # Strict compilation
mix hex.info <package>            # Check package versions
```

## 🔌 API Integration

### GitHub API (`StaffBot.GitHub.API`)
- RESTful GitHub API wrapper
- JWT-based authentication
- Automatic error handling and logging
- Rate limiting awareness

### AI Integration (`Instructor`)
- Gemini 2.0 Flash model integration
- Structured response generation
- Automatic retry logic for reliability

## 📊 Monitoring

StaffBot includes comprehensive logging and telemetry:
- Webhook processing metrics
- AI workflow success/failure rates  
- GitHub API response times
- Error tracking and stacktraces

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add comprehensive tests
4. Follow existing code patterns
5. Submit a pull request

### Code Standards
- Follow Elixir community conventions
- 100% test coverage for new features
- Proper error handling with stacktrace logging
- Mimic-based mocking for external dependencies

## 📜 License

[Add your license information here]

## 🔗 Learn More

- [Phoenix Framework](https://www.phoenixframework.org/)
- [Reactor Pattern](https://github.com/ash-project/reactor)
- [GitHub Apps Documentation](https://docs.github.com/en/developers/apps)
- [Gemini AI API](https://ai.google.dev/)

## 🙏 Acknowledgments

Originally inspired by [jump_bot](https://github.com/Git002/jump_bot) - rebuilt from scratch while preserving core architectural concepts.