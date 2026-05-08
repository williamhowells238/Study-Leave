import { LightningElement, track } from 'lwc';

export default class Epa_SubmissionForm_LWC extends LightningElement {
    @track leaveType = '';
    @track startDate = '';
    @track endDate = '';
    @track reason = '';

    get leaveTypeOptions() {
        return [
            { label: 'College', value: 'College' },
            { label: 'Exam', value: 'Exam' },
            { label: 'Revision', value: 'Revision' },
            { label: 'Resit', value: 'Resit' }
        ];
    }

    get numberOfDaysDisplay() {
        return this.calculateNumberOfDays();
    }

    handleLeaveTypeChange(event) {
        this.leaveType = event.detail.value;
    }

    handleStartDateChange(event) {
        this.startDate = event.target.value;
    }

    handleEndDateChange(event) {
        this.endDate = event.target.value;
    }

    handleReasonChange(event) {
        this.reason = event.target.value;
    }

    calculateNumberOfDays() {
        if (!this.startDate || !this.endDate) {
            return null;
        }
        const start = new Date(this.startDate);
        const end = new Date(this.endDate);
        if (isNaN(start.getTime()) || isNaN(end.getTime())) {
            return null;
        }
        if (end < start) {
            return null;
        }
        const diffTime = end.getTime() - start.getTime();
        const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24)) + 1;
        return diffDays;
    }

    handleSubmit() {
        // Submission logic deferred to Story 007
    }
}
