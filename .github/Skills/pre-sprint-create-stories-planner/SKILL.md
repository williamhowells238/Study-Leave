---
name: pre-sprint-create-stories-planner
description: Guide for the Planner agent to create stories for Salesforce Development.
---

## When to use this skill

Use this skill when you have an epic that requires the creation of stories. 

## Instructions
1. Review the specified epic
2. Read the project conventions and platform scope at `/.github/copilot-instructions.md`.
3. Use the information to create clear and concise user stories (see `Creating a User Story`).
4. Ensure the story is stored in the correct location with the appropriate naming convention (see `Storing the Artifact`).
5. Notify the Orchestrator agent upon completion of the story.

## Creating a User Story
A user story should be written using the who, what and why format.

The user story should aim to follow the INVEST principles:
- Independent: The story should aim to be as independent as possible from other stories to avoid tight coupling.
- Negotiable: The story should capture the essence of the requirements but allow for flexibility in the details.
- Valuable: The story should be valuable to the customer.
- Estimable: The story should be clear so that the team can estimation the effort involved.
- Small: The story should be small enough to be completed within a single sprint (see `Story Granularity` below).
- Testable: The story should be written in a manner that a QA agent can develop test cases based on the acceptance criteria.

An acceptance criteria should be written following the Given, When, Then format as well as using the `AND` keyword where needed to separate multiple criteria.
The story should be formatted as shown in the `Story Template` section below.

## STORY TEMPLATE

The story must use the following format:
- As a [type of user], I want [some goal], so that [some reason].

Acceptance Criteria

- Given [context], when [action], then [expected outcome].
- Ensure the acceptance criteria fully covers the requirements of the story and that the outcomes are testable by a QA agent.

Related Parent Epic: [reference to parent epic]

## STORY GRANULARITY
- A story should involve a minimal number of Salesforce components.
- If a story involves multiple components break it down where possible into multiple stories.
- Common Acceptable themes for a split story include:
    - UI Creation story and UI functionality story
    - Object creation stories for individual objects
    - Processess being broken into individual parts.

## Storing the Artifact
- The story must be saved as a markdown file in the `/artefacts/stories/backlog` directory. If it does not already exist, create the directory.
- The file name must follow the format `story[xxx]--[short-description].md`, where [short-description] is a brief summary of the story and where [xxx] is a unique identifier for the story.

## Constraints
- Do not overwrite any details already present on the epics, simply create the new stories with a reference to the parent epic.
- Do not use tabular format for any of the outputted data.
