import { LightningElement, wire } from 'lwc';
import getMyBalance from '@salesforce/apex/EPA_ApprenticeBalanceDisplay_Class.getMyBalance';

export default class Epa_ApprenticeBalanceDisplay_LWC extends LightningElement {
    balance;
    error;

    @wire(getMyBalance)
    wiredBalance({ data, error }) {
        if (data) {
            this.balance = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.balance = undefined;
        }
    }

    get hasBalance() {
        return !!this.balance;
    }

    get hasError() {
        return !!this.error;
    }

    get hasNoRecord() {
        return !this.balance && !this.error;
    }

    get annualEntitlement() {
        return this.balance?.EPA_AnnualEntitlement__c ?? 0;
    }

    get daysUsed() {
        return this.balance?.EPA_DaysUsed__c ?? 0;
    }

    get daysRemaining() {
        return this.balance?.EPA_DaysRemaining__c ?? 0;
    }

    get progressPercent() {
        const entitlement = this.annualEntitlement;
        if (entitlement === 0) {
            return 0;
        }
        return Math.round((this.daysUsed / entitlement) * 100);
    }

    get progressVariant() {
        const percent = this.progressPercent;
        if (percent >= 90) {
            return 'expired';
        }
        if (percent >= 75) {
            return 'warning';
        }
        return 'base';
    }
}
