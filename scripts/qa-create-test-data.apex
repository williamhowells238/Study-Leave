// Create past-dated record (advance notice deactivated)
EPA_StudyLeaveRequest__c pastReq = new EPA_StudyLeaveRequest__c(
    EPA_StartDate__c = Date.newInstance(2026, 4, 20),
    EPA_EndDate__c = Date.newInstance(2026, 4, 21),
    EPA_Category__c = 'a009I00000JBlljQAD',
    EPA_Apprentice__c = '0059I000009VMgbQAG',
    EPA_Status__c = 'Pending'
);
insert pastReq;
System.debug('Past-dated record created: ' + pastReq.Id);

// Set the approved record (a029I000009ABv6QAG) to Approved status
EPA_StudyLeaveRequest__c approvedReq = new EPA_StudyLeaveRequest__c(
    Id = 'a029I000009ABv6QAG',
    EPA_Status__c = 'Approved'
);
update approvedReq;
System.debug('Record set to Approved: ' + approvedReq.Id);
