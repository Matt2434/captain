# User Story Format — DAEN 690 Scrum Board Standard
Source: instructor's "User Story Format Instructions" template card (YouTrack 01A-1), provided by Matt 2026-08-26.

## User Story
As a [type of user] or [role or stakeholder]
I want [some goal or capability] or [perform an action or capability]
So that [some business value or reason] or [a clear outcome or benefit is achieved]

**Formatting stipulation (per Matt):** the User Story statement is written one sentence/clause per line — the "As a", "I want", and "So that" parts each go on their own line, not run together as a single paragraph sentence.

## Description
A well-written User Story description should briefly explain the user's context, the problem they are facing, and the value they hope to achieve, expanding on the "As a / I want / So that" statement without dictating technical solutions. It should describe the user's real-world situation, clarify why the capability matters, and articulate how it improves their workflow or outcomes, all while remaining concise, user-centered, and focused on purpose rather than implementation. The paragraph should provide just enough background to support productive discussion during refinement, ensuring the team understands the intent of the story while leaving room for creative and collaborative decision-making during development.

## Acceptance Criteria (Given/When/Then)
When you create acceptance criteria in the Given/When/Then style, your goal is to define the clear, testable conditions that must be met for the User Story to be considered complete. Each scenario begins with the Given, which establishes the required preconditions; continues with the When, which describes the user action or system event; and ends with the Then, which states the expected outcome when the feature works correctly. Acceptance criteria serve to prevent ambiguity and ensure that both your team and your project sponsor share the same understanding of what "done" means. Because a single User Story often involves more than one situation or behavior, you may include multiple Given/When/Then sequences, each representing a distinct scenario that guides implementation, validation, and sprint-review demonstration without prescribing how the solution must be built. While you may explain the logic narratively, the acceptance criteria themselves should be written as a bulleted or enumerated list, since separate, line-by-line Given/When/Then steps keep each scenario independent, clear, and testable. Narrative provides context, but the structured bulleted format is the standard and recommended way to document acceptance criteria in Agile and Scrum.

Typically, Given/When/Then acceptance criteria are written as a bulleted or enumerated list, not in narrative form. This format keeps each scenario clear, testable, and easy for teams to scan during refinement, development, and QA review. Although you can describe the overall logic narratively, the acceptance criteria themselves are almost always written as distinct, line-separated steps using the G/W/T pattern. A standard format looks like this:

### Acceptance Criteria (Given/When/Then)
1. Scenario 1: [Title]
   - Given [precondition]
   - When [user action or system event]
   - Then [expected outcome]
2. Scenario 2: [Title]
   - Given [precondition]
   - When [user action or system event]
   - Then [expected outcome]
3. Scenario 3: [Title]
   - Given [precondition]
   - When [user action or system event]
   - Then [expected outcome]

Teams prefer the bulleted or line-by-line structure because it removes ambiguity: each scenario is visually separated and can be validated independently. Narratives tend to blend conditions, which makes testing and verification harder. In short, narrative for explanation, bulleted G/W/T lines for actual acceptance criteria is the typical and recommended practice in Agile Scrum.
