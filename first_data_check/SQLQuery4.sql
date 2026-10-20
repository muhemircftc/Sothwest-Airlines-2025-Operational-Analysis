USE AirlineAnalytics;
GO

SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    TRUNCATE TABLE dbo.StagingFlights;

    BULK INSERT dbo.StagingFlights
    FROM 'C:\Users\faari\Downloads\On_Time_Reporting_Carrier_On_Time_Performance_1987_present_2025_3\On_Time_Reporting_Carrier_On_Time_Performance_(1987_present)_2025_3.csv'
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




SELECT
    COUNT(*) AS TotalRecords,
    SUM(
        CASE
            WHEN TRY_CONVERT(date, FlightDate, 23) IS NULL
            THEN 1 ELSE 0
        END
    ) AS MissingOrInvalidDates,
    MIN(TRY_CONVERT(date, FlightDate, 23)) AS FirstFlightDate,
    MAX(TRY_CONVERT(date, FlightDate, 23)) AS LastFlightDate,
    SUM(
        CASE
            WHEN TRY_CONVERT(date, FlightDate, 23) < '20250301'
              OR TRY_CONVERT(date, FlightDate, 23) >= '20250401'
            THEN 1 ELSE 0
        END
    ) AS OutsideMarchRecords
FROM dbo.StagingFlights;










WITH Clean AS (
    SELECT
        TRY_CONVERT(date, FlightDate, 23) AS FlightDateValue,

        NULLIF(LTRIM(RTRIM(Reporting_Airline)), '') AS CarrierCode,
        NULLIF(LTRIM(RTRIM(Flight_Number_Reporting_Airline)), '') AS FlightNumber,
        NULLIF(LTRIM(RTRIM(Origin)), '') AS OriginAirport,
        NULLIF(LTRIM(RTRIM(Dest)), '') AS DestinationAirport,
        NULLIF(LTRIM(RTRIM(CRSDepTime)), '') AS DepartureTimeRaw,
        NULLIF(LTRIM(RTRIM(DepTimeBlk)), '') AS DepartureBlock,
        NULLIF(LTRIM(RTRIM(CancellationCode)), '') AS CancellationCodeValue,

        NULLIF(LTRIM(RTRIM(Cancelled)), '') AS CancelledRaw,
        NULLIF(LTRIM(RTRIM(Diverted)), '') AS DivertedRaw,
        NULLIF(LTRIM(RTRIM(ArrDelay)), '') AS ArrivalDelayRaw,

        TRY_CONVERT(
            decimal(10,2),
            NULLIF(LTRIM(RTRIM(Cancelled)), '')
        ) AS IsCancelled,

        TRY_CONVERT(
            decimal(10,2),
            NULLIF(LTRIM(RTRIM(Diverted)), '')
        ) AS IsDiverted,

        TRY_CONVERT(
            decimal(10,2),
            NULLIF(LTRIM(RTRIM(ArrDelay)), '')
        ) AS ArrivalDelayMinutes
    FROM dbo.StagingFlights
)
SELECT
    COUNT(*) AS TotalRecords,

    SUM(CASE
        WHEN CarrierCode IS NULL OR LEN(CarrierCode) > 10
          OR FlightNumber IS NULL OR LEN(FlightNumber) > 10
          OR OriginAirport IS NULL OR LEN(OriginAirport) <> 3
          OR DestinationAirport IS NULL OR LEN(DestinationAirport) <> 3
        THEN 1 ELSE 0
    END) AS InvalidRequiredFlightFields,

    SUM(CASE
        WHEN DepartureTimeRaw IS NULL
          OR LEN(DepartureTimeRaw) <> 4
          OR DepartureTimeRaw LIKE '%[^0-9]%'
          OR TRY_CONVERT(
              time(0), STUFF(DepartureTimeRaw, 3, 0, ':')
          ) IS NULL
        THEN 1 ELSE 0
    END) AS InvalidDepartureTimes,

    SUM(CASE
        WHEN DepartureBlock IS NULL OR LEN(DepartureBlock) <> 9
        THEN 1 ELSE 0
    END) AS InvalidDepartureBlocks,

    SUM(CASE
        WHEN IsCancelled IS NULL OR IsCancelled NOT IN (0, 1)
          OR IsDiverted IS NULL OR IsDiverted NOT IN (0, 1)
          OR (IsCancelled = 1 AND IsDiverted = 1)
        THEN 1 ELSE 0
    END) AS InvalidFlightStatuses,

    SUM(CASE
        WHEN ArrivalDelayRaw IS NOT NULL
         AND ArrivalDelayMinutes IS NULL
        THEN 1 ELSE 0
    END) AS InvalidArrivalDelayRecords,

    SUM(CASE
        WHEN ArrivalDelayMinutes IS NULL
        THEN 1 ELSE 0
    END) AS MissingArrivalDelayRecords,

    SUM(CASE
        WHEN IsCancelled = 0 AND IsDiverted = 0
         AND ArrivalDelayMinutes IS NULL
        THEN 1 ELSE 0
    END) AS MissingArrivalOnRegularFlights,

    SUM(CASE
        WHEN (IsCancelled = 1 OR IsDiverted = 1)
         AND ArrivalDelayMinutes IS NOT NULL
        THEN 1 ELSE 0
    END) AS ArrivalPresentOnCancelledOrDiverted,

    SUM(CASE
        WHEN IsCancelled = 1
        THEN 1 ELSE 0
    END) AS CancelledRecords,

    SUM(CASE
        WHEN IsDiverted = 1
        THEN 1 ELSE 0
    END) AS DivertedRecords,

    SUM(CASE
        WHEN CancellationCodeValue IS NOT NULL
         AND CancellationCodeValue NOT IN ('A', 'B', 'C', 'D')
        THEN 1 ELSE 0
    END) AS InvalidCancellationCodes,

    SUM(CASE
        WHEN IsCancelled = 1 AND CancellationCodeValue IS NULL
        THEN 1 ELSE 0
    END) AS MissingCodeOnCancelledFlights,

    SUM(CASE
        WHEN IsCancelled = 0 AND CancellationCodeValue IS NOT NULL
        THEN 1 ELSE 0
    END) AS CodePresentOnNonCancelledFlights
FROM Clean;




-- 1. Gecikme nedeni alanlarının kontrolü

SELECT
    d.DelayField,

    SUM(CASE
        WHEN v.RawValue IS NOT NULL
         AND n.DelayMinutes IS NULL
        THEN 1 ELSE 0
    END) AS InvalidRecords,

    SUM(CASE
        WHEN n.DelayMinutes < 0
        THEN 1 ELSE 0
    END) AS NegativeRecords,

    SUM(CASE
        WHEN TRY_CONVERT(
            decimal(10,2),
            NULLIF(LTRIM(RTRIM(s.ArrDelay)), '')
        ) >= 15
         AND v.RawValue IS NULL
        THEN 1 ELSE 0
    END) AS MissingOnDelayedFlights

FROM dbo.StagingFlights AS s

CROSS APPLY (VALUES
    ('CarrierDelay',      s.CarrierDelay),
    ('WeatherDelay',      s.WeatherDelay),
    ('NASDelay',          s.NASDelay),
    ('SecurityDelay',     s.SecurityDelay),
    ('LateAircraftDelay', s.LateAircraftDelay)
) AS d(DelayField, RawDelay)

CROSS APPLY (VALUES (
    NULLIF(LTRIM(RTRIM(d.RawDelay)), '')
)) AS v(RawValue)

CROSS APPLY (VALUES (
    TRY_CONVERT(decimal(10,2), v.RawValue)
)) AS n(DelayMinutes)

GROUP BY d.DelayField
ORDER BY d.DelayField;



-- 2. Aynı uçuş anahtarının birden fazla bulunması

SELECT COUNT(*) AS DuplicateFlightKeyGroups
FROM (
    SELECT
        TRY_CONVERT(date, FlightDate, 23) AS FlightDateValue,
        LTRIM(RTRIM(Reporting_Airline)) AS CarrierCode,
        LTRIM(RTRIM(Flight_Number_Reporting_Airline)) AS FlightNumber,
        LTRIM(RTRIM(Origin)) AS OriginAirport,
        LTRIM(RTRIM(Dest)) AS DestinationAirport,
        LTRIM(RTRIM(CRSDepTime)) AS DepartureTimeRaw
    FROM dbo.StagingFlights
    GROUP BY
        TRY_CONVERT(date, FlightDate, 23),
        LTRIM(RTRIM(Reporting_Airline)),
        LTRIM(RTRIM(Flight_Number_Reporting_Airline)),
        LTRIM(RTRIM(Origin)),
        LTRIM(RTRIM(Dest)),
        LTRIM(RTRIM(CRSDepTime))
    HAVING COUNT(*) > 1
) AS duplicates;