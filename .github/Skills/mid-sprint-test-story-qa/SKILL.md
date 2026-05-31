---
name: mid-sprint-test-story-qa
description: Guide for the QA agent to test a story against its acceptance criteria during a sprint.
---

## When to use this skill

Use this skill when a story has been merged into the target branch and is in `ready-for-test`, awaiting QA testing.

## Instructions
1. Read the story file including all acceptance criteria and the solution plan.
2. Read the project conventions and platform scope at `/.github/copilot-instructions.md`.
3. Move the story file from `ready-for-test` to `in-test` within the sprint folder.
4. Test the implementation against each acceptance criterion (see `Testing Approach`).
5. Record the test results on the story file (see `TEST RESULTS TEMPLATE`).
6. Return a result: Passed or Failed with details.
7. Handle the result:
   - **Passed (story)**: Move the story from `in-test` to `complete`, and notify the Orchestrator agent.
   - **Passed (defect)**: Move the defect from `in-test` to `complete`, move the original user story from `in-test` back to `ready-for-test`, and notify the Orchestrator agent.
   - **Failed (story)**: Leave the story in `in-test` and notify the Orchestrator agent that a defect must be raised.
   - **Failed (defect)**: Move the defect back to `in-development` and notify the Orchestrator agent that the defect requires further work.

## Testing Approach
1. Read the applicable quality skill files at `.github/Skills/` to understand the testing expectations for each component type.
2. Read the available MCP tools in `.sfdx/mcp-tools` to determine which tools to use for testing and verification.
3. Use the appropriate MCP tools to verify each acceptance criterion.
4. For each acceptance criterion, identify the Given/When/Then conditions, execute the appropriate verification, and record whether it passes or fails with evidence.

## TEST RESULTS TEMPLATE

Append the following section to the story file:

```
## Test Results

Result: Passed / Failed
Tested By: QA Agent

### Acceptance Criteria Results
- AC1: [Given/When/Then summary] - Pass / Fail
  - Verification method: Summary of how the acceptance criterion was tested.
  - Evidence: Summary of the evidence collected during testing.
(repeat for each acceptance criterion)

### Summary
Either:
All tests passed, the story is now completed
Or
Some tests failed, a defect will be raised to address the missing acceptance criteria.
```

## Constraints
> All actions in this section must follow the project conventions.
- Do not modify the codebase.
- Do not modify existing content on the story file (acceptance criteria, estimates, plan). Only append test results.
- Test every acceptance criterion. Do not skip any.
