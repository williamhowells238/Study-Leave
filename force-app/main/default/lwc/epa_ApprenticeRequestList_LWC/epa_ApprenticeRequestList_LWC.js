import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import LightningConfirm from 'lightning/confirm';
import getMyRequests from '@salesforce/apex/EPA_ApprenticeRequestList_Class.getMyRequests';
import cancelRequest from '@salesforce/apex/EPA_CancelRequest_Class.cancelRequest';

const COLUMNS = [
    { label: 'Leave Type', fieldName: 'EPA_LeaveType__c', type: 'text' },
    { label: 'Start Date', fieldName: 'EPA_StartDate__c', type: 'date' },
    { label: 'End Date', fieldName: 'EPA_EndDate__c', type: 'date' },
    { label: 'Days', fieldName: 'EPA_NumberOfDays__c', type: 'number' },
    { label: 'Status', fieldName: 'EPA_Status__c', type: 'text' },
    {
        type: 'action',
        typeAttributes: {
            rowActions: function (row, doneCallback) {
                const actions = [{ label: 'View Details', name: 'view' }];
                if (row.EPA_Status__c === 'Approved') {
                    actions.push({ label: 'Cancel', name: 'cancel' });
                }
                doneCallback(actions);
            }
        }
    }
];

export default class Epa_ApprenticeRequestList_LWC extends NavigationMixin(LightningElement) {
    requests;
    error;
    columns = COLUMNS;
    wiredRequestsResult;

    @wire(getMyRequests)
    wiredRequests(result) {
        this.wiredRequestsResult = result;
        const { data, error } = result;
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
        } else if (actionName === 'cancel') {
            this.handleCancelAction(row);
        }
    }

    async handleCancelAction(row) {
        const confirmed = await LightningConfirm.open({
            message: 'Are you sure you want to cancel this approved study leave request? The days will be returned to your balance.',
            variant: 'default',
            label: 'Confirm Cancellation'
        });
        if (!confirmed) {
            return;
        }
        try {
            await cancelRequest({ requestId: row.Id });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Study leave request has been cancelled.',
                    variant: 'success'
                })
            );
            await refreshApex(this.wiredRequestsResult);
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body?.message ?? 'An error occurred while cancelling the request.',
                    variant: 'error'
                })
            );
        }
    }
}
