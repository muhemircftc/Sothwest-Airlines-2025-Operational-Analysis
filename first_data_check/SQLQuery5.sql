USE AirlineAnalytics;
GO

CREATE OR ALTER PROCEDURE dbo.usp_LoadFlightsMonth
    @MonthStart date
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @MonthStart IS NULL OR DAY(@MonthStart) <> 1
        THROW 50001, 'MonthStart must be the first day of the month.', 1;

    DECLARE @NextMonth date = DATEADD(month, 1, @MonthStart);
    DECLARE @SourceRecords bigint;
    DECLARE @InsertedRecords bigint;

    SELECT @SourceRecords = COUNT_BIG(*)
    FROM dbo.StagingFlights;

    IF @SourceRecords = 0
        THROW 50002, 'StagingFlights is empty.', 1;

    IF EXISTS (
        SELECT 1
        FROM dbo.StagingFlights
        WHERE TRY_CONVERT(date, FlightDate, 23) IS NULL
           OR TRY_CONVERT(date, FlightDate, 23) < @MonthStart
           OR TRY_CONVERT(date, FlightDate, 23) >= @NextMonth
    )
        THROW 50003, 'Staging contains invalid dates or another month.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (
            SELECT 1
            FROM dbo.FactFlights
            WHERE FlightDate >= @MonthStart
              AND FlightDate < @NextMonth
        )
            THROW 50004, 'This month already exists in FactFlights.', 1;

        INSERT INTO dbo.FactFlights (
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

            NULLIF(LTRIM(RTRIM(Reporting_Airline)), ''),
            NULLIF(LTRIM(RTRIM(Flight_Number_Reporting_Airline)), ''),
            NULLIF(LTRIM(RTRIM(Origin)), ''),
            NULLIF(LTRIM(RTRIM(Dest)), ''),

            NULLIF(LTRIM(RTRIM(CRSDepTime)), ''),

            TRY_CONVERT(
                time(0),
                STUFF(
                    NULLIF(LTRIM(RTRIM(CRSDepTime)), ''),
                    3, 0, ':'
                )
            ),

            NULLIF(LTRIM(RTRIM(DepTimeBlk)), ''),

            TRY_CONVERT(
                decimal(3,0),
                NULLIF(LTRIM(RTRIM(Cancelled)), '')
            ),

            TRY_CONVERT(
                decimal(3,0),
                NULLIF(LTRIM(RTRIM(Diverted)), '')
            ),

            NULLIF(LTRIM(RTRIM(CancellationCode)), ''),

            TRY_CONVERT(
                decimal(10,2),
                NULLIF(LTRIM(RTRIM(ArrDelay)), '')
            ),

            TRY_CONVERT(
                decimal(10,2),
                NULLIF(LTRIM(RTRIM(CarrierDelay)), '')
            ),

            TRY_CONVERT(
                decimal(10,2),
                NULLIF(LTRIM(RTRIM(WeatherDelay)), '')
            ),

            TRY_CONVERT(
                decimal(10,2),
                NULLIF(LTRIM(RTRIM(NASDelay)), '')
            ),

            TRY_CONVERT(
                decimal(10,2),
                NULLIF(LTRIM(RTRIM(SecurityDelay)), '')
            ),

            TRY_CONVERT(
                decimal(10,2),
                NULLIF(LTRIM(RTRIM(LateAircraftDelay)), '')
            )
        FROM dbo.StagingFlights;

        SET @InsertedRecords = @@ROWCOUNT;

        IF @InsertedRecords <> @SourceRecords
            THROW 50005, 'Source and inserted record counts do not match.', 1;

        COMMIT TRANSACTION;

        SELECT
            @MonthStart AS LoadedMonth,
            @SourceRecords AS SourceRecords,
            @InsertedRecords AS InsertedRecords;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO


EXEC dbo.usp_LoadFlightsMonth
    @MonthStart = '20250301';




SELECT
    YEAR(FlightDate) AS FlightYear,
    MONTH(FlightDate) AS FlightMonth,
    COUNT(*) AS FlightRecords
FROM dbo.FactFlights
GROUP BY
    YEAR(FlightDate),
    MONTH(FlightDate)
ORDER BY FlightYear, FlightMonth;

SELECT COUNT(*) AS TotalFlightRecords
FROM dbo.FactFlights;