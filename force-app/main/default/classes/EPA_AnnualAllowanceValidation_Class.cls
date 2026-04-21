/**
 * @description: Handler class for annual allowance validation on Study Leave Requests.
 *               Validates that a new request does not cause the apprentice to exceed
 *               their configured annual study leave allowance. Handles year-boundary
 *               splitting for requests spanning December to January.
 * @author: Developer Agent
 * @date: 2026-04-21
 */
public with sharing class EPA_AnnualAllowanceValidation_Class {

    @TestVisible
    private static Decimal allowanceOverride = null;

    /**
     * @description: Validates that each incoming request does not exceed the annual allowance.
     *               Queries existing Approved/Pending requests, retrieves the configured allowance,
     *               and adds an error to any record that would exceed the limit.
     * @param requests List of EPA_StudyLeaveRequest__c records to validate
     */
    public static void validateAllowance(List<EPA_StudyLeaveRequest__c> requests) {

        // Step 1: Filter valid records — only validate requests with status that counts
        //         toward the allowance. Skip Rejected and Cancelled records.
        List<EPA_StudyLeaveRequest__c> validRequests = new List<EPA_StudyLeaveRequest__c>();
        Set<Id> apprenticeIds = new Set<Id>();
        Set<Integer> relevantYears = new Set<Integer>();
        Set<String> excludedStatuses = new Set<String>{'Rejected', 'Cancelled'};

        for (EPA_StudyLeaveRequest__c req : requests) {
            if (req.EPA_Apprentice__c != null && req.EPA_StartDate__c != null &&
                req.EPA_EndDate__c != null && req.EPA_CalculatedBusinessDays__c != null &&
                !excludedStatuses.contains(req.EPA_Status__c)) {
                validRequests.add(req);
                apprenticeIds.add(req.EPA_Apprentice__c);
                relevantYears.add(req.EPA_StartDate__c.year());
                relevantYears.add(req.EPA_EndDate__c.year());
            }
        }

        if (validRequests.isEmpty()) {
            return;
        }

        // Step 2: Retrieve annual allowance
        Decimal annualAllowance = getAllowance();
        if (annualAllowance == null) {
            return;
        }

        // Step 3: Determine date boundaries for the query
        Integer minYear = null;
        Integer maxYear = null;
        for (Integer y : relevantYears) {
            if (minYear == null || y < minYear) { minYear = y; }
            if (maxYear == null || y > maxYear) { maxYear = y; }
        }
        Date queryStartDate = Date.newInstance(minYear, 1, 1);
        Date queryEndDate = Date.newInstance(maxYear, 12, 31);

        // Step 4: Collect IDs to exclude (update context)
        Set<Id> currentRecordIds = new Set<Id>();
        for (EPA_StudyLeaveRequest__c req : validRequests) {
            if (req.Id != null) {
                currentRecordIds.add(req.Id);
            }
        }

        // Step 5: Query existing Approved/Pending requests
        List<EPA_StudyLeaveRequest__c> existingRequests = [
            SELECT Id, EPA_Apprentice__c, EPA_StartDate__c, EPA_EndDate__c,
                   EPA_CalculatedBusinessDays__c
            FROM EPA_StudyLeaveRequest__c
            WHERE EPA_Apprentice__c IN :apprenticeIds
            AND EPA_Status__c IN ('Approved', 'Pending')
            AND EPA_StartDate__c <= :queryEndDate
            AND EPA_EndDate__c >= :queryStartDate
            AND Id NOT IN :currentRecordIds
            WITH USER_MODE
        ];

        // Step 6: Query public holidays for year-boundary splitting
        Set<Date> publicHolidays = new Set<Date>();
        for (EPA_PublicHoliday__c ph : [
            SELECT EPA_HolidayDate__c
            FROM EPA_PublicHoliday__c
            WHERE EPA_HolidayDate__c >= :queryStartDate
            AND EPA_HolidayDate__c <= :queryEndDate
            WITH USER_MODE
        ]) {
            publicHolidays.add(ph.EPA_HolidayDate__c);
        }

        // Step 7: Build used-days map from existing requests (apprenticeId-year -> days)
        Map<String, Decimal> usedDaysMap = new Map<String, Decimal>();
        for (EPA_StudyLeaveRequest__c existing : existingRequests) {
            addRequestDaysToMap(existing, usedDaysMap, publicHolidays);
        }

        // Step 8: Validate each incoming request
        for (EPA_StudyLeaveRequest__c req : validRequests) {
            Integer startYear = req.EPA_StartDate__c.year();
            Integer endYear = req.EPA_EndDate__c.year();

            if (startYear == endYear) {
                // No year boundary — simple validation
                String key = req.EPA_Apprentice__c + '-' + startYear;
                Decimal usedDays = usedDaysMap.containsKey(key) ? usedDaysMap.get(key) : 0;
                Decimal requestDays = req.EPA_CalculatedBusinessDays__c;
                Decimal totalDays = usedDays + requestDays;

                if (totalDays > annualAllowance) {
                    Decimal remaining = annualAllowance - usedDays;
                    remaining = remaining < 0 ? 0 : remaining;
                    req.addError('You have ' + remaining.intValue() + ' days remaining of your annual study leave allowance. This request requires ' + requestDays.intValue() + ' days.');
                }
            } else {
                // Year boundary — split days across years
                Map<Integer, Integer> daysByYear = splitBusinessDaysByYear(
                    req.EPA_StartDate__c, req.EPA_EndDate__c, publicHolidays
                );

                for (Integer yr : daysByYear.keySet()) {
                    String key = req.EPA_Apprentice__c + '-' + yr;
                    Decimal usedDays = usedDaysMap.containsKey(key) ? usedDaysMap.get(key) : 0;
                    Decimal requestDaysForYear = daysByYear.get(yr);
                    Decimal totalDays = usedDays + requestDaysForYear;

                    if (totalDays > annualAllowance) {
                        Decimal remaining = annualAllowance - usedDays;
                        remaining = remaining < 0 ? 0 : remaining;
                        req.addError('You have ' + remaining.intValue() + ' days remaining of your annual study leave allowance. This request requires ' + requestDaysForYear.intValue() + ' days.');
                        break;
                    }
                }
            }
        }
    }

    /**
     * @description: Retrieves the annual allowance value from Custom Metadata or test override.
     * @return The configured annual allowance days, or null if not configured.
     */
    private static Decimal getAllowance() {
        if (allowanceOverride != null) {
            return allowanceOverride;
        }
        List<EPA_StudyLeaveAllowance__mdt> settings = [
            SELECT EPA_AnnualAllowanceDays__c
            FROM EPA_StudyLeaveAllowance__mdt
            WHERE DeveloperName = 'EPA_Default'
            WITH USER_MODE
            LIMIT 1
        ];
        return settings.isEmpty() ? null : settings[0].EPA_AnnualAllowanceDays__c;
    }

    /**
     * @description: Adds the business days from a request to the used-days map,
     *               splitting across years if the request spans a year boundary.
     * @param req The study leave request record
     * @param usedDaysMap Map of apprenticeId-year to total used days
     * @param publicHolidays Set of public holiday dates
     */
    private static void addRequestDaysToMap(EPA_StudyLeaveRequest__c req,
                                             Map<String, Decimal> usedDaysMap,
                                             Set<Date> publicHolidays) {
        Integer startYear = req.EPA_StartDate__c.year();
        Integer endYear = req.EPA_EndDate__c.year();

        if (startYear == endYear) {
            String key = req.EPA_Apprentice__c + '-' + startYear;
            Decimal current = usedDaysMap.containsKey(key) ? usedDaysMap.get(key) : 0;
            usedDaysMap.put(key, current + (req.EPA_CalculatedBusinessDays__c ?? 0));
        } else {
            Map<Integer, Integer> daysByYear = splitBusinessDaysByYear(
                req.EPA_StartDate__c, req.EPA_EndDate__c, publicHolidays
            );
            for (Integer yr : daysByYear.keySet()) {
                String key = req.EPA_Apprentice__c + '-' + yr;
                Decimal current = usedDaysMap.containsKey(key) ? usedDaysMap.get(key) : 0;
                usedDaysMap.put(key, current + daysByYear.get(yr));
            }
        }
    }

    /**
     * @description: Splits business days across calendar years for a date range,
     *               using the same weekday/public-holiday logic as the business day calculator.
     * @param startDate The start date of the range
     * @param endDate The end date of the range
     * @param publicHolidays Set of public holiday dates
     * @return Map of year to business day count for that year
     */
    private static Map<Integer, Integer> splitBusinessDaysByYear(Date startDate, Date endDate,
                                                                  Set<Date> publicHolidays) {
        Map<Integer, Integer> daysByYear = new Map<Integer, Integer>();
        Date referenceDate = Date.newInstance(1900, 1, 7); // Sunday
        Date currentDate = startDate;

        while (currentDate <= endDate) {
            Integer dayOfWeek = Math.mod(referenceDate.daysBetween(currentDate), 7);
            if (dayOfWeek != 0 && dayOfWeek != 6) {
                if (!publicHolidays.contains(currentDate)) {
                    Integer yr = currentDate.year();
                    Integer current = daysByYear.containsKey(yr) ? daysByYear.get(yr) : 0;
                    daysByYear.put(yr, current + 1);
                }
            }
            currentDate = currentDate.addDays(1);
        }

        return daysByYear;
    }
}
