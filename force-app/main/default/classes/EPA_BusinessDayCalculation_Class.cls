/**
 * @description: Handler class for business day calculation on Study Leave Requests.
 *               Calculates the number of business days between Start Date and End Date,
 *               excluding weekends (Saturday/Sunday) and public holidays.
 * @author: Developer Agent
 * @date: 2026-04-21
 */
public with sharing class EPA_BusinessDayCalculation_Class {

    /**
     * @description: Calculates business days for a list of Study Leave Request records.
     *               Uses a single SOQL query for public holidays across the entire date range
     *               of all records (bulk-safe). Sets EPA_CalculatedBusinessDays__c directly
     *               on the trigger records (before trigger — no DML needed).
     * @param requests List of EPA_StudyLeaveRequest__c records to process
     */
    public static void calculateBusinessDays(List<EPA_StudyLeaveRequest__c> requests) {

        Date minDate;
        Date maxDate;

        // Step 1: Determine the overall date range and handle null dates
        for (EPA_StudyLeaveRequest__c req : requests) {
            if (req.EPA_StartDate__c == null || req.EPA_EndDate__c == null) {
                req.EPA_CalculatedBusinessDays__c = null;
                continue;
            }
            if (minDate == null || req.EPA_StartDate__c < minDate) {
                minDate = req.EPA_StartDate__c;
            }
            if (maxDate == null || req.EPA_EndDate__c > maxDate) {
                maxDate = req.EPA_EndDate__c;
            }
        }

        // If no valid date ranges found, exit
        if (minDate == null || maxDate == null) {
            return;
        }

        // Step 2: Query public holidays once for the entire date range
        Set<Date> publicHolidays = new Set<Date>();
        for (EPA_PublicHoliday__c ph : [
            SELECT EPA_HolidayDate__c
            FROM EPA_PublicHoliday__c
            WHERE EPA_HolidayDate__c >= :minDate
            AND EPA_HolidayDate__c <= :maxDate
        ]) {
            publicHolidays.add(ph.EPA_HolidayDate__c);
        }

        // Step 3: Calculate business days for each record
        // Reference date: 1900-01-07 is a Sunday
        Date referenceDate = Date.newInstance(1900, 1, 7);

        for (EPA_StudyLeaveRequest__c req : requests) {
            if (req.EPA_StartDate__c == null || req.EPA_EndDate__c == null) {
                continue; // Already set to null above
            }

            Integer businessDays = 0;
            Date currentDate = req.EPA_StartDate__c;

            while (currentDate <= req.EPA_EndDate__c) {
                // Calculate day of week using modulo: 0=Sun, 1=Mon, ..., 6=Sat
                Integer dayOfWeek = Math.mod(referenceDate.daysBetween(currentDate), 7);

                // Exclude weekends (0=Sunday, 6=Saturday)
                if (dayOfWeek != 0 && dayOfWeek != 6) {
                    // Exclude public holidays
                    if (!publicHolidays.contains(currentDate)) {
                        businessDays++;
                    }
                }
                currentDate = currentDate.addDays(1);
            }

            req.EPA_CalculatedBusinessDays__c = businessDays;
        }
    }
}
