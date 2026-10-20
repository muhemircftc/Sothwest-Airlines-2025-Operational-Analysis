USE AirlineAnalytics;
GO

SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    TRUNCATE TABLE dbo.StagingFlights;

    BULK INSERT dbo.StagingFlights
    FROM 'C:\Users\faari\Downloads\On_Time_Reporting_Carrier_On_Time_Performance_1987_present_2025_7\On_Time_Reporting_Carrier_On_Time_Performance_(1987_present)_2025_7.csv'
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
        NULLIF(LTRIM(RTRIM(CRSDepTime)), '') AS DepartureTimeRaw,
        NULLIF(LTRIM(RTRIM(DepTimeBlk)), '') AS DepartureBlock
    FROM dbo.StagingFlights
)
SELECT TOP (30)
    *,
    CASE
        WHEN NULLIF(LTRIM(RTRIM(Reporting_Airline)), '') IS NULL
          OR LEN(LTRIM(RTRIM(Reporting_Airline))) > 10
          OR NULLIF(LTRIM(RTRIM(Flight_Number_Reporting_Airline)), '') IS NULL
          OR LEN(LTRIM(RTRIM(Flight_Number_Reporting_Airline))) > 10
          OR NULLIF(LTRIM(RTRIM(Origin)), '') IS NULL
          OR LEN(LTRIM(RTRIM(Origin))) <> 3
          OR NULLIF(LTRIM(RTRIM(Dest)), '') IS NULL
          OR LEN(LTRIM(RTRIM(Dest))) <> 3
        THEN 'Required flight field'

        WHEN DepartureTimeRaw IS NULL
          OR LEN(DepartureTimeRaw) <> 4
          OR DepartureTimeRaw LIKE '%[^0-9]%'
          OR TRY_CONVERT(
              time(0), STUFF(DepartureTimeRaw, 3, 0, ':')
          ) IS NULL
        THEN 'Scheduled departure time'

        WHEN DepartureBlock IS NULL
          OR LEN(DepartureBlock) <> 9
          OR LEFT(DepartureBlock, 4) LIKE '%[^0-9]%'
          OR RIGHT(DepartureBlock, 4) LIKE '%[^0-9]%'
          OR SUBSTRING(DepartureBlock, 5, 1) <> '-'
          OR TRY_CONVERT(
              time(0), STUFF(LEFT(DepartureBlock, 4), 3, 0, ':')
          ) IS NULL
          OR TRY_CONVERT(
              time(0), STUFF(RIGHT(DepartureBlock, 4), 3, 0, ':')
          ) IS NULL
        THEN 'Scheduled departure block'
    END AS FailedCheck
FROM Clean
WHERE
    NULLIF(LTRIM(RTRIM(Reporting_Airline)), '') IS NULL
    OR LEN(LTRIM(RTRIM(Reporting_Airline))) > 10
    OR NULLIF(LTRIM(RTRIM(Flight_Number_Reporting_Airline)), '') IS NULL
    OR LEN(LTRIM(RTRIM(Flight_Number_Reporting_Airline))) > 10
    OR NULLIF(LTRIM(RTRIM(Origin)), '') IS NULL
    OR LEN(LTRIM(RTRIM(Origin))) <> 3
    OR NULLIF(LTRIM(RTRIM(Dest)), '') IS NULL
    OR LEN(LTRIM(RTRIM(Dest))) <> 3
    OR DepartureTimeRaw IS NULL
    OR LEN(DepartureTimeRaw) <> 4
    OR DepartureTimeRaw LIKE '%[^0-9]%'
    OR TRY_CONVERT(
        time(0), STUFF(DepartureTimeRaw, 3, 0, ':')
    ) IS NULL
    OR DepartureBlock IS NULL
    OR LEN(DepartureBlock) <> 9
    OR LEFT(DepartureBlock, 4) LIKE '%[^0-9]%'
    OR RIGHT(DepartureBlock, 4) LIKE '%[^0-9]%'
    OR SUBSTRING(DepartureBlock, 5, 1) <> '-'
    OR TRY_CONVERT(
        time(0), STUFF(LEFT(DepartureBlock, 4), 3, 0, ':')
    ) IS NULL
    OR TRY_CONVERT(
        time(0), STUFF(RIGHT(DepartureBlock, 4), 3, 0, ':')
    ) IS NULL;