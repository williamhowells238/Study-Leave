import { createElement } from 'lwc';
import Epa_ManagerTeamBalanceView_LWC from 'c/epa_ManagerTeamBalanceView_LWC';
import getTeamBalances from '@salesforce/apex/EPA_ManagerTeamBalanceView_Class.getTeamBalances';

jest.mock(
    '@salesforce/apex/EPA_ManagerTeamBalanceView_Class.getTeamBalances',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const MOCK_BALANCES = [
    {
        Id: 'a001000000000001',
        EPA_Apprentice__r: { Name: 'Apprentice One' },
        EPA_AnnualEntitlement__c: 24,
        EPA_DaysUsed__c: 5,
        EPA_DaysRemaining__c: 19,
        EPA_QuotaYear__c: '2026'
    },
    {
        Id: 'a001000000000002',
        EPA_Apprentice__r: { Name: 'Apprentice Two' },
        EPA_AnnualEntitlement__c: 24,
        EPA_DaysUsed__c: 10,
        EPA_DaysRemaining__c: 14,
        EPA_QuotaYear__c: '2026'
    }
];

describe('c-epa-manager-team-balance-view-lwc', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    async function flushPromises() {
        return Promise.resolve();
    }

    it('renders datatable when data is returned', async () => {
        const element = createElement('c-epa-manager-team-balance-view-lwc', {
            is: Epa_ManagerTeamBalanceView_LWC
        });
        document.body.appendChild(element);

        getTeamBalances.emit(MOCK_BALANCES);
        await flushPromises();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).not.toBeNull();
        expect(datatable.data.length).toBe(2);
        expect(datatable.data[0].apprenticeName).toBe('Apprentice One');
        expect(datatable.data[1].apprenticeName).toBe('Apprentice Two');
    });

    it('renders empty state when no data is returned', async () => {
        const element = createElement('c-epa-manager-team-balance-view-lwc', {
            is: Epa_ManagerTeamBalanceView_LWC
        });
        document.body.appendChild(element);

        getTeamBalances.emit([]);
        await flushPromises();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).toBeNull();

        const emptyMessage = element.shadowRoot.querySelector('.slds-text-heading_medium');
        expect(emptyMessage).not.toBeNull();
        expect(emptyMessage.textContent).toBe('No Team Balances Found');
    });

    it('shows error state when apex call fails', async () => {
        const element = createElement('c-epa-manager-team-balance-view-lwc', {
            is: Epa_ManagerTeamBalanceView_LWC
        });
        document.body.appendChild(element);

        getTeamBalances.error({ body: { message: 'An error occurred' } });
        await flushPromises();

        const errorElement = element.shadowRoot.querySelector('.slds-text-color_error');
        expect(errorElement).not.toBeNull();
    });

    it('renders card with correct title and icon', async () => {
        const element = createElement('c-epa-manager-team-balance-view-lwc', {
            is: Epa_ManagerTeamBalanceView_LWC
        });
        document.body.appendChild(element);

        getTeamBalances.emit(MOCK_BALANCES);
        await flushPromises();

        const card = element.shadowRoot.querySelector('lightning-card');
        expect(card).not.toBeNull();
        expect(card.title).toBe('Team Leave Balances');
        expect(card.iconName).toBe('standard:calibration');
    });
});
