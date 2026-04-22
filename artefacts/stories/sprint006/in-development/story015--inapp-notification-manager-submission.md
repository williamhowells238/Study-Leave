# Story 015 — In-App Notification to Manager on Request Submission

## User Story

As a **Line Manager**, I want to receive an in-app (bell icon) notification when one of my direct-report apprentices submits a study leave request, so that I can be alerted within Salesforce and take action without relying solely on email.

## Acceptance Criteria

- Given an apprentice submits a new study leave request, when the request status is set to "Pending", then an in-app notification (bell icon) is sent to the apprentice's direct line manager (identified via the User hierarchy).
- Given the in-app notification is delivered, when the manager clicks the bell icon in Salesforce, then they can see the notification with a clear message identifying the apprentice and the study leave request.
- Given the in-app notification is delivered, when the manager clicks on the notification, then they are navigated to the Study Leave Request record for review.
- Given the notification is configured, when the Custom Notification Type is inspected, then a dedicated notification type for study leave exists in the system.

## Related Parent Epic

[Epic 003 — Approval Workflow and Notifications](../../../artefacts/epics/epic003--approval-workflow-and-notifications.md)

---

## Dependencies

- Dependency Type: Story
- Dependency on: Story 001
- Dependency Justification: The Study_Leave_Request__c object must exist so the notification can link to the request record.

- Dependency Type: Story
- Dependency on: Story 005
- Dependency Justification: The User hierarchy must be configured to identify the manager as the notification recipient.

- Dependency Type: Story
- Dependency on: Story 013
- Dependency Justification: The approval process must be configured to trigger the in-app notification when a request enters "Pending" status.

## Assumptions

- Assumption Type: Technical Confirmation
- Assumption Description: A Custom Notification Type must be created in Salesforce Setup for Study Leave notifications, as standard Salesforce does not include one by default.
- Assumption Justification: The acceptance criteria explicitly state that a dedicated Custom Notification Type should exist. This must be created before in-app notifications can be sent via Flow or Apex.

- Assumption Type: Technical Confirmation
- Assumption Description: The in-app notification will be sent via a Salesforce Flow (or Apex) using the Send Custom Notification action, triggered by the approval process or a record-triggered Flow.
- Assumption Justification: Salesforce Standard Approval Processes do not natively send custom in-app notifications. A supplementary Flow or Apex trigger is needed to send the bell notification.

## Development Estimate

- Story Points: 3
- Justification: This is a moderately complex story because, unlike email alerts, in-app (bell) notifications are not natively supported by Standard Approval Processes. A Custom Notification Type must first be created in Setup, and then a separate automation (record-triggered Flow or Apex trigger) must be built to send the custom notification to the manager when the request status changes to Pending. The Flow/Apex must resolve the manager from the User hierarchy and construct an appropriate notification message with a link to the request record. The need for supplementary automation on top of the approval process and the Custom Notification Type creation add moderate complexity.

## Testing Estimate

- Story Points: 3
- Justification: Testing involves verifying that a Custom Notification Type for study leave exists in the system, confirming that a bell notification is delivered to the correct manager when a request enters Pending status, verifying the notification message clearly identifies the apprentice and the study leave request, and confirming that clicking the notification navigates the manager to the correct Study Leave Request record. Since in-app notifications require supplementary automation (Flow or Apex) beyond the standard approval process, the automation trigger must be tested independently. Testing also requires verifying the notification appears in the Salesforce bell icon interface. The moderate complexity of the supplementary automation and notification delivery verification warrants a 3-point estimate.

## Solution Plan

### Salesforce Components

- **Name:** `EPA_StudyLeaveSubmission_NotificationType`
  - **Component Type:** Custom Notification Type
  - **Purpose:** Dedicated custom notification type for study leave submissions. Required before the Send Custom Notification action can be used in a Flow. Will be configured to support the `EPA_StudyLeaveRequest__c` object so that clicking the notification navigates to the request record.

- **Name:** `EPA_ManagerSubmissionNotification_Flow`
  - **Component Type:** Record-Triggered Flow (After Save)
  - **Purpose:** Sends an in-app (bell icon) custom notification to the apprentice's direct line manager when a new Study Leave Request is created with a status of "Pending". This Flow supplements the existing `EPA_ManagerApprovalSubmit_Flow` and the approval process email notification — it does not replace them.

### Implementation Logic

1. **Create the Custom Notification Type** (`EPA_StudyLeaveSubmission_NotificationType`):
   - Navigate to Setup > Custom Notifications in the scratch org (`sprint006`).
   - Create a new Custom Notification Type with:
     - Label: `EPA Study Leave Submission`
     - API Name: `EPA_StudyLeaveSubmission_NotificationType`
     - Supported channels: Desktop and Mobile
   - Retrieve the metadata into the `force-app/main/default/notificationtypes/` directory.

2. **Build the Record-Triggered Flow** (`EPA_ManagerSubmissionNotification_Flow`):
   - **Trigger:** After Save on `EPA_StudyLeaveRequest__c`, on record creation only.
   - **Entry Condition:** `EPA_Status__c` equals `Pending` (matches the pattern used by `EPA_ManagerApprovalSubmit_Flow`).
   - **Step 1 — Get Manager:** Use a Get Records element to query the `User` object where `Id` equals `{!$Record.EPA_Apprentice__c}`, retrieving the `ManagerId` and `Name` fields. This resolves the apprentice's direct line manager via the standard User hierarchy.
   - **Step 2 — Decision:** Check that `ManagerId` is not null. If null, end the Flow gracefully (no notification to send).
   - **Step 3 — Send Custom Notification:**
     - Use the **Send Custom Notification** action.
     - **Notification Type:** `EPA_StudyLeaveSubmission_NotificationType`.
     - **Recipient:** The `ManagerId` retrieved in Step 1.
     - **Title:** `Study Leave Request Submitted`
     - **Body:** `{!ApprenticeUser.Name} has submitted a study leave request for your review.`
     - **Target Record ID:** `{!$Record.Id}` — ensures clicking the notification navigates to the Study Leave Request record.
   - **Fault Handling:** Add a fault connector on the Send Custom Notification action. Route to an Assignment element that captures `{!$Flow.FaultMessage}` (consistent with the error handling pattern in `EPA_ManagerApprovalSubmit_Flow`).
   - Deploy as **Draft** first, test, then activate.

3. **Automation Density Check:**
   - Object: `EPA_StudyLeaveRequest__c`, Trigger: After Save on Create.
   - Existing active automation: `EPA_ManagerApprovalSubmit_Flow` (After Save, Create, Status = Pending).
   - The new Flow has the same trigger context. Both Flows are independent (notification vs approval submission) and do not conflict. No recursion risk as neither updates the triggering record. Order of execution is not critical since both are fire-and-forget actions.

4. **Retrieve and commit metadata:**
   - Retrieve the Custom Notification Type and Flow metadata from the scratch org.
   - Commit to the `feature/015` branch.

### Risks or Blockers

- **Custom Notification Type metadata retrieval:** Custom Notification Types may not be fully supported in all metadata API versions. If retrieval fails, the notification type may need to be documented as a manual Setup step and tracked as a deployment dependency.
- **User hierarchy assumption:** The solution assumes all apprentice User records have a populated `ManagerId` field. If a manager is not set, no notification will be sent. The Decision element handles this gracefully, but data quality must be ensured.
- **No conflict with existing approval process email:** The approval process (`EPA_ManagerApproval_ApprovalProcess`) already sends an email to the manager via `EPA_ManagerSubmissionNotification_EmailTemplate`. The in-app notification is additive and does not duplicate or interfere with the email alert.
- **Flow ordering:** Two after-save Flows on the same object and trigger event. While independent, if Salesforce changes execution order in future releases, the notification may fire before or after the approval submission. This has no functional impact since both are independent actions.

## Implementation Record

Agent: Developer Agent
Branch: feature/015
PR: https://github.com/williamhowells238/Study-Leave/pull/22
Summary: Created Custom Notification Type (EPA_StudyLeaveSubmission_NotificationType) with Desktop and Mobile channels, and a Record-Triggered Flow (EPA_ManagerSubmissionNotification_Flow) that fires after save on EPA_StudyLeaveRequest__c creation when Status is Pending. The flow queries the CustomNotificationType by DeveloperName, resolves the apprentice's manager via User hierarchy, and sends an in-app bell notification with the apprentice's name and a link to the request record. Fault handling captures $Flow.FaultMessage. All 28 Apex tests pass at 100% with no regressions. Full deployment to scratch org sprint006 succeeded.
