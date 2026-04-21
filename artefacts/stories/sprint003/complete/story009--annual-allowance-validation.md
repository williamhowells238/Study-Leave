# Story 009 — Annual Allowance Validation

## User Story

As a **System Administrator**, I want the system to validate that a study leave request does not cause the apprentice to exceed their annual study leave allowance, so that organisational policy limits are automatically enforced.

## Acceptance Criteria

- Given an apprentice is submitting a new study leave request, when the calculated business days of the new request plus the total business days of all existing Approved and Pending requests for the same calendar year exceed the configured annual allowance (e.g. 20 days), then the system rejects the request AND displays an error message indicating the remaining balance (e.g. "You have X days remaining of your annual study leave allowance. This request requires Y days.").
- Given an apprentice is submitting a new study leave request, when the total including the new request does not exceed the annual allowance, then the validation passes AND the request proceeds.
- Given an apprentice has had a previous request Cancelled or Rejected, when the allowance is calculated, then only Approved and Pending requests count towards the used allowance.
- Given the annual allowance is calculated on a per-calendar-year basis, when a request spans a year boundary, then the business days are correctly attributed to the relevant calendar year(s).
- Given the allowance configuration value changes, when subsequent requests are validated, then the new allowance value is used.

## Related Parent Epic

[Epic 002 — Study Leave Request Submission](../../../artefacts/epics/epic002--study-leave-request-submission.md)

---

## Dependencies

- Dependency Type: Story
- Dependency on: Story 001
- Dependency Justification: The Study_Leave_Request__c object with Status__c and Calculated_Business_Days__c fields must exist to query existing requests and determine the used allowance.

- Dependency Type: Story
- Dependency on: Story 003
- Dependency Justification: The annual allowance configuration must exist so the validation can retrieve the configured maximum days allowed per year.

- Dependency Type: Story
- Dependency on: Story 008
- Dependency Justification: The business day calculation must be in place so that the Calculated_Business_Days__c value is available for the new request before the allowance validation runs.

## Assumptions

- Assumption Type: Business Confirmation
- Assumption Description: When a study leave request spans a calendar year boundary (e.g. December to January), the business days should be split and attributed to each respective calendar year for allowance validation purposes.
- Assumption Justification: The acceptance criteria mention year-boundary handling but do not specify the exact splitting mechanism. Business confirmation is needed on whether to split by year or attribute all days to the start-date year.

- Assumption Type: Technical Confirmation
- Assumption Description: The allowance validation will be implemented in Apex (trigger or invocable action) rather than a Validation Rule, because it requires querying existing approved/pending requests and the allowance configuration.
- Assumption Justification: Salesforce Validation Rules cannot perform SOQL queries. An Apex-based approach is required to aggregate existing request days and compare against the configured allowance.

## Development Estimate

- Story Points: 5
- Justification: This is a complex story requiring custom Apex development to aggregate Calculated_Business_Days__c across all Approved and Pending requests for the same apprentice within the current calendar year, retrieve the configured annual allowance from the Custom Setting/Custom Metadata Type, and compare the total. The year-boundary edge case (requests spanning December to January requiring day-splitting across calendar years) adds significant complexity. The validation must produce a user-friendly error message with remaining balance information. Multiple dependencies (Stories 001, 003, 008) must be in place, and thorough unit testing with various scenarios is required.

## Testing Estimate

- Story Points: 8
- Justification: This story requires extensive scenario-based testing: submitting a request that stays within the annual allowance (accepted), submitting a request that exactly reaches the allowance limit (accepted), submitting a request that exceeds the allowance (rejected with correct remaining balance message), verifying that only Approved and Pending requests count toward the used allowance while Cancelled and Rejected requests are excluded, testing the year-boundary edge case where a request spans December to January and days must be split across calendar years, verifying that a change to the allowance configuration value is immediately reflected in subsequent validations, and testing with multiple pre-existing requests in various statuses. The error message must dynamically display the correct remaining days and requested days. The dependency chain (Stories 001, 003, 008) and the cross-status aggregation logic create a large test matrix. The year-boundary splitting and dynamic error messaging complexity warrant an 8-point testing estimate.

## Solution Plan

### Salesforce Components
- **EPA_AnnualAllowanceValidation_Class**
  - Component Type: Apex Class
  - Purpose: Handler class containing the annual allowance validation logic. Queries existing Approved and Pending study leave requests for the same apprentice within the relevant calendar year(s), retrieves the configured annual allowance from `EPA_StudyLeaveAllowance__mdt`, calculates the total used days including the new request, and adds an error to the record if the allowance would be exceeded. Handles year-boundary splitting for requests spanning December to January.

- **EPA_AnnualAllowanceValidation_TestClass**
  - Component Type: Apex Test Class
  - Purpose: PNB (Positive/Negative/Bulk) test coverage for the validation logic. Covers: request within allowance (positive), request exceeding allowance (negative with error message assertion), request at exact limit (positive), only Approved/Pending statuses counted, Cancelled/Rejected excluded, year-boundary splitting, allowance config change reflected, and bulk insert of 200+ records.

- **EPA_BusinessDayCalculation_Trigger** (modify existing)
  - Component Type: Apex Trigger
  - Purpose: Add a call to `EPA_AnnualAllowanceValidation_Class` after the existing business day calculation. This maintains the one-trigger-per-object pattern. The validation runs after `EPA_CalculatedBusinessDays__c` has been set so the new request's calculated days are available.

### Implementation Logic
1. **Create `EPA_AnnualAllowanceValidation_Class`** (`with sharing`):
   - Define a `public static void validateAllowance(List<EPA_StudyLeaveRequest__c> requests)` method.
   - Filter incoming requests to only those with a non-null `EPA_Apprentice__c`, `EPA_StartDate__c`, `EPA_EndDate__c`, and `EPA_CalculatedBusinessDays__c`.
   - Collect all unique `EPA_Apprentice__c` IDs and determine the calendar year(s) covered by each request's date range.
   - Query `EPA_StudyLeaveAllowance__mdt` (the `EPA_Default` record) to retrieve `EPA_AnnualAllowanceDays__c`.
   - Query all existing `EPA_StudyLeaveRequest__c` records for the collected apprentices where `EPA_Status__c IN ('Approved', 'Pending')` and the request falls within the relevant calendar year(s). Exclude the current records if this is an update context (by checking for non-null Id).
   - Build a `Map<String, Decimal>` keyed by `apprenticeId + '-' + year` holding the sum of `EPA_CalculatedBusinessDays__c` for existing requests.
   - For each incoming request:
     - If the request does **not** span a year boundary: add its `EPA_CalculatedBusinessDays__c` to the existing total for that apprentice+year and compare against the allowance.
     - If the request **spans a year boundary** (start year ≠ end year): use the `EPA_BusinessDayCalculation_Class` date-iteration logic (reuse the weekday/public-holiday check) to split business days across each calendar year. Validate each year's total independently.
     - If the total exceeds the allowance for any year, call `req.addError()` with the message: `'You have X days remaining of your annual study leave allowance. This request requires Y days.'` where X = allowance − existing used days, and Y = the days this request would add to that year.
2. **Modify `EPA_BusinessDayCalculation_Trigger`**:
   - After the existing call to `EPA_BusinessDayCalculation_Class.calculateBusinessDays()`, add a call to `EPA_AnnualAllowanceValidation_Class.validateAllowance()` passing the same `recordsToProcess` list.
   - On insert: pass all `Trigger.new` records (the full list, as all new records need validation).
   - On update: pass `recordsToProcess` (only records where dates changed, as the allowance needs revalidation when business days change).
3. **Create `EPA_AnnualAllowanceValidation_TestClass`** (`@isTest(SeeAllData=false)`):
   - `@TestSetup`: Create test `EPA_PublicHoliday__c` records, and multiple `EPA_StudyLeaveRequest__c` records in various statuses (Approved, Pending, Rejected, Cancelled) for a test user.
   - **Positive test**: Insert a request within the remaining allowance — assert no error, record is inserted.
   - **Positive test (exact limit)**: Insert a request that exactly reaches the allowance — assert no error.
   - **Negative test**: Insert a request that exceeds the allowance — assert `DmlException` is thrown with the correct remaining balance message.
   - **Negative test (status filtering)**: Create only Rejected/Cancelled prior requests, insert a new request within allowance — assert it succeeds (those statuses don't count).
   - **Year-boundary test**: Insert a request spanning Dec–Jan, assert days are split correctly and each year is validated independently.
   - **Config change test**: Modify the allowance value (use a test-visible approach or dependency injection), assert the new value is respected.
   - **Bulk test**: Insert 200+ records in a single DML — assert all records are processed without governor limit exceptions.

### Risks or Blockers
- **Year-boundary day splitting**: The business day calculation logic in `EPA_BusinessDayCalculation_Class` iterates day-by-day. The allowance validation will need to replicate or reuse this iteration to split days across calendar years. Consider extracting a shared utility method from `EPA_BusinessDayCalculation_Class` that counts business days for a sub-range to avoid code duplication.
- **Custom Metadata in tests**: Custom Metadata Type records (`EPA_StudyLeaveAllowance__mdt`) cannot be inserted in Apex tests. The validation class should query the metadata via a method that can be overridden or mocked in tests (e.g., a `@TestVisible` static variable holding the allowance value, falling back to the CMDT query in production).
- **Assumption**: Year-boundary requests will have their business days split and attributed to each respective calendar year per the story's assumption. If business confirmation changes this to "attribute all days to start-date year", the logic simplifies significantly.
- **Trigger ordering**: The validation must run after `EPA_CalculatedBusinessDays__c` is set. Since both run in the same before-trigger context and the calculation is called first, this ordering is guaranteed.

## PR Review - story-009: Annual Allowance Validation

Result: Approved

### Summary
- All five changed files were reviewed against the Apex quality guardrails, component standards, project conventions, and story acceptance criteria.
- **Governor Limit Safety**: No SOQL or DML inside loops. All queries are bulk-safe with collections and bind variables.
- **Sharing Model**: `EPA_AnnualAllowanceValidation_Class` correctly declares `with sharing`.
- **CRUD/FLS**: Both SOQL queries in the handler use `WITH USER_MODE`.
- **SOQL Injection**: No dynamic SOQL; all queries use bind variables.
- **Modern Apex Idioms**: Uses `??` null-coalescing operator and `Assert.*` methods.
- **Naming Conventions**: All files follow the `EPA_CamelCaseName_Suffix` pattern.
- **Flowerboxing**: Class and method flowerbox comments are present on all classes and methods.
- **Trigger Architecture**: One trigger per object maintained; business logic delegated to handler class; trigger body contains only routing logic.
- **PNB Test Coverage**: Positive (within allowance, exact limit, status filtering), Negative (exceeds allowance with error message assertion, year-boundary exceeds), Bulk (200 records).
- **Acceptance Criteria**: All five acceptance criteria are covered — allowance exceeded rejection with remaining balance message, within-allowance pass, status filtering (only Approved/Pending count), year-boundary day splitting, and config change reflection.
- **Minor observation**: The `splitBusinessDaysByYear` method replicates weekday/holiday logic from `EPA_BusinessDayCalculation_Class`. This is acceptable duplication acknowledged in the solution plan; a future refactoring could extract a shared utility.

### Changes to be made
- None. The implementation meets all quality standards and acceptance criteria.

## Test Results

Result: Passed
Tested By: QA Agent

### Acceptance Criteria Results
- AC1: Given a request exceeds the annual allowance, when submitted, then the system rejects it with an error message showing remaining balance — **Pass**
  - Verification method: Ran `givenRequestExceedsAllowance_whenInserted_thenErrorWithMessage` which inserts a request exceeding the allowance and asserts a DmlException is thrown with the correct remaining balance message.
  - Evidence: Test passed (27ms). Error message format "You have X days remaining of your annual study leave allowance. This request requires Y days." validated.

- AC2: Given a request does not exceed the annual allowance, when submitted, then the validation passes and the request proceeds — **Pass**
  - Verification method: Ran `givenRequestWithinAllowance_whenInserted_thenNoError` and `givenRequestAtExactLimit_whenInserted_thenNoError` which insert requests within and at the exact allowance limit respectively.
  - Evidence: Both tests passed (51ms, 46ms). Records inserted successfully with no errors.

- AC3: Given cancelled or rejected prior requests exist, when the allowance is calculated, then only Approved and Pending requests count towards the used allowance — **Pass**
  - Verification method: Ran `givenOnlyRejectedCancelledPrior_whenInserted_thenSucceeds` which creates only Rejected/Cancelled prior requests and asserts a new request within allowance succeeds.
  - Evidence: Test passed (314ms). Rejected and Cancelled requests correctly excluded from allowance calculation.

- AC4: Given a request spans a year boundary, when submitted, then the business days are correctly attributed to the relevant calendar year(s) — **Pass**
  - Verification method: Ran `givenYearBoundaryRequest_whenInserted_thenDaysSplitAcrossYears` and `givenYearBoundaryExceedsAllowance_whenInserted_thenError` which test cross-year requests for correct day splitting and per-year validation.
  - Evidence: Both tests passed (101ms, 30ms). Days correctly split across calendar years with independent per-year validation.

- AC5: Given the allowance configuration value changes, when subsequent requests are validated, then the new allowance value is used — **Pass**
  - Verification method: Ran `givenAllowanceIncreased_whenInserted_thenNewValueRespected` which modifies the allowance value and asserts the new value is respected in subsequent validations.
  - Evidence: Test passed (56ms). Updated allowance configuration correctly reflected in validation.

### Bulk Safety
- Bulk insert of 200+ records processed without governor limit exceptions — **Pass**
  - Verification method: Ran `givenBulkInsert_whenInserted_thenAllProcessed` (341ms).

### Test Run Summary
- Test Run Id: 707C300000Yysex
- Tests Ran: 9
- Pass Rate: 100%
- Total Time: 1147ms

### Summary
All tests passed. All five acceptance criteria are verified. The story is now completed.