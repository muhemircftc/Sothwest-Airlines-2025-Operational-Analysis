# Power BI model setup

## Existing report
Open `Airline_Operational_Performance_2025.pbix` (included). Keep Import mode. Viewing and filtering the embedded snapshot requires no SQL connection. To refresh, change the SQL Server source for the destination machine and authenticate; then refresh. The database name is `AirlineAnalytics`.

## Power Query: FactFlights
Replace SERVER_NAME with the actual SQL Server instance. This is a placeholder, not a credential.

```powerquery
let
    Source = Sql.Database("SERVER_NAME", "AirlineAnalytics"),
    Navigation = Source{[Schema = "dbo", Item = "vw_Flights"]}[Data],
    ChangedType = Table.TransformColumnTypes(Navigation, {
        {"ScheduledDepartureTimeRaw", type text},
        {"IsDiverted", Int64.Type},
        {"IsCancelled", Int64.Type},
        {"FlightDate", type date}
    })
in
    ChangedType
```

SQL supplies the remaining numeric and time types. Do not convert ScheduledDepartureTimeRaw to Time; it can contain 2400. Do not replace missing delays with zero or remove valid early arrivals. The SQL source must remain vw_Flights, not the physical table: the view derives IsArrivalDelayed15.

## Calculated tables
Create after loading flight data. A fresh installation should load at least one month before creating the dynamic date table.

```dax
DimDate =
VAR FirstFlightDate = MIN(FactFlights[FlightDate])
VAR LastFlightDate = MAX(FactFlights[FlightDate])
RETURN
    ADDCOLUMNS(
        CALENDAR(
            DATE(YEAR(FirstFlightDate), 1, 1),
            DATE(YEAR(LastFlightDate), 12, 31)
        ),
        "Year", YEAR([Date]),
        "MonthNumber", MONTH([Date]),
        "YearMonth", FORMAT([Date], "yyyy-MM"),
        "DayOfWeekNumber", WEEKDAY([Date], 2)
    )
```

```dax
DimDelayCause =
DATATABLE(
    "CauseCode", STRING,
    "CauseName", STRING,
    {
        {"CARRIER", "Air Carrier"},
        {"LATE", "Late Aircraft"},
        {"NAS", "National Aviation System"},
        {"WEATHER", "Weather"},
        {"SECURITY", "Security"}
    }
)
```

## Calculated column on FactFlights
```dax
CancellationReason =
SWITCH(
    FactFlights[CancellationCode],
    "A", "Air Carrier",
    "B", "Weather",
    "C", "National Aviation System",
    "D", "Security",
    IF(FactFlights[IsCancelled] = 1, "Unknown / Missing", BLANK())
)
```

## Relationships
Mark DimDate as a date table using Date. Use an active, single-direction relationship from DimDate[Date] (1) to FactFlights[FlightDate] (*). The relationship dialog can show *:1 when FactFlights appears first. Leave DimDelayCause disconnected.

## Measures and formats
The CSV contains 29 measures from the author's export. The Overview Context fallback has been updated to All Loaded Dates, as confirmed in the working report; two damaged title symbols were replaced with ASCII -> and >=. This is a reference list, not an executable bulk model import. Create dependency measures before dependent measures if rebuilding manually. Measure home tables do not change their calculations. Formatting metadata was blank in the export; the following are delivery specifications, not recovered FormatString values.

| Measures | Format | Decimals |
|---|---|---:|
| Flight Records, Valid Arrival Records, Delayed 15 Plus Records, Cancelled Flight Records, Diverted Flight Records, Missing Arrival Delay on Regular Flights | Whole number | 0 |
| Delayed 15 Plus Rate, Cancellation Rate, Diversion Rate | Percentage | 2 |
| Reported Cause Coverage Rate, Arrival Minus Reported Cause Rate | Percentage | 4 |
| Delay Rate Gap pp | Decimal number, not percentage | 2 |
| Avg Arrival Delay Minutes 15 Plus, Delay Minutes per Valid Arrival | Decimal number | 2 |
| Total Arrival Delay Minutes 15 Plus; five cause-minute measures; Reported Cause Minutes 15 Plus; Arrival Minus Reported Cause Minutes; Selected Cause Minutes 15 Plus | Decimal number | 0 |
| Flight Records Display and title measures | Text | N/A |

Use numeric Flight Records for calculations. Flight Records Display is text for the KPI card only.

## Report behavior
1. Overview: station bar selection filters KPI cards and the monthly trend.
2. Stations & Routes: destination-table selection must not filter station summary cards or the origin-versus-carrier monthly chart. Carrier Overall Delay Rate removes only OriginAirport, retaining date, carrier and other filters; it is not an unconditional network benchmark.
3. Causes & Timing: departure-block selection filters the cause chart and coverage cards. Disconnected cause selection does not filter flight records by itself. Do not interpret a cause-bar selection as a flight-subset filter.
4. Cancellations: origin selection filters trends and reason chart; daily selection filters reasons. Reason selection must not filter rate charts, which would restrict denominators to coded cancelled flights.

Keep complete flights in rate denominators; apply the IsCancelled=1 visual filter only to the cancellation reason chart. Use YearMonth in chronological order and the plain Date field for daily trends. The date table expands at refresh; report names and any fixed-year labels must still be reviewed when extending beyond 2025.

## Accepted final presentation
The author retained plain DimDate[Date] for the daily trend and hid its axis date labels. DateLabelEN was proposed but not applied; it is not a model dependency. Dropdown slicers and table widths were revised in the final PBIX. Static PDF export includes only visible rows/bars; use the PBIX for scrolling and daily-date tooltips. Four development pages remain hidden and four delivery pages are visible.
