# Story 019 — Apprentice Balance and History View

## User Story

As an **Apprentice**, I want a dedicated view in Salesforce that shows my remaining annual study leave balance and my full request history, so that I can plan future study leave and track the status of all my requests in one place.

## Acceptance Criteria

- Given an apprentice is logged into Salesforce Lightning Experience, when they navigate to the apprentice study leave view, then they can see their remaining annual study leave balance for the current calendar year displayed clearly.
- Given the apprentice views their request history, when the history is displayed, then each request shows: Start Date, End Date, Leave Category, Calculated Business Days, and Status.
- Given the balance is calculated, when it is displayed, then the remaining balance equals the configured annual allowance minus the total business days of all Approved and Pending requests for the current calendar year.
- Given multiple requests exist across different statuses, when the history is viewed, then all requests are visible (including Pending, Approved, Rejected, and Cancelled).
- Given the view uses standard Salesforce Lightning components, when the view is rendered, then it uses standard Salesforce Lightning Experience pages and components only.

## Related Parent Epic

[Epic 004 — Dashboards, Views, and Reporting](../../../artefacts/epics/epic004--dashboards-views-and-reporting.md)

---

## Dependencies

- Dependency Type: Story
- Dependency on: Story 001
- Dependency Justification: The Study_Leave_Request__c object and all its fields must exist for the view to display request history data.

- Dependency Type: Story
- Dependency on: Story 003
- Dependency Justification: The annual allowance configuration must exist to calculate the remaining balance (allowance minus used days).

- Dependency Type: Story
- Dependency on: Story 008
- Dependency Justification: The business day calculation must be in place so that Calculated_Business_Days__c values are populated and available for balance computation.

## Assumptions

- Assumption Type: Technical Confirmation
- Assumption Description: The view will be implemented using a standard Salesforce Lightning App Page with standard Lightning components (e.g. related list, rich text for balance display), not a custom Visualforce page.
- Assumption Justification: The acceptance criteria specify standard Salesforce Lightning Experience pages and components. A technical decision is needed on which specific components to use.

- Assumption Type: Business Confirmation
- Assumption Description: This view (Story 019) and the balance/history feature in Story 012 may overlap in functionality. Business must confirm whether they are the same view or distinct pages serving different contexts.
- Assumption Justification: Story 012 (Epic 002) and Story 019 (Epic 004) both describe an apprentice view with balance and history. Clarification is needed to avoid duplicate implementation.

## Development Estimate

- Story Points: 3
- Justification: This is a moderately complex story involving the creation of a dedicated Lightning App Page for apprentices that displays both the remaining annual leave balance and a full request history. The balance calculation (allowance minus Approved and Pending days) requires querying configuration data and aggregating request records. The history list must display multiple columns across all statuses. There is significant functional overlap with Story 012, and if both are implemented independently, the effort increases; if consolidated, this story effectively becomes the same deliverable. The moderate complexity comes from the balance computation logic and the page layout design using standard Lightning components.

## Testing Estimate

- Story Points: 3
- Justification: Testing mirrors Story 012 with a focus on the dedicated view context: verifying the remaining balance calculation (annual allowance minus Approved and Pending business days for the current calendar year), confirming the history list displays all required columns (Start Date, End Date, Leave Category, Calculated Business Days, Status) for requests across all statuses, verifying the balance displays the full allowance when no requests exist, and confirming standard Lightning components render correctly. The functional overlap with Story 012 means test cases may be reusable, but the distinct page context requires independent verification. The balance computation accuracy and multi-status history display warrant a 3-point estimate.

## Solution Plan

### Salesforce Components

All components listed below **already exist** from Story 012 implementation. Story 019 acceptance criteria are fully satisfied by the existing deliverables. No new components need to be created. The plan is to verify and confirm coverage of all ACs against the existing implementation.

- **EPA_StudyLeaveBalance_Class**
  - Name: `EPA_StudyLeaveBalance_Class`
  - Component Type: Apex Class (`with sharing`)
  - Purpose: Server-side controller already provides `getBalanceSummary()` (returns annual allowance, consumed days for Approved/Pending requests, and remaining balance for the current calendar year) and `getRequestHistory()` (returns all requests for the current user across all statuses with Start Date, End Date, Leave Category, Calculated Business Days, and Status). Both methods use `WITH USER_MODE` for FLS/CRUD enforcement. **Satisfies AC1, AC3, AC4.**

- **epa_StudyLeaveBalance_LWC**
  - Name: `epa_StudyLeaveBalance_LWC`
  - Component Type: Lightning Web Component
  - Purpose: Already displays the remaining balance prominently using `lightning-card` with three summary boxes (Annual Allowance, Used/Pending, Remaining) and a `lightning-datatable` showing request history with columns: Start Date, End Date, Leave Category, Business Days, Status. Uses `@wire` adapters for reactive data loading. **Satisfies AC1, AC2, AC4, AC5.**

- **EPA_StudyLeaveBalance_FlexiPage**
  - Name: `EPA_StudyLeaveBalance_FlexiPage`
  - Component Type: FlexiPage (Lightning App Page)
  - Purpose: Standalone Lightning App Page hosting the `epa_StudyLeaveBalance_LWC` component. This is the dedicated view that apprentices navigate to. Uses the `flexipage:defaultAppHomeTemplate` standard template. **Satisfies AC5.**

- **EPA_StudyLeaveBalance (Custom Tab)**
  - Name: `EPA_StudyLeaveBalance`
  - Component Type: Custom Tab
  - Purpose: Provides navigation access to the FlexiPage so apprentices can find the dedicated view from the app navigation bar. **Enables AC1 navigation requirement ("when they navigate to the apprentice study leave view").**

- **EPA_StudyLeaveApprentice_PermissionSet**
  - Name: `EPA_StudyLeaveApprentice_PermissionSet`
  - Component Type: Permission Set
  - Purpose: Already grants apprentice users access to the tab and underlying object/fields. No modification needed.

### Implementation Logic

1. Verify that all Story 019 acceptance criteria are met by the existing Story 012 components by mapping each AC to the existing code:
   - AC1 (balance display on navigation): Confirmed — `EPA_StudyLeaveBalance` tab navigates to `EPA_StudyLeaveBalance_FlexiPage` which hosts `epa_StudyLeaveBalance_LWC` displaying the remaining balance.
   - AC2 (history columns): Confirmed — `lightning-datatable` columns include Start Date, End Date, Leave Category, Business Days, and Status.
   - AC3 (balance calculation): Confirmed — `getBalanceSummary()` computes allowance minus SUM of Approved and Pending business days for the current calendar year.
   - AC4 (all statuses visible): Confirmed — `getRequestHistory()` has no status filter, returning Pending, Approved, Rejected, and Cancelled requests.
   - AC5 (standard Lightning components): Confirmed — uses `lightning-card`, `lightning-datatable`, SLDS classes, and a `flexipage:defaultAppHomeTemplate` App Page.
2. Deploy existing components to the `sprint006` scratch org to confirm they deploy and function correctly in the new sprint context.
3. Run all existing Apex tests (`EPA_StudyLeaveBalance_TestClass`) in the scratch org to confirm passing.
4. Manually verify the view in the scratch org by navigating to the Study Leave Balance tab and confirming the balance and history display as expected.

### Risks or Blockers

- **Overlap with Story 012**: Story 019 is functionally identical to Story 012, which was already implemented in Sprint 005. All five acceptance criteria are satisfied by the existing components. This story may effectively be a verification/confirmation exercise rather than new development.
- **No new code required**: Since no new Apex, LWC, or metadata components need to be created, the implementation effort is limited to deployment verification and AC confirmation in the sprint006 scratch org.
- **Assumption**: The existing `EPA_StudyLeaveBalance` tab is included in the apprentice's app navigation. If a custom Lightning App is introduced in a future story, the tab may need to be added to that app's navigation items.

## Implementation Record

Agent: Developer Agent
Branch: feature/019
PR: https://github.com/williamhowells238/Study-Leave/pull/24
Summary: No new code was required for Story 019. All five acceptance criteria are fully satisfied by the existing Story 012 implementation (EPA_StudyLeaveBalance_Class, epa_StudyLeaveBalance_LWC, EPA_StudyLeaveBalance_FlexiPage, EPA_StudyLeaveBalance custom tab, and EPA_StudyLeaveApprentice_PermissionSet). Deployment to sprint006 scratch org succeeded (65 components, 0 errors). Apex tests passed 27/28 (96%) — the single failure is a pre-existing bulk test governor limit issue in EPA_AnnualAllowanceValidation_TestClass unrelated to this story.
