/**
 * @description: Bulk-safe Bell notification service for EPA_StudyLeaveRequest__c status change events.
 *               Builds and sends custom notifications (Bell) for four scenarios: new submission
 *               (Pending → manager), approval (→ apprentice), rejection with optional reason
 *               (→ apprentice), and cancellation (→ manager).
 * @author: Developer Agent
 * @date: 2026-05-09
 */
public with sharing class EPA_BellNotificationService_Class {

    @TestVisible
    private static List<Messaging.CustomNotification> lastSentNotifications = new List<Messaging.CustomNotification>();

    @TestVisible
    private static List<Set<String>> lastRecipientSets = new List<Set<String>>();

    @TestVisible
    private static List<String> lastNotificationBodies = new List<String>();

    /**
     * @description: Handles after-insert events. Sends submission Bell notifications to managers
     *               for all new records in Pending status with a manager assigned.
     * @param newRecords List of newly inserted EPA_StudyLeaveRequest__c records
     * @return void
     */
    public static void handleAfterInsert(List<EPA_StudyLeaveRequest__c> newRecords) {
        lastSentNotifications = new List<Messaging.CustomNotification>();
        lastRecipientSets = new List<Set<String>>();
        lastNotificationBodies = new List<String>();

        List<EPA_StudyLeaveRequest__c> pendingRecords = new List<EPA_StudyLeaveRequest__c>();
        Set<Id> userIds = new Set<Id>();

        for (EPA_StudyLeaveRequest__c req : newRecords) {
            if (req.EPA_Status__c == 'Pending' && req.EPA_Manager__c != null) {
                pendingRecords.add(req);
                userIds.add(req.EPA_Apprentice__c);
            }
        }

        if (pendingRecords.isEmpty()) {
            return;
        }

        Map<Id, User> userMap = new Map<Id, User>(
            [SELECT Id, Name FROM User WHERE Id IN :userIds]
        );

        CustomNotificationType notifType = getNotificationType();
        if (notifType == null) {
            return;
        }

        List<Messaging.CustomNotification> notifications = new List<Messaging.CustomNotification>();
        List<Set<String>> recipientSets = new List<Set<String>>();
        List<String> bodies = new List<String>();

        for (EPA_StudyLeaveRequest__c req : pendingRecords) {
            User apprentice = userMap.get(req.EPA_Apprentice__c);
            String apprenticeName = apprentice?.Name ?? 'Unknown';

            String body = 'A new study leave request has been submitted by ' + apprenticeName + '.\n'
                + 'Leave Type: ' + req.EPA_LeaveType__c + '\n'
                + 'Start Date: ' + formatDate(req.EPA_StartDate__c) + '\n'
                + 'End Date: ' + formatDate(req.EPA_EndDate__c);

            Messaging.CustomNotification notif = new Messaging.CustomNotification();
            notif.setNotificationTypeId(notifType.Id);
            notif.setTitle('Study Leave Request — New Submission');
            notif.setBody(body);
            notif.setTargetId(req.Id);

            notifications.add(notif);
            recipientSets.add(new Set<String>{ (String) req.EPA_Manager__c });
            bodies.add(body);
        }

        dispatchNotifications(notifications, recipientSets, bodies);
    }

    /**
     * @description: Handles after-update events. Detects status transitions and sends
     *               appropriate Bell notifications for Approved, Rejected, and Cancelled statuses.
     * @param newRecords List of updated EPA_StudyLeaveRequest__c records (new values)
     * @param oldMap Map of old record values keyed by Id
     * @return void
     */
    public static void handleAfterUpdate(List<EPA_StudyLeaveRequest__c> newRecords, Map<Id, EPA_StudyLeaveRequest__c> oldMap) {
        lastSentNotifications = new List<Messaging.CustomNotification>();
        lastRecipientSets = new List<Set<String>>();
        lastNotificationBodies = new List<String>();

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
            } else if (newStatus == 'Rejected') {
                rejectedRecords.add(req);
            } else if (newStatus == 'Cancelled') {
                cancelledRecords.add(req);
                userIds.add(req.EPA_Apprentice__c);
            }
        }

        if (approvedRecords.isEmpty() && rejectedRecords.isEmpty() && cancelledRecords.isEmpty()) {
            return;
        }

        Map<Id, User> userMap = new Map<Id, User>();
        if (!userIds.isEmpty()) {
            userMap = new Map<Id, User>(
                [SELECT Id, Name FROM User WHERE Id IN :userIds]
            );
        }

        CustomNotificationType notifType = getNotificationType();
        if (notifType == null) {
            return;
        }

        List<Messaging.CustomNotification> notifications = new List<Messaging.CustomNotification>();
        List<Set<String>> recipientSets = new List<Set<String>>();
        List<String> bodies = new List<String>();

        for (EPA_StudyLeaveRequest__c req : approvedRecords) {
            String body = 'Your study leave request has been approved.\n'
                + 'Leave Type: ' + req.EPA_LeaveType__c + '\n'
                + 'Start Date: ' + formatDate(req.EPA_StartDate__c) + '\n'
                + 'End Date: ' + formatDate(req.EPA_EndDate__c);

            Messaging.CustomNotification notif = new Messaging.CustomNotification();
            notif.setNotificationTypeId(notifType.Id);
            notif.setTitle('Study Leave Request — Approved');
            notif.setBody(body);
            notif.setTargetId(req.Id);

            notifications.add(notif);
            recipientSets.add(new Set<String>{ (String) req.EPA_Apprentice__c });
            bodies.add(body);
        }

        for (EPA_StudyLeaveRequest__c req : rejectedRecords) {
            String body = 'Your study leave request has been rejected.\n'
                + 'Leave Type: ' + req.EPA_LeaveType__c + '\n'
                + 'Start Date: ' + formatDate(req.EPA_StartDate__c) + '\n'
                + 'End Date: ' + formatDate(req.EPA_EndDate__c);

            if (String.isNotBlank(req.EPA_RejectionReason__c)) {
                body += '\nReason: ' + req.EPA_RejectionReason__c;
            }

            Messaging.CustomNotification notif = new Messaging.CustomNotification();
            notif.setNotificationTypeId(notifType.Id);
            notif.setTitle('Study Leave Request — Rejected');
            notif.setBody(body);
            notif.setTargetId(req.Id);

            notifications.add(notif);
            recipientSets.add(new Set<String>{ (String) req.EPA_Apprentice__c });
            bodies.add(body);
        }

        for (EPA_StudyLeaveRequest__c req : cancelledRecords) {
            User apprentice = userMap.get(req.EPA_Apprentice__c);
            String apprenticeName = apprentice?.Name ?? 'Unknown';

            String body = 'A study leave request has been cancelled by ' + apprenticeName + '.\n'
                + 'Leave Type: ' + req.EPA_LeaveType__c + '\n'
                + 'Start Date: ' + formatDate(req.EPA_StartDate__c) + '\n'
                + 'End Date: ' + formatDate(req.EPA_EndDate__c);

            Messaging.CustomNotification notif = new Messaging.CustomNotification();
            notif.setNotificationTypeId(notifType.Id);
            notif.setTitle('Study Leave Request — Cancelled');
            notif.setBody(body);
            notif.setTargetId(req.Id);

            notifications.add(notif);
            if (req.EPA_Manager__c != null) {
                recipientSets.add(new Set<String>{ (String) req.EPA_Manager__c });
            } else {
                recipientSets.add(new Set<String>());
            }
            bodies.add(body);
        }

        if (!notifications.isEmpty()) {
            dispatchNotifications(notifications, recipientSets, bodies);
        }
    }

    /**
     * @description: Dispatches Bell notifications. In test context, stores them for assertion.
     *               In production context, sends via notification.send() with error handling.
     * @param notifications List of CustomNotification instances to dispatch
     * @param recipientMap Map of record Id to set of recipient User Ids
     * @return void
     */
    private static void dispatchNotifications(List<Messaging.CustomNotification> notifications, List<Set<String>> recipientSets, List<String> bodies) {
        lastSentNotifications = notifications;
        lastRecipientSets = recipientSets;
        lastNotificationBodies = bodies;

        if (!Test.isRunningTest()) {
            for (Integer i = 0; i < notifications.size(); i++) {
                Set<String> recipients = recipientSets[i];
                if (!recipients.isEmpty()) {
                    try {
                        notifications[i].send(recipients);
                    } catch (Exception e) {
                        System.debug(LoggingLevel.WARN, 'Bell notification send failed: ' + e.getMessage());
                    }
                }
            }
        }
    }

    /**
     * @description: Queries the CustomNotificationType record for study leave status changes.
     * @return CustomNotificationType record, or null if not found
     */
    private static CustomNotificationType getNotificationType() {
        List<CustomNotificationType> types = [
            SELECT Id FROM CustomNotificationType
            WHERE DeveloperName = 'EPA_StudyLeaveStatusChange' LIMIT 1
        ];
        return types.isEmpty() ? null : types[0];
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
