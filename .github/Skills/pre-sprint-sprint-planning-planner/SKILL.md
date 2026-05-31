---
name: pre-sprint-sprint-planning-planner
description: Guide for the Planner agent to plan sprints for Salesforce Development.
---

## When to use this skill

Use this skill when the planning agent requires the planning of sprints. 

## Instructions
1. Review the most recent (highest numbered) backlog and the prioritised user stories.
2. Read the project conventions and platform scope at `/.github/copilot-instructions.md`.
3. Use the backlog-order and orchestrator's sprint capacity value to select stories for the new sprint (see `Selecting Sprint Stories`).
4. Create the sprint plan file (see `Storing the Artifact`).
5. Notify the Orchestrator agent upon completion of the sprint plan.

## Selecting Sprint Stories
Stories should be selected based on the following criteria:
- Prioritisation - the most highly prioritised stories should be selected for the sprint.
- Dependencies - no story should enter the sprint without its dependencies also being included (lower priority stories that have many stories dependent on them should be considered).
- Estimation - the total estimation of the stories should not exceed the sprint capacity provided by the Orchestrator agent (the estimation does not need to exactly match the sprint capacity).


## Sprint Plan Template
The sprint plan should be created as a markdown file that lists all the stories that have been selected for the new sprint.

The stories selected for the sprint plan must be listed using the following format using the information provided in the backlog-order:
1. Story Title and Number
2. MOSCOW ranking
3. Justification
4. Dependencies
5. Estimation

## Sprint Increment
Describe the expected outcome of the sprint — what will be delivered and the value it provides to the stakeholders upon completion.

## Storing the Artifact
- The sprint plan must be saved as a markdown file in the `/artefacts/sprintplan` directory. If it does not already exist, create the directory.
- The file name must follow the format `sprintplan[xxx].md`, where [xxx] is a unique identifier for the sprint plan.

## Constraints
- Do not overwrite any details already present on the backlog-order, simply create the new sprintplan with references to the selected stories.
- Do not select stories that have dependencies that are not also selected for the sprint.
- Do not select stories that have a total estimation that exceeds the sprint capacity.
- Do not invent new information for the stories, simply use the information provided in the backlog-order.
- Do not use tabular format for any of the outputted data.
- Do not include information related to timelines.