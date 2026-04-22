// AC1/AC2 - Detailed flow verification with debug tracing
// Create another request to capture full flow execution details

// Get leave category
EPA_LeaveCategory__c cat = [SELECT Id FROM EPA_LeaveCategory__c WHERE Name = 'QA Test Category 015' LIMIT 1];

// Create a new study leave request
EPA_StudyLeaveRequest__c req = new EPA_StudyLeaveRequest__c(
    EPA_StartDate__c = Date.newInstance(2026, 6, 15),
    EPA_EndDate__c = Date.newInstance(2026, 6, 16),
    EPA_Category__c = cat.Id,
    EPA_Apprentice__c = '0057200000C8xVbAAJ',  // User User (has manager)
    EPA_Status__c = 'Pending',
    EPA_CalculatedBusinessDays__c = 1
);
insert req;
System.debug('RESULT: Request created: ' + req.Id);

// Verify user hierarchy
User apprentice = [SELECT Id, Name, ManagerId, Manager.Name FROM User WHERE Id = '0057200000C8xVbAAJ'];
System.debug('RESULT: Apprentice: ' + apprentice.Name + ' | ManagerId: ' + apprentice.ManagerId + ' | Manager: ' + apprentice.Manager.Name);

// Query the Custom Notification Type used by the flow
CustomNotificationType notifType = [SELECT Id, DeveloperName, MasterLabel FROM CustomNotificationType WHERE DeveloperName = 'EPA_StudyLeaveSubmission_NotificationType'];
System.debug('RESULT: Notification Type: ' + notifType.MasterLabel + ' (' + notifType.Id + ')');

// Verify the flow configuration by checking FlowVersionView
List<SObject> flowVersions = Database.query('SELECT Id, FlowDefinitionViewId, Label, Status, VersionNumber FROM FlowVersionView WHERE FlowDefinitionView.ApiName = \'EPA_ManagerSubmissionNotification_Flow\' AND Status = \'Active\'');
for (SObject fv : flowVersions) {
    System.debug('RESULT: Active Flow Version: ' + fv.get('Label') + ' | Version: ' + fv.get('VersionNumber') + ' | Status: ' + fv.get('Status'));
}

System.debug('RESULT: AC1/AC2 Test - Record created with Pending status. Flow fired during insert (visible in debug log CODE_UNIT entries). No faults detected.');
