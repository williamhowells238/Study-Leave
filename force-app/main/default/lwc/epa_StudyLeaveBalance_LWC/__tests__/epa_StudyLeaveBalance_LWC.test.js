import { createElement } from 'lwc';
import Epa_StudyLeaveBalance_LWC from 'c/epa_StudyLeaveBalance_LWC';
import getBalanceSummary from '@salesforce/apex/EPA_StudyLeaveBalance_Class.getBalanceSummary';
import getRequestHistory from '@salesforce/apex/EPA_StudyLeaveBalance_Class.getRequestHistory';

// Mock Apex wire adapters
jest.mock(
    '@salesforce/apex/EPA_StudyLeaveBalance_Class.getBalanceSummary',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/EPA_StudyLeaveBalance_Class.getRequestHistory',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const MOCK_BALANCE = {
    annualAllowance: 20,
    consumedDays: 10,
    remainingDays: 10
};

const MOCK_HISTORY = [
    {
        Id: '1',
        EPA_StartDate__c: '2026-04-06',
        EPA_EndDate__c: '2026-04-10',
        EPA_Category__c: 'Exam Prep',
        EPA_CalculatedBusinessDays__c: 5,
        EPA_Status__c: 'Approved'
    },
    {
        Id: '2',
        EPA_StartDate__c: '2026-03-03',
        EPA_EndDate__c: '2026-03-07',
        EPA_Category__c: 'Study Block',
        EPA_CalculatedBusinessDays__c: 5,
        EPA_Status__c: 'Pending'
    }
];

describe('c-epa_StudyLeaveBalance_LWC', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    async function flushPromises() {
        return Promise.resolve();
    }

    it('renders balance summary when data is returned', async () => {
        getBalanceSummary.mockResolvedValue(MOCK_BALANCE);
        getRequestHistory.mockResolvedValue([]);

        const element = createElement('c-epa_StudyLeaveBalance_LWC', {
            is: Epa_StudyLeaveBalance_LWC
        });
        document.body.appendChild(element);

        await flushPromises();

        const headings = element.shadowRoot.querySelectorAll('.slds-text-heading_large');
        expect(headings.length).toBe(3);
        expect(headings[0].textContent).toBe('20');
        expect(headings[1].textContent).toBe('10');
        expect(headings[2].textContent).toBe('10');
    });

    it('renders request history datatable when data is returned', async () => {
        getBalanceSummary.mockResolvedValue(MOCK_BALANCE);
        getRequestHistory.mockResolvedValue(MOCK_HISTORY);

        const element = createElement('c-epa_StudyLeaveBalance_LWC', {
            is: Epa_StudyLeaveBalance_LWC
        });
        document.body.appendChild(element);

        await flushPromises();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).not.toBeNull();
        expect(datatable.data.length).toBe(2);
        expect(datatable.columns.length).toBe(5);
    });

    it('shows empty state when no history exists', async () => {
        getBalanceSummary.mockResolvedValue(MOCK_BALANCE);
        getRequestHistory.mockResolvedValue([]);

        const element = createElement('c-epa_StudyLeaveBalance_LWC', {
            is: Epa_StudyLeaveBalance_LWC
        });
        document.body.appendChild(element);

        await flushPromises();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).toBeNull();

        const emptyMsg = element.shadowRoot.querySelector('.slds-illustration p');
        expect(emptyMsg).not.toBeNull();
        expect(emptyMsg.textContent).toContain('No study leave requests found');
    });

    it('shows error state when balance apex call fails', async () => {
        getBalanceSummary.mockRejectedValue({ body: { message: 'Balance error' } });
        getRequestHistory.mockResolvedValue([]);

        const element = createElement('c-epa_StudyLeaveBalance_LWC', {
            is: Epa_StudyLeaveBalance_LWC
        });
        document.body.appendChild(element);

        await flushPromises();

        const errorMsg = element.shadowRoot.querySelector('.slds-text-color_error');
        expect(errorMsg).not.toBeNull();
        expect(errorMsg.textContent).toBe('Balance error');
    });
});
