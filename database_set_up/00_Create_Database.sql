-- Initial setup only. Requires CREATE DATABASE permission.
-- Uses SQL Server's default data/log locations; no machine-specific paths.
USE master;
GO
IF DB_ID(N'AirlineAnalytics') IS NULL
    EXEC(N'CREATE DATABASE [AirlineAnalytics]');
GO
