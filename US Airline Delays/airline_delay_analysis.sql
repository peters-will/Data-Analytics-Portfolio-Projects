SELECT * FROM airline_delay_cleaned;

-- -----------------------------------------------------------
-- ***DATA CLEANING/WRANGLING***
-- -----------------------------------------------------------

-- Create a new column to combine two columns into

ALTER TABLE airline_delay_cleaned
ADD COLUMN airport_name_2 VARCHAR(255);

-- Turn off MySQL safe mode 
SET SQL_SAFE_UPDATES = 0;

-- Merge columns airport_name and airport_abbrev into the new column made above
UPDATE airline_delay_cleaned
SET airport_name_2 = 
	CONCAT(airport_name, ' (', airport_abbrev, ')');	

-- Check to see it works 
SELECT airport_name, airport_abbrev, airport_name_2 FROM airline_delay_cleaned;

-- Drop the 2 original columns that we merged
ALTER TABLE airline_delay_cleaned
DROP COLUMN airport_name,
DROP COLUMN airport_abbrev;

-- Turn safe mode back on
SET SQL_SAFE_UPDATES = 1;

-- Change a few column names for clarity
ALTER TABLE airline_delay_cleaned
RENAME COLUMN airport_name_2 TO airport_name;

-- -----------------------------------------------------------
-- ***AIRLINE ANALYSIS***
-- -----------------------------------------------------------

-- Which airline has the most overall delays? (ANS: Southwest! 1,254,279) 
SELECT carrier_name, SUM(arriving_del15) AS total_delays
FROM airline_delay_cleaned
GROUP BY carrier_name
ORDER BY total_delays DESC;

-- What are the total delays for each airline and each delay type?
SELECT carrier_name,
		ROUND(SUM(carrier_ct), 2) AS total_carrier_ct,
		ROUND(SUM(weather_ct), 2) AS total_weather_ct, 
		ROUND(SUM(nas_ct), 2) AS total_nas_ct, 
		ROUND(SUM(security_ct), 2) AS total_security_ct, 
		ROUND(SUM(late_aircraft_ct), 2) AS total_late_aircraft_ct
FROM airline_delay_cleaned
GROUP BY carrier_name
ORDER BY total_carrier_ct DESC;

-- What is the most common delay for all airlines? (ANS: late aircraft delays!)
SELECT
	ROUND(SUM(carrier_ct), 2) AS total_carrier_ct,
	ROUND(SUM(weather_ct), 2) AS total_weather_ct, 
	ROUND(SUM(nas_ct), 2) AS total_nas_ct, 
	ROUND(SUM(security_ct), 2) AS total_security_ct, 
	ROUND(SUM(late_aircraft_ct), 2) AS total_late_aircraft_ct
FROM airline_delay_cleaned;

-- -----------------------------------------------------------
-- ***SEASONAL AND TEMPORAL ANALYSIS***
-- -----------------------------------------------------------

-- Which year had the most delays? (ANS: 2019!)
SELECT 
	year, 
	SUM(arriving_del15) AS total_delays
FROM airline_delay_cleaned
GROUP BY year
ORDER BY total_delays DESC;

-- What was the most common delay in 2019? (ANS: Late airfraft)
SELECT
	year, 
	ROUND(SUM(carrier_ct), 2) AS total_carrier_ct,
	ROUND(SUM(weather_ct), 2) AS total_weather_ct, 
	ROUND(SUM(nas_ct), 2) AS total_nas_ct, 
	ROUND(SUM(security_ct), 2) AS total_security_ct, 
	ROUND(SUM(late_aircraft_ct), 2) AS total_late_aircraft_ct
FROM airline_delay_cleaned
WHERE year = 2019;

-- Which months were all delays most common in? (ANS: July! Most delays overall occur in summer)
SELECT month, 
	SUM(arriving_del15) AS total_delays
FROM airline_delay_cleaned
GROUP BY month
ORDER BY total_delays DESC;

-- Which months were weather delays most common in? (ANS: July! mostly summer months, which makes sense, per prev stat)
SELECT month,
		ROUND(SUM(weather_ct), 2) AS total_weather_delays 
FROM airline_delay_cleaned
GROUP BY month
ORDER BY total_weather_delays DESC;

-- Which delay's took the longest, in hours, on average? (ANS: Late flights had the longest delays on average!)
SELECT
	ROUND(AVG(carrier_delay), 2)/60 AS avg_carrier_hrs,
	ROUND(AVG(weather_delay), 2)/60 AS avg_weather_hrs,
	ROUND(AVG(nas_delay), 2)/60 AS avg_nas_hrs,
	ROUND(AVG(security_delay), 2)/60 AS avg_security_hrs,
	ROUND(AVG(late_aircraft_delay), 2)/60 AS avg_late_hrs
FROM airline_delay_cleaned;

-- -----------------------------------------------------------
-- ***GEOGRAPHICAL ANALYSIS***
-- -----------------------------------------------------------

-- Which airport, city, and state had the most delays? And of what type?
SELECT
    city, 
    state,
    airport_name,
    arriving_del15
FROM airline_delay_cleaned
ORDER BY arriving_del15 DESC;

-- Rank of Cities with most to least weather delays
SELECT
	city,
    RANK () OVER (
        ORDER BY total_weather DESC
	) AS weather_rank
FROM (SELECT
	city,
    SUM(weather_ct) AS total_weather
FROM airline_delay_cleaned
GROUP BY city) AS weather_summary;

-- Carrier delay rank
SELECT
	city,
    RANK () OVER (
        ORDER BY carrier_total DESC
	) AS carrier_rank
FROM (SELECT
	city,
    SUM(carrier_ct) AS carrier_total
FROM airline_delay_cleaned
GROUP BY city) AS carrier_summary;

-- Security delay rank
SELECT
	city,
    RANK () OVER (
        ORDER BY security_total DESC
	) AS weather_rank
FROM (SELECT
	city,
    SUM(security_ct) AS security_total
FROM airline_delay_cleaned
GROUP BY city) AS security_summary;

-- Change in delays per year per airline
SELECT
	carrier_name, 
    year, 
    total_delays - LAG(total_delays, 1, total_delays) OVER (
		PARTITION BY carrier_name
        ORDER BY carrier_name) AS change_in_delays
FROM (SELECT 
	carrier_name,
    year,
    SUM(arriving_del15) AS total_delays
FROM airline_delay_cleaned
GROUP BY carrier_name, year
ORDER BY carrier_name) AS delays_per_year;

-- Overall change in weather delays per year
SELECT
	year, 
    SUM(weather_ct) - LAG(SUM(weather_ct), 1, SUM(weather_ct)) OVER (
    ORDER BY year) AS change_in_weather
FROM airline_delay_cleaned
GROUP BY year;

-- Overall change in late plane delays per year
SELECT
	year, 
    SUM(late_aircraft_ct) - LAG(SUM(late_aircraft_ct), 1, SUM(late_aircraft_ct)) OVER (
    ORDER BY year) AS change_in_late_aircraft
FROM airline_delay_cleaned
GROUP BY year;

-- *** GUT-CHECKS: code that makes sure things were working above!
-- Double check if the sum of all delay types equals the Delay Indicator column (tested with american airlines flights)
SELECT carrier, arriving_del15,
	carrier_ct + weather_ct + nas_ct + security_ct + late_aircraft_ct AS total_delays 
FROM airline_delay_cleaned
HAVING carrier = 'AA';

-- Gut check - do all of total delay types equal the arr_del15 delays? (roughly, yes)
SELECT
	SUM(arriving_del15) AS total_delays,
    (ROUND(SUM(carrier_ct), 2) +
	ROUND(SUM(weather_ct), 2) +
	ROUND(SUM(nas_ct), 2) + 
	ROUND(SUM(security_ct), 2) +
	ROUND(SUM(late_aircraft_ct), 2)) AS sum_delays
FROM airline_delay_cleaned;
