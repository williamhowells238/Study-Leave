import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import validateAndSubmit from '@salesforce/apex/EPA_SubmissionValidation_Class.validateAndSubmit';

export default class Epa_SubmissionForm_LWC extends LightningElement {
    leaveType = '';
    startDate = '';
    endDate = '';
    reason = '';
    errorMessage = '';
    isSubmitting = false;

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

    get hasError() {
        return this.errorMessage !== '';
    }

    handleLeaveTypeChange(event) {
        this.leaveType = event.detail.value;
        this.errorMessage = '';
    }

    handleStartDateChange(event) {
        this.startDate = event.target.value;
        this.errorMessage = '';
    }

    handleEndDateChange(event) {
        this.endDate = event.target.value;
        this.errorMessage = '';
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
        this.errorMessage = '';

        // Client-side validation
        if (!this.leaveType || !this.startDate || !this.endDate) {
            this.errorMessage = 'Please complete all required fields before submitting.';
            return;
        }

        const numberOfDays = this.calculateNumberOfDays();
        if (!numberOfDays || numberOfDays < 1) {
            this.errorMessage = 'End date must be on or after the start date.';
            return;
        }

        this.isSubmitting = true;

        validateAndSubmit({
            startDate: this.startDate,
            endDate: this.endDate,
            numberOfDays: numberOfDays,
            leaveType: this.leaveType,
            reason: this.reason
        })
            .then((result) => {
                if (result.success) {
                    const formattedStart = new Date(result.startDate).toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' });
                    const formattedEnd = new Date(result.endDate).toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' });
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: `Your ${result.leaveType} study leave request for ${formattedStart} to ${formattedEnd} has been submitted and is pending manager review.`,
                            variant: 'success'
                        })
                    );
                    this.resetForm();
                } else {
                    this.errorMessage = result.errorMessage;
                }
            })
            .catch((error) => {
                this.errorMessage = error.body?.message
                    ? error.body.message
                    : 'An unexpected error occurred. Please try again or contact your administrator.';
            })
            .finally(() => {
                this.isSubmitting = false;
            });
    }

    resetForm() {
        this.leaveType = '';
        this.startDate = '';
        this.endDate = '';
        this.reason = '';
        this.errorMessage = '';
    }
}