// Deactivate advance notice validation temporarily to create past-dated test record
HttpRequest req = new HttpRequest();
req.setEndpoint(URL.getOrgDomainURL().toExternalForm() + '/services/data/v66.0/tooling/sobjects/ValidationRule/03d9I000000CVb7QAG');
req.setMethod('PATCH');
req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
req.setHeader('Content-Type', 'application/json');
req.setBody('{"Metadata": {"active": false, "errorConditionFormula": "EPA_StartDate__c < ADDMONTHS(TODAY(), 1) && NOT(ISPICKVAL(EPA_Status__c, \\"Cancelled\\"))", "errorMessage": "Study leave requests must be submitted at least one month before the start date.", "errorDisplayField": "EPA_StartDate__c"}}');
Http http = new Http();
HttpResponse res = http.send(req);
System.debug('Deactivation response: ' + res.getStatusCode() + ' - ' + res.getBody());
