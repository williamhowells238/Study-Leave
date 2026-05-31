---
name: pre-sprint-backlog-prioritisation-planner
description: Guide for the Planner agent to create an order backlog priority List for user stories.
---

## When to use this skill

Use this skill when you have a set of user stories that require prioritisation. 

## Instructions
1. Review all problem definitions, epics, and user stories.
2. Read the project conventions and platform scope at `/.github/copilot-instructions.md`.
3. Prioritise stories (see `How to Prioritise Stories`).
4. Ensure the problem definition is stored in the correct location with the appropriate naming convention (see `Storing the Artifact`).
5. Notify the Orchestrator agent upon completion of all stories.


## How to Prioritise Stories

When prioritising, the Planner agent should consider the following.
- Problem Definitions - what the main objectives are and which stories contribute most to these objectives.
- Epics - which stories are part of which epics and the importance of the epics to the overall project.
- User Stories - the value of the user stories and the dependencies between them.

Stories should each be assigned a MOSCOW ranking (see below) whilst also being ordered within their MOSCOW category based on individual value and dependencies.

MOSCOW ranking:
- Must Have: Critical stories that are essential for the successful delivery of the project.
- Should Have: Important stories that add significant value but are not critical for the project.
- Could Have: Desired stories that offer some value to the project.
- Won't Have: Stories that are not a priority for the current iteration of the project.


## BACKLOG ORDER TEMPLATE
The stories in the backlog order must be listed in order of priority and must use the following format:
1. Story Title and Number
2. MOSCOW ranking
3. Justification
4. Dependencies
  (to be retrieved from the user stories)
5. Estimation
  (to be retrieved from the user stories)

## Storing the Artifact
- The prioritised backlog order must be saved as a markdown file in the `/artefacts/backlog` directory. If it does not already exist, create the directory.
- The file name must follow the format `backlog-order[xxx].md`, where [xxx] is a unique identifier for the backlog order.

## Constraints
- Do not overwrite any details already present on other artifacts, only create the new backlog order.
- Do not use tabular format for any of the outputted data.
- Do not include a prioritisation summary in the output.
