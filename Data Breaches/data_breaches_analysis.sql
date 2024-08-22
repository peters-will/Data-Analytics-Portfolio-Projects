/*  --------------------
	Case Study Questions
    -------------------- */
    
-- 1. What are the total amount of records breached for each data breach type?
-- 2. What method has the most amount of records breached? (hacking, poor security, etc)
-- 3. What years had the worst hacks?
-- 4. Which companies had more than one data breach?
-- 5. What industry had the worst data breaches? 
-- 6. What's the #1 type of data breach? 
-- 7. What was the top method of hacking for each year?
-- 8. How did data breaches change over the years?

-- -----------------------------------
-- ***DATA CLEANING***
-- -----------------------------------

-- Change "organization type" column to "industry"
ALTER TABLE data_breaches
RENAME COLUMN `organization type` TO industry;

-- Change "entity_ID" to "breach_ID"
ALTER TABLE data_breaches
RENAME COLUMN entity_ID TO breach_ID;

-- Make all columns lowercase for simplicity/consistency
ALTER TABLE data_breaches
RENAME COLUMN Entity TO entity;

ALTER TABLE data_breaches
RENAME COLUMN Year TO year;

ALTER TABLE data_breaches
RENAME COLUMN Records TO records_breached;

ALTER TABLE data_breaches
RENAME COLUMN Method TO method;

-- Delete the sources column, no valuable info here
SET SQL_SAFE_UPDATES = 0;

ALTER TABLE data_breaches
DROP COLUMN Sources;

SET SQL_SAFE_UPDATES = 1;

-- -----------------------------------
-- ***DATA ANALYSIS***
-- -----------------------------------

-- 1. What are the total amount of records breached for each data breach type?
SELECT DISTINCT(method) AS indv_methods, 
	SUM(records_breached) AS total_records
FROM data_breaches
GROUP BY indv_methods
ORDER BY total_records;

-- 2. What method has the most amount of records breached?
SELECT DISTINCT(method) AS indv_methods, 
	SUM(records) AS total_records
FROM data_breaches
GROUP BY indv_methods
ORDER BY total_records DESC;

-- 3. What years had the worst hacks? (ANS: 2019)
SELECT 
	year, 
    SUM(records) AS records_per_yr
FROM data_breaches
GROUP BY year
ORDER BY records_per_yr DESC;

-- 4. Which companies had more than one data breach? (6 companies)
SELECT
	entity, 
    COUNT(entity) AS total_breaches
FROM data_breaches
GROUP BY entity
HAVING total_breaches > 1
ORDER BY total_breaches DESC;

-- 5. What industry had the worst data breaches? (ANS: Facebook, 5 breaches)
SELECT
	entity, 
    COUNT(entity) AS total_breaches
FROM data_breaches
GROUP BY entity
HAVING total_breaches > 1
ORDER BY total_breaches DESC
LIMIT 1;

-- 6. What's the #1 type of data breach? (ANS: getting hacked!)
SELECT 
	method, 
    COUNT(method) AS total_methods
FROM data_breaches
GROUP BY method
ORDER BY total_methods DESC;

-- 7. What was the top method of hacking for each year?
SELECT
	year,
    method,
    yearly_records
FROM (SELECT
	year,
    method, 
    SUM(records_breached) AS yearly_records,
        RANK () OVER (
			PARTITION BY year
			ORDER BY SUM(records_breached) DESC) AS record_rank
FROM data_breaches
	GROUP BY year, method
	ORDER BY year) AS record_rank
WHERE record_rank = 1;

-- 8. How did data breaches change over the years?
SELECT
	year,
	total_records, 
    total_records - LAG(total_records, 1, total_records) OVER (
		ORDER BY year) AS delta_records
FROM (SELECT 
		year, 
		SUM(records_breached) AS total_records
	FROM data_breaches
		GROUP BY year
		ORDER BY year) AS yearly_records;
        
    
