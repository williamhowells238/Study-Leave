/**
 * @description: Test class for EPA_ManagerTeamRequestList_Class covering positive,
 *               negative, and bulk scenarios (PNB pattern).
 * @author: Developer Agent
 * @date: 2026-05-08
 */
@isTest(SeeAllData=false)
private class EPA_ManagerTeamRequestList_TestClass {

    /**
     * @description: Creates test data including a manager user, two direct report
     *               apprentices, a non-direct-report user, and study leave requests.
     */
    @TestSetup
    static void makeData() {
        // Use the running user as the manager
        Id managerId = UserInfo.getUserId();

        // Create Profile reference for test users
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        // Create two direct-report apprentice users
        List<User> directReports = new List<User>();
        for (Integer i = 1; i <= 2; i++) {
            directReports.add(new User(
                FirstName = 'Apprentice',
                LastName = 'DirectReport' + i,
                Email = 'apprentice.dr' + i + '@epa.test.invalid',
                Username = 'apprentice.dr' + i + '.' + DateTime.now().getTime() + '@epa.test.invalid',
                Alias = 'aprdr' + i,
                TimeZoneSidKey = 'Europe/London',
                LocaleSidKey = 'en_GB',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = standardProfile.Id,
                ManagerId = managerId
            ));
        }
        insert directReports;

        // Create a non-direct-report user (no ManagerId link to running user)
        User nonReport = new User(
            FirstName = 'Other',
            LastName = 'Employee',
            Email = 'other.employee@epa.test.invalid',
            Username = 'other.employee.' + DateTime.now().getTime() + '@epa.test.invalid',
            Alias = 'othremp',
            TimeZoneSidKey = 'Europe/London',
            LocaleSidKey = 'en_GB',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        insert nonReport;

        // Create leave quotas for all test users
        List<EPA_LeaveQuota__c> quotas = new List<EPA_LeaveQuota__c>();
        for (User dr : directReports) {
            quotas.add(new EPA_LeaveQuota__c(
                EPA_Apprentice__c = dr.Id,
                EPA_QuotaYear__c = String.valueOf(Date.today().year()),
                EPA_AnnualEntitlement__c = 24,
                EPA_DaysUsed__c = 0
            ));
        }
        quotas.add(new EPA_LeaveQuota__c(
            EPA_Apprentice__c = nonReport.Id,
            EPA_QuotaYear__c = String.valueOf(Date.today().year()),
            EPA_AnnualEntitlement__c = 24,
            EPA_DaysUsed__c = 0
        ));
        insert quotas;

        // Create requests for direct reports across all statuses
        Datetime now = Datetime.now();
        List<EPA_StudyLeaveRequest__c> requests = new List<EPA_StudyLeaveRequest__c>();

        // Direct Report 1 requests
        requests.add(new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = directReports[0].Id,
            EPA_LeaveType__c = 'College',
            EPA_StartDate__c = Date.today().addDays(10),
            EPA_EndDate__c = Date.today().addDays(12),
            EPA_NumberOfDays__c = 3,
            EPA_Status__c = 'Pending',
            EPA_SubmissionTimestamp__c = now
        ));
        requests.add(new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = directReports[0].Id,
            EPA_LeaveType__c = 'Exam',
            EPA_StartDate__c = Date.today().addDays(30),
            EPA_EndDate__c = Date.today().addDays(30),
            EPA_NumberOfDays__c = 1,
            EPA_Status__c = 'Approved',
            EPA_SubmissionTimestamp__c = now
        ));

        // Direct Report 2 requests
        requests.add(new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = directReports[1].Id,
            EPA_LeaveType__c = 'College',
            EPA_StartDate__c = Date.today().addDays(20),
            EPA_EndDate__c = Date.today().addDays(21),
            EPA_NumberOfDays__c = 2,
            EPA_Status__c = 'Rejected',
            EPA_SubmissionTimestamp__c = now
        ));
        requests.add(new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = directReports[1].Id,
            EPA_LeaveType__c = 'Revision',
            EPA_StartDate__c = Date.today().addDays(40),
            EPA_EndDate__c = Date.today().addDays(42),
            EPA_NumberOfDays__c = 3,
            EPA_Status__c = 'Cancelled',
            EPA_SubmissionTimestamp__c = now
        ));

        // Non-direct-report request (should NOT appear in results)
        requests.add(new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = nonReport.Id,
            EPA_LeaveType__c = 'College',
            EPA_StartDate__c = Date.today().addDays(15),
            EPA_EndDate__c = Date.today().addDays(16),
            EPA_NumberOfDays__c = 2,
            EPA_Status__c = 'Pending',
            EPA_SubmissionTimestamp__c = now
        ));
        insert requests;
    }

    /**
     * @description: Positive test - manager sees all direct-report requests with
     *               correct fields when no status filter is applied.
     */
    @isTest
    static void givenDirectReports_whenGetTeamRequestsNoFilter_thenAllReturned() {
        Test.startTest();
        List<EPA_StudyLeaveRequest__c> results = EPA_ManagerTeamRequestList_Class.getTeamRequests(null);
        Test.stopTest();

        Assert.areEqual(4, results.size(), 'Manager should see all 4 direct-report requests');

        // Verify ordering by start date descending
        Date previousDate = null;
        for (EPA_StudyLeaveRequest__c req : results) {
            if (previousDate != null) {
                Assert.isTrue(req.EPA_StartDate__c <= previousDate,
                    'Results should be ordered by start date descending');
            }
            previousDate = req.EPA_StartDate__c;
        }

        // Verify fields are populated
        for (EPA_StudyLeaveRequest__c req : results) {
            Assert.isNotNull(req.EPA_Apprentice__r?.Name, 'Apprentice name should be populated');
            Assert.isNotNull(req.EPA_LeaveType__c, 'Leave type should be populated');
            Assert.isNotNull(req.EPA_StartDate__c, 'Start date should be populated');
            Assert.isNotNull(req.EPA_EndDate__c, 'End date should be populated');
            Assert.isNotNull(req.EPA_NumberOfDays__c, 'Number of days should be populated');
            Assert.isNotNull(req.EPA_Status__c, 'Status should be populated');
        }
    }

    /**
     * @description: Positive test - manager sees only filtered requests when
     *               a status filter is applied.
     */
    @isTest
    static void givenDirectReports_whenGetTeamRequestsWithFilter_thenFilteredReturned() {
        Test.startTest();
        List<EPA_StudyLeaveRequest__c> results = EPA_ManagerTeamRequestList_Class.getTeamRequests('Pending');
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'Should return only 1 Pending request from direct reports');
        Assert.areEqual('Pending', results[0].EPA_Status__c, 'Status should be Pending');
    }

    /**
     * @description: Negative test - requests from non-direct-reports are never returned.
     */
    @isTest
    static void givenNonDirectReportRequests_whenGetTeamRequests_thenNotReturned() {
        Test.startTest();
        List<EPA_StudyLeaveRequest__c> results = EPA_ManagerTeamRequestList_Class.getTeamRequests(null);
        Test.stopTest();

        // Get the non-direct-report user
        User nonReport = [SELECT Id FROM User WHERE LastName = 'Employee' AND FirstName = 'Other' LIMIT 1];

        for (EPA_StudyLeaveRequest__c req : results) {
            Assert.areNotEqual(nonReport.Id, req.EPA_Apprentice__c,
                'Non-direct-report requests should not appear in results');
        }
    }

    /**
     * @description: Negative test - a user with no direct reports gets an empty list.
     */
    @isTest
    static void givenNoDirectReports_whenGetTeamRequests_thenEmptyListReturned() {
        // Run as a user who has no direct reports
        User nonReport = [SELECT Id FROM User WHERE LastName = 'Employee' AND FirstName = 'Other' LIMIT 1];

        List<EPA_StudyLeaveRequest__c> results;
        System.runAs(nonReport) {
            Test.startTest();
            results = EPA_ManagerTeamRequestList_Class.getTeamRequests(null);
            Test.stopTest();
        }

        Assert.areEqual(0, results.size(), 'User with no direct reports should get empty list');
    }

    /**
     * @description: Bulk test - 200 requests for direct reports are returned
     *               without governor limit issues.
     */
    @isTest
    static void givenBulkRequests_whenGetTeamRequests_thenAllReturned() {
        // Get a direct report user
        User directReport = [SELECT Id FROM User WHERE LastName = 'DirectReport1' LIMIT 1];

        // Delete existing test requests
        delete [SELECT Id FROM EPA_StudyLeaveRequest__c WHERE EPA_Apprentice__c = :directReport.Id];

        Datetime now = Datetime.now();
        List<EPA_StudyLeaveRequest__c> bulkRequests = new List<EPA_StudyLeaveRequest__c>();
        for (Integer i = 0; i < 200; i++) {
            bulkRequests.add(new EPA_StudyLeaveRequest__c(
                EPA_Apprentice__c = directReport.Id,
                EPA_LeaveType__c = 'College',
                EPA_StartDate__c = Date.today().addDays(i + 1),
                EPA_EndDate__c = Date.today().addDays(i + 2),
                EPA_NumberOfDays__c = 1,
                EPA_Status__c = 'Pending',
                EPA_SubmissionTimestamp__c = now
            ));
        }
        insert bulkRequests;

        Test.startTest();
        List<EPA_StudyLeaveRequest__c> results = EPA_ManagerTeamRequestList_Class.getTeamRequests('Pending');
        Test.stopTest();

        Assert.areEqual(200, results.size(), 'Should return all 200 bulk records');
    }
}
