---
name: pre-sprint-generate-clarifications-planner
description: Guide for the Planner agent to generate clarification questions for the Orchestrator to present to the User.
---

## When to use this skill

Use this skill when you have been presented with a business problem to and need to generate clarification questions to understand the requirements involved. 

## Instructions

1. Review the business problem provided.
2. Read the project conventions and platform scope at `/.github/copilot-instructions.md`.
3. Create upto 20 multiple choice questions to gain a deeper understanding of the problem (see `Creating Clarification Questions`). (Please note that the number of questions should be enough to clarify any knowledge gaps or ambiguities, but should not be used excessively.)
4. Ensure the clarifications are stored in the correct location with the appropriate naming convention (see `Storing the Artifact`).
5. Notify the Orchestrator agent upon completion of the problem definition questions.

## Creating Clarification Questions
When creating clarification questions, the Planner agent should consider the following:

The questions must aim to clarify any ambiguous requeirements, fill in any information gaps and confirm assumptions.
The questions must be targeted to an end user. 
The user is a non-technical client, so you can ask only **"what"** questions (what they want, need, or expect), never **"how"** questions (how something should be implemented or achieved).

The questions must be multiple choice with 3 predefined answers to choose from as well as a 4th option allowing the user to provide a custom answer.

Each question must be multiple choice with 3 predefined answers and a 4th free-text option.

Each question must be formatted exactly as follows:

Q[X]. [Question]
- [A] Option 1
- [B] Option 2  
- [C] Option 3
- [D] Other (please describe)

The question statement should not include any of the answer options.
All multiple choice answers must be plausible and should aim to minimise the need for the user to provide a custom answer.


## Storing the Artifact
- The clarifications must be saved as a markdown file in the `/artefacts/clarifications` directory. If it does not already exist, create the directory.
- The file name must follow the format `clarifications-[short-description].md`, where [short-description] is a brief summary of the problem.

## Constraints
- Do not use tabular format for any of the outputted data.
- There is a limit of 20 overall question that can be asked.
- Do not attempt to answer the questions yourself, leave that for the user.
- Do not ask about technical implementation details.
