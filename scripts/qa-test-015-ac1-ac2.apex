// AC1 & AC2 Test: Create a study leave request as apprentice with a manager
// Expect: Flow triggers, sends notification to manager (Integration User)
// Apprentice: User User (0057200000C8xVbAAJ) - Manager: Integration User (0057200000C8wo6AAB)

// Get leave category
EPA_LeaveCategory__c cat = [SELECT Id FROM EPA_LeaveCategory__c WHERE Name = 'QA Test Category 015' LIMIT 1];

// Create study leave request with future dates (>1 month to pass advance notice VR)
EPA_StudyLeaveRequest__c req = new EPA_StudyLeaveRequest__c(
    EPA_StartDate__c = Date.newInstance(2026, 6, 1),
    EPA_EndDate__c = Date.newInstance(2026, 6, 2),
    EPA_Category__c = cat.Id,
    EPA_Apprentice__c = '0057200000C8xVbAAJ',  // User User
    EPA_Status__c = 'Pending',
    EPA_CalculatedBusinessDays__c = 1
);
insert req;
System.debug('RESULT: Study Leave Request created: ' + req.Id);

// Query flow interviews to verify the flow ran
List<FlowInterview> interviews = [
    SELECT Id, InterviewLabel, CurrentElement, InterviewStatus, CreatedDate
    FROM FlowInterview
    WHERE InterviewLabel LIKE '%Manager Submission Notification%'
    ORDER BY CreatedDate DESC
    LIMIT 5
];
System.debug('RESULT: Flow interviews found: ' + interviews.size());
for (FlowInterview fi : interviews) {
    System.debug('RESULT: Interview: ' + fi.Id + ' | Status: ' + fi.InterviewStatus + ' | Element: ' + fi.CurrentElement + ' | Label: ' + fi.InterviewLabel);
}

// Verify the request was created with correct data
EPA_StudyLeaveRequest__c verifyReq = [
    SELECT Id, EPA_Apprentice__c, EPA_Apprentice__r.Name, EPA_Apprentice__r.ManagerId, EPA_Apprentice__r.Manager.Name, EPA_Status__c
    FROM EPA_StudyLeaveRequest__c
    WHERE Id = :req.Id
];
System.debug('RESULT: Request verified - Apprentice: ' + verifyReq.EPA_Apprentice__r.Name + 
    ' | Manager: ' + verifyReq.EPA_Apprentice__r.Manager.Name + 
    ' | ManagerId: ' + verifyReq.EPA_Apprentice__r.ManagerId +
    ' | Status: ' + verifyReq.EPA_Status__c);

// Check custom notifications sent (query CustomNotification - this may not be queryable)
// Instead, verify flow debug log entries
System.debug('RESULT: AC1 test complete - flow should have fired for record ' + req.Id);
