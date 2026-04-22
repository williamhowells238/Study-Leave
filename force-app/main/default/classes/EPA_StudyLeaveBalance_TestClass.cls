/**
 * @description: Test class for EPA_StudyLeaveBalance_Class.
 *               Provides Positive, Negative, and Bulk (PNB) test coverage for
 *               balance summary and request history retrieval methods.
 * @author: Developer Agent
 * @date: 2026-04-22
 */
@isTest(SeeAllData=false)
private class EPA_StudyLeaveBalance_TestClass {

    private static Id testUserId = UserInfo.getUserId();

    /**
     * @description: Creates test data including leave category and study leave requests
     *               in various statuses for the current calendar year.
     */
    @TestSetup
    static void makeData() {
        // Override allowance to prevent validation blocking test data creation
        EPA_AnnualAllowanceValidation_Class.allowanceOverride = 1000;

        EPA_LeaveCategory__c category = new EPA_LeaveCategory__c(Name = 'Study Block');
        insert category;

        Integer currentYear = Date.today().year();

        List<EPA_StudyLeaveRequest__c> requests = new List<EPA_StudyLeaveRequest__c>();

        // Request 1: 5 business days — will become Approved
        // Mon to Fri = 5 weekdays
        requests.add(new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = testUserId,
            EPA_Category__c = category.Id,
            EPA_StartDate__c = Date.newInstance(currentYear, 3, 2),
            EPA_EndDate__c = Date.newInstance(currentYear, 3, 6)
        ));

        // Request 2: 5 business days — stays Pending
        requests.add(new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = testUserId,
            EPA_Category__c = category.Id,
            EPA_StartDate__c = Date.newInstance(currentYear, 4, 6),
            EPA_EndDate__c = Date.newInstance(currentYear, 4, 10)
        ));

        // Request 3: 5 business days — will become Rejected
        requests.add(new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = testUserId,
            EPA_Category__c = category.Id,
            EPA_StartDate__c = Date.newInstance(currentYear, 5, 4),
            EPA_EndDate__c = Date.newInstance(currentYear, 5, 8)
        ));

        // Request 4: 5 business days — will become Cancelled
        requests.add(new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = testUserId,
            EPA_Category__c = category.Id,
            EPA_StartDate__c = Date.newInstance(currentYear, 6, 1),
            EPA_EndDate__c = Date.newInstance(currentYear, 6, 5)
        ));

        insert requests;

        // Update statuses after insert
        requests[0].EPA_Status__c = 'Approved';
        requests[2].EPA_Status__c = 'Rejected';
        requests[3].EPA_Status__c = 'Cancelled';
        update new List<EPA_StudyLeaveRequest__c>{requests[0], requests[2], requests[3]};
    }

    // =========================================================================
    // POSITIVE TESTS
    // =========================================================================

    /**
     * @description: Verify balance summary returns correct values when apprentice has
     *               Approved and Pending requests. Consumed = Approved + Pending days only.
     */
    @isTest
    static void givenApprovedAndPendingRequests_whenGetBalanceSummary_thenCorrectBalance() {
        EPA_StudyLeaveBalance_Class.allowanceOverride = 20;

        Test.startTest();
        EPA_StudyLeaveBalance_Class.BalanceSummary summary =
            EPA_StudyLeaveBalance_Class.getBalanceSummary();
        Test.stopTest();

        Assert.areEqual(20, summary.annualAllowance, 'Annual allowance should be 20');
        Assert.areEqual(10, summary.consumedDays, 'Consumed days should be 10 (5 Approved + 5 Pending)');
        Assert.areEqual(10, summary.remainingDays, 'Remaining days should be 10');
    }

    /**
     * @description: Verify request history returns all requests regardless of status,
     *               with correct field values and descending start date order.
     */
    @isTest
    static void givenMultipleRequests_whenGetRequestHistory_thenAllReturnedInOrder() {
        Test.startTest();
        List<EPA_StudyLeaveRequest__c> history =
            EPA_StudyLeaveBalance_Class.getRequestHistory();
        Test.stopTest();

        Assert.areEqual(4, history.size(), 'Should return all 4 requests regardless of status');
        // Verify descending order by start date
        for (Integer i = 0; i < history.size() - 1; i++) {
            Assert.isTrue(
                history[i].EPA_StartDate__c >= history[i + 1].EPA_StartDate__c,
                'Requests should be ordered by start date descending'
            );
        }
    }

    // =========================================================================
    // NEGATIVE TESTS
    // =========================================================================

    /**
     * @description: Verify balance summary returns full allowance when apprentice has
     *               no requests for the current year.
     */
    @isTest
    static void givenNoRequests_whenGetBalanceSummary_thenFullAllowance() {
        // Delete all test requests
        delete [SELECT Id FROM EPA_StudyLeaveRequest__c];
        EPA_StudyLeaveBalance_Class.allowanceOverride = 20;

        Test.startTest();
        EPA_StudyLeaveBalance_Class.BalanceSummary summary =
            EPA_StudyLeaveBalance_Class.getBalanceSummary();
        Test.stopTest();

        Assert.areEqual(20, summary.annualAllowance, 'Annual allowance should be 20');
        Assert.areEqual(0, summary.consumedDays, 'Consumed days should be 0');
        Assert.areEqual(20, summary.remainingDays, 'Remaining days should be full allowance');
    }

    /**
     * @description: Verify request history returns empty list when apprentice has no requests.
     */
    @isTest
    static void givenNoRequests_whenGetRequestHistory_thenEmptyList() {
        delete [SELECT Id FROM EPA_StudyLeaveRequest__c];

        Test.startTest();
        List<EPA_StudyLeaveRequest__c> history =
            EPA_StudyLeaveBalance_Class.getRequestHistory();
        Test.stopTest();

        Assert.areEqual(0, history.size(), 'History should be empty when no requests exist');
    }

    /**
     * @description: Verify that Rejected and Cancelled requests are excluded from the
     *               balance consumed count but are included in request history.
     */
    @isTest
    static void givenRejectedCancelledRequests_whenGetBalance_thenExcludedFromConsumed() {
        // Delete Approved and Pending, keep only Rejected and Cancelled
        delete [SELECT Id FROM EPA_StudyLeaveRequest__c
                WHERE EPA_Status__c IN ('Approved', 'Pending')];
        EPA_StudyLeaveBalance_Class.allowanceOverride = 20;

        Test.startTest();
        EPA_StudyLeaveBalance_Class.BalanceSummary summary =
            EPA_StudyLeaveBalance_Class.getBalanceSummary();
        List<EPA_StudyLeaveRequest__c> history =
            EPA_StudyLeaveBalance_Class.getRequestHistory();
        Test.stopTest();

        Assert.areEqual(0, summary.consumedDays, 'Rejected/Cancelled should not count as consumed');
        Assert.areEqual(20, summary.remainingDays, 'Full allowance should remain');
        Assert.areEqual(2, history.size(), 'Rejected and Cancelled requests should appear in history');
    }

    // =========================================================================
    // BULK TESTS
    // =========================================================================

    /**
     * @description: Verify balance summary and request history handle 200+ records
     *               without governor limit issues.
     */
    @isTest
    static void givenBulkRequests_whenGetBalanceAndHistory_thenNoGovernorLimits() {
        // Delete existing test data
        delete [SELECT Id FROM EPA_StudyLeaveRequest__c];
        EPA_AnnualAllowanceValidation_Class.allowanceOverride = 100000;
        EPA_StudyLeaveBalance_Class.allowanceOverride = 100000;

        EPA_LeaveCategory__c cat = [SELECT Id FROM EPA_LeaveCategory__c LIMIT 1];
        Integer currentYear = Date.today().year();

        List<EPA_StudyLeaveRequest__c> bulkRequests = new List<EPA_StudyLeaveRequest__c>();
        for (Integer i = 0; i < 200; i++) {
            // Spread across months — use modulo to cycle through months 1-10
            Integer month = Math.mod(i, 10) + 1;
            Integer day = Math.mod(i, 20) + 1;
            Date startDate = Date.newInstance(currentYear, month, day);
            // Single day requests to avoid overlaps
            bulkRequests.add(new EPA_StudyLeaveRequest__c(
                EPA_Apprentice__c = testUserId,
                EPA_Category__c = cat.Id,
                EPA_StartDate__c = startDate,
                EPA_EndDate__c = startDate
            ));
        }
        insert bulkRequests;

        Test.startTest();
        EPA_StudyLeaveBalance_Class.BalanceSummary summary =
            EPA_StudyLeaveBalance_Class.getBalanceSummary();
        List<EPA_StudyLeaveRequest__c> history =
            EPA_StudyLeaveBalance_Class.getRequestHistory();
        Test.stopTest();

        Assert.isTrue(summary.consumedDays > 0, 'Consumed days should be greater than 0 for bulk records');
        Assert.areEqual(200, history.size(), 'All 200 records should be returned in history');
        Assert.areEqual(100000, summary.annualAllowance, 'Allowance should be set correctly');
    }
}
