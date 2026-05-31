---
name: pre-sprint-dependency-considerations-check-architect
description: Guide for the Architect agent to check dependency considerations for user stories.
---

## When to use this skill

Use this skill when you have a set of user stories that require dependency analysis. 

## Instructions
1. Review each user story provided, including the acceptance criteria.
2. Read the project conventions and platform scope at `/.github/copilot-instructions.md`.
3. For each story, identify any dependencies (see `How to identify dependencies`).
4. Update each story by adding a dependency section (see `Adding a dependency section to a user story`).
5. Notify the Orchestrator agent upon completion of all stories.

## How to identify dependencies
For each user story:    
 - Identify any dependencies on other stories
 - Identify assumptions on business confirmations
 - Identify assumptions on technical confirmations


## Adding a dependency section to a user story
Add the following section to the end of the user story for each identified dependency/assumption:

Dependencies:
- Dependency Type: [Story]
- Dependency on: [Story ID]
- Dependency Justification: [Justification of the dependency]

OR

Assumptions:
- Assumption Type: [Business Confirmation, Technical Confirmation]
- Assumption Description: [Description of the assumption]
- Assumption Justification: [Justification of the assumption]

## Constraints
- Do not overwrite any details already present on the stories, only add the dependencies on each story.
- Do not use tabular format for any of the outputted data.

