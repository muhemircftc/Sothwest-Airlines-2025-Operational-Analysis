# Validation record

Validation below was executed by the author in local SQL Server / Power BI and reported during the project. This delivery package was inspected and packaged offline; SQL Server was not executed in the packaging environment.

## Monthly loaded snapshot
| Month | Records | Cancelled | Diverted | Missing arrival delay |
|---|---:|---:|---:|---:|
| 2025-01 | 539747 | 16312 | 1166 | 17478 |
| 2025-02 | 504884 | 7405 | 1003 | 8408 |
| 2025-03 | 600872 | 6923 | 1648 | 8571 |
| 2025-04 | 583950 | 4914 | 1306 | 6220 |
| 2025-05 | 605648 | 6344 | 1730 | 8074 |
| 2025-06 | 611575 | 9736 | 2367 | 12103 |
| 2025-07 | 631428 | 15473 | 3144 | 18617 |
| 2025-08 | 602378 | 6483 | 2162 | 8645 |
| 2025-09 | 562439 | 2886 | 1224 | 4111 |
| 2025-10 | 605844 | 3204 | 1070 | 4274 |
| 2025-11 | 570550 | 14195 | 1059 | 15254 |
| 2025-12 | 582304 | 9001 | 1379 | 10380 |

Total: 7,001,619 flight records. Source revisions can change counts on later downloads; differences require investigation, not forced adjustment.

## Reconciled Power BI selections
| Selection | Expected |
|---|---|
| WN, full year | 1,391,885 records; 21.40% delayed; 0.85% cancelled; 0.23% diverted; 56.98 min conditional average; 12.19 min load per valid arrival |
| WN / DEN, full year | 90,439 records; 89,623 valid arrivals; 30.61% delayed; 1,580,610 delayed arrival minutes; 17.64 min load; 9.22 pp benchmark gap |
| WN / DEN, January | 6,775 valid arrivals; 23.66% delay rate vs WN 15.21%; 8.45 pp gap |
| WN / DEN / LAS, January, 1800-1859 | 10 valid arrivals; 5 delayed; 50% rate; 84 min conditional average; 420 min total; NAS 188 / carrier 134 / late aircraft 98 |
| WN / DAL, January 9 | 177 records; 135 cancelled; 76.27%; Weather 121 / Air Carrier 14 |
| WN, full year cancellation page | 11,799 cancellations; 3,249 diversions |

## Preserved source exceptions
- One noncancelled/nondiverted record with missing arrival delay: 2025-09-06 YX 5859 JFK-MVY, scheduled raw departure 1209. Retained with NULL delay and excluded only from valid-arrival denominators.
- 14 WN flights have arrival delay >=15 but zero in all five cause fields: September 1 flight / 75 min; October 2 / 297 min; November 11 / 3197 min. Total 3569 min; five DEN-origin flights contribute 920 min.
- WN annual reported-minute coverage: 99.9787%; DEN annual: 99.9418% (rounded).
- 2025-07-24 OO 6512 DSM-ORD uses 2400; source retained, time-only representation normalized to 00:00:00.

## Completed local tests
Schema installation into an empty test database passed. July load into that database passed with 631,428 records, including midnight conversion. Duplicate April load was rejected with error 51014 and unchanged production count. Power Query refresh passed after preserving raw departure time as text. Dashboard filtering and the listed SQL comparisons passed. Dynamic date table and relationship checks passed.
