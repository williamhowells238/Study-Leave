import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getTeamRequests from '@salesforce/apex/EPA_ManagerTeamRequestList_Class.getTeamRequests';

const COLUMNS = [
    { label: 'Apprentice Name', fieldName: 'apprenticeName', type: 'text' },
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

const STATUS_OPTIONS = [
    { label: 'All', value: '' },
    { label: 'Pending', value: 'Pending' },
    { label: 'Approved', value: 'Approved' },
    { label: 'Rejected', value: 'Rejected' },
    { label: 'Cancelled', value: 'Cancelled' }
];

export default class Epa_ManagerTeamRequestList_LWC extends NavigationMixin(LightningElement) {
    requests;
    error;
    columns = COLUMNS;
    statusOptions = STATUS_OPTIONS;
    selectedStatus = '';

    @wire(getTeamRequests, { statusFilter: '$wireStatusFilter' })
    wiredRequests({ data, error }) {
        if (data) {
            this.requests = data.map(record => ({
                ...record,
                apprenticeName: record.EPA_Apprentice__r?.Name ?? ''
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.requests = undefined;
        }
    }

    get wireStatusFilter() {
        return this.selectedStatus || null;
    }

    get hasRequests() {
        return this.requests && this.requests.length > 0;
    }

    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
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
