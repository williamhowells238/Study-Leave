/**
 * @description: Provisions initial EPA_LeaveQuota__c records for active apprentice users.
 *               Queries PermissionSetAssignment to identify apprentices, checks for existing
 *               quota records for the current year, and creates missing records. Designed to
 *               be re-runnable (idempotent) without creating duplicates.
 * @author: Developer Agent
 * @date: 2026-05-08
 */
public with sharing class EPA_ProvisionLeaveQuota_Class {

    /**
     * @description: Invocable method that provisions leave quota records for all active
     *               apprentice users who do not yet have a record for the current year.
     * @param requests List of empty request objects (required for InvocableMethod signature)
     * @return List<Integer> containing the count of records created
     */
    @InvocableMethod(label='Provision Leave Quotas' description='Creates leave quota records for active apprentices missing a current-year quota.')
    public static List<Integer> provisionQuotas(List<ProvisionRequest> requests) {
        String currentYear = String.valueOf(Date.today().year());

        // Query active apprentice User IDs via permission set assignment
        List<PermissionSetAssignment> assignments = [
            SELECT AssigneeId
            FROM PermissionSetAssignment
            WHERE PermissionSet.Name = 'EPA_ApprenticeUser_PermissionSet'
            AND Assignee.IsActive = true
        ];

        Set<Id> apprenticeUserIds = new Set<Id>();
        for (PermissionSetAssignment psa : assignments) {
            apprenticeUserIds.add(psa.AssigneeId);
        }

        if (apprenticeUserIds.isEmpty()) {
            return new List<Integer>{ 0 };
        }

        // Query existing quota records for the current year
        List<EPA_LeaveQuota__c> existingQuotas = [
            SELECT EPA_Apprentice__c
            FROM EPA_LeaveQuota__c
            WHERE EPA_QuotaYear__c = :currentYear
            AND EPA_Apprentice__c IN :apprenticeUserIds
        ];

        Set<Id> usersWithExistingQuota = new Set<Id>();
        for (EPA_LeaveQuota__c quota : existingQuotas) {
            usersWithExistingQuota.add(quota.EPA_Apprentice__c);
        }

        // Create quota records for apprentices who do not have one
        List<EPA_LeaveQuota__c> newQuotas = new List<EPA_LeaveQuota__c>();
        for (Id userId : apprenticeUserIds) {
            if (!usersWithExistingQuota.contains(userId)) {
                newQuotas.add(new EPA_LeaveQuota__c(
                    EPA_Apprentice__c = userId,
                    EPA_AnnualEntitlement__c = 24,
                    EPA_DaysUsed__c = 0,
                    EPA_QuotaYear__c = currentYear
                ));
            }
        }

        if (!newQuotas.isEmpty()) {
            insert newQuotas;
        }

        return new List<Integer>{ newQuotas.size() };
    }

    /**
     * @description: Wrapper class for InvocableMethod input. Currently empty as no input
     *               parameters are required for provisioning.
     */
    public class ProvisionRequest {
        @InvocableVariable(label='Placeholder' description='No input required' required=false)
        public String placeholder;
    }
}
