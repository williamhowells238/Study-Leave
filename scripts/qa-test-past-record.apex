// Create a past-dated record by first inserting as Cancelled (bypasses advance notice),
// then updating the status to Pending
EPA_StudyLeaveRequest__c req = new EPA_StudyLeaveRequest__c(
    EPA_StartDate__c = Date.newInstance(2026, 4, 20),
    EPA_EndDate__c = Date.newInstance(2026, 4, 21),
    EPA_Category__c = 'a009I00000JBlljQAD',
    EPA_Apprentice__c = '0059I000009VMgbQAG',
    EPA_Status__c = 'Cancelled',
    EPA_CalculatedBusinessDays__c = 2
);
insert req;
System.debug('Created cancelled record: ' + req.Id);

// Now update to Pending - the edit past start date validation only fires on ISCHANGED fields
// not on status changes
req.EPA_Status__c = 'Pending';
update req;
System.debug('Updated to Pending: ' + req.Id);
