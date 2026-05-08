import { createElement } from 'lwc';
import Epa_SubmissionForm_LWC from 'c/epa_SubmissionForm_LWC';

describe('c-epa_SubmissionForm_LWC', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    function createComponent() {
        const element = createElement('c-epa_submission-form_lwc', {
            is: Epa_SubmissionForm_LWC
        });
        document.body.appendChild(element);
        return element;
    }

    it('renders all form fields correctly', () => {
        const element = createComponent();

        const combobox = element.shadowRoot.querySelector('lightning-combobox');
        expect(combobox).not.toBeNull();
        expect(combobox.label).toBe('Leave Type');

        const dateInputs = element.shadowRoot.querySelectorAll('lightning-input[type="date"]');
        expect(dateInputs.length).toBe(2);
        expect(dateInputs[0].label).toBe('Start Date');
        expect(dateInputs[1].label).toBe('End Date');

        const textarea = element.shadowRoot.querySelector('lightning-textarea');
        expect(textarea).not.toBeNull();
        expect(textarea.label).toBe('Reason (Optional)');

        const button = element.shadowRoot.querySelector('lightning-button');
        expect(button).not.toBeNull();
        expect(button.label).toBe('Submit Request');
    });

    it('displays correct leave type options', () => {
        const element = createComponent();

        const combobox = element.shadowRoot.querySelector('lightning-combobox');
        const options = combobox.options;
        expect(options).toEqual([
            { label: 'College', value: 'College' },
            { label: 'Exam', value: 'Exam' },
            { label: 'Revision', value: 'Revision' },
            { label: 'Resit', value: 'Resit' }
        ]);
    });

    it('calculates number of days as 1 for same-day selection', async () => {
        const element = createComponent();

        const dateInputs = element.shadowRoot.querySelectorAll('lightning-input[type="date"]');
        dateInputs[0].value = '2026-06-01';
        dateInputs[0].dispatchEvent(new CustomEvent('change', { target: { value: '2026-06-01' } }));
        dateInputs[1].value = '2026-06-01';
        dateInputs[1].dispatchEvent(new CustomEvent('change', { target: { value: '2026-06-01' } }));

        await Promise.resolve();

        const daysDisplay = element.shadowRoot.querySelector('[aria-live="polite"]');
        expect(daysDisplay.textContent).toContain('1');
    });

    it('calculates number of days for multi-day span', async () => {
        const element = createComponent();

        const dateInputs = element.shadowRoot.querySelectorAll('lightning-input[type="date"]');
        dateInputs[0].value = '2026-06-01';
        dateInputs[0].dispatchEvent(new CustomEvent('change', { target: { value: '2026-06-01' } }));
        dateInputs[1].value = '2026-06-03';
        dateInputs[1].dispatchEvent(new CustomEvent('change', { target: { value: '2026-06-03' } }));

        await Promise.resolve();

        const daysDisplay = element.shadowRoot.querySelector('[aria-live="polite"]');
        expect(daysDisplay.textContent).toContain('3');
    });

    it('displays dash when dates are empty', () => {
        const element = createComponent();

        const daysDisplay = element.shadowRoot.querySelector('[aria-live="polite"]');
        expect(daysDisplay.textContent).toContain('—');
    });

    it('displays dash when end date is before start date', async () => {
        const element = createComponent();

        const dateInputs = element.shadowRoot.querySelectorAll('lightning-input[type="date"]');
        dateInputs[0].value = '2026-06-05';
        dateInputs[0].dispatchEvent(new CustomEvent('change', { target: { value: '2026-06-05' } }));
        dateInputs[1].value = '2026-06-01';
        dateInputs[1].dispatchEvent(new CustomEvent('change', { target: { value: '2026-06-01' } }));

        await Promise.resolve();

        const daysDisplay = element.shadowRoot.querySelector('[aria-live="polite"]');
        expect(daysDisplay.textContent).toContain('—');
    });

    it('reactively updates days count when dates change', async () => {
        const element = createComponent();

        const dateInputs = element.shadowRoot.querySelectorAll('lightning-input[type="date"]');

        // Set initial dates
        dateInputs[0].value = '2026-06-01';
        dateInputs[0].dispatchEvent(new CustomEvent('change', { target: { value: '2026-06-01' } }));
        dateInputs[1].value = '2026-06-03';
        dateInputs[1].dispatchEvent(new CustomEvent('change', { target: { value: '2026-06-03' } }));

        await Promise.resolve();

        let daysDisplay = element.shadowRoot.querySelector('[aria-live="polite"]');
        expect(daysDisplay.textContent).toContain('3');

        // Change end date
        dateInputs[1].value = '2026-06-05';
        dateInputs[1].dispatchEvent(new CustomEvent('change', { target: { value: '2026-06-05' } }));

        await Promise.resolve();

        daysDisplay = element.shadowRoot.querySelector('[aria-live="polite"]');
        expect(daysDisplay.textContent).toContain('5');
    });
});
