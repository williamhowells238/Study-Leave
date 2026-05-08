/**
 * @description: Trigger handler that detects status transitions on EPA_StudyLeaveRequest__c
 *               records and adjusts EPA_DaysUsed__c on the corresponding EPA_LeaveQuota__c
 *               record. Increments on approval, decrements on cancellation from approved.
 *               Uses 'without sharing' because EPA_LeaveQuota__c OWD is Private and the
 *               trigger fires in the context of the user performing the status change, who
 *               may not have edit access to the quota record.
 * @author: Developer Agent
 * @date: 2026-05-08
 */
public without sharing class EPA_LeaveBalanceCalculation_Class {

    /**
     * @description: Handles after-update events on EPA_StudyLeaveRequest__c. Identifies
     *               status transitions to Approved (increment) or from Approved to Cancelled
     *               (decrement), then applies net balance changes to quota records in bulk.
     * @param newRecords List of updated EPA_StudyLeaveRequest__c records (new values)
     * @param oldMap Map of old record values keyed by Id
     * @return void
     */
    public static void handleAfterUpdate(List<EPA_StudyLeaveRequest__c> newRecords, Map<Id, EPA_StudyLeaveRequest__c> oldMap) {
        // Map of apprentice User Id to net day change (positive = increment, negative = decrement)
        Map<Id, Decimal> apprenticeNetChange = new Map<Id, Decimal>();

        for (EPA_StudyLeaveRequest__c req : newRecords) {
            EPA_StudyLeaveRequest__c oldReq = oldMap.get(req.Id);
            String oldStatus = oldReq.EPA_Status__c;
            String newStatus = req.EPA_Status__c;

            if (oldStatus == newStatus) {
                continue;
            }

            Decimal days = req.EPA_NumberOfDays__c ?? 0;

            if (oldStatus != 'Approved' && newStatus == 'Approved') {
                // Transition to Approved — increment Days Used
                Decimal current = apprenticeNetChange.get(req.EPA_Apprentice__c) ?? 0;
                apprenticeNetChange.put(req.EPA_Apprentice__c, current + days);
            } else if (oldStatus == 'Approved' && newStatus == 'Cancelled') {
                // Transition from Approved to Cancelled — decrement Days Used
                Decimal current = apprenticeNetChange.get(req.EPA_Apprentice__c) ?? 0;
                apprenticeNetChange.put(req.EPA_Apprentice__c, current - days);
            }
        }

        if (apprenticeNetChange.isEmpty()) {
            return;
        }

        String currentYear = String.valueOf(Date.today().year());
        Set<Id> apprenticeIds = apprenticeNetChange.keySet();

        // Single SOQL query for all affected quota records
        List<EPA_LeaveQuota__c> quotas = [
            SELECT Id, EPA_Apprentice__c, EPA_DaysUsed__c, EPA_AnnualEntitlement__c
            FROM EPA_LeaveQuota__c
            WHERE EPA_Apprentice__c IN :apprenticeIds
            AND EPA_QuotaYear__c = :currentYear
        ];

        Map<Id, EPA_LeaveQuota__c> quotaByApprentice = new Map<Id, EPA_LeaveQuota__c>();
        for (EPA_LeaveQuota__c quota : quotas) {
            quotaByApprentice.put(quota.EPA_Apprentice__c, quota);
        }

        List<EPA_LeaveQuota__c> quotasToUpdate = new List<EPA_LeaveQuota__c>();

        for (Id apprenticeId : apprenticeNetChange.keySet()) {
            EPA_LeaveQuota__c quota = quotaByApprentice.get(apprenticeId);

            if (quota == null) {
                System.debug(LoggingLevel.WARN, 'EPA_LeaveBalanceCalculation_Class: No quota record found for apprentice '
                    + apprenticeId + ' in year ' + currentYear + '. Skipping balance update.');
                continue;
            }

            Decimal netChange = apprenticeNetChange.get(apprenticeId);
            Decimal currentDaysUsed = quota.EPA_DaysUsed__c ?? 0;
            Decimal newDaysUsed = currentDaysUsed + netChange;

            // Floor at zero — Days Used must never go negative
            newDaysUsed = Math.max(0, newDaysUsed);
            // Cap at Annual Entitlement — Days Remaining must never go negative
            newDaysUsed = Math.min(quota.EPA_AnnualEntitlement__c, newDaysUsed);

            quota.EPA_DaysUsed__c = newDaysUsed;
            quotasToUpdate.add(quota);
        }

        // Single DML statement outside all loops
        if (!quotasToUpdate.isEmpty()) {
            update quotasToUpdate;
        }
    }
}
