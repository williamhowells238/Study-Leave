# Story 024 — Configure Object-Level Security

## User Story

As a **System Administrator**, I want object-level security configured on all custom objects so that each role has the appropriate Create, Read, Update, and Delete permissions, ensuring users can only interact with objects relevant to their function.

## Acceptance Criteria

- Given the Apprentice role, when object-level permissions are inspected, then apprentices have:
  - Study Leave Request: Create, Read, Edit (own records only — record-level handled separately)
  - Leave Category: Read only
  - Public Holiday: Read only
  - Study Leave Allowance: Read only
- Given the Line Manager role, when object-level permissions are inspected, then managers have:
  - Study Leave Request: Read (direct report records — record-level handled separately)
  - Leave Category: Read only
  - Public Holiday: Read only
  - Study Leave Allowance: Read only
- Given the System Administrator role, when object-level permissions are inspected, then administrators have:
  - Study Leave Request: Full CRUD (Create, Read, Update, Delete)
  - Leave Category: Full CRUD
  - Public Holiday: Full CRUD
  - Study Leave Allowance: Full CRUD
- Given object-level security is configured, when a user without the required permission attempts to access an object, then the system denies access.

## Related Parent Epic

[Epic 005 — Security and Access Control](../../../artefacts/epics/epic005--security-and-access-control.md)

---

## Dependencies

- Dependency Type: Story
- Dependency on: Story 001
- Dependency Justification: The Study_Leave_Request__c object must exist to configure CRUD permissions.

- Dependency Type: Story
- Dependency on: Story 002
- Dependency Justification: The Leave_Category__c object must exist to configure CRUD permissions.

- Dependency Type: Story
- Dependency on: Story 003
- Dependency Justification: The Study_Leave_Allowance__c configuration must exist to configure CRUD permissions.

- Dependency Type: Story
- Dependency on: Story 004
- Dependency Justification: The Public_Holiday__c object must exist to configure CRUD permissions.

- Dependency Type: Story
- Dependency on: Story 022
- Dependency Justification: User Profiles must be configured as the vehicle through which object-level permissions are granted.

- Dependency Type: Story
- Dependency on: Story 023
- Dependency Justification: Permission Sets must be created as an additional vehicle for granting object-level permissions beyond the profile baseline.

## Assumptions

- Assumption Type: Business Confirmation
- Assumption Description: The CRUD permission matrix per role (as defined in the acceptance criteria) is confirmed as the final specification.
- Assumption Justification: Object-level permissions are foundational to the security model. Changes to the CRUD matrix after implementation could require rework across profiles, permission sets, and testing.

- Assumption Type: Technical Confirmation
- Assumption Description: Object-level security will be configured on both Profiles and Permission Sets, with Profiles providing a restrictive baseline and Permission Sets granting additional access as needed.
- Assumption Justification: This is Salesforce best practice for security layering — restrictive profiles with additive permission sets.

## Development Estimate

- Story Points: 2
- Justification: This is a simple story involving the configuration of CRUD permissions on Profiles and Permission Sets for four custom objects across three roles. The CRUD matrix is clearly defined in the acceptance criteria, making the implementation straightforward. The work is entirely declarative — setting Create, Read, Update, and Delete checkboxes on each Profile and Permission Set for each object. The effort is low but methodical, requiring careful verification that each role has exactly the specified permissions.

## Testing Estimate

- Story Points: 3
- Justification: Testing requires verifying the full CRUD matrix across three roles and four custom objects (12 role-object combinations), with both positive testing (confirming permitted operations succeed) and negative testing (confirming denied operations are blocked). Specifically: apprentices can Create, Read, and Edit Study Leave Requests but only Read Leave Categories, Public Holidays, and Study Leave Allowance; managers can Read Study Leave Requests and Read the configuration objects; administrators have full CRUD on all objects. Each denied operation must be tested to confirm the system blocks access. The systematic nature of 12+ test scenarios with both positive and negative cases warrants a 3-point estimate.

## Solution Plan

### Salesforce Components

- **EPA Apprentice.profile-meta.xml**
  - Component Type: Profile
  - Purpose: Add Read-only object permissions for `EPA_PublicHoliday__c`. Confirm existing permissions on `EPA_StudyLeaveRequest__c` (Create, Read, Edit) and `EPA_LeaveCategory__c` (Read) are correct.

- **EPA Line Manager.profile-meta.xml**
  - Component Type: Profile
  - Purpose: Add Read-only object permissions for `EPA_PublicHoliday__c`. Confirm existing permissions on `EPA_StudyLeaveRequest__c` (Read) and `EPA_LeaveCategory__c` (Read) are correct.

- **EPA System Administrator.profile-meta.xml**
  - Component Type: Profile
  - Purpose: Add Full CRUD object permissions for `EPA_PublicHoliday__c` (already present — verify). No changes expected as existing permissions already cover Study Leave Request, Leave Category, and Public Holiday with full CRUD.

- **EPA_StudyLeaveApprentice_PermissionSet.permissionset-meta.xml**
  - Component Type: Permission Set
  - Purpose: Add Read-only object permissions for `EPA_PublicHoliday__c` and `EPA_StudyLeaveAllowance__mdt`. Confirm existing permissions on `EPA_StudyLeaveRequest__c` (Create, Read, Edit) and `EPA_LeaveCategory__c` (Read) are correct.

- **EPA_StudyLeaveManager_PermissionSet.permissionset-meta.xml**
  - Component Type: Permission Set
  - Purpose: Add Read-only object permissions for `EPA_PublicHoliday__c` and `EPA_StudyLeaveAllowance__mdt`. Confirm existing permissions on `EPA_StudyLeaveRequest__c` (Read) and `EPA_LeaveCategory__c` (Read) are correct.

- **EPA_StudyLeaveAdministrator_PermissionSet.permissionset-meta.xml**
  - Component Type: Permission Set
  - Purpose: No changes required — already has Full CRUD + ViewAll/ModifyAll on all four objects including `EPA_StudyLeaveAllowance__mdt`. Verify only.

### Implementation Logic

1. **Audit current state against acceptance criteria** — Map the CRUD matrix from the acceptance criteria against existing Profile and Permission Set XML files to confirm the gap analysis:
   - Apprentice Profile/PermSet: Missing Read on `EPA_PublicHoliday__c` and `EPA_StudyLeaveAllowance__mdt`.
   - Manager Profile/PermSet: Missing Read on `EPA_PublicHoliday__c` and `EPA_StudyLeaveAllowance__mdt`.
   - Admin Profile: Missing `EPA_StudyLeaveAllowance__mdt` (note: Custom Metadata Type permissions on profiles are limited — see Risks).
   - Admin PermSet: Already complete.

2. **Update EPA Apprentice Profile** — Add `objectPermissions` block for `EPA_PublicHoliday__c` with `allowRead=true` and all other CRUD flags set to `false`.

3. **Update EPA Line Manager Profile** — Add `objectPermissions` block for `EPA_PublicHoliday__c` with `allowRead=true` and all other CRUD flags set to `false`.

4. **Update EPA_StudyLeaveApprentice_PermissionSet** — Add two `objectPermissions` blocks:
   - `EPA_PublicHoliday__c` with `allowRead=true`, all others `false`.
   - `EPA_StudyLeaveAllowance__mdt` with `allowRead=true`, all others `false`.

5. **Update EPA_StudyLeaveManager_PermissionSet** — Add two `objectPermissions` blocks:
   - `EPA_PublicHoliday__c` with `allowRead=true`, all others `false`.
   - `EPA_StudyLeaveAllowance__mdt` with `allowRead=true`, all others `false`.

6. **Verify EPA System Administrator Profile** — Confirm existing Full CRUD on `EPA_StudyLeaveRequest__c`, `EPA_LeaveCategory__c`, and `EPA_PublicHoliday__c`. No changes needed for custom objects. CMDT permissions are handled via the Admin Permission Set.

7. **Verify EPA_StudyLeaveAdministrator_PermissionSet** — Confirm all four objects have Full CRUD + ViewAll/ModifyAll. No changes expected.

8. **Deploy to scratch org** — Push the updated metadata to the `sprint003` scratch org using `sf project deploy start`.

9. **Verify deployment** — Confirm successful deployment with no errors. Spot-check one Profile and one Permission Set in the org to validate the permissions are correctly applied.

### Risks or Blockers

- **Custom Metadata Type permissions on Profiles:** Salesforce Profiles have limited support for setting object permissions on Custom Metadata Types (`__mdt`). Read access to CMDT records is generally available to all authenticated users by default. Full CRUD on CMDTs requires the "Customize Application" system permission or Metadata API access, which is already handled through the Admin Permission Set. Therefore, `EPA_StudyLeaveAllowance__mdt` permissions will be configured on Permission Sets only, not on Profiles. This satisfies the acceptance criteria since Permission Sets are the primary vehicle for granting access (per Story 023 assumptions).
- **No blockers identified:** All dependency stories (001, 002, 003, 004, 022, 023) are complete. The four custom objects and three Permission Sets already exist in the codebase.

## Implementation Record

Agent: Developer Agent
Branch: feature/024
PR: https://github.com/williamhowells238/Study-Leave/pull/13
Summary: Audited existing Profile and Permission Set XML files against the acceptance criteria CRUD matrix. Identified four gaps: EPA_PublicHoliday__c Read access missing from Apprentice Profile, Line Manager Profile, Apprentice PermSet, and Manager PermSet; EPA_StudyLeaveAllowance__mdt Read access missing from Apprentice and Manager PermSets. Added the required objectPermissions blocks to all four files. Admin Profile and Admin PermSet were verified as already complete — no changes needed. Deployed successfully to sprint003 scratch org (Deploy ID: 0AfC300000BtrADKAZ, 7/7 components). All 21 Apex tests passed with 100% pass rate. No code quality scan required as changes are purely declarative XML metadata.
