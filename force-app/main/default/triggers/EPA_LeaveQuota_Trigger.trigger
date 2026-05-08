/**
 * @description: Trigger on EPA_LeaveQuota__c that delegates after-insert and after-update
 *               events to the sharing handler class for Apex Managed Sharing.
 * @author: Developer Agent
 * @date: 2026-05-08
 */
trigger EPA_LeaveQuota_Trigger on EPA_LeaveQuota__c (after insert, after update) {

    if (Trigger.isAfter && Trigger.isInsert) {
        EPA_LeaveQuotaSharing_Class.handleAfterInsert(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        EPA_LeaveQuotaSharing_Class.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}
