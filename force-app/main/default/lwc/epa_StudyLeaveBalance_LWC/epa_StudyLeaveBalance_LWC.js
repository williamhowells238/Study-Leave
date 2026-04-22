import { LightningElement, wire } from 'lwc';
import getBalanceSummary from '@salesforce/apex/EPA_StudyLeaveBalance_Class.getBalanceSummary';
import getRequestHistory from '@salesforce/apex/EPA_StudyLeaveBalance_Class.getRequestHistory';

const COLUMNS = [
    { label: 'Start Date', fieldName: 'EPA_StartDate__c', type: 'date-local' },
    { label: 'End Date', fieldName: 'EPA_EndDate__c', type: 'date-local' },
    { label: 'Leave Category', fieldName: 'categoryName', type: 'text' },
    { label: 'Business Days', fieldName: 'EPA_CalculatedBusinessDays__c', type: 'number' },
    { label: 'Status', fieldName: 'EPA_Status__c', type: 'text' }
];

export default class Epa_StudyLeaveBalance_LWC extends LightningElement {
    balanceSummary;
    balanceError;
    requestHistory;
    historyError;
    columns = COLUMNS;

    @wire(getBalanceSummary)
    wiredBalance({ data, error }) {
        if (data) {
            this.balanceSummary = data;
            this.balanceError = undefined;
        } else if (error) {
            this.balanceError = this.reduceErrors(error);
            this.balanceSummary = undefined;
        }
    }

    @wire(getRequestHistory)
    wiredHistory({ data, error }) {
        if (data) {
            this.requestHistory = data.map(record => ({
                ...record,
                categoryName: record.EPA_Category__r?.Name
            }));
            this.historyError = undefined;
        } else if (error) {
            this.historyError = this.reduceErrors(error);
            this.requestHistory = undefined;
        }
    }

    get hasHistory() {
        return this.requestHistory && this.requestHistory.length > 0;
    }

    reduceErrors(error) {
        if (typeof error === 'string') {
            return error;
        }
        if (error?.body?.message) {
            return error.body.message;
        }
        if (error?.message) {
            return error.message;
        }
        return 'An unknown error occurred.';
    }
}
