/**
 * @description: Controller class for the Manager Team Balance View LWC.
 *               Returns leave quota records for the current manager's direct reports.
 * @author: Developer Agent
 * @date: 2026-05-08
 */
public with sharing class EPA_ManagerTeamBalanceView_Class {

    /**
     * @description: Retrieves leave quota records for the current manager's direct reports
     *               for the current quota year. Uses the two-step pattern: query direct-report
     *               User IDs, then query their quota records.
     * @return List of EPA_LeaveQuota__c records for the manager's direct reports.
     */
    @AuraEnabled(cacheable=true)
    public static List<EPA_LeaveQuota__c> getTeamBalances() {
        List<Id> directReportIds = new List<Id>();
        for (User u : [SELECT Id FROM User WHERE ManagerId = :UserInfo.getUserId() WITH USER_MODE]) {
            directReportIds.add(u.Id);
        }

        if (directReportIds.isEmpty()) {
            return new List<EPA_LeaveQuota__c>();
        }

        String currentYear = String.valueOf(Date.today().year());

        return [
            SELECT Id,
                   EPA_Apprentice__r.Name,
                   EPA_AnnualEntitlement__c,
                   EPA_DaysUsed__c,
                   EPA_DaysRemaining__c,
                   EPA_QuotaYear__c
            FROM EPA_LeaveQuota__c
            WHERE EPA_Apprentice__c IN :directReportIds
              AND EPA_QuotaYear__c = :currentYear
            WITH USER_MODE
            ORDER BY EPA_Apprentice__r.Name ASC
        ];
    }
}
