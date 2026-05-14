/**
 * @description: PNB test class for EPA_ProvisionLeaveQuota_Class. Covers positive path
 *               (records created with correct defaults), negative path (no duplicates on
 *               re-run, non-apprentice users excluded), and bulk path (200+ users).
 * @author: Developer Agent
 * @date: 2026-05-08
 */
@isTest(SeeAllData=false)
private class EPA_ProvisionLeaveQuota_TestClass {

    private static final String PERM_SET_NAME = 'EPA_ApprenticeUser_PermissionSet';

    /**
     * @description: Creates test users for use across all test methods.
     */
    @TestSetup
    static void makeData() {
        Profile stdProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        // Create 3 apprentice users
        List<User> apprenticeUsers = new List<User>();
        for (Integer i = 1; i <= 3; i++) {
            apprenticeUsers.add(new User(
                FirstName = 'Apprentice',
                LastName = 'User' + i,
                Email = 'apprentice.user' + i + '@epa.test.invalid',
                Username = 'apprentice.user' + i + '.' + System.currentTimeMillis() + '@epa.test.invalid',
                Alias = 'app' + i,
                TimeZoneSidKey = 'Europe/London',
                LocaleSidKey = 'en_GB',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = stdProfile.Id,
                IsActive = true
            ));
        }

        // Create 1 non-apprentice user
        apprenticeUsers.add(new User(
            FirstName = 'Manager',
            LastName = 'UserX',
            Email = 'manager.userx@epa.test.invalid',
            Username = 'manager.userx.' + System.currentTimeMillis() + '@epa.test.invalid',
            Alias = 'mgrx',
            TimeZoneSidKey = 'Europe/London',
            LocaleSidKey = 'en_GB',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = stdProfile.Id,
            IsActive = true
        ));

        insert apprenticeUsers;

        // Assign permission set to apprentice users only (first 3)
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = :PERM_SET_NAME LIMIT 1];
        List<PermissionSetAssignment> psAssignments = new List<PermissionSetAssignment>();
        for (Integer i = 0; i < 3; i++) {
            psAssignments.add(new PermissionSetAssignment(
                AssigneeId = apprenticeUsers[i].Id,
                PermissionSetId = ps.Id
            ));
        }
        insert psAssignments;
    }

    /**
     * @description: Positive path — verifies that provisioning creates one quota record per
     *               apprentice user with correct field values.
     */
    @isTest
    static void givenApprenticeUsers_whenProvisionQuotas_thenQuotaRecordsCreated() {
        List<EPA_ProvisionLeaveQuota_Class.ProvisionRequest> requests =
            new List<EPA_ProvisionLeaveQuota_Class.ProvisionRequest>();
        requests.add(new EPA_ProvisionLeaveQuota_Class.ProvisionRequest());

        // Collect test apprentice user IDs for isolated assertions
        Set<Id> testUserIds = new Set<Id>();
        for (User u : [SELECT Id FROM User WHERE FirstName = 'Apprentice' AND LastName LIKE 'User%' AND Email LIKE 'apprentice.user%@epa.test.invalid']) {
            testUserIds.add(u.Id);
        }

        Test.startTest();
        List<Integer> results = EPA_ProvisionLeaveQuota_Class.provisionQuotas(requests);
        Test.stopTest();

        Assert.isTrue(results[0] >= 3, 'Should create at least 3 quota records for test apprentice users');

        String currentYear = String.valueOf(Date.today().year());
        List<EPA_LeaveQuota__c> quotas = [
            SELECT EPA_Apprentice__c, EPA_AnnualEntitlement__c, EPA_DaysUsed__c, EPA_QuotaYear__c
            FROM EPA_LeaveQuota__c
            WHERE EPA_QuotaYear__c = :currentYear
            AND EPA_Apprentice__c IN :testUserIds
        ];

        Assert.areEqual(3, quotas.size(), 'Should have exactly 3 quota records for test apprentice users');
        for (EPA_LeaveQuota__c q : quotas) {
            Assert.areEqual(24, q.EPA_AnnualEntitlement__c, 'Annual Entitlement should be 24');
            Assert.areEqual(0, q.EPA_DaysUsed__c, 'Days Used should be 0');
            Assert.areEqual(currentYear, q.EPA_QuotaYear__c, 'Quota Year should be current year');
            Assert.isNotNull(q.EPA_Apprentice__c, 'Apprentice lookup should be populated');
        }
    }

    /**
     * @description: Negative path — verifies that running provisioning twice does not create
     *               duplicate records.
     */
    @isTest
    static void givenExistingQuotas_whenProvisionQuotasAgain_thenNoDuplicatesCreated() {
        List<EPA_ProvisionLeaveQuota_Class.ProvisionRequest> requests =
            new List<EPA_ProvisionLeaveQuota_Class.ProvisionRequest>();
        requests.add(new EPA_ProvisionLeaveQuota_Class.ProvisionRequest());

        // First run
        EPA_ProvisionLeaveQuota_Class.provisionQuotas(requests);

        Test.startTest();
        // Second run
        List<Integer> results = EPA_ProvisionLeaveQuota_Class.provisionQuotas(requests);
        Test.stopTest();

        Assert.areEqual(0, results[0], 'Second run should create 0 records');

        // Scope assertion to test-created user IDs only
        Set<Id> testUserIds = new Set<Id>();
        for (User u : [SELECT Id FROM User WHERE FirstName = 'Apprentice' AND LastName LIKE 'User%' AND Email LIKE 'apprentice.user%@epa.test.invalid']) {
            testUserIds.add(u.Id);
        }

        String currentYear = String.valueOf(Date.today().year());
        List<EPA_LeaveQuota__c> quotas = [
            SELECT Id FROM EPA_LeaveQuota__c
            WHERE EPA_QuotaYear__c = :currentYear
            AND EPA_Apprentice__c IN :testUserIds
        ];
        Assert.areEqual(3, quotas.size(), 'Should still have exactly 3 quota records for test apprentice users');
    }

    /**
     * @description: Negative path — verifies that non-apprentice users (without the
     *               permission set) do not receive quota records.
     */
    @isTest
    static void givenNonApprenticeUser_whenProvisionQuotas_thenNoQuotaCreated() {
        List<EPA_ProvisionLeaveQuota_Class.ProvisionRequest> requests =
            new List<EPA_ProvisionLeaveQuota_Class.ProvisionRequest>();
        requests.add(new EPA_ProvisionLeaveQuota_Class.ProvisionRequest());

        Test.startTest();
        EPA_ProvisionLeaveQuota_Class.provisionQuotas(requests);
        Test.stopTest();

        User managerUser = [SELECT Id FROM User WHERE LastName = 'UserX' AND Email = 'manager.userx@epa.test.invalid' LIMIT 1];
        String currentYear = String.valueOf(Date.today().year());
        List<EPA_LeaveQuota__c> managerQuotas = [
            SELECT Id FROM EPA_LeaveQuota__c
            WHERE EPA_Apprentice__c = :managerUser.Id
            AND EPA_QuotaYear__c = :currentYear
        ];
        Assert.areEqual(0, managerQuotas.size(), 'Non-apprentice user should not have a quota record');
    }

    /**
     * @description: Bulk path — verifies that provisioning handles 200+ users without
     *               governor limit failures. Uses System.runAs to isolate setup object
     *               DML (PermissionSetAssignment) from non-setup object DML.
     */
    @isTest
    static void givenBulkApprenticeUsers_whenProvisionQuotas_thenAllRecordsCreated() {
        Profile stdProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = :PERM_SET_NAME LIMIT 1];

        List<User> bulkUsers = new List<User>();
        for (Integer i = 1; i <= 200; i++) {
            bulkUsers.add(new User(
                FirstName = 'BulkApp',
                LastName = 'User' + i,
                Email = 'bulkapp.user' + i + '@epa.test.invalid',
                Username = 'bulkapp.user' + i + '.' + System.currentTimeMillis() + '@epa.test.invalid',
                Alias = 'ba' + String.valueOf(i).leftPad(3, '0'),
                TimeZoneSidKey = 'Europe/London',
                LocaleSidKey = 'en_GB',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = stdProfile.Id,
                IsActive = true
            ));
        }
        insert bulkUsers;

        // Use System.runAs to isolate setup object DML from non-setup DML
        User adminUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(adminUser) {
            List<PermissionSetAssignment> psAssignments = new List<PermissionSetAssignment>();
            for (User u : bulkUsers) {
                psAssignments.add(new PermissionSetAssignment(
                    AssigneeId = u.Id,
                    PermissionSetId = ps.Id
                ));
            }
            insert psAssignments;
        }

        List<EPA_ProvisionLeaveQuota_Class.ProvisionRequest> requests =
            new List<EPA_ProvisionLeaveQuota_Class.ProvisionRequest>();
        requests.add(new EPA_ProvisionLeaveQuota_Class.ProvisionRequest());

        Test.startTest();
        List<Integer> results = EPA_ProvisionLeaveQuota_Class.provisionQuotas(requests);
        Test.stopTest();

        // 200 bulk users + 3 from @TestSetup = 203 total provisioned
        Assert.isTrue(results[0] >= 200, 'Should create at least 200 quota records');

        String currentYear = String.valueOf(Date.today().year());
        List<EPA_LeaveQuota__c> quotas = [
            SELECT Id FROM EPA_LeaveQuota__c
            WHERE EPA_QuotaYear__c = :currentYear
            AND EPA_Apprentice__c IN :new Map<Id, User>(bulkUsers).keySet()
        ];
        Assert.areEqual(200, quotas.size(), 'All 200 bulk quota records should exist');
    }
}
