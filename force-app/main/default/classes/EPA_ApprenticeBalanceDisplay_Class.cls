/**
 * @description: Controller class for the Apprentice Balance Display LWC.
 *               Returns the current user's leave quota record for the current year.
 * @author: Developer Agent
 * @date: 2026-05-08
 */
public with sharing class EPA_ApprenticeBalanceDisplay_Class {

    /**
     * @description: Retrieves the current user's EPA_LeaveQuota__c record for the
     *               current quota year. Returns null if no record exists.
     * @return EPA_LeaveQuota__c record or null
     */
    @AuraEnabled(cacheable=true)
    public static EPA_LeaveQuota__c getMyBalance() {
        String currentYear = String.valueOf(Date.today().year());

        List<EPA_LeaveQuota__c> quotas = [
            SELECT Id,
                   EPA_AnnualEntitlement__c,
                   EPA_DaysUsed__c,
                   EPA_DaysRemaining__c,
                   EPA_QuotaYear__c
            FROM EPA_LeaveQuota__c
            WHERE EPA_Apprentice__c = :UserInfo.getUserId()
            AND EPA_QuotaYear__c = :currentYear
            WITH USER_MODE
            LIMIT 1
        ];

        return quotas.isEmpty() ? null : quotas[0];
    }
}
