/**
 * @description: Bulk-safe email notification service for EPA_StudyLeaveRequest__c status change events.
 *               Builds and sends emails for four scenarios: new submission (Pending → manager),
 *               approval (→ apprentice), rejection with optional reason (→ apprentice),
 *               and cancellation (→ manager).
 * @author: Developer Agent
 * @date: 2026-05-09
 */
public with sharing class EPA_NotificationService_Class {

    @TestVisible
    private static List<Messaging.SingleEmailMessage> lastSentEmails = new List<Messaging.SingleEmailMessage>();

    /**
     * @description: Handles after-insert events. Sends submission notification emails to managers
     *               for all new records in Pending status with a manager assigned.
     * @param newRecords List of newly inserted EPA_StudyLeaveRequest__c records
     * @return void
     */
    public static void handleAfterInsert(List<EPA_StudyLeaveRequest__c> newRecords) {
        lastSentEmails = new List<Messaging.SingleEmailMessage>();
        List<EPA_StudyLeaveRequest__c> pendingRecords = new List<EPA_StudyLeaveRequest__c>();
        Set<Id> userIds = new Set<Id>();

        for (EPA_StudyLeaveRequest__c req : newRecords) {
            if (req.EPA_Status__c == 'Pending' && req.EPA_Manager__c != null) {
                pendingRecords.add(req);
                userIds.add(req.EPA_Apprentice__c);
                userIds.add(req.EPA_Manager__c);
            }
        }

        if (pendingRecords.isEmpty()) {
            return;
        }

        Map<Id, User> userMap = new Map<Id, User>(
            [SELECT Id, Name, Email FROM User WHERE Id IN :userIds]
        );

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (EPA_StudyLeaveRequest__c req : pendingRecords) {
            User apprentice = userMap.get(req.EPA_Apprentice__c);
            User manager = userMap.get(req.EPA_Manager__c);
            if (manager?.Email != null) {
                emails.add(buildSubmissionEmail(req, apprentice, manager));
            }
        }

        if (!emails.isEmpty()) {
            dispatchEmails(emails);
        }
    }

    /**
     * @description: Handles after-update events. Detects status transitions and sends
     *               appropriate notification emails for Approved, Rejected, and Cancelled statuses.
     * @param newRecords List of updated EPA_StudyLeaveRequest__c records (new values)
     * @param oldMap Map of old record values keyed by Id
     * @return void
     */
    public static void handleAfterUpdate(List<EPA_StudyLeaveRequest__c> newRecords, Map<Id, EPA_StudyLeaveRequest__c> oldMap) {
        lastSentEmails = new List<Messaging.SingleEmailMessage>();
        List<EPA_StudyLeaveRequest__c> approvedRecords = new List<EPA_StudyLeaveRequest__c>();
        List<EPA_StudyLeaveRequest__c> rejectedRecords = new List<EPA_StudyLeaveRequest__c>();
        List<EPA_StudyLeaveRequest__c> cancelledRecords = new List<EPA_StudyLeaveRequest__c>();
        Set<Id> userIds = new Set<Id>();

        for (EPA_StudyLeaveRequest__c req : newRecords) {
            String oldStatus = oldMap.get(req.Id).EPA_Status__c;
            String newStatus = req.EPA_Status__c;

            if (oldStatus == newStatus) {
                continue;
            }

            if (newStatus == 'Approved') {
                approvedRecords.add(req);
                userIds.add(req.EPA_Apprentice__c);
            } else if (newStatus == 'Rejected') {
                rejectedRecords.add(req);
                userIds.add(req.EPA_Apprentice__c);
            } else if (newStatus == 'Cancelled') {
                cancelledRecords.add(req);
                userIds.add(req.EPA_Apprentice__c);
                userIds.add(req.EPA_Manager__c);
            }
        }

        if (approvedRecords.isEmpty() && rejectedRecords.isEmpty() && cancelledRecords.isEmpty()) {
            return;
        }

        Map<Id, User> userMap = new Map<Id, User>(
            [SELECT Id, Name, Email FROM User WHERE Id IN :userIds]
        );

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (EPA_StudyLeaveRequest__c req : approvedRecords) {
            User apprentice = userMap.get(req.EPA_Apprentice__c);
            if (apprentice?.Email != null) {
                emails.add(buildApprovalEmail(req, apprentice));
            }
        }

        for (EPA_StudyLeaveRequest__c req : rejectedRecords) {
            User apprentice = userMap.get(req.EPA_Apprentice__c);
            if (apprentice?.Email != null) {
                emails.add(buildRejectionEmail(req, apprentice));
            }
        }

        for (EPA_StudyLeaveRequest__c req : cancelledRecords) {
            User apprentice = userMap.get(req.EPA_Apprentice__c);
            User manager = userMap.get(req.EPA_Manager__c);
            if (manager?.Email != null) {
                emails.add(buildCancellationEmail(req, apprentice, manager));
            }
        }

        if (!emails.isEmpty()) {
            dispatchEmails(emails);
        }
    }

    /**
     * @description: Sends or stores emails depending on execution context.
     *               In test context, emails are stored in lastSentEmails for assertion.
     *               In production context, emails are sent via Messaging.sendEmail.
     * @param emails List of SingleEmailMessage instances to dispatch
     * @return void
     */
    private static void dispatchEmails(List<Messaging.SingleEmailMessage> emails) {
        lastSentEmails = emails;
        if (!Test.isRunningTest()) {
            Messaging.sendEmail(emails);
        }
    }

    /**
     * @description: Builds a submission notification email to the manager.
     * @param req The study leave request record
     * @param apprentice The apprentice User record
     * @param manager The manager User record
     * @return Messaging.SingleEmailMessage configured for submission notification
     */
    private static Messaging.SingleEmailMessage buildSubmissionEmail(
        EPA_StudyLeaveRequest__c req, User apprentice, User manager
    ) {
        String subject = 'Study Leave Request \u2014 New Submission from ' + apprentice.Name;
        String body = 'A new study leave request has been submitted.\n\n'
            + 'Apprentice: ' + apprentice.Name + '\n'
            + 'Leave Type: ' + req.EPA_LeaveType__c + '\n'
            + 'Start Date: ' + formatDate(req.EPA_StartDate__c) + '\n'
            + 'End Date: ' + formatDate(req.EPA_EndDate__c) + '\n'
            + 'Number of Days: ' + req.EPA_NumberOfDays__c + '\n\n'
            + 'Please log in to Salesforce to review and action this request.';

        return buildEmail(new List<String>{ manager.Email }, subject, body);
    }

    /**
     * @description: Builds an approval notification email to the apprentice.
     * @param req The study leave request record
     * @param apprentice The apprentice User record
     * @return Messaging.SingleEmailMessage configured for approval notification
     */
    private static Messaging.SingleEmailMessage buildApprovalEmail(
        EPA_StudyLeaveRequest__c req, User apprentice
    ) {
        String subject = 'Study Leave Request \u2014 Approved';
        String body = 'Your study leave request has been approved.\n\n'
            + 'Leave Type: ' + req.EPA_LeaveType__c + '\n'
            + 'Start Date: ' + formatDate(req.EPA_StartDate__c) + '\n'
            + 'End Date: ' + formatDate(req.EPA_EndDate__c) + '\n'
            + 'Number of Days: ' + req.EPA_NumberOfDays__c;

        return buildEmail(new List<String>{ apprentice.Email }, subject, body);
    }

    /**
     * @description: Builds a rejection notification email to the apprentice.
     *               Includes rejection reason if one was provided.
     * @param req The study leave request record
     * @param apprentice The apprentice User record
     * @return Messaging.SingleEmailMessage configured for rejection notification
     */
    private static Messaging.SingleEmailMessage buildRejectionEmail(
        EPA_StudyLeaveRequest__c req, User apprentice
    ) {
        String subject = 'Study Leave Request \u2014 Rejected';
        String body = 'Your study leave request has been rejected.\n\n'
            + 'Leave Type: ' + req.EPA_LeaveType__c + '\n'
            + 'Start Date: ' + formatDate(req.EPA_StartDate__c) + '\n'
            + 'End Date: ' + formatDate(req.EPA_EndDate__c) + '\n'
            + 'Number of Days: ' + req.EPA_NumberOfDays__c;

        if (String.isNotBlank(req.EPA_RejectionReason__c)) {
            body += '\n\nReason: ' + req.EPA_RejectionReason__c;
        }

        return buildEmail(new List<String>{ apprentice.Email }, subject, body);
    }

    /**
     * @description: Builds a cancellation notification email to the manager.
     * @param req The study leave request record
     * @param apprentice The apprentice User record
     * @param manager The manager User record
     * @return Messaging.SingleEmailMessage configured for cancellation notification
     */
    private static Messaging.SingleEmailMessage buildCancellationEmail(
        EPA_StudyLeaveRequest__c req, User apprentice, User manager
    ) {
        String subject = 'Study Leave Request \u2014 Cancelled by ' + apprentice.Name;
        String body = 'A study leave request has been cancelled.\n\n'
            + 'Apprentice: ' + apprentice.Name + '\n'
            + 'Leave Type: ' + req.EPA_LeaveType__c + '\n'
            + 'Start Date: ' + formatDate(req.EPA_StartDate__c) + '\n'
            + 'End Date: ' + formatDate(req.EPA_EndDate__c) + '\n'
            + 'Number of Days: ' + req.EPA_NumberOfDays__c;

        return buildEmail(new List<String>{ manager.Email }, subject, body);
    }

    /**
     * @description: Builds a SingleEmailMessage with common settings.
     * @param toAddresses List of recipient email addresses
     * @param subject Email subject line
     * @param body Plain text email body
     * @return Messaging.SingleEmailMessage configured with common settings
     */
    private static Messaging.SingleEmailMessage buildEmail(List<String> toAddresses, String subject, String body) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(toAddresses);
        email.setSubject(subject);
        email.setPlainTextBody(body);
        email.setSaveAsActivity(false);
        return email;
    }

    /**
     * @description: Formats a Date value to a user-friendly string (dd/MM/yyyy).
     * @param d The Date to format
     * @return Formatted date string, or empty string if null
     */
    private static String formatDate(Date d) {
        if (d == null) {
            return '';
        }
        return String.valueOf(d.day()).leftPad(2, '0') + '/'
            + String.valueOf(d.month()).leftPad(2, '0') + '/'
            + d.year();
    }
}
