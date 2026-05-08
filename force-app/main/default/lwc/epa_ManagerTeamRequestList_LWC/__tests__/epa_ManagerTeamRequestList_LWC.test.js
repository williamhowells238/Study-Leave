import { createElement } from 'lwc';
import Epa_ManagerTeamRequestList_LWC from 'c/epa_ManagerTeamRequestList_LWC';
import getTeamRequests from '@salesforce/apex/EPA_ManagerTeamRequestList_Class.getTeamRequests';

// Mock Apex wire adapter
jest.mock(
    '@salesforce/apex/EPA_ManagerTeamRequestList_Class.getTeamRequests',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

// Mock NavigationMixin
const mockNavigate = jest.fn();
jest.mock('lightning/navigation', () => ({
    NavigationMixin: (Base) => {
        return class extends Base {
            [Symbol.for('Navigate')] = mockNavigate;
        };
    }
}), { virtual: true });

const MOCK_REQUESTS = [
    {
        Id: '001000000000001',
        EPA_Apprentice__r: { Name: 'Apprentice One' },
        EPA_LeaveType__c: 'College',
        EPA_StartDate__c: '2026-06-01',
        EPA_EndDate__c: '2026-06-03',
        EPA_NumberOfDays__c: 3,
        EPA_Status__c: 'Pending'
    },
    {
        Id: '001000000000002',
        EPA_Apprentice__r: { Name: 'Apprentice Two' },
        EPA_LeaveType__c: 'Exam',
        EPA_StartDate__c: '2026-07-15',
        EPA_EndDate__c: '2026-07-15',
        EPA_NumberOfDays__c: 1,
        EPA_Status__c: 'Approved'
    }
];

describe('c-epa-manager-team-request-list-lwc', () => {
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
        const element = createElement('c-epa-manager-team-request-list-lwc', {
            is: Epa_ManagerTeamRequestList_LWC
        });
        document.body.appendChild(element);

        getTeamRequests.emit(MOCK_REQUESTS);
        await flushPromises();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).not.toBeNull();
        expect(datatable.data.length).toBe(2);
        expect(datatable.data[0].apprenticeName).toBe('Apprentice One');
    });

    it('renders empty state when no data is returned', async () => {
        const element = createElement('c-epa-manager-team-request-list-lwc', {
            is: Epa_ManagerTeamRequestList_LWC
        });
        document.body.appendChild(element);

        getTeamRequests.emit([]);
        await flushPromises();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).toBeNull();

        const emptyMessage = element.shadowRoot.querySelector('.slds-text-heading_medium');
        expect(emptyMessage).not.toBeNull();
        expect(emptyMessage.textContent).toBe('No Team Requests Found');
    });

    it('shows error state when apex call fails', async () => {
        const element = createElement('c-epa-manager-team-request-list-lwc', {
            is: Epa_ManagerTeamRequestList_LWC
        });
        document.body.appendChild(element);

        getTeamRequests.error({ body: { message: 'An error occurred' } });
        await flushPromises();

        const errorElement = element.shadowRoot.querySelector('.slds-text-color_error');
        expect(errorElement).not.toBeNull();
    });

    it('renders status filter combobox', async () => {
        const element = createElement('c-epa-manager-team-request-list-lwc', {
            is: Epa_ManagerTeamRequestList_LWC
        });
        document.body.appendChild(element);

        getTeamRequests.emit(MOCK_REQUESTS);
        await flushPromises();

        const combobox = element.shadowRoot.querySelector('lightning-combobox');
        expect(combobox).not.toBeNull();
        expect(combobox.label).toBe('Filter by Status');
    });

    it('navigates to record on row action view', async () => {
        const element = createElement('c-epa-manager-team-request-list-lwc', {
            is: Epa_ManagerTeamRequestList_LWC
        });
        document.body.appendChild(element);

        getTeamRequests.emit(MOCK_REQUESTS);
        await flushPromises();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        datatable.dispatchEvent(
            new CustomEvent('rowaction', {
                detail: {
                    action: { name: 'view' },
                    row: { Id: '001000000000001' }
                }
            })
        );
        await flushPromises();

        expect(mockNavigate).toHaveBeenCalledWith({
            type: 'standard__recordPage',
            attributes: {
                recordId: '001000000000001',
                objectApiName: 'EPA_StudyLeaveRequest__c',
                actionName: 'view'
            }
        });
    });
});
