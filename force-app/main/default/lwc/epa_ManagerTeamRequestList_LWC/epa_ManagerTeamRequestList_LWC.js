import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getTeamRequests from '@salesforce/apex/EPA_ManagerTeamRequestList_Class.getTeamRequests';
import approveRequest from '@salesforce/apex/EPA_ApproveRejectRequest_Class.approveRequest';
import rejectRequest from '@salesforce/apex/EPA_ApproveRejectRequest_Class.rejectRequest';

function getRowActions(row, doneCallback) {
    const actions = [{ label: 'View Details', name: 'view' }];
    if (row.EPA_Status__c === 'Pending') {
        actions.push({ label: 'Approve', name: 'approve' });
        actions.push({ label: 'Reject', name: 'reject' });
    }
    doneCallback(actions);
}

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
            rowActions: getRowActions
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
    wiredResult;

    // Rejection modal state
    showRejectModal = false;
    rejectionReason = '';
    rejectingRequestId;

    @wire(getTeamRequests, { statusFilter: '$wireStatusFilter' })
    wiredRequests(result) {
        this.wiredResult = result;
        const { data, error } = result;
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
        } else if (actionName === 'approve') {
            this.handleApprove(row.Id);
        } else if (actionName === 'reject') {
            this.rejectingRequestId = row.Id;
            this.rejectionReason = '';
            this.showRejectModal = true;
        }
    }

    handleApprove(requestId) {
        approveRequest({ requestId })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Request has been approved.',
                        variant: 'success'
                    })
                );
                return refreshApex(this.wiredResult);
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body?.message ?? 'An error occurred while approving the request.',
                        variant: 'error'
                    })
                );
            });
    }

    handleRejectReasonChange(event) {
        this.rejectionReason = event.detail.value;
    }

    handleRejectConfirm() {
        const requestId = this.rejectingRequestId;
        const reason = this.rejectionReason || null;
        this.showRejectModal = false;

        rejectRequest({ requestId, rejectionReason: reason })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Request has been rejected.',
                        variant: 'success'
                    })
                );
                return refreshApex(this.wiredResult);
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body?.message ?? 'An error occurred while rejecting the request.',
                        variant: 'error'
                    })
                );
            });
    }

    handleRejectCancel() {
        this.showRejectModal = false;
        this.rejectionReason = '';
        this.rejectingRequestId = undefined;
    }
}
