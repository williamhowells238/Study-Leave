/**
 * @description: Validates study leave request submissions against date notice rules
 *               and annual quota limits, then creates the request record on success.
 * @author: Developer Agent
 * @date: 2026-05-08
 */
public with sharing class EPA_SubmissionValidation_Class {

    /**
     * @description: Inner class to wrap the validation/submission result.
     */
    public class SubmissionResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Id recordId;
        @AuraEnabled public String leaveType;
        @AuraEnabled public Date startDate;
        @AuraEnabled public Date endDate;

        /**
         * @description: Constructs a success result with the new record Id and confirmation details.
         * @param recId The Id of the newly created study leave request record.
         * @param leaveType The type of leave requested.
         * @param startDate The start date of the leave request.
         * @param endDate The end date of the leave request.
         * @return SubmissionResult instance indicating success.
         */
        public SubmissionResult(Id recId, String leaveType, Date startDate, Date endDate) {
            this.success = true;
            this.errorMessage = null;
            this.recordId = recId;
            this.leaveType = leaveType;
            this.startDate = startDate;
            this.endDate = endDate;
        }

        /**
         * @description: Constructs an error result with a user-friendly message.
         * @param message The validation error message to display to the user.
         * @return SubmissionResult instance indicating failure.
         */
        public SubmissionResult(String message) {
            this.success = false;
            this.errorMessage = message;
            this.recordId = null;
            this.leaveType = null;
            this.startDate = null;
            this.endDate = null;
        }
    }

    /**
     * @description: Validates the submission against date notice and quota rules,
     *               then creates an EPA_StudyLeaveRequest__c record if all validations pass.
     * @param startDate The requested start date for study leave.
     * @param endDate The requested end date for study leave.
     * @param numberOfDays The calculated number of leave days requested.
     * @param leaveType The type of study leave (College, Exam, Revision, Resit).
     * @param reason Optional reason text for the request.
     * @return SubmissionResult indicating success (with record Id) or failure (with error message).
     */
    @AuraEnabled
    public static SubmissionResult validateAndSubmit(Date startDate, Date endDate, Integer numberOfDays, String leaveType, String reason) {
        // Date validation: must provide at least one full calendar month notice
        Date earliestPermittedDate = Date.today().addMonths(1);
        if (startDate < earliestPermittedDate) {
            String formattedDate = DateTime.newInstance(earliestPermittedDate, Time.newInstance(0, 0, 0, 0)).format('dd MMMM yyyy');
            return new SubmissionResult(
                'Start date must be on or after ' + formattedDate + '. You must provide at least one full calendar month\'s notice.'
            );
        }

        // Quota validation: query current year quota for running user
        Id currentUserId = UserInfo.getUserId();
        String currentYear = String.valueOf(Date.today().year());

        List<EPA_LeaveQuota__c> quotas = [
            SELECT Id, EPA_DaysRemaining__c
            FROM EPA_LeaveQuota__c
            WHERE EPA_Apprentice__c = :currentUserId
            AND EPA_QuotaYear__c = :currentYear
            WITH USER_MODE
            LIMIT 1
        ];

        if (quotas.isEmpty()) {
            return new SubmissionResult(
                'No leave quota record found for the current year. Please contact your administrator.'
            );
        }

        Decimal daysRemaining = quotas[0].EPA_DaysRemaining__c;

        if (daysRemaining == 0) {
            return new SubmissionResult(
                'Your annual study leave quota has been exhausted.'
            );
        }

        if (daysRemaining < numberOfDays) {
            return new SubmissionResult(
                'Insufficient leave balance. You have ' + daysRemaining.intValue() + ' day(s) remaining but requested ' + numberOfDays + ' day(s).'
            );
        }

        // All validations passed — populate Manager from hierarchy
        User currentUser = [
            SELECT ManagerId
            FROM User
            WHERE Id = :currentUserId
            WITH USER_MODE
            LIMIT 1
        ];

        // Create the request record
        EPA_StudyLeaveRequest__c request = new EPA_StudyLeaveRequest__c(
            EPA_Apprentice__c = currentUserId,
            EPA_Manager__c = currentUser.ManagerId,
            EPA_StartDate__c = startDate,
            EPA_EndDate__c = endDate,
            EPA_NumberOfDays__c = numberOfDays,
            EPA_LeaveType__c = leaveType,
            EPA_Reason__c = reason,
            EPA_Status__c = 'Pending',
            EPA_SubmissionTimestamp__c = Datetime.now()
        );

        try {
            insert request;
        } catch (DmlException e) {
            return new SubmissionResult(
                'An unexpected error occurred while saving your request. Please try again or contact your administrator.'
            );
        }

        return new SubmissionResult(request.Id, leaveType, startDate, endDate);
    }
}