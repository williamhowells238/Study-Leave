# Story 007 — Advance Notice Validation Rule

## User Story

As a **System Administrator**, I want the system to validate that study leave requests are submitted at least one month in advance of the start date, so that managers have adequate time to review and plan around the absence.

## Acceptance Criteria

- Given an apprentice is submitting a new study leave request, when the selected Start Date is less than one calendar month from the current date (date of submission), then the system rejects the request AND displays an error message: "Study leave requests must be submitted at least one month before the start date."
- Given an apprentice is submitting a new study leave request, when the selected Start Date is exactly one calendar month or more from the current date, then the validation passes AND the request proceeds to the next step.
- Given the validation rule is in place, when an apprentice edits an existing request and changes the Start Date to a date less than one month from today, then the same validation applies AND the edit is rejected with the same error message.

## Related Parent Epic

[Epic 002 — Study Leave Request Submission](../../../artefacts/epics/epic002--study-leave-request-submission.md)

---

## Dependencies

- Dependency Type: Story
- Dependency on: Story 001
- Dependency Justification: The Study_Leave_Request__c object with the Start_Date__c field must exist for the validation rule to reference.

- Dependency Type: Story
- Dependency on: Story 006
- Dependency Justification: The submission form must exist to trigger the validation when an apprentice creates or edits a request.

## Assumptions

- Assumption Type: Business Confirmation
- Assumption Description: "One calendar month" is defined as the same date in the following month (e.g. a submission on 15th March requires a start date of 15th April or later), not 30 calendar days.
- Assumption Justification: The interpretation of "one calendar month" affects edge cases (e.g. end-of-month dates, February). A clear business definition is required to implement the validation correctly.

- Assumption Type: Technical Confirmation
- Assumption Description: The validation will be implemented as a Salesforce Validation Rule on the Study_Leave_Request__c object, not in Apex or Flow.
- Assumption Justification: A declarative Validation Rule is the simplest and most maintainable approach for date-based field validation and aligns with Salesforce best practices.

## Development Estimate

- Story Points: 2
- Justification: This is a simple story involving the creation of a declarative Validation Rule on the Study_Leave_Request__c object. The rule compares the Start_Date__c to TODAY() plus one calendar month. The main consideration is the precise interpretation of "one calendar month" for edge cases (e.g. end-of-month dates, February), but the implementation is a single validation rule formula. The rule must also apply on both insert and edit contexts, which is standard validation rule behaviour.

## Testing Estimate

- Story Points: 3
- Justification: While the validation rule itself is simple, testing requires thorough boundary and edge case coverage: submitting with a start date less than one month away (rejected), exactly one month away (accepted), and more than one month away (accepted). Date edge cases are critical — end-of-month scenarios (e.g., submitting on 31st January for 28th February), leap year boundaries, and month-length variations must be tested. The validation must also be verified on both record insert (new submission) and update (editing an existing request's Start Date). Verifying the exact error message text adds additional test scenarios. The date boundary complexity elevates this above a 2-point testing estimate.

## Solution Plan

### Salesforce Components
- **EPA_AdvanceNotice_ValidationRule**
  - Component Type: Validation Rule (on `EPA_StudyLeaveRequest__c`)
  - Purpose: Prevents saving a Study Leave Request when the `EPA_StartDate__c` is less than one calendar month from the current date (`TODAY()`). Displays the error message: "Study leave requests must be submitted at least one month before the start date." The rule fires on both insert and update, which is the default behaviour for validation rules.

### Implementation Logic
1. Navigate to the `EPA_StudyLeaveRequest__c` object in the scratch org (`sprint002`).
2. Create a new Validation Rule named `EPA_AdvanceNotice_ValidationRule`.
3. Set the error condition formula to:
   ```
   EPA_StartDate__c < ADDMONTHS(TODAY(), 1)
   ```
   This uses the `ADDMONTHS` function to add one calendar month to today's date, matching the business definition of "one calendar month" (same date in the following month, e.g. 15th March → 15th April). The `ADDMONTHS` function handles end-of-month edge cases natively (e.g. 31st January → 28th/29th February).
4. Set the error message to: `Study leave requests must be submitted at least one month before the start date.`
5. Set the error display field to `EPA_StartDate__c` so the message appears next to the Start Date field.
6. Activate the validation rule.
7. Retrieve the metadata into `force-app/main/default/objects/EPA_StudyLeaveRequest__c/validationRules/` using `sf project retrieve start`.

### Risks or Blockers
- **No blockers identified.** All dependencies are satisfied — the `EPA_StudyLeaveRequest__c` object and `EPA_StartDate__c` field exist (Story 001 complete), and the submission form exists (Story 006 complete).
- **Assumption confirmed:** The `ADDMONTHS` function aligns with the business definition of "one calendar month" (same date in the following month). Salesforce's `ADDMONTHS` handles end-of-month edge cases (e.g. adding one month to 31st January returns 28th February in a non-leap year).

## Implementation Record

Agent: Developer Agent
Branch: feature/story007
PR: https://github.com/williamhowells238/Study-Leave/pull/9
Summary: Created the `EPA_AdvanceNotice_ValidationRule` validation rule on `EPA_StudyLeaveRequest__c` with formula `EPA_StartDate__c < ADDMONTHS(TODAY(), 1)`. Updated `EPA_BusinessDayCalculation_TestClass` to shift all test dates from January 2026 to January 2027 (preserving day-of-week alignment) to prevent the new validation rule from causing test failures. Deployed to scratch org `sprint002` and verified all 12 Apex tests pass at 100%.

## PR Review - story-007: Advance Notice Validation Rule

Result: Approved

### Summary
- **Validation Rule (EPA_AdvanceNotice_ValidationRule):** Formula `EPA_StartDate__c < ADDMONTHS(TODAY(), 1)` correctly enforces the one-calendar-month advance notice requirement. Error message matches the acceptance criteria verbatim. Error is displayed on `EPA_StartDate__c` field as specified. Rule is active and fires on both insert and update (default validation rule behaviour), satisfying AC3.
- **Naming Conventions:** `EPA_AdvanceNotice_ValidationRule` follows the `EPA_CamelCaseName_ValidationRule` pattern. All field references use the correct `EPA_` prefix.
- **Test Class Updates (EPA_BusinessDayCalculation_TestClass):** All dates shifted from January 2026 to January 2027 with correct day-of-week alignment verified (Mon/Wed/Fri/Sat/Sun all confirmed). No logic changes — only date literal values updated. All 12 tests passing at 100%.
- **PR Conventions:** Title `story-007: Advance Notice Validation Rule`, target branch `Dev1`, feature branch `feature/story007` — all compliant.
- **Acceptance Criteria Coverage:** AC1 (reject < 1 month) ✓, AC2 (allow >= 1 month) ✓, AC3 (applies on edit) ✓.
- **Note:** Hardcoded 2027 test dates will need attention by approximately December 2026 when they fall within the one-month validation window. This is acceptable given the business day calculation tests require known specific dates for day-of-week alignment.

### Changes to be made
- None. PR approved and merged.
