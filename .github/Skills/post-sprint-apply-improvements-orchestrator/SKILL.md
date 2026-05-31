---
name: post-sprint-apply-improvements-orchestrator
description: Guide for the Orchestrator to present agent-recommended changes to the user for approval, and then apply approved changes to agent and skill files.
---

## When to use this skill

Use this skill after all agents have completed their post-sprint reviews.

## Instructions
1. Read the recommended changes list from all the agents.
2. Present a numbered list to the user of proposed changes and ask them to approve or reject each change.
4. For each approved change, read the skill file, apply the change, and save the file.
5. Save the retrospective artefact (see `RETROSPECTIVE TEMPLATE`).
6. Notify the Orchestrator upon completion.

## RETROSPECTIVE TEMPLATE
Save a markdown file at `/artefacts/retrospectives/sprint[XXX]-Orchestrator.md` containing:
- The Sprint Retrospective Summary
- Each agent's recommended changes
- Which changes were approved and applied

## Constraints
- Do not apply any changes before receiving user approval.
- Only modify files inside `.github/skills/` or `.github/agents/`.
