HttpRequest req = new HttpRequest();
req.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v66.0/analytics/reports');
req.setMethod('POST');
req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
req.setHeader('Content-Type', 'application/json');
String body = '{' +
    '"reportMetadata": {' +
        '"name": "EPA Test Deploy Report",' +
        '"reportType": {"type": "EPA_StudyLeaveWithApprentice__c"},' +
        '"reportFormat": "TABULAR",' +
        '"detailColumns": ["CUST_NAME"],' +
        '"reportBooleanFilter": null,' +
        '"reportFilters": [],' +
        '"standardDateFilter": {"durationValue": "CUSTOM", "column": "CUST_CREATED_DATE"}' +
    '},' +
    '"reportExtendedMetadata": null,' +
    '"folderId": null' +
'}';
req.setBody(body);
HttpResponse res = new Http().send(req);
System.debug('STATUS: ' + res.getStatusCode());
System.debug('BODY: ' + res.getBody().substring(0, Math.min(2000, res.getBody().length())));