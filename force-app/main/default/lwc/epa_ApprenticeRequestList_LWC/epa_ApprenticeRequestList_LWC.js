import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMyRequests from '@salesforce/apex/EPA_ApprenticeRequestList_Class.getMyRequests';

const COLUMNS = [
    { label: 'Leave Type', fieldName: 'EPA_LeaveType__c', type: 'text' },
    { label: 'Start Date', fieldName: 'EPA_StartDate__c', type: 'date' },
    { label: 'End Date', fieldName: 'EPA_EndDate__c', type: 'date' },
    { label: 'Days', fieldName: 'EPA_NumberOfDays__c', type: 'number' },
    { label: 'Status', fieldName: 'EPA_Status__c', type: 'text' },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [{ label: 'View Details', name: 'view' }]
        }
    }
];

export default class Epa_ApprenticeRequestList_LWC extends NavigationMixin(LightningElement) {
    requests;
    error;
    columns = COLUMNS;

    @wire(getMyRequests)
    wiredRequests({ data, error }) {
        if (data) {
            this.requests = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.requests = undefined;
        }
    }

    get hasRequests() {
        return this.requests && this.requests.length > 0;
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        if (actionName === 'view') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: row.Id,
                    objectApiName: 'EPA_StudyLeaveRequest__c',
                    actionName: 'view'
                }
            });
        }
    }
}
