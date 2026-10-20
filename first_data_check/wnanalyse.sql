use AirlineAnalytics


select TOP 10*
from RawFlights_2025_01


select distinct CANCELLATION_CODE
,count(*) as total_cancellations
from RawFlights_2025_01
where CANCELLATION_CODE IS NOT NULL
group by CANCELLATION_CODE
order by total_cancellations desc





select distinct DIVERTED
,count(*) as total_diverts
from RawFlights_2025_01
where DIVERTED IS NOT NULL
group by DIVERTED
order by total_diverts desc


select count(*)
from RawFlights_2025_01
where ARR_DELAY IS NULL



select CANCELLED
,count(*) as cancels
from RawFlights_2025_01
group by CANCELLED
order by cancels desc


select CANCELLED
,DIVERTED
,count(*) 
from RawFlights_2025_01
WHERE ARR_DELAY IS NULL
group by CANCELLED, DIVERTED



SELECT COUNT(*) AS EmptyArrivalDelayCount
FROM RawFlights_2025_01
WHERE RTRIM(LTRIM(ARR_DELAY)) = ''



SELECT COUNT(*) AS EmptyArrivalDelayCount
FROM RawFlights_2025_01
WHERE RTRIM(LTRIM(ARR_DELAY)) = ''
AND
TRY_CONVERT(decimal(10,2), ARR_DELAY) IS NULL

SELECT COUNT(*) AS InvalidArrivalDelayCount
FROM RawFlights_2025_01
WHERE ARR_DELAY IS NOT NULL
AND
TRY_CONVERT(decimal(10,2), ARR_DELAY) IS NULL


select MIN(TRY_CONVERT(decimal(10,2), ARR_DELAY)) as min_delay
,MAX(TRY_CONVERT(decimal(10,2), ARR_DELAY)) as max_delay
,AVG(TRY_CONVERT(decimal(10,2), ARR_DELAY)) as avg_delay
from RawFlights_2025_01



select TOP 10*
,FL_DATE
,OP_UNIQUE_CARRIER
,OP_CARRIER_FL_NUM
,ORIGIN
,DEST
,CANCELLED
,DIVERTED
,(TRY_CONVERT(decimal(10,2), ARR_DELAY)) as ARR_DELAY_1
from RawFlights_2025_01
where ARR_DELAY IS NOT NULL
group by ARR_DELAY_1
order by ARR_DELAY_1 desc



select TOP 10*

from (

          select FL_DATE
          ,OP_UNIQUE_CARRIER
          ,OP_CARRIER_FL_NUM
          ,ORIGIN
          ,DEST
          ,CANCELLED
          ,DIVERTED
          ,(TRY_CONVERT(decimal(10,2), ARR_DELAY)) as ARR_DELAY_1
          from RawFlights_2025_01

          ) a


where ARR_DELAY_1 IS NOT NULL
ORDER BY ARR_DELAY_1 DESC


select COUNT(*) AS WN_VALID_ARRIVAL_RECORDS
,MIN(TRY_CONVERT(decimal(10,2), ARR_DELAY)) as min_delay
,MAX(TRY_CONVERT(decimal(10,2), ARR_DELAY)) as max_delay
,AVG(TRY_CONVERT(decimal(10,2), ARR_DELAY)) as avg_delay
from RawFlights_2025_01
WHERE OP_UNIQUE_CARRIER = 'WN'
AND
ARR_DELAY IS NOT NULL



select COUNT(*) AS WN_DELAYED_15_PLUS
from RawFlights_2025_01
WHERE OP_UNIQUE_CARRIER = 'WN'
AND
TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15



SELECT TOP 10*
 FROM (
       select TRY_CONVERT(decimal(10,2), ARR_DELAY) AS ArrivalDelayMinutes
       ,CASE
           WHEN TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15 THEN 1
           ELSE 0
       END AS IsDelayed15
       from RawFlights_2025_01
       WHERE OP_UNIQUE_CARRIER = 'WN'
       AND
       ARR_DELAY IS NOT NULL

       ) a



SELECT COUNT(*) AS ValidArrivalRecords
,SUM(IsDelayed15) as Delayed15PlusRecords
 FROM (
       select TRY_CONVERT(decimal(10,2), ARR_DELAY) AS ArrivalDelayMinutes
       ,CASE
           WHEN TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15 THEN 1
           ELSE 0
       END AS IsDelayed15
       from RawFlights_2025_01
       WHERE OP_UNIQUE_CARRIER = 'WN'
       AND
       ARR_DELAY IS NOT NULL

       ) a





SELECT COUNT(*) AS ValidArrivalRecords
,SUM(IsDelayed15) as Delayed15PlusRecords
,100.00 * SUM(IsDelayed15) /  NULLIF(COUNT(*), 0) as Delayed15PlusPct
,ORIGIN
 FROM (
       select TRY_CONVERT(decimal(10,2), ARR_DELAY) AS ArrivalDelayMinutes
       ,CASE
           WHEN TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15 THEN 1
           ELSE 0
       END AS IsDelayed15
       ,ORIGIN
       from RawFlights_2025_01
       WHERE OP_UNIQUE_CARRIER = 'WN'
       AND
       ARR_DELAY IS NOT NULL

       ) a

group by ORIGIN
order by Delayed15PlusRecords desc





SELECT COUNT(*) AS ValidArrivalRecords
,SUM(IsDelayed15) as Delayed15PlusRecords
,100.00 * SUM(IsDelayed15) /  NULLIF(COUNT(*), 0) as Delayed15PlusPct
,ORIGIN
 FROM (
       select TRY_CONVERT(decimal(10,2), ARR_DELAY) AS ArrivalDelayMinutes
       ,CASE
           WHEN TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15 THEN 1
           ELSE 0
       END AS IsDelayed15
       ,ORIGIN
       from RawFlights_2025_01
       WHERE OP_UNIQUE_CARRIER = 'WN'
       AND
       ARR_DELAY IS NOT NULL

       ) a

group by ORIGIN
HAVING COUNT(*) >= 500
ORDER BY Delayed15PlusPct DESC, ValidArrivalRecords DESC




SELECT COUNT(*) AS ValidArrivalRecords
,SUM(IsDelayed15) as Delayed15PlusRecords
,100.00 * SUM(IsDelayed15) /  NULLIF(COUNT(*), 0) as Delayed15PlusPct
,ORIGIN
,AVG(
    CASE
        WHEN IsDelayed15 = 1 THEN ArrivalDelayMinutes
        ELSE NULL
    END
) AS AvgDelayMinutes15Plus
 FROM (
       select TRY_CONVERT(decimal(10,2), ARR_DELAY) AS ArrivalDelayMinutes
       ,CASE
           WHEN TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15 THEN 1
           ELSE 0
       END AS IsDelayed15
       ,ORIGIN
       from RawFlights_2025_01
       WHERE OP_UNIQUE_CARRIER = 'WN'
       AND
       ARR_DELAY IS NOT NULL

       ) a

group by ORIGIN
HAVING COUNT(*) >= 500
ORDER BY Delayed15PlusPct DESC, ValidArrivalRecords DESC




SELECT TOP 10 
COUNT(*) AS ValidArrivalRecords
,SUM(IsDelayed15) as Delayed15PlusRecords
,100.00 * SUM(IsDelayed15) /  NULLIF(COUNT(*), 0) as Delayed15PlusPct
,ORIGIN
,AVG(
    CASE
        WHEN IsDelayed15 = 1 THEN ArrivalDelayMinutes
        ELSE NULL
    END
) AS AvgDelayMinutes15Plus
,SUM(
    CASE
        WHEN IsDelayed15 = 1 THEN ArrivalDelayMinutes
        ELSE NULL
    END
) AS TotalArrivalDelayMinutes15Plus
 FROM (
       select TRY_CONVERT(decimal(10,2), ARR_DELAY) AS ArrivalDelayMinutes
       ,CASE
           WHEN TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15 THEN 1
           ELSE 0
       END AS IsDelayed15
       ,ORIGIN
       from RawFlights_2025_01
       WHERE OP_UNIQUE_CARRIER = 'WN'
       AND
       ARR_DELAY IS NOT NULL

       ) a

group by ORIGIN
HAVING COUNT(*) >= 500
ORDER BY TotalArrivalDelayMinutes15Plus DESC, Delayed15PlusPct DESC, ValidArrivalRecords DESC


select count(*) as InvalidCarrierDelayCount
from RawFlights_2025_01
where OP_UNIQUE_CARRIER = 'WN'
and
ORIGIN = 'DEN'
and
TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15
and
CARRIER_DELAY IS NOT NULL
and
TRY_CONVERT(decimal(10,2), CARRIER_DELAY) IS  NULL

select count(*) as MissingCarrierDelayCount
from RawFlights_2025_01
where OP_UNIQUE_CARRIER = 'WN'
and
ORIGIN = 'DEN'
and
TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15
and
CARRIER_DELAY IS NULL


select count(*) as EmptyCarrierDelayCount
from RawFlights_2025_01
where OP_UNIQUE_CARRIER = 'WN'
and
ORIGIN = 'DEN'
and
TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15
and
RTRIM(LTRIM(CARRIER_DELAY)) = ''



select SUM(TRY_CONVERT(decimal(10,2), CARRIER_DELAY)) AS TotalCarrierDelayMinutes
from RawFlights_2025_01
where OP_UNIQUE_CARRIER = 'WN'
and
ORIGIN = 'DEN'
and
TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15


select count(*) as InvalidWeatherDelayCount
from RawFlights_2025_01
where OP_UNIQUE_CARRIER = 'WN'
and
ORIGIN = 'DEN'
and
TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15
and
WEATHER_DELAY IS NOT NULL
and
TRY_CONVERT(decimal(10,2), WEATHER_DELAY) IS  NULL

select count(*) as MissingWeatherDelayCount
from RawFlights_2025_01
where OP_UNIQUE_CARRIER = 'WN'
and
ORIGIN = 'DEN'
and
TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15
and
WEATHER_DELAY IS NULL


select count(*) as EmptyWeatherDelayCount
from RawFlights_2025_01
where OP_UNIQUE_CARRIER = 'WN'
and
ORIGIN = 'DEN'
and
TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15
and
RTRIM(LTRIM(WEATHER_DELAY)) = ''


select SUM(TRY_CONVERT(decimal(10,2), WEATHER_DELAY)) AS TotalWeatherDelayMinutes
from RawFlights_2025_01
where OP_UNIQUE_CARRIER = 'WN'
and
ORIGIN = 'DEN'
and
TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15


select count(*) as InvalidNasDelayCount
from RawFlights_2025_01
where OP_UNIQUE_CARRIER = 'WN'
and
ORIGIN = 'DEN'
and
TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15
and
NAS_DELAY IS NOT NULL
and
TRY_CONVERT(decimal(10,2), NAS_DELAY) IS  NULL

select count(*) as MissingNasDelayCount
from RawFlights_2025_01
where OP_UNIQUE_CARRIER = 'WN'
and
ORIGIN = 'DEN'
and
TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15
and
NAS_DELAY IS NULL


select count(*) as EmptyNasDelayCount
from RawFlights_2025_01
where OP_UNIQUE_CARRIER = 'WN'
and
ORIGIN = 'DEN'
and
TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15
and
RTRIM(LTRIM(NAS_DELAY)) = ''


select SUM(TRY_CONVERT(decimal(10,2), NAS_DELAY)) AS TotalNasDelayMinutes
from RawFlights_2025_01
where OP_UNIQUE_CARRIER = 'WN'
and
ORIGIN = 'DEN'
and
TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15




select count(*) as InvalidSecurityDelayCount
from RawFlights_2025_01
where OP_UNIQUE_CARRIER = 'WN'
and
ORIGIN = 'DEN'
and
TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15
and
SECURITY_DELAY IS NOT NULL
and
TRY_CONVERT(decimal(10,2), SECURITY_DELAY) IS  NULL

select count(*) as MissingSecurityDelayCount
from RawFlights_2025_01
where OP_UNIQUE_CARRIER = 'WN'
and
ORIGIN = 'DEN'
and
TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15
and
SECURITY_DELAY IS NULL


select count(*) as EmptySecurityDelayCount
from RawFlights_2025_01
where OP_UNIQUE_CARRIER = 'WN'
and
ORIGIN = 'DEN'
and
TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15
and
RTRIM(LTRIM(SECURITY_DELAY)) = ''


select SUM(TRY_CONVERT(decimal(10,2), SECURITY_DELAY)) AS TotalSecurityDelayMinutes
from RawFlights_2025_01
where OP_UNIQUE_CARRIER = 'WN'
and
ORIGIN = 'DEN'
and
TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15


select count(*) as InvalidLateAircraftDelayCount
from RawFlights_2025_01
where OP_UNIQUE_CARRIER = 'WN'
and
ORIGIN = 'DEN'
and
TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15
and
LATE_AIRCRAFT_DELAY IS NOT NULL
and
TRY_CONVERT(decimal(10,2), LATE_AIRCRAFT_DELAY) IS  NULL

select count(*) as MissingLateAircraftDelayCount
from RawFlights_2025_01
where OP_UNIQUE_CARRIER = 'WN'
and
ORIGIN = 'DEN'
and
TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15
and
LATE_AIRCRAFT_DELAY IS NULL


select count(*) as EmptyLateAircraftDelayCount
from RawFlights_2025_01
where OP_UNIQUE_CARRIER = 'WN'
and
ORIGIN = 'DEN'
and
TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15
and
RTRIM(LTRIM(LATE_AIRCRAFT_DELAY)) = ''


select SUM(TRY_CONVERT(decimal(10,2), LATE_AIRCRAFT_DELAY)) AS TotalLateAircraftDelayMinutes
from RawFlights_2025_01
where OP_UNIQUE_CARRIER = 'WN'
and
ORIGIN = 'DEN'
and
TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15


select count(*) as MismatchCount
from (

         select TRY_CONVERT(decimal(10,2), ARR_DELAY) as arr_delay_total
         ,TRY_CONVERT(decimal(10,2), LATE_AIRCRAFT_DELAY)
         +
         TRY_CONVERT(decimal(10,2), SECURITY_DELAY)
         +
         TRY_CONVERT(decimal(10,2), NAS_DELAY)
         +
         TRY_CONVERT(decimal(10,2), WEATHER_DELAY)
         +
         TRY_CONVERT(decimal(10,2), CARRIER_DELAY) as ReportedCauseMinutes
         from RawFlights_2025_01
         where TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15
         and
         OP_UNIQUE_CARRIER = 'WN'
         and
         ORIGIN = 'DEN'

         ) a

where arr_delay_total <> ReportedCauseMinutes



SELECT TOP 10
SUM(ArrivalDelayMinutes) as TotalDelayMinutes
,DEST
,ORIGIN
 FROM (
       select TRY_CONVERT(decimal(10,2), ARR_DELAY) AS ArrivalDelayMinutes
       ,CASE
           WHEN TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15 THEN 1
           ELSE 0
       END AS IsDelayed15
       ,DEST
       ,ORIGIN
       from RawFlights_2025_01
       WHERE OP_UNIQUE_CARRIER = 'WN'
       AND
       ORIGIN = 'DEN'
       and
       ARR_DELAY IS NOT NULL
      
       
       ) a

where IsDelayed15 = 1
group by ORIGIN, DEST
order by TotalDelayMinutes desc


SELECT TOP 10 
COUNT(*) AS ValidArrivalRecords
,SUM(IsDelayed15) as Delayed15PlusRecords
,100.00 * SUM(IsDelayed15) /  NULLIF(COUNT(*), 0) as Delayed15PlusPct
,ORIGIN
,DEST
,AVG(
    CASE
        WHEN IsDelayed15 = 1 THEN ArrivalDelayMinutes
        ELSE NULL
    END
) AS AvgDelayMinutes15Plus
,SUM(
    CASE
        WHEN IsDelayed15 = 1 THEN ArrivalDelayMinutes
        ELSE NULL
    END
) AS TotalArrivalDelayMinutes15Plus
 FROM (
       select TRY_CONVERT(decimal(10,2), ARR_DELAY) AS ArrivalDelayMinutes
       ,CASE
           WHEN TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15 THEN 1
           ELSE 0
       END AS IsDelayed15
       ,ORIGIN
       ,DEST
       from RawFlights_2025_01
       WHERE OP_UNIQUE_CARRIER = 'WN'
       AND
       ORIGIN = 'DEN'
       and
       ARR_DELAY IS NOT NULL

       ) a

group by ORIGIN, DEST
order by TotalArrivalDelayMinutes15Plus desc





SELECT 
COUNT(*) AS ValidArrivalRecords
,SUM(IsDelayed15) as Delayed15PlusRecords
,100.00 * SUM(IsDelayed15) /  NULLIF(COUNT(*), 0) as Delayed15PlusPct
,ORIGIN
,DEST
,AVG(
    CASE
        WHEN IsDelayed15 = 1 THEN ArrivalDelayMinutes
        ELSE NULL
    END
) AS AvgDelayMinutes15Plus
,SUM(
    CASE
        WHEN IsDelayed15 = 1 THEN ArrivalDelayMinutes
        ELSE NULL
    END
) AS TotalArrivalDelayMinutes15Plus
 FROM (
       select TRY_CONVERT(decimal(10,2), ARR_DELAY) AS ArrivalDelayMinutes
       ,CASE
           WHEN TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15 THEN 1
           ELSE 0
       END AS IsDelayed15
       ,ORIGIN
       ,DEST
       from RawFlights_2025_01
       WHERE OP_UNIQUE_CARRIER = 'WN'
       AND
       ORIGIN = 'DEN'
       and
       ARR_DELAY IS NOT NULL

       ) a

group by ORIGIN, DEST
order by TotalArrivalDelayMinutes15Plus desc


select 

SUM(ArrDelayTotal) as ArrDelayUnitTotal
,SUM(AircraftDelay) as LateAirCraftDelayUnitTotal
,SUM(SecurityDelay) as SecurityDelayUnitTotal
,SUM(NasDelay) as NasDelayUnitTotal
,SUM(WeatherDelay) as WeatherDelayUnitTotal
,SUM(CarrierDelay) as CarrierDelayUnitTotal

from (

       select TRY_CONVERT(decimal(10,2), ARR_DELAY) as ArrDelayTotal
       ,TRY_CONVERT(decimal(10,2), LATE_AIRCRAFT_DELAY) as AircraftDelay
       ,TRY_CONVERT(decimal(10,2), SECURITY_DELAY) as SecurityDelay
       ,TRY_CONVERT(decimal(10,2), NAS_DELAY) as NasDelay
       ,TRY_CONVERT(decimal(10,2), WEATHER_DELAY) as WeatherDelay
       ,TRY_CONVERT(decimal(10,2), CARRIER_DELAY) as CarrierDelay
       from RawFlights_2025_01
       where TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15
       and
       OP_UNIQUE_CARRIER = 'WN'
       and
       ORIGIN = 'DEN'
       and
       DEST = 'LAS'

       ) a



SELECT 
COUNT(*) AS ValidArrivalRecords
,SUM(IsDelayed15) as Delayed15PlusRecords
,100.00 * SUM(IsDelayed15) /  NULLIF(COUNT(*), 0) as Delayed15PlusPct
,ORIGIN
,DEST
,AVG(
    CASE
        WHEN IsDelayed15 = 1 THEN ArrivalDelayMinutes
        ELSE NULL
    END
) AS AvgDelayMinutes15Plus
,SUM(
    CASE
        WHEN IsDelayed15 = 1 THEN ArrivalDelayMinutes
        ELSE NULL
    END
) AS TotalArrivalDelayMinutes15Plus
,DEP_TIME_BLK
 FROM (
       select TRY_CONVERT(decimal(10,2), ARR_DELAY) AS ArrivalDelayMinutes
       ,CASE
           WHEN TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15 THEN 1
           ELSE 0
       END AS IsDelayed15
       ,ORIGIN
       ,DEST
       ,DEP_TIME_BLK
       from RawFlights_2025_01
       WHERE OP_UNIQUE_CARRIER = 'WN'
       AND
       ORIGIN = 'DEN'
       and
       DEST = 'LAS'
       AND
       ARR_DELAY IS NOT NULL

       ) a

group by ORIGIN, DEST, DEP_TIME_BLK
order by TotalArrivalDelayMinutes15Plus desc





select TRY_CONVERT(decimal(10,2), ARR_DELAY) as ArrDelayTotal
,TRY_CONVERT(decimal(10,2), LATE_AIRCRAFT_DELAY) as AircraftDelay
,TRY_CONVERT(decimal(10,2), SECURITY_DELAY) as SecurityDelay
,TRY_CONVERT(decimal(10,2), NAS_DELAY) as NasDelay
,TRY_CONVERT(decimal(10,2), WEATHER_DELAY) as WeatherDelay
,TRY_CONVERT(decimal(10,2), CARRIER_DELAY) as CarrierDelay
,FL_DATE
,OP_CARRIER_FL_NUM
,DEP_TIME_BLK
from RawFlights_2025_01
where TRY_CONVERT(decimal(10,2), ARR_DELAY) >= 15
and
OP_UNIQUE_CARRIER = 'WN'
and
ORIGIN = 'DEN'
and
DEP_TIME_BLK = '1800-1859'
and
DEST = 'LAS'
ORDER BY ArrDelayTotal DESC;
       
SELECT TOP 5
    FL_DATE,
    TRY_CONVERT(date, FL_DATE, 101) AS FlightDate
FROM RawFlights_2025_01;

SELECT
    COUNT(*) AS TotalRecords,
    SUM(
        CASE
            WHEN TRY_CONVERT(date, FL_DATE, 101) IS NULL THEN 1
            ELSE 0
        END
    ) AS MissingOrInvalidDateRecords,
    MIN(TRY_CONVERT(date, FL_DATE, 101)) AS FirstFlightDate,
    MAX(TRY_CONVERT(date, FL_DATE, 101)) AS LastFlightDate
FROM RawFlights_2025_01;


select count(*) as totalcancellations
,CANCELLATION_CODE
from dbo.RawFlights_2025_01
where OP_UNIQUE_CARRIER = 'WN'
AND
ORIGIN = 'DAL'
AND
TRY_CONVERT(date, FL_DATE, 101) = '20250109'
AND 
TRY_CONVERT(decimal(3,0), CANCELLED) = 1
group by CANCELLATION_CODE
order by totalcancellations desc


