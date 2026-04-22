# Story 010 — Edit Study Leave Request

## User Story

As an **Apprentice**, I want to edit the dates or category of my submitted study leave request before the leave start date has passed, so that I can make corrections or adjustments if my plans change.

## Acceptance Criteria

- Given an apprentice has a submitted study leave request with a Start Date in the future, when they choose to edit the request, then they can update the Start Date, End Date, and/or Leave Category fields.
- Given the apprentice edits a request, when they save the changes, then the Calculated Business Days are recalculated based on the new date range AND all validations (advance notice, annual allowance) are re-applied.
- Given an apprentice has a study leave request whose Start Date has already passed (is today or earlier), when they attempt to edit the request, then the system prevents the edit AND displays an appropriate message: "This request can no longer be edited as the leave start date has passed."
- Given a request is in "Approved" status and the apprentice edits the dates, when the edit is saved, then the status is reset to "Pending" to go through the approval process again.

## Related Parent Epic

[Epic 002 — Study Leave Request Submission](../../../artefacts/epics/epic002--study-leave-request-submission.md)

---

## Dependencies

- Dependency Type: Story
- Dependency on: Story 001
- Dependency Justification: The Study_Leave_Request__c object with all fields must exist before edit functionality can be implemented.

- Dependency Type: Story
- Dependency on: Story 006
- Dependency Justification: The submission form and UI must exist as the basis for the edit interface.

- Dependency Type: Story
- Dependency on: Story 007
- Dependency Justification: The advance notice validation must be in place because it is re-applied when an apprentice edits the Start Date.

- Dependency Type: Story
- Dependency on: Story 008
- Dependency Justification: The business day calculation must be in place because business days are recalculated when the date range is changed on edit.

- Dependency Type: Story
- Dependency on: Story 009
- Dependency Justification: The annual allowance validation must be in place because it is re-applied when dates change on edit, to ensure the apprentice does not exceed their balance.

## Assumptions

- Assumption Type: Business Confirmation
- Assumption Description: When an Approved request is edited, the status resets to "Pending" and goes through the approval process again, as stated in the acceptance criteria.
- Assumption Justification: This has implications for the manager's workload and the apprentice's balance. Business must confirm this is the desired behaviour rather than allowing minor edits without re-approval.

- Assumption Type: Business Confirmation
- Assumption Description: "Start Date has already passed" means the Start Date is today or earlier (i.e. the check is Start_Date__c <= TODAY()).
- Assumption Justification: The exact boundary condition needs business confirmation to determine whether editing is blocked on the start date itself or only after it.

## Development Estimate

- Story Points: 3
- Justification: This is a moderately complex story that involves enforcing edit restrictions based on the Start Date (preventing edits once the leave start date has passed), re-triggering all existing validations (advance notice and annual allowance) on edit, recalculating business days when dates change, and resetting the status from Approved to Pending when an approved request is edited. While each individual behaviour is straightforward, the combination of date-gating, validation re-application, recalculation, and status transition logic across multiple scenarios increases the overall complexity. The five dependencies also indicate integration testing effort.

## Testing Estimate

- Story Points: 5
- Justification: Testing this story involves multiple interacting behaviours that must be verified in combination: editing a request with a future start date (allowed), editing a request with a past or current start date (blocked with error message), verifying the advance notice validation re-fires when the Start Date is changed, verifying the annual allowance validation re-fires when dates change (including scenarios where the edit would cause the apprentice to exceed their allowance), confirming business days are recalculated on date changes, and confirming the status resets from Approved to Pending when an approved request is modified. Each behaviour has its own positive and negative test cases, and the interactions between five dependencies (Stories 001, 006, 007, 008, 009) create a significant integration testing matrix. The compound nature of multiple validations re-triggering on a single edit action warrants a 5-point testing estimate.

## Solution Plan

### Salesforce Components

- **EPA_EditPastStartDate_ValidationRule**
  - Component Type: Validation Rule (on `EPA_StudyLeaveRequest__c`)
  - Purpose: Data-level guard that prevents saving changes to Start Date, End Date, or Leave Category when the original Start Date has already passed (is today or earlier). Formula: `(ISCHANGED(EPA_StartDate__c) || ISCHANGED(EPA_EndDate__c) || ISCHANGED(EPA_Category__c)) && PRIORVALUE(EPA_StartDate__c) <= TODAY()`. Error message: "This request can no longer be edited as the leave start date has passed."

- **EPA_EditStudyLeaveRequest_Flow**
  - Component Type: Screen Flow
  - Purpose: Provides a controlled edit UI for apprentices to update Start Date, End Date, and Leave Category on a submitted study leave request. Follows the existing Screen Flow pattern used by `EPA_CancelStudyLeaveRequest_Flow`. Accepts a `recordId` input, retrieves the record, checks if the Start Date has passed (UI-level guard with error screen), then presents an edit screen with the three editable fields pre-populated. On save, performs an Update Records element which triggers all existing before-update automations (business day recalculation, allowance validation, advance notice validation rule).

- **EPA_EditStatusReset_Flow**
  - Component Type: Before-save Record-Triggered Flow (on Update of `EPA_StudyLeaveRequest__c`)
  - Purpose: Resets the Status field from "Approved" to "Pending" when an apprentice edits the Start Date, End Date, or Leave Category on an approved request. Uses Entry Conditions: Status equals "Approved" AND (Start Date is changed OR End Date is changed OR Category is changed). Single Assignment element sets Status to "Pending". This ensures the request re-enters the approval process.

- **EPA_BusinessDayCalculation_Trigger** (existing — no modification required)
  - Component Type: Apex Trigger
  - Purpose: Already handles `before update` — recalculates business days when Start Date or End Date changes, and re-runs annual allowance validation. No changes needed.

- **EPA_AdvanceNotice_ValidationRule** (existing — no modification required)
  - Component Type: Validation Rule
  - Purpose: Already fires on update. Ensures the new Start Date is at least one month in the future. No changes needed.

- **EPA_AnnualAllowanceValidation_Class** (existing — no modification required)
  - Component Type: Apex Class
  - Purpose: Already called from the trigger on update. Excludes the current record ID to avoid double-counting on edit. No changes needed.

### Implementation Logic

1. **Create the validation rule `EPA_EditPastStartDate_ValidationRule`** on `EPA_StudyLeaveRequest__c` to prevent field edits when the prior Start Date is today or earlier. This provides a data-level safety net regardless of how the record is edited.
2. **Create the before-save record-triggered flow `EPA_EditStatusReset_Flow`** on `EPA_StudyLeaveRequest__c` for Update events. Entry conditions: Status equals "Approved" AND at least one of Start Date, End Date, or Category has changed. The flow contains a single Assignment element that sets Status to "Pending".
3. **Create the screen flow `EPA_EditStudyLeaveRequest_Flow`**:
   - Input variable: `recordId` (Text, available for input).
   - Get Records: retrieve the `EPA_StudyLeaveRequest__c` record by Id.
   - Decision: if `EPA_StartDate__c <= {!$Flow.CurrentDate}` → route to an error screen displaying "This request can no longer be edited as the leave start date has passed."
   - Otherwise → route to an edit screen with `EPA_StartDate__c`, `EPA_EndDate__c`, and `EPA_Category__c` fields pre-populated with current values.
   - Update Records: save the edited values back to the record. Add a fault connector to an error screen for DML failures (validation rule errors will surface here).
   - Success screen: confirm the edit was saved successfully.
4. **Add a Quick Action** on `EPA_StudyLeaveRequest__c` to launch the `EPA_EditStudyLeaveRequest_Flow`, making it accessible from the record page.
5. **Verify no automation conflicts**: confirm no other before-save flows fire on Update for `EPA_StudyLeaveRequest__c` that would conflict with the status reset logic. The existing `EPA_StudyLeaveSubmission_Flow` only triggers on Create, so there is no conflict.
6. **Deploy and test** in the `sprint005` scratch org.

### Risks or Blockers

- **Assumption: "Start Date has passed" boundary** — The solution treats Start Date <= TODAY() as "passed" (i.e., editing is blocked on the start date itself), consistent with the same boundary used in the Cancel flow (`EPA_CancelPastStartDate_ValidationRule`). If business confirms a different boundary, the validation rule formula will need adjustment.
- **Assumption: Re-approval on edit** — The solution resets Approved status to Pending on any field edit (dates or category), requiring re-approval. Business confirmation is noted in the story assumptions.
- **Advance notice validation on category-only edits** — If the apprentice only changes the Leave Category (not dates), the advance notice validation rule will still fire. Since dates are unchanged and the Start Date was already validated on original submission, this will pass. No issue expected, but worth verifying during testing.
- **No existing LWC** — The submission form (Story 006) was implemented as a Flow, not an LWC. The edit functionality follows the same Screen Flow pattern for consistency.

## Implementation Record

Agent: Developer Agent
Branch: feature/010
PR: https://github.com/williamhowells238/Study-Leave/pull/18
Summary: Implemented all four components per the solution plan — validation rule (EPA_EditPastStartDate_ValidationRule), before-save record-triggered flow (EPA_EditStatusReset_Flow) with Decision element to check field changes via $Record__Prior, screen flow (EPA_EditStudyLeaveRequest_Flow) with lookup component for Category, and a Quick Action (EPA_EditRequest). Resolved a flow deployment error caused by a duplicate developer name for the Leave_Category screen field and variable. All components deployed successfully to sprint005 scratch org. All 21 existing Apex tests pass with 100% pass rate — no regressions.
