/**
 * @description: Controller class for the Study Leave Balance LWC component.
 *               Provides methods to retrieve the apprentice's annual balance summary
 *               and their complete request history for the current calendar year.
 * @author: Developer Agent
 * @date: 2026-04-22
 */
public with sharing class EPA_StudyLeaveBalance_Class {

    @TestVisible
    private static Decimal allowanceOverride = null;

    /**
     * @description: Wrapper class containing balance summary data.
     */
    public class BalanceSummary {
        @AuraEnabled public Decimal annualAllowance { get; set; }
        @AuraEnabled public Decimal consumedDays { get; set; }
        @AuraEnabled public Decimal remainingDays { get; set; }
    }

    /**
     * @description: Retrieves the balance summary for the current user for the current calendar year.
     *               Balance = Annual Allowance - (Approved + Pending business days).
     * @return BalanceSummary wrapper with allowance, consumed, and remaining values.
     */
    @AuraEnabled(cacheable=true)
    public static BalanceSummary getBalanceSummary() {
        Decimal annualAllowance = getAllowance();

        Id currentUserId = UserInfo.getUserId();
        Integer currentYear = Date.today().year();
        Date yearStart = Date.newInstance(currentYear, 1, 1);
        Date yearEnd = Date.newInstance(currentYear, 12, 31);

        List<AggregateResult> aggResults = [
            SELECT SUM(EPA_CalculatedBusinessDays__c) totalDays
            FROM EPA_StudyLeaveRequest__c
            WHERE EPA_Apprentice__c = :currentUserId
            AND EPA_Status__c IN ('Approved', 'Pending')
            AND EPA_StartDate__c >= :yearStart
            AND EPA_StartDate__c <= :yearEnd
            WITH USER_MODE
        ];

        Decimal consumed = 0;
        if (!aggResults.isEmpty() && aggResults[0].get('totalDays') != null) {
            consumed = (Decimal) aggResults[0].get('totalDays');
        }

        BalanceSummary summary = new BalanceSummary();
        summary.annualAllowance = annualAllowance ?? 0;
        summary.consumedDays = consumed;
        summary.remainingDays = (annualAllowance ?? 0) - consumed;
        return summary;
    }

    /**
     * @description: Retrieves all study leave requests for the current user for the current
     *               calendar year, regardless of status, ordered by start date descending.
     * @return List of EPA_StudyLeaveRequest__c records with key fields.
     */
    @AuraEnabled(cacheable=true)
    public static List<EPA_StudyLeaveRequest__c> getRequestHistory() {
        Id currentUserId = UserInfo.getUserId();
        Integer currentYear = Date.today().year();
        Date yearStart = Date.newInstance(currentYear, 1, 1);
        Date yearEnd = Date.newInstance(currentYear, 12, 31);

        return [
            SELECT EPA_StartDate__c, EPA_EndDate__c, EPA_Category__c,
                   EPA_CalculatedBusinessDays__c, EPA_Status__c
            FROM EPA_StudyLeaveRequest__c
            WHERE EPA_Apprentice__c = :currentUserId
            AND EPA_StartDate__c >= :yearStart
            AND EPA_StartDate__c <= :yearEnd
            WITH USER_MODE
            ORDER BY EPA_StartDate__c DESC
        ];
    }

    /**
     * @description: Retrieves the annual allowance value from Custom Metadata or test override.
     * @return The configured annual allowance days, or null if not configured.
     */
    private static Decimal getAllowance() {
        if (allowanceOverride != null) {
            return allowanceOverride;
        }
        List<EPA_StudyLeaveAllowance__mdt> settings = [
            SELECT EPA_AnnualAllowanceDays__c
            FROM EPA_StudyLeaveAllowance__mdt
            WHERE DeveloperName = 'EPA_Default'
            WITH USER_MODE
            LIMIT 1
        ];
        return settings.isEmpty() ? null : settings[0].EPA_AnnualAllowanceDays__c;
    }
}
