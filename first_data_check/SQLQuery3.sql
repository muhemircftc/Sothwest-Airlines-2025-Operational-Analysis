USE AirlineAnalytics;
GO

BULK INSERT dbo.StagingFlights
FROM 'C:\Users\faari\Downloads\On_Time_Reporting_Carrier_On_Time_Performance_1987_present_2025_3\On_Time_Reporting_Carrier_On_Time_Performance_(1987_present)_2025_3.csv'
WITH (
    FORMAT = 'CSV',
    CODEPAGE = '65001',
    FIRSTROW = 2,
    LASTROW = 11,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    KEEPNULLS
);


SELECT
    FlightDate,
    Reporting_Airline,
    Flight_Number_Reporting_Airline,
    Origin,
    Dest,
    CRSDepTime,
    ArrDelay,
    Cancelled,
    Diverted,
    column110
FROM dbo.StagingFlights;