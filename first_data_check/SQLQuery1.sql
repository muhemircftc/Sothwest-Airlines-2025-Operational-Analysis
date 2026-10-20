USE AirlineAnalytics;
GO

SELECT TOP (0) *
INTO dbo.StagingFlights
FROM dbo.RawFlights_2025_02;
GO

SELECT COUNT(*) AS StagingRecordCount
FROM dbo.StagingFlights;