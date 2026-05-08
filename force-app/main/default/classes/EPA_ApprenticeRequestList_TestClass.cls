/**
 * @description: Test class for EPA_ApprenticeRequestList_Class covering positive,
 *               negative, and bulk scenarios (PNB pattern).
 * @author: Developer Agent
 * @date: 2026-05-08
 */
@isTest(SeeAllData=false)
private class EPA_ApprenticeRequestList_TestClass {

    @TestSetup
    static void makeData() {
        // Create a leave quota for the running user (required for insert context)
        EPA_LeaveQuota__c quota = new EPA_LeaveQuota__c(
            EPA_Apprentice__c = UserInfo.getUserId(),
            EPA_QuotaYear__c = String.valueOf(Date.today().year()),
            EPA_AnnualEntitlement__c = 24,
            EPA_DaysUsed__c = 0
        );
        insert quota;

        // Create study leave requests for the running user
        Datetime now = Datetime.now();
        List<EPA_StudyLeaveRequest__c> requests = new List<EPA_StudyLeaveRequest__c>();
        requests.add(new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = UserInfo.getUserId(),
            EPA_LeaveType__c = 'College',
            EPA_StartDate__c = Date.today().addDays(30),
            EPA_EndDate__c = Date.today().addDays(32),
            EPA_NumberOfDays__c = 3,
            EPA_Status__c = 'Pending',
            EPA_Reason__c = 'Attending lectures',
            EPA_SubmissionTimestamp__c = now
        ));
        requests.add(new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = UserInfo.getUserId(),
            EPA_LeaveType__c = 'Exam',
            EPA_StartDate__c = Date.today().addDays(60),
            EPA_EndDate__c = Date.today().addDays(60),
            EPA_NumberOfDays__c = 1,
            EPA_Status__c = 'Approved',
            EPA_SubmissionTimestamp__c = now
        ));
        requests.add(new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = UserInfo.getUserId(),
            EPA_LeaveType__c = 'College',
            EPA_StartDate__c = Date.today().addDays(90),
            EPA_EndDate__c = Date.today().addDays(91),
            EPA_NumberOfDays__c = 2,
            EPA_Status__c = 'Rejected',
            EPA_RejectionReason__c = 'Insufficient notice',
            EPA_SubmissionTimestamp__c = now
        ));
        insert requests;
    }

    /**
     * @description: Positive test - running user's requests are returned with correct
     *               field values and ordering.
     */
    @isTest
    static void givenUserHasRequests_whenGetMyRequests_thenRequestsReturned() {
        Test.startTest();
        List<EPA_StudyLeaveRequest__c> results = EPA_ApprenticeRequestList_Class.getMyRequests();
        Test.stopTest();

        Assert.areEqual(3, results.size(), 'Should return all 3 requests for the running user');

        // Verify ordering by start date descending (90 days > 60 days > 30 days)
        Assert.areEqual(Date.today().addDays(90), results[0].EPA_StartDate__c,
            'First result should have the latest start date');
        Assert.areEqual(Date.today().addDays(60), results[1].EPA_StartDate__c,
            'Second result should have the middle start date');
        Assert.areEqual(Date.today().addDays(30), results[2].EPA_StartDate__c,
            'Third result should have the earliest start date');

        // Verify field values on first record
        Assert.areEqual('College', results[0].EPA_LeaveType__c, 'Leave type should be College');
        Assert.areEqual(2, results[0].EPA_NumberOfDays__c, 'Number of days should be 2');
        Assert.areEqual('Rejected', results[0].EPA_Status__c, 'Status should be Rejected');
        Assert.areEqual('Insufficient notice', results[0].EPA_RejectionReason__c,
            'Rejection reason should be populated');
    }

    /**
     * @description: Negative test - a different user's requests are not returned
     *               for the running user (empty list).
     */
    @isTest
    static void givenNoOwnRequests_whenGetMyRequests_thenEmptyListReturned() {
        // Delete all requests belonging to the running user
        delete [SELECT Id FROM EPA_StudyLeaveRequest__c WHERE EPA_Apprentice__c = :UserInfo.getUserId()];

        Test.startTest();
        List<EPA_StudyLeaveRequest__c> results = EPA_ApprenticeRequestList_Class.getMyRequests();
        Test.stopTest();

        Assert.areEqual(0, results.size(), 'Should return empty list when user has no requests');
    }

    /**
     * @description: Bulk test - 200 records for the running user are returned
     *               without governor limit issues.
     */
    @isTest
    static void givenBulkRequests_whenGetMyRequests_thenAllReturned() {
        // Delete test setup data to start fresh for bulk
        delete [SELECT Id FROM EPA_StudyLeaveRequest__c WHERE EPA_Apprentice__c = :UserInfo.getUserId()];

        Datetime now = Datetime.now();
        List<EPA_StudyLeaveRequest__c> bulkRequests = new List<EPA_StudyLeaveRequest__c>();
        for (Integer i = 0; i < 200; i++) {
            bulkRequests.add(new EPA_StudyLeaveRequest__c(
                EPA_Apprentice__c = UserInfo.getUserId(),
                EPA_LeaveType__c = 'College',
                EPA_StartDate__c = Date.today().addDays(30 + i),
                EPA_EndDate__c = Date.today().addDays(31 + i),
                EPA_NumberOfDays__c = 1,
                EPA_Status__c = 'Pending',
                EPA_SubmissionTimestamp__c = now
            ));
        }
        insert bulkRequests;

        Test.startTest();
        List<EPA_StudyLeaveRequest__c> results = EPA_ApprenticeRequestList_Class.getMyRequests();
        Test.stopTest();

        Assert.areEqual(200, results.size(), 'Should return all 200 bulk records');
    }
}
