defmodule StaffBot.GitHub.EnhancedAiWorkflowReactor do
  @moduledoc """
  An enhanced Reactor implementation for the complete AI code review workflow.

  This reactor orchestrates the full AI workflow using composable step modules:
  1. Set PR status to pending (UpdatePRStatusStep)
  2. Fetch rules from repository (FetchRulesStep)
  3. Generate AI response based on rules and code (GenerateAiResponseStep)
  4. Format the AI response for display (FormatAiResponseStep)
  5. Post comment to PR (PostCommentStep)
  6. Set PR status to success/failure based on results (UpdatePRStatusStep)

  Each step is implemented as a separate, reusable module that can be
  composed into different workflows as needed.
  """

  use Reactor

  alias StaffBot.GitHub.Steps.{
    FetchRulesStep,
    GenerateAiResponseStep,
    FormatAiResponseStep,
    PostCommentStep,
    UpdatePRStatusStep
  }

  # Inputs
  input(:repo)
  input(:token)
  input(:code)
  input(:pr_number)
  input(:sha)

  # Step 1: Fetch rules from repository
  step :fetch_rules, FetchRulesStep do
    argument(:repo, input(:repo))
    argument(:token, input(:token))
  end

  # Conditional flow: Check if we should proceed or fail
  switch :with_rules_decision do
    on(result(:fetch_rules))

    matches? &(map_size(&1) == 0) do
      # AI generation failed - set failure status
      step :set_failure_status, UpdatePRStatusStep do
        argument(:repo, input(:repo))
        argument(:token, input(:token))
        argument(:sha, input(:sha))
        argument(:status, value("failure"))
        argument(:context, value("ai-review"))
        argument(:description, value("AI code review failed - could not retrieve rules"))
      end
    end

    default do
      # Step 2: Generate AI response with retry logic
      step :generate_response, GenerateAiResponseStep do
        argument(:rules, result(:fetch_rules))
        argument(:code, input(:code))
        max_retries(2)
      end

      # Step 3: Format the AI response
      step :format_response, FormatAiResponseStep do
        argument(:ai_response, result(:generate_response))
      end

      # Step 4: Post comment to PR
      step :post_comment, PostCommentStep do
        argument(:repo, input(:repo))
        argument(:token, input(:token))
        argument(:number, input(:pr_number))
        argument(:comment, result(:format_response))
      end

      # Step 5: Set PR status to success (if we get here, everything worked)
      step :set_success_status, UpdatePRStatusStep do
        wait_for(:post_comment)
        argument(:repo, input(:repo))
        argument(:token, input(:token))
        argument(:sha, input(:sha))
        argument(:status, value("success"))
        argument(:context, value("ai-review"))
        argument(:description, value("AI code review completed successfully"))
      end
    end
  end
end
