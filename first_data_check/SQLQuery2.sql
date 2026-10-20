USE AirlineAnalytics;
GO

SELECT
    column_id AS ColumnOrder,
    name AS ColumnName,
    TYPE_NAME(user_type_id) AS DataType,
    max_length AS MaxLengthBytes
FROM sys.columns
WHERE object_id = OBJECT_ID('dbo.StagingFlights')
ORDER BY column_id;