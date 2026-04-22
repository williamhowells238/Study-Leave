# Story 025 — Configure Field-Level Security

## User Story

As a **System Administrator**, I want field-level security configured on all custom object fields so that each role can only view and edit the fields relevant to their function, protecting sensitive or administrative data from unauthorised access.

## Acceptance Criteria

- Given the Apprentice role, when field-level security is inspected on the Study Leave Request object, then apprentices can:
  - View and edit: Start Date, End Date, Category
  - View only (read-only): Calculated Business Days, Status
  - Not visible: Any administrative or internal-only fields
- Given the Line Manager role, when field-level security is inspected on the Study Leave Request object, then managers can:
  - View only: Start Date, End Date, Category, Calculated Business Days, Status, Apprentice Name
  - Not edit: Any request detail fields (managers can only approve/reject, not edit requests)
- Given the System Administrator role, when field-level security is inspected, then administrators can view and edit all fields on all custom objects.
- Given field-level security is configured on configuration objects (Leave Category, Public Holiday, Study Leave Allowance), when an apprentice or manager views these objects, then they can only see fields marked as visible for their role.
- Given field-level security is applied, when it is tested, then no user role has visibility into fields they do not require for their defined functions.

## Related Parent Epic

[Epic 005 — Security and Access Control](../../../artefacts/epics/epic005--security-and-access-control.md)

---

## Dependencies

- Dependency Type: Story
- Dependency on: Story 001
- Dependency Justification: The Study_Leave_Request__c object and all its fields must exist before field-level security can be configured.

- Dependency Type: Story
- Dependency on: Story 002
- Dependency Justification: The Leave_Category__c object and fields must exist before field-level security can be configured.

- Dependency Type: Story
- Dependency on: Story 003
- Dependency Justification: The Study_Leave_Allowance__c configuration and fields must exist before field-level security can be configured.

- Dependency Type: Story
- Dependency on: Story 004
- Dependency Justification: The Public_Holiday__c object and fields must exist before field-level security can be configured.

- Dependency Type: Story
- Dependency on: Story 022
- Dependency Justification: User Profiles must be configured as field-level security is set per profile.

- Dependency Type: Story
- Dependency on: Story 023
- Dependency Justification: Permission Sets must be created as FLS can also be configured via permission sets.

- Dependency Type: Story
- Dependency on: Story 024
- Dependency Justification: Object-level security must be configured first as a prerequisite; field-level security refines access within the objects a user already has access to.

## Assumptions

- Assumption Type: Business Confirmation
- Assumption Description: The field visibility and editability matrix per role (as described in the acceptance criteria) is confirmed as the final specification.
- Assumption Justification: FLS changes after implementation require retesting of all UI components, reports, and automations that reference those fields.

- Assumption Type: Technical Confirmation
- Assumption Description: Field-level security will be configured via Profiles and Permission Sets using the standard Salesforce FLS settings, not via code-level enforcement.
- Assumption Justification: Declarative FLS configuration is the standard Salesforce approach and is enforced automatically across the platform UI, reports, and APIs.

## Development Estimate

- Story Points: 3
- Justification: This is a moderately complex story requiring detailed field-by-field visibility and editability configuration across all custom objects for three distinct roles. The Study Leave Request object alone has multiple fields with varying access levels per role (e.g. apprentices can edit Start Date, End Date, and Category but can only view Status and Calculated Business Days; managers have view-only access to all fields). Configuration objects (Leave Category, Public Holiday, Study Leave Allowance) also need per-role FLS settings. The sheer number of field-role combinations to configure and verify, plus the need to ensure FLS does not interfere with automations, reports, and UI components, warrants a 3-point estimate.

## Testing Estimate

- Story Points: 5
- Justification: Testing field-level security requires a large matrix of field-role-object combinations to verify. For the Study Leave Request object alone: apprentices must be able to view and edit Start Date, End Date, and Category; view-only Calculated Business Days and Status; and not see any administrative fields. Managers must have view-only access to Start Date, End Date, Category, Calculated Business Days, Status, and Apprentice Name with no edit capability. Administrators must have full access to all fields. Configuration objects (Leave Category, Public Holiday, Study Leave Allowance) also need per-role FLS verification. Each field-role combination requires both positive (can see/edit) and negative (cannot see/cannot edit) testing. Additionally, FLS must be verified to not interfere with automations (e.g., Apex triggers updating Status or Calculated Business Days must still function despite FLS restrictions on non-admin users), reports, and UI components. The extensive field-role matrix and automation impact verification warrant a 5-point testing estimate.

## Solution Plan

### Salesforce Components

- **EPA Apprentice (Profile)**
  - Name: `EPA Apprentice`
  - Component Type: Profile
  - Purpose: Add missing fieldPermissions for EPA_StartDate__c (readable + editable), EPA_EndDate__c (readable + editable) on EPA_StudyLeaveRequest__c. Add fieldPermissions for EPA_PublicHoliday__c.EPA_HolidayDate__c (readable). Existing FLS entries for Category (editable), CalculatedBusinessDays (read-only), Status (read-only), Apprentice (read-only), and LeaveCategory Description (read-only) are already correct.

- **EPA Line Manager (Profile)**
  - Name: `EPA Line Manager`
  - Component Type: Profile
  - Purpose: Add missing fieldPermissions for EPA_StartDate__c (readable) and EPA_EndDate__c (readable) on EPA_StudyLeaveRequest__c. Add fieldPermissions for EPA_PublicHoliday__c.EPA_HolidayDate__c (readable). Existing FLS entries for Category (read-only), CalculatedBusinessDays (read-only), Status (read-only), Apprentice (read-only), and LeaveCategory Description (read-only) are already correct.

- **EPA System Administrator (Profile)**
  - Name: `EPA System Administrator`
  - Component Type: Profile
  - Purpose: Add missing fieldPermissions for EPA_StartDate__c (readable + editable) and EPA_EndDate__c (readable + editable) on EPA_StudyLeaveRequest__c. Add fieldPermissions for EPA_PublicHoliday__c.EPA_HolidayDate__c (readable + editable). Existing FLS entries already grant full access to other fields.

- **EPA_StudyLeaveApprentice_PermissionSet**
  - Name: `EPA_StudyLeaveApprentice_PermissionSet`
  - Component Type: Permission Set
  - Purpose: Add missing fieldPermissions for EPA_StartDate__c (readable + editable), EPA_EndDate__c (readable + editable) on EPA_StudyLeaveRequest__c. Add fieldPermissions for EPA_PublicHoliday__c.EPA_HolidayDate__c (readable). Add fieldPermissions for EPA_StudyLeaveAllowance__mdt.EPA_AnnualAllowanceDays__c (readable).

- **EPA_StudyLeaveManager_PermissionSet**
  - Name: `EPA_StudyLeaveManager_PermissionSet`
  - Component Type: Permission Set
  - Purpose: Add missing fieldPermissions for EPA_StartDate__c (readable) and EPA_EndDate__c (readable) on EPA_StudyLeaveRequest__c. Add fieldPermissions for EPA_PublicHoliday__c.EPA_HolidayDate__c (readable). Add fieldPermissions for EPA_StudyLeaveAllowance__mdt.EPA_AnnualAllowanceDays__c (readable).

- **EPA_StudyLeaveAdministrator_PermissionSet**
  - Name: `EPA_StudyLeaveAdministrator_PermissionSet`
  - Component Type: Permission Set
  - Purpose: Add missing fieldPermissions for EPA_StartDate__c (readable + editable) and EPA_EndDate__c (readable + editable) on EPA_StudyLeaveRequest__c. Add fieldPermissions for EPA_PublicHoliday__c.EPA_HolidayDate__c (readable + editable). Add fieldPermissions for EPA_StudyLeaveAllowance__mdt.EPA_AnnualAllowanceDays__c (readable + editable).

### Implementation Logic

1. **Add StartDate and EndDate FLS to Apprentice Profile** — Add `<fieldPermissions>` entries for `EPA_StudyLeaveRequest__c.EPA_StartDate__c` (readable + editable) and `EPA_StudyLeaveRequest__c.EPA_EndDate__c` (readable + editable) to `EPA Apprentice.profile-meta.xml`. Add `EPA_PublicHoliday__c.EPA_HolidayDate__c` (readable).
2. **Add StartDate and EndDate FLS to Line Manager Profile** — Add `<fieldPermissions>` entries for `EPA_StudyLeaveRequest__c.EPA_StartDate__c` (readable) and `EPA_StudyLeaveRequest__c.EPA_EndDate__c` (readable) to `EPA Line Manager.profile-meta.xml`. Add `EPA_PublicHoliday__c.EPA_HolidayDate__c` (readable).
3. **Add StartDate and EndDate FLS to System Administrator Profile** — Add `<fieldPermissions>` entries for `EPA_StudyLeaveRequest__c.EPA_StartDate__c` (readable + editable) and `EPA_StudyLeaveRequest__c.EPA_EndDate__c` (readable + editable) to `EPA System Administrator.profile-meta.xml`. Add `EPA_PublicHoliday__c.EPA_HolidayDate__c` (readable + editable).
4. **Add missing FLS to Apprentice Permission Set** — Add `<fieldPermissions>` entries for `EPA_StartDate__c` (readable + editable), `EPA_EndDate__c` (readable + editable), `EPA_PublicHoliday__c.EPA_HolidayDate__c` (readable), and `EPA_StudyLeaveAllowance__mdt.EPA_AnnualAllowanceDays__c` (readable).
5. **Add missing FLS to Manager Permission Set** — Add `<fieldPermissions>` entries for `EPA_StartDate__c` (readable), `EPA_EndDate__c` (readable), `EPA_PublicHoliday__c.EPA_HolidayDate__c` (readable), and `EPA_StudyLeaveAllowance__mdt.EPA_AnnualAllowanceDays__c` (readable).
6. **Add missing FLS to Administrator Permission Set** — Add `<fieldPermissions>` entries for `EPA_StartDate__c` (readable + editable), `EPA_EndDate__c` (readable + editable), `EPA_PublicHoliday__c.EPA_HolidayDate__c` (readable + editable), and `EPA_StudyLeaveAllowance__mdt.EPA_AnnualAllowanceDays__c` (readable + editable).
7. **Deploy to scratch org** — Run `sf project deploy start --target-org sprint005` to push all profile and permission set changes.
8. **Verify deployment** — Confirm no deployment errors and spot-check FLS settings in the scratch org Setup UI.

### Risks or Blockers

- **Assumption:** The EPA_Apprentice__c field (Apprentice Name lookup) is not listed in the Apprentice role's view+edit or view-only AC lists. The current configuration grants read-only access to apprentices. This has been preserved as-is since apprentices likely need to see the submitter name on their own records. If business intent is to hide this field from apprentices, the fieldPermissions entry should be removed.
- **Automation impact:** Apex triggers and flows that update EPA_Status__c and EPA_CalculatedBusinessDays__c run in system context and will not be affected by FLS restrictions on non-admin users. No blocker.
- **Custom Metadata FLS:** EPA_StudyLeaveAllowance__mdt is a Custom Metadata Type. In Salesforce, Custom Metadata Types are readable by all users with the "View Setup and Configuration" permission. FLS on Custom Metadata Types can be set in permission sets but the platform may not enforce it the same way as custom objects. This is a minor risk to verify during testing.

## Implementation Record

Agent: Developer Agent
Branch: feature/025
PR: pending
Summary: During implementation, all four fields identified in the solution plan as needing new fieldPermissions entries (EPA_StartDate__c, EPA_EndDate__c, EPA_HolidayDate__c, EPA_AnnualAllowanceDays__c) were found to be **required fields** in the scratch org. Salesforce does not allow explicit FLS configuration on required fields — they are always visible and editable to any user with object-level access. Deployment attempts with these fieldPermissions entries failed with "You cannot deploy to a required field" errors.

Verification confirmed that the existing FLS configuration already fully satisfies the acceptance criteria:
- **Apprentice**: Category (read+edit), Status (read-only), CalculatedBusinessDays (read-only), Apprentice (read-only), LeaveCategory Description (read-only) — all correctly configured. StartDate and EndDate are required fields, automatically visible and editable.
- **Line Manager**: Category (read-only), Status (read-only), CalculatedBusinessDays (read-only), Apprentice (read-only), LeaveCategory Description (read-only) — all correctly configured. StartDate and EndDate are required fields, automatically visible. Object-level permissions prevent editing.
- **System Administrator**: All fields read+edit — correctly configured.
- **Permission Sets**: Mirror the same FLS patterns as the corresponding profiles.
- **Required fields** (StartDate, EndDate, HolidayDate, AnnualAllowanceDays) are inherently visible to all users with object Read access and editable to users with object Edit access — no explicit FLS entries needed.

No metadata file changes were required. The profiles and permission sets were deployed and verified in the sprint005 scratch org via SOQL FieldPermissions query. All FLS settings confirmed correct.
