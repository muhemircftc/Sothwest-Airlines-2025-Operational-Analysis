USE AirlineAnalytics;
GO

SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    TRUNCATE TABLE dbo.StagingFlights;

    BULK INSERT dbo.StagingFlights
    FROM 'C:\Users\faari\Downloads\On_Time_Reporting_Carrier_On_Time_Performance_1987_present_2025_9\On_Time_Reporting_Carrier_On_Time_Performance_(1987_present)_2025_9.csv'
    WITH (
        FORMAT = 'CSV',
        CODEPAGE = '65001',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a',
        KEEPNULLS,
        MAXERRORS = 0
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;


WITH Clean AS (
    SELECT
        FlightDate,
        Reporting_Airline,
        Flight_Number_Reporting_Airline,
        Origin,
        Dest,
        CRSDepTime,

        TRY_CONVERT(
            decimal(10,2),
            NULLIF(LTRIM(RTRIM(Cancelled)), '')
        ) AS IsCancelled,

        TRY_CONVERT(
            decimal(10,2),
            NULLIF(LTRIM(RTRIM(Diverted)), '')
        ) AS IsDiverted,

        NULLIF(LTRIM(RTRIM(ArrDelay)), '') AS ArrivalDelayRaw,

        TRY_CONVERT(
            decimal(10,2),
            NULLIF(LTRIM(RTRIM(ArrDelay)), '')
        ) AS ArrivalDelayMinutes,

        NULLIF(LTRIM(RTRIM(CancellationCode)), '') AS CancellationCodeValue
    FROM dbo.StagingFlights
),
Issues AS (
    SELECT
        *,
        CASE
            WHEN IsCancelled = 0
             AND IsDiverted = 0
             AND ArrivalDelayMinutes IS NULL
            THEN 1 ELSE 0
        END AS MissingRegularArrival,

        CASE
            WHEN CancellationCodeValue IS NOT NULL
             AND CancellationCodeValue NOT IN ('A', 'B', 'C', 'D')
            THEN 1 ELSE 0
        END AS InvalidCancellationCode,

        CASE
            WHEN IsCancelled = 1
             AND CancellationCodeValue IS NULL
            THEN 1 ELSE 0
        END AS MissingCancellationCode,

        CASE
            WHEN IsCancelled = 0
             AND CancellationCodeValue IS NOT NULL
            THEN 1 ELSE 0
        END AS CodeOnNonCancelledFlight
    FROM Clean
)
SELECT
    COUNT(*) OVER () AS TotalProblemRecords,
    *
FROM Issues
WHERE MissingRegularArrival = 1
   OR InvalidCancellationCode = 1
   OR MissingCancellationCode = 1
   OR CodeOnNonCancelledFlight = 1
ORDER BY FlightDate, Reporting_Airline,
         Flight_Number_Reporting_Airline;




WITH DelayTotals AS (
    SELECT
        FlightDate,
        CarrierCode,
        FlightNumber,
        OriginAirport,
        DestinationAirport,
        ScheduledDepartureTimeRaw,
        ArrivalDelayMinutes,
        CarrierDelayMinutes,
        WeatherDelayMinutes,
        NasDelayMinutes,
        SecurityDelayMinutes,
        LateAircraftDelayMinutes,

        CarrierDelayMinutes
        + WeatherDelayMinutes
        + NasDelayMinutes
        + SecurityDelayMinutes
        + LateAircraftDelayMinutes AS ReportedCauseMinutes

    FROM dbo.FactFlights
    WHERE FlightDate >= '20250901'
      AND FlightDate < '20251001'
      AND ArrivalDelayMinutes >= 15
)
SELECT
    *,
    ArrivalDelayMinutes - ReportedCauseMinutes
        AS ArrivalMinusCauseMinutes
FROM DelayTotals
WHERE ArrivalDelayMinutes <> ReportedCauseMinutes;











WITH CauseCheck AS (
    SELECT
        FlightDate,
        CarrierCode,
        FlightNumber,
        OriginAirport,
        DestinationAirport,
        ScheduledDepartureTimeRaw,
        ArrivalDelayMinutes,
        CarrierDelayMinutes,
        WeatherDelayMinutes,
        NasDelayMinutes,
        SecurityDelayMinutes,
        LateAircraftDelayMinutes,

        CarrierDelayMinutes
        + WeatherDelayMinutes
        + NasDelayMinutes
        + SecurityDelayMinutes
        + LateAircraftDelayMinutes AS ReportedCauseMinutes

    FROM dbo.FactFlights
    WHERE FlightDate >= '20250101'
      AND FlightDate < '20260101'
      AND ArrivalDelayMinutes >= 15
)
SELECT
    *,
    ArrivalDelayMinutes - ReportedCauseMinutes
        AS ArrivalMinusCauseMinutes,

    CASE
        WHEN ReportedCauseMinutes IS NULL
            THEN 'Missing cause value'
        WHEN ReportedCauseMinutes = 0
            THEN 'Zero reported cause minutes'
        WHEN ReportedCauseMinutes < ArrivalDelayMinutes
            THEN 'Cause total below arrival delay'
        ELSE 'Cause total above arrival delay'
    END AS DifferenceType

FROM CauseCheck
WHERE ReportedCauseMinutes IS NULL
   OR ArrivalDelayMinutes <> ReportedCauseMinutes
ORDER BY FlightDate, CarrierCode, FlightNumber;