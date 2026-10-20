# KPI definitions and interpretation

One fact row represents a reported flight record. FlightRecordID is a surrogate identifier. The enforced source key is FlightDate + CarrierCode + FlightNumber + OriginAirport + DestinationAirport + ScheduledDepartureTimeRaw.

| KPI | Definition |
|---|---|
| Flight Records | All records in the selected context, including cancellations and diversions |
| Valid Arrival Records | Records with a nonblank ArrivalDelayMinutes; includes early and on-time arrivals |
| Delayed 15 Plus Records | ArrivalDelayMinutes >= 15 |
| Delayed 15 Plus Rate | Delayed records / valid arrival records |
| Cancellation / Diversion Rate | Corresponding status count / all flight records |
| Avg Arrival Delay Minutes 15 Plus | Average arrival delay only for flights delayed at least 15 minutes |
| Total Arrival Delay Minutes 15 Plus | Sum of arrival delay for that same delayed subset |
| Delay Minutes per Valid Arrival | That delayed-subset minute total / all valid arrival records; not mean signed delay |
| Delay Rate Gap pp | 100 x (selected delay rate - carrier benchmark rate) |
| Reported Cause Minutes 15 Plus | Five reported cause-minute measures summed for the delayed subset |
| Reported Cause Coverage Rate | Reported cause minutes / delayed-subset arrival minutes; minute-based, not flight-based |
| Arrival Minus Reported Cause Minutes | Arrival delay total minus reported cause total; signed reconciliation difference |
| Missing Arrival Delay on Regular Flights | Neither cancelled nor diverted, with missing arrival delay |

The signed reconciliation difference can be negative or conceal offsetting row-level differences in future data. Coverage above 100% must not be clipped. The reviewed 2025 mismatches are all positive differences with five zero cause fields. A cause-total difference is not a sixth proven cause, nor automatically missing weather minutes.

Reported categories support investigation, not proof of station-level root cause. Weather can affect other points in the network. Late aircraft is not proof of avoidable turnaround delay. Flight-delay minutes are not passenger-delay minutes. No passenger, fare, cost or staffing data supports financial savings estimates. A 500-record exploratory threshold is not a statistical significance guarantee.
