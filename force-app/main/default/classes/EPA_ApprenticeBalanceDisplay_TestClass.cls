/**
 * @description: Test class for EPA_ApprenticeBalanceDisplay_Class covering positive
 *               and negative scenarios (PNB pattern — bulk not applicable for single-user query).
 * @author: Developer Agent
 * @date: 2026-05-08
 */
@isTest(SeeAllData=false)
private class EPA_ApprenticeBalanceDisplay_TestClass {

    @TestSetup
    static void makeData() {
        // Create a leave quota record for the running user
        EPA_LeaveQuota__c quota = new EPA_LeaveQuota__c(
            EPA_Apprentice__c = UserInfo.getUserId(),
            EPA_QuotaYear__c = String.valueOf(Date.today().year()),
            EPA_AnnualEntitlement__c = 24,
            EPA_DaysUsed__c = 5
        );
        insert quota;
    }

    /**
     * @description: Positive test — when a quota record exists for the current year,
     *               getMyBalance returns the record with correct field values.
     */
    @isTest
    static void givenQuotaExists_whenGetMyBalance_thenRecordReturned() {
        Test.startTest();
        EPA_LeaveQuota__c result = EPA_ApprenticeBalanceDisplay_Class.getMyBalance();
        Test.stopTest();

        Assert.isNotNull(result, 'Should return a quota record');
        Assert.areEqual(24, result.EPA_AnnualEntitlement__c, 'Annual entitlement should be 24');
        Assert.areEqual(5, result.EPA_DaysUsed__c, 'Days used should be 5');
        Assert.areEqual(19, result.EPA_DaysRemaining__c, 'Days remaining should be 19');
        Assert.areEqual(String.valueOf(Date.today().year()), result.EPA_QuotaYear__c,
            'Quota year should match the current year');
    }

    /**
     * @description: Negative test — when no quota record exists for the current year,
     *               getMyBalance returns null.
     */
    @isTest
    static void givenNoQuota_whenGetMyBalance_thenNullReturned() {
        // Delete the quota record created in TestSetup
        delete [SELECT Id FROM EPA_LeaveQuota__c WHERE EPA_Apprentice__c = :UserInfo.getUserId()];

        Test.startTest();
        EPA_LeaveQuota__c result = EPA_ApprenticeBalanceDisplay_Class.getMyBalance();
        Test.stopTest();

        Assert.isNull(result, 'Should return null when no quota record exists');
    }
}
