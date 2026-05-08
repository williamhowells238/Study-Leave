import { createElement } from 'lwc';
import Epa_ApprenticeBalanceDisplay_LWC from 'c/epa_ApprenticeBalanceDisplay_LWC';
import getMyBalance from '@salesforce/apex/EPA_ApprenticeBalanceDisplay_LWC.getMyBalance';

// Mock the Apex wire adapter
jest.mock(
    '@salesforce/apex/EPA_ApprenticeBalanceDisplay_Class.getMyBalance',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);

const MOCK_BALANCE = {
    Id: '001000000000001',
    EPA_AnnualEntitlement__c: 24,
    EPA_DaysUsed__c: 5,
    EPA_DaysRemaining__c: 19,
    EPA_QuotaYear__c: '2026'
};

describe('c-epa_ApprenticeBalanceDisplay_LWC', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders balance values when data is returned', async () => {
        const element = createElement('c-epa_ApprenticeBalanceDisplay_LWC', {
            is: Epa_ApprenticeBalanceDisplay_LWC
        });
        document.body.appendChild(element);

        getMyBalance.emit(MOCK_BALANCE);

        await Promise.resolve();

        const headings = element.shadowRoot.querySelectorAll('.slds-text-heading_large');
        expect(headings.length).toBe(3);
        expect(headings[0].textContent).toBe('24');
        expect(headings[1].textContent).toBe('5');
        expect(headings[2].textContent).toBe('19');
    });

    it('displays no-record message when null is returned', async () => {
        const element = createElement('c-epa_ApprenticeBalanceDisplay_LWC', {
            is: Epa_ApprenticeBalanceDisplay_LWC
        });
        document.body.appendChild(element);

        getMyBalance.emit(null);

        await Promise.resolve();

        const noRecordHeading = element.shadowRoot.querySelector('.slds-text-heading_medium');
        expect(noRecordHeading).not.toBeNull();
        expect(noRecordHeading.textContent).toBe('No Balance Found');
    });

    it('displays error message when wire fails', async () => {
        const element = createElement('c-epa_ApprenticeBalanceDisplay_LWC', {
            is: Epa_ApprenticeBalanceDisplay_LWC
        });
        document.body.appendChild(element);

        getMyBalance.error();

        await Promise.resolve();

        const errorDiv = element.shadowRoot.querySelector('.slds-text-color_error');
        expect(errorDiv).not.toBeNull();
        expect(errorDiv.textContent).toContain('An error occurred');
    });
});
