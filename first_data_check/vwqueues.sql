use AirlineAnalytics


CREATE VIEW dbo.vw_Flights AS
SELECT
    TRY_CONVERT(date, FL_DATE, 101) AS FlightDate,
    OP_UNIQUE_CARRIER AS CarrierCode,
    ORIGIN AS OriginAirport,
    DEST AS DestinationAirport,
    TRY_CONVERT(decimal(10,2), ARR_DELAY) AS ArrivalDelayMinutes
FROM dbo.RawFlights_2025_01;

SELECT TOP 10 *
FROM dbo.vw_Flights;

ALTER VIEW dbo.vw_Flights AS
SELECT
    TRY_CONVERT(date, FL_DATE, 101) AS FlightDate,
    OP_UNIQUE_CARRIER AS CarrierCode,
    ORIGIN AS OriginAirport,
    DEST AS DestinationAirport,
    TRY_CONVERT(decimal(10,2), ARR_DELAY) AS ArrivalDelayMinutes,
    TRY_CONVERT(decimal(3,0), CANCELLED) AS IsCancelled,
    TRY_CONVERT(decimal(3,0), DIVERTED) AS IsDiverted
FROM dbo.RawFlights_2025_01;

SELECT
    IsCancelled,
    IsDiverted,
    COUNT(*) AS FlightRecordCount
FROM dbo.vw_Flights
GROUP BY IsCancelled, IsDiverted

ALTER VIEW dbo.vw_Flights AS
SELECT
    TRY_CONVERT(date, FL_DATE, 101) AS FlightDate,
    OP_UNIQUE_CARRIER AS CarrierCode,
    ORIGIN AS OriginAirport,
    DEST AS DestinationAirport,
    TRY_CONVERT(decimal(10,2), ARR_DELAY) AS ArrivalDelayMinutes,
    TRY_CONVERT(decimal(3,0), CANCELLED) AS IsCancelled,
    TRY_CONVERT(decimal(3,0), DIVERTED) AS IsDiverted,
    OP_CARRIER_FL_NUM AS FlightNumber,
    DEP_TIME_BLK AS	ScheduledDepartureBlock,
    TRY_CONVERT(decimal(10,2), LATE_AIRCRAFT_DELAY) as LateAircraftDelayMinutes,
    TRY_CONVERT(decimal(10,2), SECURITY_DELAY) as SecurityDelayMinutes,
    TRY_CONVERT(decimal(10,2), NAS_DELAY) as NasDelayMinutes,
    TRY_CONVERT(decimal(10,2), WEATHER_DELAY) as WeatherDelayMinutes,
    TRY_CONVERT(decimal(10,2), CARRIER_DELAY) as CarrierDelayMinutes
FROM dbo.RawFlights_2025_01;


select count(*)
,SUM(ArrivalDelayMinutes)
,SUM(LateAircraftDelayMinutes)
,SUM(SecurityDelayMinutes)
,SUM(NasDelayMinutes)
,SUM(WeatherDelayMinutes)
,SUM(CarrierDelayMinutes)
from vw_Flights
where ArrivalDelayMinutes >= 15
AND
CarrierCode = 'WN'
AND
OriginAirport = 'DEN'

ALTER VIEW dbo.vw_Flights AS
SELECT
    TRY_CONVERT(date, FL_DATE, 101) AS FlightDate,
    OP_UNIQUE_CARRIER AS CarrierCode,
    ORIGIN AS OriginAirport,
    DEST AS DestinationAirport,
    TRY_CONVERT(decimal(10,2), ARR_DELAY) AS ArrivalDelayMinutes,
    TRY_CONVERT(decimal(3,0), CANCELLED) AS IsCancelled,
    TRY_CONVERT(decimal(3,0), DIVERTED) AS IsDiverted,
    OP_CARRIER_FL_NUM AS FlightNumber,
    DEP_TIME_BLK AS	ScheduledDepartureBlock,
    TRY_CONVERT(decimal(10,2), LATE_AIRCRAFT_DELAY) as LateAircraftDelayMinutes,
    TRY_CONVERT(decimal(10,2), SECURITY_DELAY) as SecurityDelayMinutes,
    TRY_CONVERT(decimal(10,2), NAS_DELAY) as NasDelayMinutes,
    TRY_CONVERT(decimal(10,2), WEATHER_DELAY) as WeatherDelayMinutes,
    TRY_CONVERT(decimal(10,2), CARRIER_DELAY) as CarrierDelayMinutes,
    CASE
    WHEN TRY_CONVERT(decimal(10,2), ARR_DELAY) IS NULL THEN NULL
    WHEN TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15 THEN 1
    ELSE 0
END AS IsArrivalDelayed15
FROM dbo.RawFlights_2025_01;


SELECT
    IsArrivalDelayed15,
    COUNT(*) AS FlightRecordCount
FROM dbo.vw_Flights
WHERE CarrierCode = 'WN'
GROUP BY IsArrivalDelayed15;

SELECT
    FL_DATE,
    OP_UNIQUE_CARRIER,
    OP_CARRIER_FL_NUM,
    ORIGIN,
    DEST,
    CRS_DEP_TIME,
    COUNT(*) AS RecordCount
FROM dbo.RawFlights_2025_01
GROUP BY
    FL_DATE,
    OP_UNIQUE_CARRIER,
    OP_CARRIER_FL_NUM,
    ORIGIN,
    DEST,
    CRS_DEP_TIME
HAVING COUNT(*) > 1
ORDER BY RecordCount DESC;



ALTER VIEW dbo.vw_Flights AS
SELECT
    TRY_CONVERT(date, FL_DATE, 101) AS FlightDate,
    OP_UNIQUE_CARRIER AS CarrierCode,
    ORIGIN AS OriginAirport,
    DEST AS DestinationAirport,
    TRY_CONVERT(decimal(10,2), ARR_DELAY) AS ArrivalDelayMinutes,
    TRY_CONVERT(decimal(3,0), CANCELLED) AS IsCancelled,
    TRY_CONVERT(decimal(3,0), DIVERTED) AS IsDiverted,
    OP_CARRIER_FL_NUM AS FlightNumber,
    DEP_TIME_BLK AS	ScheduledDepartureBlock,
    TRY_CONVERT(decimal(10,2), LATE_AIRCRAFT_DELAY) as LateAircraftDelayMinutes,
    TRY_CONVERT(decimal(10,2), SECURITY_DELAY) as SecurityDelayMinutes,
    TRY_CONVERT(decimal(10,2), NAS_DELAY) as NasDelayMinutes,
    TRY_CONVERT(decimal(10,2), WEATHER_DELAY) as WeatherDelayMinutes,
    TRY_CONVERT(decimal(10,2), CARRIER_DELAY) as CarrierDelayMinutes,
    CASE
    WHEN TRY_CONVERT(decimal(10,2), ARR_DELAY) IS NULL THEN NULL
    WHEN TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15 THEN 1
    ELSE 0
    END AS IsArrivalDelayed15,
    CRS_DEP_TIME AS ScheduledDepartureTimeRaw
FROM dbo.RawFlights_2025_01;


SELECT TOP 10
    FlightDate,
    CarrierCode,
    FlightNumber,
    OriginAirport,
    DestinationAirport,
    ScheduledDepartureTimeRaw,
    ScheduledDepartureBlock
FROM dbo.vw_Flights
WHERE CarrierCode = 'WN';


SELECT TOP 10
    ScheduledDepartureTimeRaw,
    TRY_CONVERT(
        time(0),
        STUFF(ScheduledDepartureTimeRaw, 3, 0, ':')
    ) AS ScheduledDepartureTime,
    ScheduledDepartureBlock
FROM dbo.vw_Flights
WHERE CarrierCode = 'WN';


SELECT
    ScheduledDepartureTimeRaw,
    COUNT(*) AS RecordCount
FROM dbo.vw_Flights
WHERE
    ScheduledDepartureTimeRaw IS NULL
    OR LEN(LTRIM(RTRIM(ScheduledDepartureTimeRaw))) <> 4
    OR TRY_CONVERT(
        time(0),
        STUFF(ScheduledDepartureTimeRaw, 3, 0, ':')
    ) IS NULL
GROUP BY ScheduledDepartureTimeRaw
ORDER BY RecordCount DESC;


ALTER VIEW dbo.vw_Flights AS
SELECT
    TRY_CONVERT(date, FL_DATE, 101) AS FlightDate,
    OP_UNIQUE_CARRIER AS CarrierCode,
    ORIGIN AS OriginAirport,
    DEST AS DestinationAirport,
    TRY_CONVERT(decimal(10,2), ARR_DELAY) AS ArrivalDelayMinutes,
    TRY_CONVERT(decimal(3,0), CANCELLED) AS IsCancelled,
    TRY_CONVERT(decimal(3,0), DIVERTED) AS IsDiverted,
    OP_CARRIER_FL_NUM AS FlightNumber,
    DEP_TIME_BLK AS	ScheduledDepartureBlock,
    TRY_CONVERT(decimal(10,2), LATE_AIRCRAFT_DELAY) as LateAircraftDelayMinutes,
    TRY_CONVERT(decimal(10,2), SECURITY_DELAY) as SecurityDelayMinutes,
    TRY_CONVERT(decimal(10,2), NAS_DELAY) as NasDelayMinutes,
    TRY_CONVERT(decimal(10,2), WEATHER_DELAY) as WeatherDelayMinutes,
    TRY_CONVERT(decimal(10,2), CARRIER_DELAY) as CarrierDelayMinutes,
    CASE
    WHEN TRY_CONVERT(decimal(10,2), ARR_DELAY) IS NULL THEN NULL
    WHEN TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15 THEN 1
    ELSE 0
    END AS IsArrivalDelayed15,
    CRS_DEP_TIME AS ScheduledDepartureTimeRaw,
    TRY_CONVERT(
    time(0),
    STUFF(CRS_DEP_TIME, 3, 0, ':')
) AS ScheduledDepartureTime
FROM dbo.RawFlights_2025_01;


SELECT TOP 10
    ScheduledDepartureTimeRaw,
    ScheduledDepartureTime,
    ScheduledDepartureBlock
FROM dbo.vw_Flights
WHERE CarrierCode = 'WN';


SELECT
    COUNT(*) AS FlightRecords,
    COUNT(ArrivalDelayMinutes) AS ValidArrivalRecords,
    SUM(IsArrivalDelayed15) AS Delayed15PlusRecords,
    100.0 * SUM(IsArrivalDelayed15)
        / NULLIF(COUNT(ArrivalDelayMinutes), 0) AS Delayed15PlusPct
FROM dbo.vw_Flights
WHERE CarrierCode = 'WN'
  AND FlightDate = '20250107';


  ALTER VIEW dbo.vw_Flights AS
SELECT
    TRY_CONVERT(date, FL_DATE, 101) AS FlightDate,
    OP_UNIQUE_CARRIER AS CarrierCode,
    ORIGIN AS OriginAirport,
    DEST AS DestinationAirport,
    TRY_CONVERT(decimal(10,2), ARR_DELAY) AS ArrivalDelayMinutes,
    TRY_CONVERT(decimal(3,0), CANCELLED) AS IsCancelled,
    TRY_CONVERT(decimal(3,0), DIVERTED) AS IsDiverted,
    OP_CARRIER_FL_NUM AS FlightNumber,
    DEP_TIME_BLK AS	ScheduledDepartureBlock,
    TRY_CONVERT(decimal(10,2), LATE_AIRCRAFT_DELAY) as LateAircraftDelayMinutes,
    TRY_CONVERT(decimal(10,2), SECURITY_DELAY) as SecurityDelayMinutes,
    TRY_CONVERT(decimal(10,2), NAS_DELAY) as NasDelayMinutes,
    TRY_CONVERT(decimal(10,2), WEATHER_DELAY) as WeatherDelayMinutes,
    TRY_CONVERT(decimal(10,2), CARRIER_DELAY) as CarrierDelayMinutes,
    CASE
    WHEN TRY_CONVERT(decimal(10,2), ARR_DELAY) IS NULL THEN NULL
    WHEN TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15 THEN 1
    ELSE 0
    END AS IsArrivalDelayed15,
    CANCELLATION_CODE AS CancellationCode,
    CRS_DEP_TIME AS ScheduledDepartureTimeRaw,
    TRY_CONVERT(
    time(0),
    STUFF(CRS_DEP_TIME, 3, 0, ':')
) AS ScheduledDepartureTime
FROM dbo.RawFlights_2025_01;