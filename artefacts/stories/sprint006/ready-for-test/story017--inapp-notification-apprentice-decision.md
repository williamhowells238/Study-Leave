# Story 017 — In-App Notification to Apprentice on Approval or Rejection

## User Story

As an **Apprentice**, I want to receive an in-app (bell icon) notification when my study leave request is approved or rejected by my manager, so that I can be alerted within Salesforce immediately without relying solely on email.

## Acceptance Criteria

- Given a manager approves a study leave request, when the request status changes to "Approved", then an in-app notification (bell icon) is sent to the apprentice who submitted the request.
- Given a manager rejects a study leave request, when the request status changes to "Rejected", then an in-app notification (bell icon) is sent to the apprentice who submitted the request.
- Given an approval in-app notification is delivered, when the apprentice clicks the bell icon, then the notification message clearly states the request has been approved AND identifies the relevant request.
- Given a rejection in-app notification is delivered, when the apprentice clicks the bell icon, then the notification message clearly states the request has been rejected AND identifies the relevant request.
- Given the apprentice clicks on the in-app notification, when they select it, then they are navigated to the relevant Study Leave Request record.

## Related Parent Epic

[Epic 003 — Approval Workflow and Notifications](../../../artefacts/epics/epic003--approval-workflow-and-notifications.md)

---

## Dependencies

- Dependency Type: Story
- Dependency on: Story 001
- Dependency Justification: The Study_Leave_Request__c object must exist so the notification can link to the relevant request record.

- Dependency Type: Story
- Dependency on: Story 013
- Dependency Justification: The manager approval process with status transitions to "Approved" and "Rejected" must be in place to trigger the in-app notification on decision.

## Assumptions

- Assumption Type: Technical Confirmation
- Assumption Description: The same Custom Notification Type created for Story 015 can be reused, or a separate type is created for decision notifications.
- Assumption Justification: A technical decision is needed on whether to use a single Custom Notification Type for all study leave notifications or separate types for submission and decision events.

- Assumption Type: Technical Confirmation
- Assumption Description: The in-app notification will be sent via a Salesforce Flow or Apex triggered by the status change to "Approved" or "Rejected", as standard Approval Processes do not natively send custom in-app notifications.
- Assumption Justification: Standard Approval Process final actions support email alerts but not custom in-app notifications. A supplementary automation is required.

## Development Estimate

- Story Points: 3
- Justification: This is a moderately complex story similar to Story 015 but triggered on two different status changes (Approved and Rejected) and targeting the apprentice rather than the manager. A supplementary automation (record-triggered Flow or Apex) must detect the status transition to Approved or Rejected and send a custom in-app notification to the apprentice with a clear message identifying the decision and a link to the request record. The Custom Notification Type created in Story 015 may be reusable, but the notification content and recipient logic differ. Handling two distinct trigger conditions (approve and reject) with appropriately differentiated messages adds moderate complexity.

## Testing Estimate

- Story Points: 3
- Justification: Testing involves verifying two in-app notification scenarios: one on approval and one on rejection. For each, the bell notification must be delivered to the correct apprentice, the message must clearly state the decision (approved or rejected) and identify the relevant request, and clicking the notification must navigate the apprentice to the Study Leave Request record. The supplementary automation (Flow or Apex) must correctly detect both status transitions and send differentiated messages. Testing also requires verifying the notification appears correctly in the Salesforce bell icon UI. The two distinct trigger paths and message differentiation warrant a 3-point estimate.

## Solution Plan

### Salesforce Components
- **EPA_StudyLeaveDecision_NotificationType**
  - Component Type: Custom Notification Type
  - Purpose: A dedicated notification type for approval/rejection decision notifications sent to apprentices. A separate type is created (rather than reusing the submission type) because the description, audience, and purpose differ — submission notifications target managers while decision notifications target apprentices. Separate types also allow independent notification preference control.

- **EPA_ApprenticeDecisionNotification_Flow**
  - Component Type: Record-Triggered Flow (After Save)
  - Purpose: Detects when `EPA_Status__c` changes to "Approved" or "Rejected" on an `EPA_StudyLeaveRequest__c` record and sends an in-app notification to the apprentice (`EPA_Apprentice__c`) with a decision-specific message and a link to the record.

### Implementation Logic
1. **Create Custom Notification Type** — Create `EPA_StudyLeaveDecision_NotificationType` with desktop and mobile enabled, description: "Notifies the apprentice when their study leave request is approved or rejected."
2. **Create Record-Triggered Flow** — `EPA_ApprenticeDecisionNotification_Flow` on `EPA_StudyLeaveRequest__c`, trigger type: After Save, on Update only.
3. **Entry Conditions** — The flow triggers when `EPA_Status__c` is changed (use `ISCHANGED`) and the new value equals "Approved" OR "Rejected". Use `{!$Record.EPA_Status__c}` with OR condition logic.
4. **Get Notification Type** — Query `CustomNotificationType` where `DeveloperName` equals `EPA_StudyLeaveDecision_NotificationType`. Store the first record automatically.
5. **Get Apprentice User** — Query `User` where `Id` equals `{!$Record.EPA_Apprentice__c}`. Retrieve `Id` and `Name` fields. Store in an `ApprenticeUser` SObject variable.
6. **Decision: Check Apprentice Exists** — Verify the apprentice user lookup is not null before proceeding.
7. **Assignment: Add Apprentice to Recipients** — Add `{!$Record.EPA_Apprentice__c}` to a `RecipientIdCollection` text collection variable.
8. **Decision: Approved or Rejected** — Branch on `{!$Record.EPA_Status__c}`:
   - **Approved path**: Set formula variables — Title: `Study Leave Request Approved`, Body: `Your study leave request has been approved.`
   - **Rejected path**: Set formula variables — Title: `Study Leave Request Rejected`, Body: `Your study leave request has been rejected.`
9. **Send Custom Notification** — Use the `customNotificationAction` core action with:
   - `customNotifTypeId` → `{!Get_Notification_Type.Id}`
   - `recipientIds` → `{!RecipientIdCollection}`
   - `title` → Decision-specific title from step 8
   - `body` → Decision-specific body from step 8
   - `targetId` → `{!$Record.Id}` (navigates to the Study Leave Request record on click)
10. **Fault Handler** — Add a fault connector on the Send Notification action. Assign `{!$Flow.FaultMessage}` to a `FaultMessage` text variable (matching the Story 015 pattern).
11. **Activate the Flow** — Set status to Active.
12. **Deploy to scratch org** — Deploy both the notification type and flow to `sprint006`.

### Risks or Blockers
- The approval process updates `EPA_Status__c` via field update actions. The record-triggered flow must fire on those field updates. This is expected behaviour for after-save flows triggered by field updates in approval processes, but should be verified during testing.
- No blockers identified. All dependencies (Story 001 custom object, Story 013 approval process) are complete.

## Implementation Record

Agent: Developer Agent
Branch: feature/017
PR: https://github.com/williamhowells238/Study-Leave/pull/23
Summary: Created EPA_StudyLeaveDecision_NotificationType (Custom Notification Type) and EPA_ApprenticeDecisionNotification_Flow (Record-Triggered After Save Flow) following the solution plan and Story 015 reference pattern. The flow triggers on EPA_Status__c changing to Approved or Rejected, validates the apprentice exists, branches to set decision-specific title/body, and sends an in-app notification to the apprentice with a link to the record. Deployed successfully to sprint006 scratch org. 26/28 Apex tests pass; 2 pre-existing bulk test failures are unrelated to this story.

## PR Review - story-017: in-app notification to apprentice on approval or rejection

Result: Approved

### Summary
- All naming conventions followed (`EPA_ApprenticeDecisionNotification_Flow`, `EPA_StudyLeaveDecision_NotificationType`).
- Flow design passes all quality checks: correct flow type (After-Save Record-Triggered on Update), no DML/SOQL in loops, fault connector on the Send Notification action, and no automation density conflicts with the existing Story 015 flow (different trigger events and conditions).
- Pattern is consistent with the approved Story 015 implementation. The Developer made a sensible optimisation by skipping the User query — `EPA_Apprentice__c` is directly usable as a recipient ID.
- Custom Notification Type has desktop and mobile enabled with a clear description.
- All five acceptance criteria are fully covered: notifications on Approved and Rejected status changes, decision-specific messages, and navigation to the Study Leave Request record on click.
- No issues identified.

### Changes to be made
- None. PR is approved as submitted.
