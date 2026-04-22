# Story 020 — Study Leave Request List Views

## User Story

As a **Salesforce User** (Apprentice, Manager, or System Administrator), I want filterable list views for Study Leave Requests, so that I can quickly find and manage requests based on status, apprentice, date range, or category.

## Acceptance Criteria

- Given a user navigates to the Study Leave Request object tab, when they view the list views, then predefined list views are available (e.g. "All Requests", "My Requests", "Pending Requests", "Approved Requests").
- Given a user selects a list view, when they apply filters, then they can filter by Status (Pending, Approved, Rejected, Cancelled).
- Given a user selects a list view, when they apply filters, then they can filter by Apprentice (User lookup).
- Given a user selects a list view, when they apply filters, then they can filter by date range (Start Date and/or End Date).
- Given a user selects a list view, when they apply filters, then they can filter by Leave Category.
- Given the list views are configured, when a user views a list, then the columns displayed include: Request Name, Apprentice, Start Date, End Date, Category, Calculated Business Days, and Status.
- Given record-level security is enforced, when a user views a list, then they only see records they have access to per the sharing model.

## Related Parent Epic

[Epic 004 — Dashboards, Views, and Reporting](../../../artefacts/epics/epic004--dashboards-views-and-reporting.md)

---

## Dependencies

- Dependency Type: Story
- Dependency on: Story 001
- Dependency Justification: The Study_Leave_Request__c object and all fields must exist for list views to display request data.

- Dependency Type: Story
- Dependency on: Story 002
- Dependency Justification: The Leave_Category__c object must exist to enable filtering by Leave Category in list views.

- Dependency Type: Story
- Dependency on: Story 005
- Dependency Justification: The object relationships (Apprentice lookup) must be configured to enable filtering by Apprentice and displaying the apprentice name column.

- Dependency Type: Story
- Dependency on: Story 026
- Dependency Justification: Record-level security must be configured to ensure list views only show records the user has access to per the sharing model.

## Assumptions

- Assumption Type: Business Confirmation
- Assumption Description: The predefined list views ("All Requests", "My Requests", "Pending Requests", "Approved Requests") are confirmed as the complete set of required views. Additional custom views can be created by users.
- Assumption Justification: Creating additional predefined views after deployment is straightforward but should be agreed upfront to ensure consistency.

- Assumption Type: Technical Confirmation
- Assumption Description: List views will use standard Salesforce List View functionality with standard filter capabilities, not custom Lightning components.
- Assumption Justification: Standard list views support the filtering requirements described in the acceptance criteria. Custom components would only be needed if advanced cross-object filtering or visualisations are required.

## Development Estimate

- Story Points: 2
- Justification: This is a simple story involving the creation of multiple predefined list views (All Requests, My Requests, Pending Requests, Approved Requests) on the Study_Leave_Request__c object with appropriate columns and filters. List view creation is entirely declarative and quick to configure. The acceptance criteria around filtering by Status, Apprentice, date range, and Category are all supported by standard Salesforce list view filter functionality. The main effort is configuring each view with the correct columns and filters and verifying that record-level security correctly restricts visible records.

## Testing Estimate

- Story Points: 2
- Justification: Testing involves verifying that all predefined list views (All Requests, My Requests, Pending Requests, Approved Requests) exist and display the correct columns (Request Name, Apprentice, Start Date, End Date, Category, Calculated Business Days, Status). Filter functionality must be validated for Status, Apprentice, date range, and Leave Category. Record-level security enforcement must be confirmed — users should only see records they have access to per the sharing model. While the number of list views to check is moderate, each verification is straightforward. The record-level security verification adds a small integration testing element.

## Solution Plan

### Salesforce Components
- **EPA_AllRequests**
  - Component Type: ListView (on EPA_StudyLeaveRequest__c)
  - Purpose: Displays all Study Leave Request records visible to the user. No filters applied. Shared with all users.

- **EPA_MyRequests**
  - Component Type: ListView (on EPA_StudyLeaveRequest__c)
  - Purpose: Displays only the current user's Study Leave Requests, filtered by EPA_Apprentice__c = $CurrentUser. Shared with all users.

- **EPA_PendingRequests**
  - Component Type: ListView (on EPA_StudyLeaveRequest__c)
  - Purpose: Displays Study Leave Requests where EPA_Status__c = "Pending". Shared with all users.

- **EPA_ApprovedRequests**
  - Component Type: ListView (on EPA_StudyLeaveRequest__c)
  - Purpose: Displays Study Leave Requests where EPA_Status__c = "Approved". Shared with all users.

### Implementation Logic
1. Create the `listViews` folder under `force-app/main/default/objects/EPA_StudyLeaveRequest__c/`.
2. Create `EPA_AllRequests.listView-meta.xml` — filter scope set to "Everything", no filter conditions, shared visibility to all users.
3. Create `EPA_MyRequests.listView-meta.xml` — filter scope set to "Mine" (uses standard Salesforce "My Records" scope to show only the running user's owned records, combined with a filter on EPA_Apprentice__c equals $CurrentUser to match the Apprentice lookup).
4. Create `EPA_PendingRequests.listView-meta.xml` — filter scope set to "Everything", filter condition: EPA_Status__c equals "Pending".
5. Create `EPA_ApprovedRequests.listView-meta.xml` — filter scope set to "Everything", filter condition: EPA_Status__c equals "Approved".
6. All four list views will display the following columns: NAME, EPA_Apprentice__c, EPA_StartDate__c, EPA_EndDate__c, EPA_Category__c, EPA_CalculatedBusinessDays__c, EPA_Status__c.
7. Deploy all list view metadata to the scratch org (`sprint005`) and verify via the Study Leave Request tab.
8. Record-level security enforcement is handled automatically by the object's sharing model (Private), so list views will only display records the user has access to — no additional configuration required.

### Risks or Blockers
- **Dependency on Story 026 (Record-Level Security):** AC7 requires record-level security enforcement. The object's sharing model is already set to Private, which provides base-level enforcement. However, if Story 026 introduces sharing rules or OWD changes, the list view visibility behaviour may need re-verification. This is not a blocker for implementation but should be validated during QA.
- **"My Requests" filter approach:** The EPA_Apprentice__c field is a User lookup (not the OwnerId). The "Mine" filter scope filters by record ownership, not by the Apprentice lookup. The implementation will use a filter condition `EPA_Apprentice__c = $CurrentUser` to correctly show requests where the running user is the Apprentice, rather than relying solely on the "Mine" scope.

## Implementation Record

Agent: Developer Agent
Branch: feature/020
PR: https://github.com/williamhowells238/Study-Leave/pull/21
Summary: Created 4 declarative list view metadata XML files (EPA_AllRequests, EPA_MyRequests, EPA_PendingRequests, EPA_ApprovedRequests) on EPA_StudyLeaveRequest__c. All list views include the required columns (Name, Apprentice, Start Date, End Date, Category, Calculated Business Days, Status) and are shared with all internal users. EPA_MyRequests filters by EPA_Apprentice__c = $CurrentUser. EPA_PendingRequests and EPA_ApprovedRequests filter by EPA_Status__c. Deployed to sprint005 scratch org and verified all 4 list views via SOQL query. No code quality issues — solution is purely declarative XML.

## PR Review - story-020: add study leave request list views

Result: Approved

### Summary
- All 4 list view metadata XML files (EPA_AllRequests, EPA_MyRequests, EPA_PendingRequests, EPA_ApprovedRequests) are present and well-formed.
- All list views include the required columns: NAME, EPA_Apprentice__c, EPA_StartDate__c, EPA_EndDate__c, EPA_Category__c, EPA_CalculatedBusinessDays__c, EPA_Status__c — matching AC6.
- EPA_AllRequests uses filterScope "Everything" with no filters — correct for AC1.
- EPA_MyRequests filters by EPA_Apprentice__c = $CurrentUser — correctly targets the Apprentice lookup rather than record ownership, as noted in the solution plan risks section.
- EPA_PendingRequests and EPA_ApprovedRequests filter by EPA_Status__c with correct values — matching the solution plan.
- All list views are shared with allInternalUsers — appropriate for the use case.
- Naming conventions follow the EPA_ prefix standard.
- Git conventions followed: branch `feature/020`, PR title `story-020: add study leave request list views`, target `Dev1`.
- No code quality issues — solution is purely declarative XML with no Apex or LWC components.
- Record-level security (AC7) is handled by the object's Private sharing model; no additional configuration required in list views.

### Changes to be made
- None. All acceptance criteria are met and the implementation aligns with the solution plan.
