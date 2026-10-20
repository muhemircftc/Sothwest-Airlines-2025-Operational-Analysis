SELECT
    SERVERPROPERTY('Edition') AS ServerEdition,
    SERVERPROPERTY('ProductVersion') AS ProductVersion;

SELECT
    SUM(size) * 8.0 / 1024 AS AllocatedDataSizeMB
FROM sys.database_files
WHERE type = 0;

SELECT SERVERPROPERTY('Edition') AS ServerEdition;

SELECT OBJECT_DEFINITION(
    OBJECT_ID('dbo.vw_Flights')
) AS ViewDefinition;

CREATE TABLE dbo.FactFlights
(
    FlightRecordID bigint IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_FactFlights PRIMARY KEY,

    FlightDate date NOT NULL,
    CarrierCode varchar(10) NOT NULL,
    FlightNumber varchar(10) NOT NULL,
    OriginAirport varchar(3) NOT NULL,
    DestinationAirport varchar(3) NOT NULL,

    ScheduledDepartureTimeRaw varchar(4) NOT NULL,
    ScheduledDepartureTime time(0) NOT NULL,
    ScheduledDepartureBlock varchar(9) NOT NULL,

    IsCancelled bit NOT NULL,
    IsDiverted bit NOT NULL,
    CancellationCode varchar(1) NULL,

    ArrivalDelayMinutes decimal(10,2) NULL,
    CarrierDelayMinutes decimal(10,2) NULL,
    WeatherDelayMinutes decimal(10,2) NULL,
    NasDelayMinutes decimal(10,2) NULL,
    SecurityDelayMinutes decimal(10,2) NULL,
    LateAircraftDelayMinutes decimal(10,2) NULL,

    CONSTRAINT UQ_FactFlights_Flight UNIQUE
    (
        FlightDate,
        CarrierCode,
        FlightNumber,
        OriginAirport,
        DestinationAirport,
        ScheduledDepartureTimeRaw
    ),

    CONSTRAINT CK_FactFlights_CancellationCode CHECK
    (
        CancellationCode IS NULL
        OR CancellationCode IN ('A', 'B', 'C', 'D')
    )
);


SELECT COUNT(*) AS FlightRecordCount
FROM dbo.FactFlights;


SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF EXISTS (SELECT 1 FROM dbo.FactFlights)
        THROW 50001, N'Hedef tablo boş değil. Aktarım durduruldu.', 1;

    INSERT INTO dbo.FactFlights
    (
        FlightDate,
        CarrierCode,
        FlightNumber,
        OriginAirport,
        DestinationAirport,
        ScheduledDepartureTimeRaw,
        ScheduledDepartureTime,
        ScheduledDepartureBlock,
        IsCancelled,
        IsDiverted,
        CancellationCode,
        ArrivalDelayMinutes,
        CarrierDelayMinutes,
        WeatherDelayMinutes,
        NasDelayMinutes,
        SecurityDelayMinutes,
        LateAircraftDelayMinutes
    )
    SELECT
        FlightDate,
        CarrierCode,
        FlightNumber,
        OriginAirport,
        DestinationAirport,
        ScheduledDepartureTimeRaw,
        ScheduledDepartureTime,
        ScheduledDepartureBlock,
        IsCancelled,
        IsDiverted,
        NULLIF(LTRIM(RTRIM(CancellationCode)), ''),
        ArrivalDelayMinutes,
        CarrierDelayMinutes,
        WeatherDelayMinutes,
        NasDelayMinutes,
        SecurityDelayMinutes,
        LateAircraftDelayMinutes
    FROM dbo.vw_Flights;

    IF (SELECT COUNT(*) FROM dbo.FactFlights) <> 539747
        THROW 50002, N'Kayıt sayısı beklenen değerle eşleşmedi.', 1;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;


SELECT
    COUNT(*) AS FlightRecords,
    MIN(FlightDate) AS FirstFlightDate,
    MAX(FlightDate) AS LastFlightDate,
    SUM(CAST(IsCancelled AS int)) AS CancelledRecords,
    SUM(CAST(IsDiverted AS int)) AS DivertedRecords
FROM dbo.FactFlights;

ALTER VIEW dbo.vw_Flights AS
SELECT
    FlightDate,
    CarrierCode,
    OriginAirport,
    DestinationAirport,
    ArrivalDelayMinutes,
    CAST(IsCancelled AS decimal(3,0)) AS IsCancelled,
    CAST(IsDiverted AS decimal(3,0)) AS IsDiverted,
    FlightNumber,
    ScheduledDepartureBlock,
    LateAircraftDelayMinutes,
    SecurityDelayMinutes,
    NasDelayMinutes,
    WeatherDelayMinutes,
    CarrierDelayMinutes,
    CASE
        WHEN ArrivalDelayMinutes IS NULL THEN NULL
        WHEN ArrivalDelayMinutes >= 15 THEN 1
        ELSE 0
    END AS IsArrivalDelayed15,
    CancellationCode,
    ScheduledDepartureTimeRaw,
    ScheduledDepartureTime
FROM dbo.FactFlights;

SELECT COUNT(*) AS FebruaryRawRecords
FROM dbo.RawFlights_2025_02;

SELECT
    COUNT(*) AS TotalRecords,

    SUM(CASE
        WHEN TRY_CONVERT(
            date, NULLIF(LTRIM(RTRIM(FlightDate)), ''), 23
        ) IS NULL THEN 1 ELSE 0
    END) AS MissingOrInvalidDates,

    MIN(TRY_CONVERT(date, FlightDate, 23)) AS FirstFlightDate,
    MAX(TRY_CONVERT(date, FlightDate, 23)) AS LastFlightDate,

    SUM(CASE
        WHEN CRSDepTime IS NULL
          OR LEN(LTRIM(RTRIM(CRSDepTime))) <> 4
          OR TRY_CONVERT(
              time(0),
              STUFF(LTRIM(RTRIM(CRSDepTime)), 3, 0, ':')
          ) IS NULL
        THEN 1 ELSE 0
    END) AS MissingOrInvalidDepartureTimes
FROM dbo.RawFlights_2025_02;

SELECT
    COUNT(*) AS TotalRecords,

    SUM(CASE
        WHEN NULLIF(LTRIM(RTRIM(ArrDelay)), '') IS NULL
        THEN 1 ELSE 0
    END) AS MissingArrivalDelayRecords,

    SUM(CASE
        WHEN NULLIF(LTRIM(RTRIM(ArrDelay)), '') IS NOT NULL
         AND TRY_CONVERT(decimal(10,2), ArrDelay) IS NULL
        THEN 1 ELSE 0
    END) AS InvalidArrivalDelayRecords,

    SUM(CASE
        WHEN TRY_CONVERT(decimal(3,0), Cancelled) = 1
        THEN 1 ELSE 0
    END) AS CancelledRecords,

    SUM(CASE
        WHEN TRY_CONVERT(decimal(3,0), Diverted) = 1
        THEN 1 ELSE 0
    END) AS DivertedRecords
FROM dbo.RawFlights_2025_02;

SELECT
    TRY_CONVERT(decimal(3,0), Cancelled) AS IsCancelled,
    TRY_CONVERT(decimal(3,0), Diverted) AS IsDiverted,
    COUNT(*) AS FlightRecords,
    SUM(CASE
        WHEN NULLIF(LTRIM(RTRIM(ArrDelay)), '') IS NULL
        THEN 1 ELSE 0
    END) AS MissingArrivalDelayRecords
FROM dbo.RawFlights_2025_02
GROUP BY
    TRY_CONVERT(decimal(3,0), Cancelled),
    TRY_CONVERT(decimal(3,0), Diverted);


    SELECT
    TRY_CONVERT(date, FlightDate, 23) AS FlightDate,
    Reporting_Airline,
    Flight_Number_Reporting_Airline,
    Origin,
    Dest,
    CRSDepTime,
    COUNT(*) AS RecordCount
FROM dbo.RawFlights_2025_02
GROUP BY
    TRY_CONVERT(date, FlightDate, 23),
    Reporting_Airline,
    Flight_Number_Reporting_Airline,
    Origin,
    Dest,
    CRSDepTime
HAVING COUNT(*) > 1
ORDER BY RecordCount DESC;




SELECT
    d.DelayField,
    SUM(CASE
        WHEN d.CleanValue IS NOT NULL
         AND TRY_CONVERT(decimal(10,2), d.CleanValue) IS NULL
        THEN 1 ELSE 0
    END) AS InvalidRecords,
    SUM(CASE
        WHEN TRY_CONVERT(decimal(10,2), d.CleanValue) < 0
        THEN 1 ELSE 0
    END) AS NegativeRecords,
    SUM(CASE
        WHEN TRY_CONVERT(
                 decimal(10,2),
                 NULLIF(LTRIM(RTRIM(r.ArrDelay)), '')
             ) >= 15
         AND d.CleanValue IS NULL
        THEN 1 ELSE 0
    END) AS MissingOnDelayedFlights
FROM dbo.RawFlights_2025_02 AS r
CROSS APPLY
(
    VALUES
        ('CarrierDelay',
         NULLIF(LTRIM(RTRIM(r.CarrierDelay)), '')),
        ('WeatherDelay',
         NULLIF(LTRIM(RTRIM(r.WeatherDelay)), '')),
        ('NASDelay',
         NULLIF(LTRIM(RTRIM(r.NASDelay)), '')),
        ('SecurityDelay',
         NULLIF(LTRIM(RTRIM(r.SecurityDelay)), '')),
        ('LateAircraftDelay',
         NULLIF(LTRIM(RTRIM(r.LateAircraftDelay)), ''))
) AS d(DelayField, CleanValue)
GROUP BY d.DelayField;




SELECT
    SUM(CASE
        WHEN NULLIF(LTRIM(RTRIM(Reporting_Airline)), '') IS NULL
          OR LEN(LTRIM(RTRIM(Reporting_Airline))) > 10
          OR NULLIF(LTRIM(RTRIM(Flight_Number_Reporting_Airline)), '') IS NULL
          OR LEN(LTRIM(RTRIM(Flight_Number_Reporting_Airline))) > 10
          OR NULLIF(LTRIM(RTRIM(Origin)), '') IS NULL
          OR LEN(LTRIM(RTRIM(Origin))) <> 3
          OR NULLIF(LTRIM(RTRIM(Dest)), '') IS NULL
          OR LEN(LTRIM(RTRIM(Dest))) <> 3
          OR NULLIF(LTRIM(RTRIM(DepTimeBlk)), '') IS NULL
          OR LEN(LTRIM(RTRIM(DepTimeBlk))) <> 9
        THEN 1 ELSE 0
    END) AS InvalidRequiredTextRecords,

    SUM(CASE
        WHEN TRY_CONVERT(
                 decimal(10,2),
                 NULLIF(LTRIM(RTRIM(Cancelled)), '')
             ) IS NULL
          OR TRY_CONVERT(decimal(10,2), Cancelled) NOT IN (0, 1)
          OR TRY_CONVERT(
                 decimal(10,2),
                 NULLIF(LTRIM(RTRIM(Diverted)), '')
             ) IS NULL
          OR TRY_CONVERT(decimal(10,2), Diverted) NOT IN (0, 1)
        THEN 1 ELSE 0
    END) AS InvalidStatusRecords,

    SUM(CASE
        WHEN NULLIF(LTRIM(RTRIM(CancellationCode)), '') IS NOT NULL
         AND LTRIM(RTRIM(CancellationCode)) NOT IN ('A', 'B', 'C', 'D')
        THEN 1 ELSE 0
    END) AS InvalidCancellationCodeRecords,

    SUM(CASE
        WHEN TRY_CONVERT(decimal(10,2), Cancelled) = 1
         AND NULLIF(LTRIM(RTRIM(CancellationCode)), '') IS NULL
        THEN 1 ELSE 0
    END) AS MissingCodeOnCancelledRecords
FROM dbo.RawFlights_2025_02;


SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF EXISTS (
        SELECT 1
        FROM dbo.FactFlights
        WHERE FlightDate >= '20250201'
          AND FlightDate <  '20250301'
    )
        THROW 50001, N'Şubat verisi hedef tabloda mevcut.', 1;

    INSERT INTO dbo.FactFlights
    (
        FlightDate,
        CarrierCode,
        FlightNumber,
        OriginAirport,
        DestinationAirport,
        ScheduledDepartureTimeRaw,
        ScheduledDepartureTime,
        ScheduledDepartureBlock,
        IsCancelled,
        IsDiverted,
        CancellationCode,
        ArrivalDelayMinutes,
        CarrierDelayMinutes,
        WeatherDelayMinutes,
        NasDelayMinutes,
        SecurityDelayMinutes,
        LateAircraftDelayMinutes
    )
    SELECT
        TRY_CONVERT(date, FlightDate, 23),
        LTRIM(RTRIM(Reporting_Airline)),
        LTRIM(RTRIM(Flight_Number_Reporting_Airline)),
        LTRIM(RTRIM(Origin)),
        LTRIM(RTRIM(Dest)),
        LTRIM(RTRIM(CRSDepTime)),
        TRY_CONVERT(
            time(0),
            STUFF(LTRIM(RTRIM(CRSDepTime)), 3, 0, ':')
        ),
        LTRIM(RTRIM(DepTimeBlk)),
        TRY_CONVERT(decimal(10,2), Cancelled),
        TRY_CONVERT(decimal(10,2), Diverted),
        NULLIF(LTRIM(RTRIM(CancellationCode)), ''),
        TRY_CONVERT(decimal(10,2),
            NULLIF(LTRIM(RTRIM(ArrDelay)), '')),
        TRY_CONVERT(decimal(10,2),
            NULLIF(LTRIM(RTRIM(CarrierDelay)), '')),
        TRY_CONVERT(decimal(10,2),
            NULLIF(LTRIM(RTRIM(WeatherDelay)), '')),
        TRY_CONVERT(decimal(10,2),
            NULLIF(LTRIM(RTRIM(NASDelay)), '')),
        TRY_CONVERT(decimal(10,2),
            NULLIF(LTRIM(RTRIM(SecurityDelay)), '')),
        TRY_CONVERT(decimal(10,2),
            NULLIF(LTRIM(RTRIM(LateAircraftDelay)), ''))
    FROM dbo.RawFlights_2025_02;

    IF @@ROWCOUNT <> 504884
        THROW 50002, N'Aktarılan kayıt sayısı beklenenle eşleşmedi.', 1;

   

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;


SELECT
    YEAR(FlightDate) AS FlightYear,
    MONTH(FlightDate) AS FlightMonth,
    COUNT(*) AS FlightRecords,
    SUM(CAST(IsCancelled AS int)) AS CancelledRecords,
    SUM(CAST(IsDiverted AS int)) AS DivertedRecords
FROM dbo.FactFlights
GROUP BY YEAR(FlightDate), MONTH(FlightDate)
ORDER BY FlightYear, FlightMonth;





SELECT COUNT(*) AS CauseMismatchRecords
FROM dbo.vw_Flights
WHERE CarrierCode = 'WN'
  AND OriginAirport = 'DEN'
  AND FlightDate >= '20250201'
  AND FlightDate < '20250301'
  AND IsArrivalDelayed15 = 1
  AND (
      ArrivalDelayMinutes <>
          CarrierDelayMinutes
        + LateAircraftDelayMinutes
        + NasDelayMinutes
        + WeatherDelayMinutes
        + SecurityDelayMinutes
      OR CarrierDelayMinutes IS NULL
      OR LateAircraftDelayMinutes IS NULL
      OR NasDelayMinutes IS NULL
      OR WeatherDelayMinutes IS NULL
      OR SecurityDelayMinutes IS NULL
  );