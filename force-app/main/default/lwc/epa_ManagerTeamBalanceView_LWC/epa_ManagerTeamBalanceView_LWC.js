import { LightningElement, wire } from 'lwc';
import getTeamBalances from '@salesforce/apex/EPA_ManagerTeamBalanceView_Class.getTeamBalances';

const COLUMNS = [
    { label: 'Apprentice Name', fieldName: 'apprenticeName', type: 'text' },
    { label: 'Annual Entitlement', fieldName: 'EPA_AnnualEntitlement__c', type: 'number' },
    { label: 'Days Used', fieldName: 'EPA_DaysUsed__c', type: 'number' },
    { label: 'Days Remaining', fieldName: 'EPA_DaysRemaining__c', type: 'number' }
];

export default class Epa_ManagerTeamBalanceView_LWC extends LightningElement {
    balances;
    error;
    columns = COLUMNS;

    @wire(getTeamBalances)
    wiredBalances({ data, error }) {
        if (data) {
            this.balances = data.map(record => ({
                ...record,
                apprenticeName: record.EPA_Apprentice__r?.Name ?? ''
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.balances = undefined;
        }
    }

    get hasBalances() {
        return this.balances && this.balances.length > 0;
    }
}
