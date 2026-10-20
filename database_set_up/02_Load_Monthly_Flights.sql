/* AirlineAnalytics - Monthly CSV Loader v1.2 (English delivery copy)
   Change only @CsvPath, then execute the entire file in SSMS.
   Prerequisites: FactFlights, StagingFlights (110 columns), vw_Flights.
   Input: one official BTS PREZIP Reporting Carrier monthly CSV.
   SQL Server must have permission to read the file on the server filesystem.
   Existing months are rejected; this is append-only, not a revision workflow.
   Header/order, required fields, statuses, numbers, cause fields and duplicates
   are checked before insertion. Counts are reconciled before commit.
   Source 2400 is stored as 00:00:00 in the time column; raw 2400 and FlightDate
   are preserved. The time-only column is not a complete timestamp.
   Missing regular arrival delays remain NULL and produce a warning count.
   Negative arrival delays are valid. Cause-total differences are warnings.
   Staging is replaced; a failed transaction rolls back this run's changes.
   Do not run inside another transaction. Refresh Power BI after success.
*/
USE AirlineAnalytics;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- ONLY USER INPUT: paste the CSV path; surrounding double quotes are accepted:
DECLARE @CsvPath nvarchar(4000) = N'PASTE_FULL_CSV_PATH_HERE';

SET @CsvPath = LTRIM(RTRIM(@CsvPath));
IF LEFT(@CsvPath, 1) = N'"' AND RIGHT(@CsvPath, 1) = N'"'
    SET @CsvPath = SUBSTRING(@CsvPath, 2, LEN(@CsvPath)-2);

IF @@TRANCOUNT <> 0
    THROW 51000, 'Run outside an existing transaction.', 1;
IF @CsvPath IS NULL OR LOWER(RIGHT(@CsvPath,4)) <> N'.csv'
    THROW 51001, 'Enter a complete CSV path in @CsvPath.', 1;
IF OBJECT_ID(N'dbo.StagingFlights', N'U') IS NULL
   OR OBJECT_ID(N'dbo.FactFlights', N'U') IS NULL
    THROW 51002, 'Required database tables are missing.', 1;
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID(N'dbo.StagingFlights')) <> 110
    THROW 51003, 'StagingFlights must have 110 columns.', 1;

DECLARE @Command nvarchar(max), @LockResult int;
DECLARE @MonthStart date, @NextMonth date, @Rows bigint, @Inserted bigint;
DECLARE @CauseMismatch bigint, @MissingRegularArrival bigint;

BEGIN TRY
    BEGIN TRANSACTION;
    EXEC @LockResult = sys.sp_getapplock
        @Resource=N'AirlineAnalytics.MonthlyFlightsLoader',
        @LockMode=N'Exclusive', @LockOwner=N'Transaction', @LockTimeout=0;
    IF @LockResult < 0
        THROW 51004, 'Another monthly load is running. Try again later.', 1;

    DROP TABLE IF EXISTS #CsvHeader;
    SELECT TOP (0) * INTO #CsvHeader FROM dbo.StagingFlights;
    SET @Command=N'BULK INSERT #CsvHeader FROM N''' + REPLACE(@CsvPath,'''','''''') + N'''
        WITH (FORMAT=''CSV'', CODEPAGE=''65001'', FIRSTROW=1, LASTROW=1,
              FIELDQUOTE=''"'', FIELDTERMINATOR='','', ROWTERMINATOR=''0x0a'',
              KEEPNULLS, MAXERRORS=0);';
    EXEC sys.sp_executesql @Command;
    IF (SELECT COUNT(*) FROM #CsvHeader) <> 1
        THROW 51005, 'CSV header could not be read.', 1;
    IF EXISTS (
        SELECT 1 FROM #CsvHeader h
        CROSS APPLY (VALUES
            (1, N'Year', h.[Year]),
            (2, N'Quarter', h.[Quarter]),
            (3, N'Month', h.[Month]),
            (4, N'DayofMonth', h.[DayofMonth]),
            (5, N'DayOfWeek', h.[DayOfWeek]),
            (6, N'FlightDate', h.[FlightDate]),
            (7, N'Reporting_Airline', h.[Reporting_Airline]),
            (8, N'DOT_ID_Reporting_Airline', h.[DOT_ID_Reporting_Airline]),
            (9, N'IATA_CODE_Reporting_Airline', h.[IATA_CODE_Reporting_Airline]),
            (10, N'Tail_Number', h.[Tail_Number]),
            (11, N'Flight_Number_Reporting_Airline', h.[Flight_Number_Reporting_Airline]),
            (12, N'OriginAirportID', h.[OriginAirportID]),
            (13, N'OriginAirportSeqID', h.[OriginAirportSeqID]),
            (14, N'OriginCityMarketID', h.[OriginCityMarketID]),
            (15, N'Origin', h.[Origin]),
            (16, N'OriginCityName', h.[OriginCityName]),
            (17, N'OriginState', h.[OriginState]),
            (18, N'OriginStateFips', h.[OriginStateFips]),
            (19, N'OriginStateName', h.[OriginStateName]),
            (20, N'OriginWac', h.[OriginWac]),
            (21, N'DestAirportID', h.[DestAirportID]),
            (22, N'DestAirportSeqID', h.[DestAirportSeqID]),
            (23, N'DestCityMarketID', h.[DestCityMarketID]),
            (24, N'Dest', h.[Dest]),
            (25, N'DestCityName', h.[DestCityName]),
            (26, N'DestState', h.[DestState]),
            (27, N'DestStateFips', h.[DestStateFips]),
            (28, N'DestStateName', h.[DestStateName]),
            (29, N'DestWac', h.[DestWac]),
            (30, N'CRSDepTime', h.[CRSDepTime]),
            (31, N'DepTime', h.[DepTime]),
            (32, N'DepDelay', h.[DepDelay]),
            (33, N'DepDelayMinutes', h.[DepDelayMinutes]),
            (34, N'DepDel15', h.[DepDel15]),
            (35, N'DepartureDelayGroups', h.[DepartureDelayGroups]),
            (36, N'DepTimeBlk', h.[DepTimeBlk]),
            (37, N'TaxiOut', h.[TaxiOut]),
            (38, N'WheelsOff', h.[WheelsOff]),
            (39, N'WheelsOn', h.[WheelsOn]),
            (40, N'TaxiIn', h.[TaxiIn]),
            (41, N'CRSArrTime', h.[CRSArrTime]),
            (42, N'ArrTime', h.[ArrTime]),
            (43, N'ArrDelay', h.[ArrDelay]),
            (44, N'ArrDelayMinutes', h.[ArrDelayMinutes]),
            (45, N'ArrDel15', h.[ArrDel15]),
            (46, N'ArrivalDelayGroups', h.[ArrivalDelayGroups]),
            (47, N'ArrTimeBlk', h.[ArrTimeBlk]),
            (48, N'Cancelled', h.[Cancelled]),
            (49, N'CancellationCode', h.[CancellationCode]),
            (50, N'Diverted', h.[Diverted]),
            (51, N'CRSElapsedTime', h.[CRSElapsedTime]),
            (52, N'ActualElapsedTime', h.[ActualElapsedTime]),
            (53, N'AirTime', h.[AirTime]),
            (54, N'Flights', h.[Flights]),
            (55, N'Distance', h.[Distance]),
            (56, N'DistanceGroup', h.[DistanceGroup]),
            (57, N'CarrierDelay', h.[CarrierDelay]),
            (58, N'WeatherDelay', h.[WeatherDelay]),
            (59, N'NASDelay', h.[NASDelay]),
            (60, N'SecurityDelay', h.[SecurityDelay]),
            (61, N'LateAircraftDelay', h.[LateAircraftDelay]),
            (62, N'FirstDepTime', h.[FirstDepTime]),
            (63, N'TotalAddGTime', h.[TotalAddGTime]),
            (64, N'LongestAddGTime', h.[LongestAddGTime]),
            (65, N'DivAirportLandings', h.[DivAirportLandings]),
            (66, N'DivReachedDest', h.[DivReachedDest]),
            (67, N'DivActualElapsedTime', h.[DivActualElapsedTime]),
            (68, N'DivArrDelay', h.[DivArrDelay]),
            (69, N'DivDistance', h.[DivDistance]),
            (70, N'Div1Airport', h.[Div1Airport]),
            (71, N'Div1AirportID', h.[Div1AirportID]),
            (72, N'Div1AirportSeqID', h.[Div1AirportSeqID]),
            (73, N'Div1WheelsOn', h.[Div1WheelsOn]),
            (74, N'Div1TotalGTime', h.[Div1TotalGTime]),
            (75, N'Div1LongestGTime', h.[Div1LongestGTime]),
            (76, N'Div1WheelsOff', h.[Div1WheelsOff]),
            (77, N'Div1TailNum', h.[Div1TailNum]),
            (78, N'Div2Airport', h.[Div2Airport]),
            (79, N'Div2AirportID', h.[Div2AirportID]),
            (80, N'Div2AirportSeqID', h.[Div2AirportSeqID]),
            (81, N'Div2WheelsOn', h.[Div2WheelsOn]),
            (82, N'Div2TotalGTime', h.[Div2TotalGTime]),
            (83, N'Div2LongestGTime', h.[Div2LongestGTime]),
            (84, N'Div2WheelsOff', h.[Div2WheelsOff]),
            (85, N'Div2TailNum', h.[Div2TailNum]),
            (86, N'Div3Airport', h.[Div3Airport]),
            (87, N'Div3AirportID', h.[Div3AirportID]),
            (88, N'Div3AirportSeqID', h.[Div3AirportSeqID]),
            (89, N'Div3WheelsOn', h.[Div3WheelsOn]),
            (90, N'Div3TotalGTime', h.[Div3TotalGTime]),
            (91, N'Div3LongestGTime', h.[Div3LongestGTime]),
            (92, N'Div3WheelsOff', h.[Div3WheelsOff]),
            (93, N'Div3TailNum', h.[Div3TailNum]),
            (94, N'Div4Airport', h.[Div4Airport]),
            (95, N'Div4AirportID', h.[Div4AirportID]),
            (96, N'Div4AirportSeqID', h.[Div4AirportSeqID]),
            (97, N'Div4WheelsOn', h.[Div4WheelsOn]),
            (98, N'Div4TotalGTime', h.[Div4TotalGTime]),
            (99, N'Div4LongestGTime', h.[Div4LongestGTime]),
            (100, N'Div4WheelsOff', h.[Div4WheelsOff]),
            (101, N'Div4TailNum', h.[Div4TailNum]),
            (102, N'Div5Airport', h.[Div5Airport]),
            (103, N'Div5AirportID', h.[Div5AirportID]),
            (104, N'Div5AirportSeqID', h.[Div5AirportSeqID]),
            (105, N'Div5WheelsOn', h.[Div5WheelsOn]),
            (106, N'Div5TotalGTime', h.[Div5TotalGTime]),
            (107, N'Div5LongestGTime', h.[Div5LongestGTime]),
            (108, N'Div5WheelsOff', h.[Div5WheelsOff]),
            (109, N'Div5TailNum', h.[Div5TailNum]),
            (110, N'', h.[column110])
        ) v(Position, ExpectedHeader, ActualHeader)
        WHERE REPLACE(REPLACE(REPLACE(COALESCE(v.ActualHeader,N''),
                  NCHAR(65279),N''),CHAR(13),N''),CHAR(10),N'')
                  COLLATE Latin1_General_100_BIN2
              <> v.ExpectedHeader COLLATE Latin1_General_100_BIN2
    )
        THROW 51006, 'CSV column headers/order do not match the approved BTS schema.', 1;

    TRUNCATE TABLE dbo.StagingFlights;
    SET @Command=N'BULK INSERT dbo.StagingFlights FROM N''' + REPLACE(@CsvPath,'''','''''') + N'''
        WITH (FORMAT=''CSV'', CODEPAGE=''65001'', FIRSTROW=2,
              FIELDQUOTE=''"'', FIELDTERMINATOR='','', ROWTERMINATOR=''0x0a'',
              KEEPNULLS, MAXERRORS=0);';
    EXEC sys.sp_executesql @Command;

    DROP TABLE IF EXISTS #CleanFlights;
    SELECT
        TRY_CONVERT(date, NULLIF(LTRIM(RTRIM([FlightDate])), N''), 23) AS [FlightDate],
        NULLIF(LTRIM(RTRIM([Reporting_Airline])), N'') AS [CarrierCode],
        NULLIF(LTRIM(RTRIM([Flight_Number_Reporting_Airline])), N'') AS [FlightNumber],
        NULLIF(LTRIM(RTRIM([Origin])), N'') AS [OriginAirport],
        NULLIF(LTRIM(RTRIM([Dest])), N'') AS [DestinationAirport],
        NULLIF(LTRIM(RTRIM([CRSDepTime])), N'') AS [ScheduledDepartureTimeRaw],
        NULLIF(LTRIM(RTRIM([DepTimeBlk])), N'') AS [ScheduledDepartureBlock],
        NULLIF(LTRIM(RTRIM([CancellationCode])), N'') AS [CancellationCode],
        NULLIF(LTRIM(RTRIM([Cancelled])), N'') AS [IsCancelledRaw],
        TRY_CONVERT(decimal(10,2), NULLIF(LTRIM(RTRIM([Cancelled])), N'')) AS [IsCancelled],
        NULLIF(LTRIM(RTRIM([Diverted])), N'') AS [IsDivertedRaw],
        TRY_CONVERT(decimal(10,2), NULLIF(LTRIM(RTRIM([Diverted])), N'')) AS [IsDiverted],
        NULLIF(LTRIM(RTRIM([ArrDelay])), N'') AS [ArrivalDelayMinutesRaw],
        TRY_CONVERT(decimal(10,2), NULLIF(LTRIM(RTRIM([ArrDelay])), N'')) AS [ArrivalDelayMinutes],
        NULLIF(LTRIM(RTRIM([CarrierDelay])), N'') AS [CarrierDelayMinutesRaw],
        TRY_CONVERT(decimal(10,2), NULLIF(LTRIM(RTRIM([CarrierDelay])), N'')) AS [CarrierDelayMinutes],
        NULLIF(LTRIM(RTRIM([WeatherDelay])), N'') AS [WeatherDelayMinutesRaw],
        TRY_CONVERT(decimal(10,2), NULLIF(LTRIM(RTRIM([WeatherDelay])), N'')) AS [WeatherDelayMinutes],
        NULLIF(LTRIM(RTRIM([NASDelay])), N'') AS [NasDelayMinutesRaw],
        TRY_CONVERT(decimal(10,2), NULLIF(LTRIM(RTRIM([NASDelay])), N'')) AS [NasDelayMinutes],
        NULLIF(LTRIM(RTRIM([SecurityDelay])), N'') AS [SecurityDelayMinutesRaw],
        TRY_CONVERT(decimal(10,2), NULLIF(LTRIM(RTRIM([SecurityDelay])), N'')) AS [SecurityDelayMinutes],
        NULLIF(LTRIM(RTRIM([LateAircraftDelay])), N'') AS [LateAircraftDelayMinutesRaw],
        TRY_CONVERT(decimal(10,2), NULLIF(LTRIM(RTRIM([LateAircraftDelay])), N'')) AS [LateAircraftDelayMinutes],
        CASE WHEN NULLIF(LTRIM(RTRIM([CRSDepTime])), N'') = N'2400'
             THEN CONVERT(time(0), '00:00:00')
             ELSE TRY_CONVERT(time(0), STUFF(NULLIF(LTRIM(RTRIM([CRSDepTime])), N''), 3, 0, ':'))
        END AS ScheduledDepartureTime
    INTO #CleanFlights
    FROM dbo.StagingFlights;

    SELECT @Rows=COUNT_BIG(*),
           @MonthStart=DATEFROMPARTS(YEAR(MIN(FlightDate)),MONTH(MIN(FlightDate)),1)
    FROM #CleanFlights;
    IF @Rows=0
        THROW 51007, 'CSV contains no flight records.', 1;
    SET @NextMonth=DATEADD(month,1,@MonthStart);
    IF EXISTS (SELECT 1 FROM #CleanFlights WHERE FlightDate IS NULL
               OR FlightDate < @MonthStart OR FlightDate >= @NextMonth)
        THROW 51008, 'Invalid dates or more than one month in CSV.', 1;

    IF EXISTS (SELECT 1 FROM #CleanFlights WHERE
        CarrierCode IS NULL OR LEN(CarrierCode)>10
        OR FlightNumber IS NULL OR LEN(FlightNumber)>10
        OR OriginAirport IS NULL OR LEN(OriginAirport)<>3
        OR DestinationAirport IS NULL OR LEN(DestinationAirport)<>3
        OR ScheduledDepartureTimeRaw IS NULL OR LEN(ScheduledDepartureTimeRaw)<>4
        OR ScheduledDepartureTimeRaw LIKE '%[^0-9]%'
        OR ScheduledDepartureTime IS NULL
        OR ScheduledDepartureBlock IS NULL OR LEN(ScheduledDepartureBlock)<>9
        OR LEFT(ScheduledDepartureBlock,4) LIKE '%[^0-9]%'
        OR RIGHT(ScheduledDepartureBlock,4) LIKE '%[^0-9]%'
        OR SUBSTRING(ScheduledDepartureBlock,5,1)<>'-'
        OR TRY_CONVERT(time(0),STUFF(LEFT(ScheduledDepartureBlock,4),3,0,':')) IS NULL
        OR TRY_CONVERT(time(0),STUFF(RIGHT(ScheduledDepartureBlock,4),3,0,':')) IS NULL
    ) THROW 51009, 'Invalid required flight fields or scheduled times.', 1;

    IF EXISTS (SELECT 1 FROM #CleanFlights WHERE
        IsCancelled IS NULL OR IsCancelled NOT IN (0,1)
        OR IsDiverted IS NULL OR IsDiverted NOT IN (0,1)
        OR (IsCancelled=1 AND IsDiverted=1)
        OR ([IsCancelledRaw] IS NOT NULL AND [IsCancelled] IS NULL)
            OR ([IsDivertedRaw] IS NOT NULL AND [IsDiverted] IS NULL)
            OR ([ArrivalDelayMinutesRaw] IS NOT NULL AND [ArrivalDelayMinutes] IS NULL)
            OR ([CarrierDelayMinutesRaw] IS NOT NULL AND [CarrierDelayMinutes] IS NULL)
            OR ([WeatherDelayMinutesRaw] IS NOT NULL AND [WeatherDelayMinutes] IS NULL)
            OR ([NasDelayMinutesRaw] IS NOT NULL AND [NasDelayMinutes] IS NULL)
            OR ([SecurityDelayMinutesRaw] IS NOT NULL AND [SecurityDelayMinutes] IS NULL)
            OR ([LateAircraftDelayMinutesRaw] IS NOT NULL AND [LateAircraftDelayMinutes] IS NULL)
    ) THROW 51010, 'Invalid status or nonnumeric delay field.', 1;

    IF EXISTS (SELECT 1 FROM #CleanFlights WHERE
        (CancellationCode IS NOT NULL AND CancellationCode NOT IN ('A','B','C','D'))
        OR (IsCancelled=1 AND CancellationCode IS NULL)
        OR (IsCancelled=0 AND CancellationCode IS NOT NULL)
    ) THROW 51011, 'Invalid or missing cancellation code.', 1;

    IF EXISTS (SELECT 1 FROM #CleanFlights WHERE [CarrierDelayMinutes] < 0 OR (ArrivalDelayMinutes >= 15 AND [CarrierDelayMinutes] IS NULL)
            OR [WeatherDelayMinutes] < 0 OR (ArrivalDelayMinutes >= 15 AND [WeatherDelayMinutes] IS NULL)
            OR [NasDelayMinutes] < 0 OR (ArrivalDelayMinutes >= 15 AND [NasDelayMinutes] IS NULL)
            OR [SecurityDelayMinutes] < 0 OR (ArrivalDelayMinutes >= 15 AND [SecurityDelayMinutes] IS NULL)
            OR [LateAircraftDelayMinutes] < 0 OR (ArrivalDelayMinutes >= 15 AND [LateAircraftDelayMinutes] IS NULL))
        THROW 51012, 'Negative cause minutes or missing cause on delayed flights.', 1;

    IF EXISTS (SELECT 1 FROM #CleanFlights
        GROUP BY FlightDate,CarrierCode,FlightNumber,OriginAirport,
                 DestinationAirport,ScheduledDepartureTimeRaw
        HAVING COUNT_BIG(*)>1)
        THROW 51013, 'Duplicate flight keys in CSV.', 1;

    IF EXISTS (SELECT 1 FROM dbo.FactFlights WITH (UPDLOCK,HOLDLOCK)
               WHERE FlightDate>=@MonthStart AND FlightDate<@NextMonth)
        THROW 51014, 'Month already loaded. No records added; automatic revision is disabled.', 1;

    SELECT @MissingRegularArrival=COUNT_BIG(*) FROM #CleanFlights
    WHERE IsCancelled=0 AND IsDiverted=0 AND ArrivalDelayMinutes IS NULL;

    SELECT @CauseMismatch=COUNT_BIG(*) FROM #CleanFlights
    WHERE ArrivalDelayMinutes>=15 AND ArrivalDelayMinutes <>
        CarrierDelayMinutes+WeatherDelayMinutes+NasDelayMinutes+
        SecurityDelayMinutes+LateAircraftDelayMinutes;

    INSERT INTO dbo.FactFlights ([FlightDate], [CarrierCode], [FlightNumber], [OriginAirport], [DestinationAirport], [ScheduledDepartureTimeRaw], [ScheduledDepartureBlock], [CancellationCode], [ScheduledDepartureTime], [IsCancelled], [IsDiverted], [ArrivalDelayMinutes], [CarrierDelayMinutes], [WeatherDelayMinutes], [NasDelayMinutes], [SecurityDelayMinutes], [LateAircraftDelayMinutes])
    SELECT [FlightDate], [CarrierCode], [FlightNumber], [OriginAirport], [DestinationAirport], [ScheduledDepartureTimeRaw], [ScheduledDepartureBlock], [CancellationCode], [ScheduledDepartureTime], [IsCancelled], [IsDiverted], [ArrivalDelayMinutes], [CarrierDelayMinutes], [WeatherDelayMinutes], [NasDelayMinutes], [SecurityDelayMinutes], [LateAircraftDelayMinutes] FROM #CleanFlights;
    SET @Inserted=ROWCOUNT_BIG();
    IF @Inserted<>@Rows
        THROW 51015, 'Source and inserted row counts differ.', 1;
    IF (SELECT COUNT_BIG(*) FROM dbo.FactFlights
        WHERE FlightDate>=@MonthStart AND FlightDate<@NextMonth)<>@Rows
        THROW 51016, 'Target monthly row count differs.', 1;

    COMMIT TRANSACTION;

    SELECT N'SUCCESS - Refresh Power BI' AS LoadStatus,
           @MonthStart AS LoadedMonth,@Rows AS SourceRecords,@Inserted AS InsertedRecords,
           @CauseMismatch AS ReportedCauseMismatchRecords,
           @MissingRegularArrival AS MissingRegularArrivalRecords,
           (SELECT COUNT_BIG(*) FROM dbo.FactFlights) AS TotalFlightRecords;
    SELECT YEAR(FlightDate) AS FlightYear,MONTH(FlightDate) AS FlightMonth,
           COUNT_BIG(*) AS FlightRecords,
           SUM(CONVERT(bigint,IsCancelled)) AS CancelledRecords,
           SUM(CONVERT(bigint,IsDiverted)) AS DivertedRecords,
           COUNT_BIG(*)-COUNT_BIG(ArrivalDelayMinutes) AS MissingArrivalDelayRecords
    FROM dbo.FactFlights
    GROUP BY YEAR(FlightDate),MONTH(FlightDate)
    ORDER BY FlightYear,FlightMonth;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
    SELECT N'FAILED - No load committed' AS LoadStatus,
           ERROR_NUMBER() AS ErrorNumber,ERROR_MESSAGE() AS ErrorMessage;
    THROW;
END CATCH;
