---
name: pre-sprint-estimate-stories-developer
description: Guide for the Developer agent to provide development estimates for user stories.
---

## When to use this skill

Use this skill when you have a set of user stories that require development estimations. 

## Instructions
1. Review each user story provided, including the acceptance criteria.
2. Read the project conventions and platform scope at `/.github/copilot-instructions.md`.
3. For each story, provide a development estimate (see `How to provide development estimates`).
4. Update each story by adding a comment with the estimates and a justification.
5. Notify the Orchestrator agent upon completion of all stories.

## How to provide development estimates
consider the following factors:
- Complexity of the acceptance criteria
- Dependencies on other stories or components
- Potential risks or uncertainties
- Required development tasks and effort

and provide an estimate in terms of story points using the Fibonacci sequence (see `Estimation Scale`).

## Estimation Scale
- 1 point: Very simple story with minimal development required.
- 2 points: Simple story with straightforward development.
- 3 points: Moderately complex story with some edge cases to consider.
- 5 points: Complex story with multiple scenarios and dependencies.
- 8 points: Very complex story with significant development effort and multiple dependencies.
- 13 points: Extremely complex story with high uncertainty and significant development effort.

## Constraints
- Do not overwrite any details already present on the stories, only add the development estimates.
- Always provide estimates in story points using the Fibonacci sequence.
- Do not use tabular format for any of the outputted data.