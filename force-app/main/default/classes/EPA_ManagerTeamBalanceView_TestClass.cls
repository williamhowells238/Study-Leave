/**
 * @description: Test class for EPA_ManagerTeamBalanceView_Class covering positive,
 *               negative, and bulk scenarios (PNB pattern).
 * @author: Developer Agent
 * @date: 2026-05-08
 */
@isTest(SeeAllData=false)
private class EPA_ManagerTeamBalanceView_TestClass {

    /**
     * @description: Creates test data including a manager user, two direct report
     *               apprentices with quota records, and a non-direct-report user
     *               with a quota record.
     */
    @TestSetup
    static void makeData() {
        Id managerId = UserInfo.getUserId();

        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        List<User> directReports = new List<User>();
        for (Integer i = 1; i <= 2; i++) {
            directReports.add(new User(
                FirstName = 'Balance',
                LastName = 'DirectReport' + i,
                Email = 'balance.dr' + i + '@epa.test.invalid',
                Username = 'balance.dr' + i + '.' + DateTime.now().getTime() + '@epa.test.invalid',
                Alias = 'baldr' + i,
                TimeZoneSidKey = 'Europe/London',
                LocaleSidKey = 'en_GB',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = standardProfile.Id,
                ManagerId = managerId
            ));
        }
        insert directReports;

        User nonReport = new User(
            FirstName = 'Balance',
            LastName = 'NonReport',
            Email = 'balance.nonreport@epa.test.invalid',
            Username = 'balance.nonreport.' + DateTime.now().getTime() + '@epa.test.invalid',
            Alias = 'balnr',
            TimeZoneSidKey = 'Europe/London',
            LocaleSidKey = 'en_GB',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        insert nonReport;

        String currentYear = String.valueOf(Date.today().year());
        List<EPA_LeaveQuota__c> quotas = new List<EPA_LeaveQuota__c>();

        quotas.add(new EPA_LeaveQuota__c(
            EPA_Apprentice__c = directReports[0].Id,
            EPA_QuotaYear__c = currentYear,
            EPA_AnnualEntitlement__c = 24,
            EPA_DaysUsed__c = 5
        ));
        quotas.add(new EPA_LeaveQuota__c(
            EPA_Apprentice__c = directReports[1].Id,
            EPA_QuotaYear__c = currentYear,
            EPA_AnnualEntitlement__c = 24,
            EPA_DaysUsed__c = 10
        ));
        quotas.add(new EPA_LeaveQuota__c(
            EPA_Apprentice__c = nonReport.Id,
            EPA_QuotaYear__c = currentYear,
            EPA_AnnualEntitlement__c = 24,
            EPA_DaysUsed__c = 3
        ));

        insert quotas;
    }

    /**
     * @description: Positive test - manager sees direct-report balances with correct
     *               field values including Apprentice Name, Annual Entitlement,
     *               Days Used, and Days Remaining.
     */
    @isTest
    static void givenDirectReports_whenGetTeamBalances_thenBalancesReturned() {
        Test.startTest();
        List<EPA_LeaveQuota__c> results = EPA_ManagerTeamBalanceView_Class.getTeamBalances();
        Test.stopTest();

        Assert.areEqual(2, results.size(), 'Manager should see 2 direct-report quota records');

        for (EPA_LeaveQuota__c quota : results) {
            Assert.isNotNull(quota.EPA_Apprentice__r?.Name, 'Apprentice name should be populated');
            Assert.areEqual(24, quota.EPA_AnnualEntitlement__c, 'Annual entitlement should be 24');
            Assert.isNotNull(quota.EPA_DaysUsed__c, 'Days Used should be populated');
            Assert.isNotNull(quota.EPA_DaysRemaining__c, 'Days Remaining should be populated');
        }

        // Verify ordering by apprentice name ascending
        Assert.isTrue(
            results[0].EPA_Apprentice__r.Name <= results[1].EPA_Apprentice__r.Name,
            'Results should be ordered by apprentice name ascending'
        );
    }

    /**
     * @description: Negative test - quota records from non-direct-reports are not returned.
     */
    @isTest
    static void givenNonDirectReportQuota_whenGetTeamBalances_thenNotReturned() {
        Test.startTest();
        List<EPA_LeaveQuota__c> results = EPA_ManagerTeamBalanceView_Class.getTeamBalances();
        Test.stopTest();

        User nonReport = [SELECT Id FROM User WHERE LastName = 'NonReport' AND FirstName = 'Balance' LIMIT 1];

        for (EPA_LeaveQuota__c quota : results) {
            Assert.areNotEqual(nonReport.Id, quota.EPA_Apprentice__c,
                'Non-direct-report quota should not appear in results');
        }
    }

    /**
     * @description: Negative test - a user with no direct reports gets an empty list.
     */
    @isTest
    static void givenNoDirectReports_whenGetTeamBalances_thenEmptyListReturned() {
        User nonReport = [SELECT Id FROM User WHERE LastName = 'NonReport' AND FirstName = 'Balance' LIMIT 1];

        List<EPA_LeaveQuota__c> results;
        System.runAs(nonReport) {
            Test.startTest();
            results = EPA_ManagerTeamBalanceView_Class.getTeamBalances();
            Test.stopTest();
        }

        Assert.areEqual(0, results.size(), 'User with no direct reports should get empty list');
    }

    /**
     * @description: Bulk test - 200 direct-report users with quota records are returned
     *               without governor limit issues.
     */
    @isTest
    static void givenBulkDirectReports_whenGetTeamBalances_thenAllReturned() {
        Id managerId = UserInfo.getUserId();
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        String currentYear = String.valueOf(Date.today().year());

        List<User> bulkUsers = new List<User>();
        for (Integer i = 0; i < 200; i++) {
            bulkUsers.add(new User(
                FirstName = 'BulkBal',
                LastName = 'User' + String.valueOf(i).leftPad(3, '0'),
                Email = 'bulkbal' + i + '@epa.test.invalid',
                Username = 'bulkbal' + i + '.' + DateTime.now().getTime() + '@epa.test.invalid',
                Alias = 'bb' + String.valueOf(i).leftPad(3, '0'),
                TimeZoneSidKey = 'Europe/London',
                LocaleSidKey = 'en_GB',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = standardProfile.Id,
                ManagerId = managerId
            ));
        }
        insert bulkUsers;

        List<EPA_LeaveQuota__c> bulkQuotas = new List<EPA_LeaveQuota__c>();
        for (User u : bulkUsers) {
            bulkQuotas.add(new EPA_LeaveQuota__c(
                EPA_Apprentice__c = u.Id,
                EPA_QuotaYear__c = currentYear,
                EPA_AnnualEntitlement__c = 24,
                EPA_DaysUsed__c = 0
            ));
        }
        insert bulkQuotas;

        Test.startTest();
        List<EPA_LeaveQuota__c> results = EPA_ManagerTeamBalanceView_Class.getTeamBalances();
        Test.stopTest();

        // Should include the 200 bulk users plus the 2 from @TestSetup
        Assert.isTrue(results.size() >= 200, 'Should return at least 200 bulk records');
    }
}
