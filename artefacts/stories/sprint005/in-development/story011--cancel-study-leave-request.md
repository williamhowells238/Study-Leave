# Story 011 — Cancel Study Leave Request

## User Story

As an **Apprentice**, I want to cancel my submitted study leave request before the leave start date has passed, so that I can withdraw a request I no longer need and free up my leave balance.

## Acceptance Criteria

- Given an apprentice has a submitted study leave request with a Start Date in the future, when they choose to cancel the request, then the request status is updated to "Cancelled".
- Given a request is cancelled, when the apprentice's annual allowance balance is recalculated, then the business days from the cancelled request are no longer counted against the used allowance.
- Given an apprentice has a study leave request whose Start Date has already passed (is today or earlier), when they attempt to cancel the request, then the system prevents the cancellation AND displays an appropriate message: "This request can no longer be cancelled as the leave start date has passed."
- Given a request is in "Approved" status and the Start Date is still in the future, when the apprentice cancels the request, then the status changes to "Cancelled" AND the approved days are released back to the apprentice's balance.

## Related Parent Epic

[Epic 002 — Study Leave Request Submission](../../../artefacts/epics/epic002--study-leave-request-submission.md)

---

## Dependencies

- Dependency Type: Story
- Dependency on: Story 001
- Dependency Justification: The Study_Leave_Request__c object with the Status__c field (including the "Cancelled" value) must exist before cancellation logic can be implemented.

- Dependency Type: Story
- Dependency on: Story 006
- Dependency Justification: The submission form and UI must exist to provide the interface from which an apprentice initiates a cancellation.

## Assumptions

- Assumption Type: Business Confirmation
- Assumption Description: Once a request is cancelled, it cannot be resubmitted or reverted to a previous status. A new request must be created instead.
- Assumption Justification: The acceptance criteria do not mention a "resubmit" or "undo cancel" capability. Business confirmation is needed to rule this out.

- Assumption Type: Business Confirmation
- Assumption Description: Cancelling an Approved request does not require manager approval; the apprentice can cancel unilaterally as long as the start date has not passed.
- Assumption Justification: The acceptance criteria state that an apprentice cancels an Approved request directly. If manager approval is needed for cancellation of approved leave, additional workflow logic is required.

## Development Estimate

- Story Points: 2
- Justification: This is a simple story involving a status change to "Cancelled" with a date-based guard (preventing cancellation once the Start Date has passed). The balance release is handled implicitly since the allowance validation (Story 009) only counts Approved and Pending requests — once a request is Cancelled, it is automatically excluded. The implementation can be achieved with a Quick Action or button combined with a simple validation rule or Flow to enforce the date restriction. The logic is straightforward with minimal edge cases.

## Testing Estimate

- Story Points: 2
- Justification: Testing involves verifying: cancellation of a request with a future start date (status changes to Cancelled), attempted cancellation of a request with a past or current start date (blocked with appropriate error message), cancellation of an Approved request with a future date (status changes to Cancelled and days are released from balance), and confirming the cancelled request's days are no longer counted in the annual allowance calculation. The scenarios are well-defined and straightforward, with no complex edge cases beyond the date boundary check.

## Solution Plan

### Salesforce Components

- **EPA_CancelPastStartDate_ValidationRule**
  - Component Type: Validation Rule (on `EPA_StudyLeaveRequest__c`)
  - Purpose: Prevents a study leave request from being set to "Cancelled" when the Start Date (`EPA_StartDate__c`) is today or in the past. Displays the error message: "This request can no longer be cancelled as the leave start date has passed." This acts as a safety net regardless of how the status change is triggered.

- **EPA_CancelStudyLeaveRequest_Flow**
  - Component Type: Screen Flow
  - Purpose: Provides the apprentice with a cancellation interface launched from the study leave request record page. The flow displays a confirmation screen, verifies the request is in a cancellable status (Pending or Approved), checks the start date is in the future, updates the `EPA_Status__c` field to "Cancelled", and shows a success or error screen. Includes fault handling on the Update Records element.

- **EPA_StudyLeaveRequest__c Lightning Record Page** (modify existing)
  - Component Type: Lightning Record Page (FlexiPage)
  - Purpose: Add the `EPA_CancelStudyLeaveRequest_Flow` as an Action on the record page so the apprentice can invoke the cancellation flow from the request record.

### Implementation Logic

1. **Create Validation Rule** — `EPA_CancelPastStartDate_ValidationRule` on `EPA_StudyLeaveRequest__c`:
   - Error Condition Formula: `ISCHANGED(EPA_Status__c) && ISPICKVAL(EPA_Status__c, "Cancelled") && EPA_StartDate__c <= TODAY()`
   - Error Message: "This request can no longer be cancelled as the leave start date has passed."
   - Display on field: `EPA_Status__c`
   - Deploy and activate.

2. **Create Screen Flow** — `EPA_CancelStudyLeaveRequest_Flow`:
   - Input variable: `recordId` (Text, input only) — receives the study leave request record ID.
   - **Get Records**: Retrieve the `EPA_StudyLeaveRequest__c` record by `recordId`, fetching `EPA_Status__c`, `EPA_StartDate__c`, and `Name`.
   - **Decision — Is Cancellable?**: Check that `EPA_Status__c` is "Pending" or "Approved" AND `EPA_StartDate__c > {!$Flow.CurrentDate}`.
     - If NOT cancellable (start date passed): navigate to an error screen displaying "This request can no longer be cancelled as the leave start date has passed."
     - If NOT cancellable (wrong status): navigate to an error screen displaying "Only Pending or Approved requests can be cancelled."
   - **Confirmation Screen**: Display the request name, current status, and start date. Ask the apprentice to confirm the cancellation with a "Cancel Request" button.
   - **Update Records**: Set `EPA_Status__c` to "Cancelled" on the retrieved record.
     - Add a **Fault Connector** to an error screen: "An error occurred while cancelling the request. Please try again or contact your administrator."
   - **Success Screen**: Display confirmation message: "Your study leave request has been successfully cancelled."

3. **Add Action to Record Page**:
   - Create an Action on `EPA_StudyLeaveRequest__c` that launches `EPA_CancelStudyLeaveRequest_Flow`, passing the record ID.
   - Add the action to the study leave request Lightning Record Page.

4. **Balance release** — No additional implementation needed. The existing `EPA_AnnualAllowanceValidation_Class` only counts requests with Pending or Approved status against the allowance. Once the status is set to "Cancelled", the days are automatically excluded from the balance calculation.

5. **Deploy to scratch org** (`sprint005`) and verify all components.

### Risks or Blockers

- **Assumption**: The existing `EPA_AdvanceNotice_ValidationRule` fires on record creation only. If it also fires on updates, it could block the status change to "Cancelled" for records whose start date is less than one month away. This needs to be verified and, if necessary, the advance notice rule should be updated with an additional condition to exclude status changes to "Cancelled".
- **Assumption**: Cancelling an Approved request does not require manager approval — the apprentice can cancel unilaterally (per the story assumptions). Business confirmation is assumed granted.
- **Assumption**: Once cancelled, a request cannot be resubmitted. A new request must be created instead (per the story assumptions).

## Implementation Record

Agent: Developer Agent
Branch: feature/011
PR: https://github.com/williamhowells238/Study-Leave/pull/17
Summary: Implemented cancel study leave request functionality. Created EPA_CancelPastStartDate_ValidationRule to prevent cancellation when start date has passed. Created EPA_CancelStudyLeaveRequest_Flow screen flow with confirmation, status/date validation, fault handling, and success/error screens. Modified EPA_AdvanceNotice_ValidationRule to exclude status changes to "Cancelled" (confirmed it fires on updates and would block cancellation). Enabled action configuration on the FlexiPage. All 21 Apex tests pass. Deployed and verified on sprint005 scratch org.
