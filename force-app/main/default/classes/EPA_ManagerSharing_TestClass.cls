/**
 * @description: PNB test class for EPA_StudyLeaveRequestSharing_Class and EPA_LeaveQuotaSharing_Class.
 *               Covers Positive, Negative, and Bulk scenarios for Apex Managed Sharing.
 * @author: Developer Agent
 * @date: 2026-05-08
 */
@isTest(SeeAllData=false)
private class EPA_ManagerSharing_TestClass {

    private static final String PROFILE_NAME = 'Standard User';

    @TestSetup
    static void makeData() {
        Profile stdProfile = [SELECT Id FROM Profile WHERE Name = :PROFILE_NAME LIMIT 1];

        // Create Manager 1
        User manager1 = createUser('mgr1', 'Manager', 'One', stdProfile.Id, null);
        // Create Manager 2
        User manager2 = createUser('mgr2', 'Manager', 'Two', stdProfile.Id, null);

        insert new List<User>{ manager1, manager2 };

        // Create Apprentices with ManagerId set
        User apprentice1 = createUser('app1', 'Apprentice', 'One', stdProfile.Id, manager1.Id);
        User apprentice2 = createUser('app2', 'Apprentice', 'Two', stdProfile.Id, manager2.Id);

        insert new List<User>{ apprentice1, apprentice2 };

        // Assign permission sets
        PermissionSet mgrPS = [SELECT Id FROM PermissionSet WHERE Name = 'EPA_ManagerUser_PermissionSet' LIMIT 1];
        PermissionSet appPS = [SELECT Id FROM PermissionSet WHERE Name = 'EPA_ApprenticeUser_PermissionSet' LIMIT 1];

        insert new List<PermissionSetAssignment>{
            new PermissionSetAssignment(AssigneeId = manager1.Id, PermissionSetId = mgrPS.Id),
            new PermissionSetAssignment(AssigneeId = manager2.Id, PermissionSetId = mgrPS.Id),
            new PermissionSetAssignment(AssigneeId = apprentice1.Id, PermissionSetId = appPS.Id),
            new PermissionSetAssignment(AssigneeId = apprentice2.Id, PermissionSetId = appPS.Id)
        };
    }

    /**
     * @description: Positive test - Manager can access their direct report's leave request
     *               after it is created with the manager assigned.
     */
    @isTest
    static void givenManagerAssigned_whenLeaveRequestCreated_thenManagerHasEditAccess() {
        User manager1 = getUser('mgr1');
        User apprentice1 = getUser('app1');

        EPA_StudyLeaveRequest__c request;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            request = new EPA_StudyLeaveRequest__c(
                EPA_Apprentice__c = apprentice1.Id,
                EPA_Manager__c = manager1.Id,
                EPA_StartDate__c = Date.today().addDays(7),
                EPA_EndDate__c = Date.today().addDays(8),
                EPA_NumberOfDays__c = 1,
                EPA_LeaveType__c = 'College',
                EPA_SubmissionTimestamp__c = DateTime.now(),
                EPA_Status__c = 'Pending'
            );
            insert request;
        }

        Test.startTest();
        System.runAs(manager1) {
            List<EPA_StudyLeaveRequest__c> results = [
                SELECT Id, EPA_Status__c
                FROM EPA_StudyLeaveRequest__c
                WHERE Id = :request.Id
            ];
            Assert.areEqual(1, results.size(), 'Manager should have read access to direct report leave request');
        }
        Test.stopTest();
    }

    /**
     * @description: Positive test - Manager can access their direct report's leave quota
     *               after it is created.
     */
    @isTest
    static void givenApprenticeWithManager_whenQuotaCreated_thenManagerHasReadAccess() {
        User manager1 = getUser('mgr1');
        User apprentice1 = getUser('app1');

        EPA_LeaveQuota__c quota;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            quota = new EPA_LeaveQuota__c(
                EPA_Apprentice__c = apprentice1.Id,
                EPA_AnnualEntitlement__c = 20,
                EPA_QuotaYear__c = '2026'
            );
            insert quota;
        }

        Test.startTest();
        System.runAs(manager1) {
            List<EPA_LeaveQuota__c> results = [
                SELECT Id, EPA_AnnualEntitlement__c
                FROM EPA_LeaveQuota__c
                WHERE Id = :quota.Id
            ];
            Assert.areEqual(1, results.size(), 'Manager should have read access to direct report quota');
        }
        Test.stopTest();
    }

    /**
     * @description: Negative test - Manager cannot access leave requests for apprentices
     *               who are not their direct reports (cross-team isolation).
     */
    @isTest
    static void givenDifferentManager_whenAccessingOtherTeamRequest_thenAccessDenied() {
        User manager2 = getUser('mgr2');
        User apprentice1 = getUser('app1');
        User manager1 = getUser('mgr1');

        EPA_StudyLeaveRequest__c request;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            request = new EPA_StudyLeaveRequest__c(
                EPA_Apprentice__c = apprentice1.Id,
                EPA_Manager__c = manager1.Id,
                EPA_StartDate__c = Date.today().addDays(7),
                EPA_EndDate__c = Date.today().addDays(8),
                EPA_NumberOfDays__c = 1,
                EPA_LeaveType__c = 'College',
                EPA_SubmissionTimestamp__c = DateTime.now(),
                EPA_Status__c = 'Pending'
            );
            insert request;
        }

        Test.startTest();
        System.runAs(manager2) {
            List<EPA_StudyLeaveRequest__c> results = [
                SELECT Id
                FROM EPA_StudyLeaveRequest__c
                WHERE Id = :request.Id
            ];
            Assert.areEqual(0, results.size(), 'Manager should NOT have access to other team leave request');
        }
        Test.stopTest();
    }

    /**
     * @description: Negative test - Manager cannot access quota records for apprentices
     *               who are not their direct reports.
     */
    @isTest
    static void givenDifferentManager_whenAccessingOtherTeamQuota_thenAccessDenied() {
        User manager2 = getUser('mgr2');
        User apprentice1 = getUser('app1');

        EPA_LeaveQuota__c quota;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            quota = new EPA_LeaveQuota__c(
                EPA_Apprentice__c = apprentice1.Id,
                EPA_AnnualEntitlement__c = 20,
                EPA_QuotaYear__c = '2026'
            );
            insert quota;
        }

        Test.startTest();
        System.runAs(manager2) {
            List<EPA_LeaveQuota__c> results = [
                SELECT Id
                FROM EPA_LeaveQuota__c
                WHERE Id = :quota.Id
            ];
            Assert.areEqual(0, results.size(), 'Manager should NOT have access to other team quota');
        }
        Test.stopTest();
    }

    /**
     * @description: Negative test - Apprentice cannot access another apprentice's records.
     */
    @isTest
    static void givenApprentice_whenAccessingOtherApprenticeRequest_thenAccessDenied() {
        User apprentice1 = getUser('app1');
        User apprentice2 = getUser('app2');
        User manager2 = getUser('mgr2');

        EPA_StudyLeaveRequest__c request;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            request = new EPA_StudyLeaveRequest__c(
                EPA_Apprentice__c = apprentice2.Id,
                EPA_Manager__c = manager2.Id,
                EPA_StartDate__c = Date.today().addDays(7),
                EPA_EndDate__c = Date.today().addDays(8),
                EPA_NumberOfDays__c = 1,
                EPA_LeaveType__c = 'College',
                EPA_SubmissionTimestamp__c = DateTime.now(),
                EPA_Status__c = 'Pending'
            );
            insert request;
        }

        Test.startTest();
        System.runAs(apprentice1) {
            List<EPA_StudyLeaveRequest__c> results = [
                SELECT Id
                FROM EPA_StudyLeaveRequest__c
                WHERE Id = :request.Id
            ];
            Assert.areEqual(0, results.size(), 'Apprentice should NOT have access to other apprentice records');
        }
        Test.stopTest();
    }

    /**
     * @description: Positive test - When manager is changed on a request, the new manager
     *               gets access and the old manager loses access.
     */
    @isTest
    static void givenManagerChanged_whenRequestUpdated_thenNewManagerHasAccess() {
        User manager1 = getUser('mgr1');
        User manager2 = getUser('mgr2');
        User apprentice1 = getUser('app1');

        EPA_StudyLeaveRequest__c request;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            request = new EPA_StudyLeaveRequest__c(
                EPA_Apprentice__c = apprentice1.Id,
                EPA_Manager__c = manager1.Id,
                EPA_StartDate__c = Date.today().addDays(7),
                EPA_EndDate__c = Date.today().addDays(8),
                EPA_NumberOfDays__c = 1,
                EPA_LeaveType__c = 'College',
                EPA_SubmissionTimestamp__c = DateTime.now(),
                EPA_Status__c = 'Pending'
            );
            insert request;
        }

        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            request.EPA_Manager__c = manager2.Id;
            update request;
        }
        Test.stopTest();

        System.runAs(manager2) {
            List<EPA_StudyLeaveRequest__c> results = [
                SELECT Id
                FROM EPA_StudyLeaveRequest__c
                WHERE Id = :request.Id
            ];
            Assert.areEqual(1, results.size(), 'New manager should have access after reassignment');
        }

        System.runAs(manager1) {
            List<EPA_StudyLeaveRequest__c> results = [
                SELECT Id
                FROM EPA_StudyLeaveRequest__c
                WHERE Id = :request.Id
            ];
            Assert.areEqual(0, results.size(), 'Old manager should lose access after reassignment');
        }
    }

    /**
     * @description: Bulk test - Insert 200 leave requests and verify share records are
     *               created without governor limit failures.
     */
    @isTest
    static void givenBulkInsert_whenRequestsCreated_thenAllSharesCreatedSuccessfully() {
        User manager1 = getUser('mgr1');
        User apprentice1 = getUser('app1');

        List<EPA_StudyLeaveRequest__c> requests = new List<EPA_StudyLeaveRequest__c>();
        for (Integer i = 0; i < 200; i++) {
            requests.add(new EPA_StudyLeaveRequest__c(
                EPA_Apprentice__c = apprentice1.Id,
                EPA_Manager__c = manager1.Id,
                EPA_StartDate__c = Date.today().addDays(7 + i),
                EPA_EndDate__c = Date.today().addDays(8 + i),
                EPA_NumberOfDays__c = 1,
                EPA_LeaveType__c = 'College',
                EPA_SubmissionTimestamp__c = DateTime.now(),
                EPA_Status__c = 'Pending'
            ));
        }

        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert requests;
        }
        Test.stopTest();

        List<EPA_StudyLeaveRequest__Share> shares = [
            SELECT Id
            FROM EPA_StudyLeaveRequest__Share
            WHERE ParentId IN :requests
            AND RowCause = :Schema.EPA_StudyLeaveRequest__Share.RowCause.EPA_ManagerAccess__c
        ];
        Assert.areEqual(200, shares.size(), 'All 200 share records should be created');
    }

    /**
     * @description: Bulk test - Insert 200 leave quotas and verify share records are
     *               created without governor limit failures.
     */
    @isTest
    static void givenBulkInsert_whenQuotasCreated_thenAllSharesCreatedSuccessfully() {
        User apprentice1 = getUser('app1');

        List<EPA_LeaveQuota__c> quotas = new List<EPA_LeaveQuota__c>();
        for (Integer i = 0; i < 200; i++) {
            quotas.add(new EPA_LeaveQuota__c(
                EPA_Apprentice__c = apprentice1.Id,
                EPA_AnnualEntitlement__c = 20,
                EPA_QuotaYear__c = String.valueOf(2020 + Math.mod(i, 50))
            ));
        }

        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert quotas;
        }
        Test.stopTest();

        List<EPA_LeaveQuota__Share> shares = [
            SELECT Id
            FROM EPA_LeaveQuota__Share
            WHERE ParentId IN :quotas
            AND RowCause = :Schema.EPA_LeaveQuota__Share.RowCause.EPA_ManagerAccess__c
        ];
        Assert.areEqual(200, shares.size(), 'All 200 quota share records should be created');
    }

    /**
     * @description: Positive test - When apprentice is changed on a quota, the new
     *               apprentice's manager gets access and the old manager loses access.
     */
    @isTest
    static void givenApprenticeChanged_whenQuotaUpdated_thenNewManagerHasAccess() {
        User manager1 = getUser('mgr1');
        User manager2 = getUser('mgr2');
        User apprentice1 = getUser('app1');
        User apprentice2 = getUser('app2');

        EPA_LeaveQuota__c quota;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            quota = new EPA_LeaveQuota__c(
                EPA_Apprentice__c = apprentice1.Id,
                EPA_AnnualEntitlement__c = 20,
                EPA_QuotaYear__c = '2026'
            );
            insert quota;
        }

        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            quota.EPA_Apprentice__c = apprentice2.Id;
            update quota;
        }
        Test.stopTest();

        System.runAs(manager2) {
            List<EPA_LeaveQuota__c> results = [
                SELECT Id
                FROM EPA_LeaveQuota__c
                WHERE Id = :quota.Id
            ];
            Assert.areEqual(1, results.size(), 'New apprentice manager should have access after reassignment');
        }

        System.runAs(manager1) {
            List<EPA_LeaveQuota__c> results = [
                SELECT Id
                FROM EPA_LeaveQuota__c
                WHERE Id = :quota.Id
            ];
            Assert.areEqual(0, results.size(), 'Old apprentice manager should lose access after reassignment');
        }
    }

    // ========== Helper Methods ==========

    /**
     * @description: Creates a User record for test data.
     * @param alias The alias for the user
     * @param firstName First name
     * @param lastName Last name
     * @param profileId The profile ID to assign
     * @param managerId The manager user ID (nullable)
     * @return User The constructed (not inserted) user record
     */
    private static User createUser(String alias, String firstName, String lastName, Id profileId, Id managerId) {
        String uniqueKey = alias + DateTime.now().getTime();
        User u = new User(
            Alias = alias,
            Email = uniqueKey + '@epatest.com',
            EmailEncodingKey = 'UTF-8',
            FirstName = firstName,
            LastName = lastName,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_GB',
            ProfileId = profileId,
            TimeZoneSidKey = 'Europe/London',
            Username = uniqueKey + '@epatest.com.test'
        );
        if (managerId != null) {
            u.ManagerId = managerId;
        }
        return u;
    }

    /**
     * @description: Retrieves a user by alias from test setup data.
     * @param alias The alias of the user to find
     * @return User The matching user record
     */
    private static User getUser(String alias) {
        return [SELECT Id, ManagerId FROM User WHERE Alias = :alias LIMIT 1];
    }
}
