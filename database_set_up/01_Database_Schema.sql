-- Initial schema installation only. Run after 00_Create_Database.sql.
-- Do not rerun against an already configured database. No data is included.
USE [AirlineAnalytics]
GO
/****** Object:  Table [dbo].[FactFlights]    Script Date: 17.10.2026 15:11:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FactFlights](
	[FlightRecordID] [bigint] IDENTITY(1,1) NOT NULL,
	[FlightDate] [date] NOT NULL,
	[CarrierCode] [varchar](10) NOT NULL,
	[FlightNumber] [varchar](10) NOT NULL,
	[OriginAirport] [varchar](3) NOT NULL,
	[DestinationAirport] [varchar](3) NOT NULL,
	[ScheduledDepartureTimeRaw] [varchar](4) NOT NULL,
	[ScheduledDepartureTime] [time](0) NOT NULL,
	[ScheduledDepartureBlock] [varchar](9) NOT NULL,
	[IsCancelled] [bit] NOT NULL,
	[IsDiverted] [bit] NOT NULL,
	[CancellationCode] [varchar](1) NULL,
	[ArrivalDelayMinutes] [decimal](10, 2) NULL,
	[CarrierDelayMinutes] [decimal](10, 2) NULL,
	[WeatherDelayMinutes] [decimal](10, 2) NULL,
	[NasDelayMinutes] [decimal](10, 2) NULL,
	[SecurityDelayMinutes] [decimal](10, 2) NULL,
	[LateAircraftDelayMinutes] [decimal](10, 2) NULL,
 CONSTRAINT [PK_FactFlights] PRIMARY KEY CLUSTERED 
(
	[FlightRecordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_FactFlights_Flight] UNIQUE NONCLUSTERED 
(
	[FlightDate] ASC,
	[CarrierCode] ASC,
	[FlightNumber] ASC,
	[OriginAirport] ASC,
	[DestinationAirport] ASC,
	[ScheduledDepartureTimeRaw] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[vw_Flights]    Script Date: 17.10.2026 15:11:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[vw_Flights] AS
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
GO
/****** Object:  Table [dbo].[StagingFlights]    Script Date: 17.10.2026 15:11:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StagingFlights](
	[Year] [nvarchar](255) NULL,
	[Quarter] [nvarchar](255) NULL,
	[Month] [nvarchar](255) NULL,
	[DayofMonth] [nvarchar](255) NULL,
	[DayOfWeek] [nvarchar](255) NULL,
	[FlightDate] [nvarchar](255) NULL,
	[Reporting_Airline] [nvarchar](255) NULL,
	[DOT_ID_Reporting_Airline] [nvarchar](255) NULL,
	[IATA_CODE_Reporting_Airline] [nvarchar](255) NULL,
	[Tail_Number] [nvarchar](255) NULL,
	[Flight_Number_Reporting_Airline] [nvarchar](255) NULL,
	[OriginAirportID] [nvarchar](255) NULL,
	[OriginAirportSeqID] [nvarchar](255) NULL,
	[OriginCityMarketID] [nvarchar](255) NULL,
	[Origin] [nvarchar](255) NULL,
	[OriginCityName] [nvarchar](255) NULL,
	[OriginState] [nvarchar](255) NULL,
	[OriginStateFips] [nvarchar](255) NULL,
	[OriginStateName] [nvarchar](255) NULL,
	[OriginWac] [nvarchar](255) NULL,
	[DestAirportID] [nvarchar](255) NULL,
	[DestAirportSeqID] [nvarchar](255) NULL,
	[DestCityMarketID] [nvarchar](255) NULL,
	[Dest] [nvarchar](255) NULL,
	[DestCityName] [nvarchar](255) NULL,
	[DestState] [nvarchar](255) NULL,
	[DestStateFips] [nvarchar](255) NULL,
	[DestStateName] [nvarchar](255) NULL,
	[DestWac] [nvarchar](255) NULL,
	[CRSDepTime] [nvarchar](255) NULL,
	[DepTime] [nvarchar](255) NULL,
	[DepDelay] [nvarchar](255) NULL,
	[DepDelayMinutes] [nvarchar](255) NULL,
	[DepDel15] [nvarchar](255) NULL,
	[DepartureDelayGroups] [nvarchar](255) NULL,
	[DepTimeBlk] [nvarchar](255) NULL,
	[TaxiOut] [nvarchar](255) NULL,
	[WheelsOff] [nvarchar](255) NULL,
	[WheelsOn] [nvarchar](255) NULL,
	[TaxiIn] [nvarchar](255) NULL,
	[CRSArrTime] [nvarchar](255) NULL,
	[ArrTime] [nvarchar](255) NULL,
	[ArrDelay] [nvarchar](255) NULL,
	[ArrDelayMinutes] [nvarchar](255) NULL,
	[ArrDel15] [nvarchar](255) NULL,
	[ArrivalDelayGroups] [nvarchar](255) NULL,
	[ArrTimeBlk] [nvarchar](255) NULL,
	[Cancelled] [nvarchar](255) NULL,
	[CancellationCode] [nvarchar](255) NULL,
	[Diverted] [nvarchar](255) NULL,
	[CRSElapsedTime] [nvarchar](255) NULL,
	[ActualElapsedTime] [nvarchar](255) NULL,
	[AirTime] [nvarchar](255) NULL,
	[Flights] [nvarchar](255) NULL,
	[Distance] [nvarchar](255) NULL,
	[DistanceGroup] [nvarchar](255) NULL,
	[CarrierDelay] [nvarchar](255) NULL,
	[WeatherDelay] [nvarchar](255) NULL,
	[NASDelay] [nvarchar](255) NULL,
	[SecurityDelay] [nvarchar](255) NULL,
	[LateAircraftDelay] [nvarchar](255) NULL,
	[FirstDepTime] [nvarchar](255) NULL,
	[TotalAddGTime] [nvarchar](255) NULL,
	[LongestAddGTime] [nvarchar](255) NULL,
	[DivAirportLandings] [nvarchar](255) NULL,
	[DivReachedDest] [nvarchar](255) NULL,
	[DivActualElapsedTime] [nvarchar](255) NULL,
	[DivArrDelay] [nvarchar](255) NULL,
	[DivDistance] [nvarchar](255) NULL,
	[Div1Airport] [nvarchar](255) NULL,
	[Div1AirportID] [nvarchar](255) NULL,
	[Div1AirportSeqID] [nvarchar](255) NULL,
	[Div1WheelsOn] [nvarchar](255) NULL,
	[Div1TotalGTime] [nvarchar](255) NULL,
	[Div1LongestGTime] [nvarchar](255) NULL,
	[Div1WheelsOff] [nvarchar](255) NULL,
	[Div1TailNum] [nvarchar](255) NULL,
	[Div2Airport] [nvarchar](255) NULL,
	[Div2AirportID] [nvarchar](255) NULL,
	[Div2AirportSeqID] [nvarchar](255) NULL,
	[Div2WheelsOn] [nvarchar](255) NULL,
	[Div2TotalGTime] [nvarchar](255) NULL,
	[Div2LongestGTime] [nvarchar](255) NULL,
	[Div2WheelsOff] [nvarchar](255) NULL,
	[Div2TailNum] [nvarchar](255) NULL,
	[Div3Airport] [nvarchar](255) NULL,
	[Div3AirportID] [nvarchar](255) NULL,
	[Div3AirportSeqID] [nvarchar](255) NULL,
	[Div3WheelsOn] [nvarchar](255) NULL,
	[Div3TotalGTime] [nvarchar](255) NULL,
	[Div3LongestGTime] [nvarchar](255) NULL,
	[Div3WheelsOff] [nvarchar](255) NULL,
	[Div3TailNum] [nvarchar](255) NULL,
	[Div4Airport] [nvarchar](255) NULL,
	[Div4AirportID] [nvarchar](255) NULL,
	[Div4AirportSeqID] [nvarchar](255) NULL,
	[Div4WheelsOn] [nvarchar](255) NULL,
	[Div4TotalGTime] [nvarchar](255) NULL,
	[Div4LongestGTime] [nvarchar](255) NULL,
	[Div4WheelsOff] [nvarchar](255) NULL,
	[Div4TailNum] [nvarchar](255) NULL,
	[Div5Airport] [nvarchar](255) NULL,
	[Div5AirportID] [nvarchar](255) NULL,
	[Div5AirportSeqID] [nvarchar](255) NULL,
	[Div5WheelsOn] [nvarchar](255) NULL,
	[Div5TotalGTime] [nvarchar](255) NULL,
	[Div5LongestGTime] [nvarchar](255) NULL,
	[Div5WheelsOff] [nvarchar](255) NULL,
	[Div5TailNum] [nvarchar](255) NULL,
	[column110] [nvarchar](255) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FactFlights]  WITH CHECK ADD  CONSTRAINT [CK_FactFlights_CancellationCode] CHECK  (([CancellationCode] IS NULL OR ([CancellationCode]='D' OR [CancellationCode]='C' OR [CancellationCode]='B' OR [CancellationCode]='A')))
GO
ALTER TABLE [dbo].[FactFlights] CHECK CONSTRAINT [CK_FactFlights_CancellationCode]
GO
