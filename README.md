# Airline Operational Performance | 2025

SQL Server and Power BI portfolio project for airline operational reliability analysis and investigation prioritization. Source: US domestic BTS Reporting Carrier On-Time Performance; focus carrier: Southwest (WN). 

## Start here
- Read Business_Analysis_Report.pdf for the business problem, findings and proposed actions.
- Open Dashboard_Preview_2025.pdf for a static four-page preview; it cannot reproduce slicers, tooltips or scrolling.
- Open Airline_Operational_Performance_2025.pbix in Power BI Desktop for interactive analysis of the embedded Import-mode snapshot. A connection to the author's SQL Server is not required to view and filter the saved data. Do not refresh unless your SQL Server source is configured.
- To refresh or rebuild the database, follow Installation below. SQL Server connectivity and appropriate permissions are required for refresh, not for viewing the embedded snapshot.

## Delivery status
This archive includes the final author-supplied PBIX, the accepted four-page dashboard preview, the four-page English business report, SQL scripts and technical documentation. No source CSVs or database backup are bundled. There is no separate PowerPoint slide deck in this package.

The preview preserves the author's accepted design: dropdown slicers, widened tables and hidden daily-date axis labels. Only currently visible rows/bars are exported; scrolling and exact daily dates are available in the interactive PBIX. Do not interpret the static preview as an exhaustive export of every station or flight.

## Files
- Airline_Operational_Performance_2025.pbix: interactive report with embedded data snapshot.
- Dashboard_Preview_2025.pdf: static four-page dashboard preview.
- Business_Analysis_Report.pdf: English management findings and investigation plan.
- 00_Create_Database.sql: create AirlineAnalytics if absent, with default server paths.
- 01_Database_Schema.sql: tables, view, primary/unique keys and cancellation-code constraint.
- 02_Load_Monthly_Flights.sql: validated monthly CSV ingestion; only @CsvPath is normally changed.
- 03_DAX_Measures.csv: 29 reference measures, standard UTF-8 CSV with headers.
- 04_Model_Setup.md: Power Query, calculated tables/column, relationships, formats and interaction rules.
- 05_KPI_Definitions.md: business definitions and limitations.
- 06_Validation_Results.md: loaded snapshot, reference results and exceptions.

## Requirements
Validated environment: SQL Server Express 17.x and SSMS 22; Power BI Desktop. The exported schema includes SQL Server 2019+ index syntax; use SQL Server 2025 for the closest match. Allow sufficient data/log disk space and edition capacity for a full-year database, staging, transactions and any test database. The entire monthly import is transactional. Credentials need schema/setup rights for initial installation and bulk-load/table rights for ingestion. SQL Server reads the path on its own machine, not an arbitrary client machine.

## Installation
1. Connect SSMS to the target SQL Server. Run 00_Create_Database.sql, then 01_Database_Schema.sql. The schema is initial-install only, not a migration or overwrite script. Do not rerun it against populated tables.
2. Download and extract the official monthly Reporting Carrier CSVs. Expected PREZIP naming: On_Time_Reporting_Carrier_On_Time_Performance_1987_present_2025_M.zip, where M is 1-12. Directory: https://transtats.bts.gov/PREZIP/ . CSV header/order must match the loader's approved 110-field schema, including the trailing empty field.
3. Open 02_Load_Monthly_Flights.sql. Confirm USE AirlineAnalytics. Paste one extracted CSV path into @CsvPath; execute the entire file. Change the path and repeat for each month.
4. Accept a run only when LoadStatus is SUCCESS and SourceRecords equals InsertedRecords. Inspect both warning counters even after success. Investigate error messages; do not bypass checks to force a load.
5. For refresh, open the included PBIX and change its SQL Server connection to this instance while retaining AirlineAnalytics and dbo.vw_Flights, authenticate, and choose Home > Refresh. Viewing the embedded data does not require this step. If rebuilding a model, follow 04_Model_Setup.md.
6. Clear report selections; reconcile 7,001,619 records for the reviewed 2025 snapshot, then check WN reference results. Save the report.

January in the original development used a differently named raw extract and manual migration. For fresh installation use the matching January PREZIP schema; the generic loader rejects the uppercase custom-extract schema. No claim is made that this alternative January download was independently reloaded during the clean July installation test.

## Routine monthly update
Download/extract CSV -> change @CsvPath -> execute the full loader -> inspect result and warnings -> refresh Power BI -> verify the new period. The dynamic calendar expands to full years represented by loaded flights; fixed-year report names or labels require review. The script does not download files, revise existing months, schedule execution, or refresh the Power BI service automatically.

## Failure handling and limits
- Error 51014: that month already has rows; no append is committed. Corrections/revised files need a separately reviewed replacement procedure.
- File access errors: check that the path exists on the SQL Server machine and the execution identity can read it.
- Header/type/duplicate errors: inspect source records; do not remove controls or replace missing delays with zero.
- Warning counters apply to the current input month, not the full database. The original loader reports warnings in query results; it does not persist a run audit log or a quarantine table.
- Missing cause values on delayed flights still block loading; zero-valued cause totals that disagree with arrival delay are retained and counted as warnings.
- sp_getapplock coordinates sessions using this loader, not unrelated manual writers or the older development procedure.
- No revenue/cost/passenger data or causal identification: recommendations are investigation priorities, not proven savings.

## Provenance
Compiled from the author's supplied schema and 29-measure export, confirmed model formulas, tested loader v1.2 and reported validation outputs. Technical packaging adds English documentation and an optional database-creation script. Loader behavior is unchanged; its comments/input placeholder are translated. The initial source files remain separate. Business findings are included in Business_Analysis_Report.pdf with periods and denominators stated explicitly. The final PBIX container and page definitions were inspected offline; no new live Desktop refresh was performed during packaging.
