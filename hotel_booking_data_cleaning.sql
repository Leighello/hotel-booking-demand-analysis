-- ==========================================================
-- HOTEL BOOKING ANALYSIS
-- Data Cleaning using SQL (MySQL 8.0)
--
-- Objectives:
-- 1. Verify the imported dataset.
-- 2. Assess data quality.
-- 3. Clean the dataset.
-- 4. Produce an analysis-ready table for SQL and Python.
-- ==========================================================


CREATE DATABASE hotel_booking_analysis;
USE hotel_booking_analysis;

-- ==========================================================
-- PHASE 1: DATASET VERIFICATION
-- ==========================================================

-- 1.1 Verify the Number of Records
SELECT COUNT(*) as total_rows
FROM hotel_bookings;

-- 1.2 Verify the Number of Columns
SELECT COUNT(*) AS total_columns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'hotel_booking_analysis'
AND TABLE_NAME = 'hotel_bookings';

-- 1.3 Inspect the Table Structure
DESCRIBE hotel_bookings;

-- ==========================================================
-- Phase 2: Data Quality Assessment
-- ==========================================================

-- 2.1 Completeness : Determine which columns contain missing data.
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN children IS NULL THEN 1 ELSE 0 END) AS missing_children,
    SUM(CASE WHEN country IS NULL OR TRIM(country) = '' THEN 1 ELSE 0 END) AS missing_country,
    SUM(CASE WHEN agent IS NULL OR TRIM(agent) = '' THEN 1 ELSE 0 END) AS missing_agent,
    SUM(CASE WHEN company IS NULL OR TRIM(company) = '' THEN 1 ELSE 0 END) AS missing_company
FROM hotel_bookings;

-- 2.2 Uniqueness : Determine whether the dataset contains duplicate records.
WITH duplicate_check AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY hotel, is_canceled, lead_time, arrival_date_year, arrival_date_month,
                            arrival_date_week_number, arrival_date_day_of_month,
                            stays_in_weekend_nights, stays_in_week_nights,
                            adults, children, babies, meal, country,
                            market_segment, distribution_channel, is_repeated_guest,
                            previous_cancellations, previous_bookings_not_canceled,
                            reserved_room_type, assigned_room_type, booking_changes,
                            deposit_type, agent, company, days_in_waiting_list,
                            customer_type, adr, required_car_parking_spaces,
                            total_of_special_requests, reservation_status,
                            reservation_status_date
               ORDER BY arrival_date_year, arrival_date_month, arrival_date_day_of_month
           ) AS row_num
    FROM hotel_bookings
)

SELECT COUNT(*) AS duplicate_rows
FROM duplicate_check
WHERE row_num > 1;

-- 2.3 Consistency : Check for inconsistent or unexpected categorical values
SELECT DISTINCT hotel FROM hotel_bookings;
SELECT DISTINCT meal FROM hotel_bookings;
SELECT DISTINCT market_segment FROM hotel_bookings;
SELECT DISTINCT distribution_channel FROM hotel_bookings;
SELECT DISTINCT customer_type FROM hotel_bookings;
SELECT DISTINCT deposit_type FROM hotel_bookings;
SELECT DISTINCT reservation_status FROM hotel_bookings;
SELECT DISTINCT reserved_room_type FROM hotel_bookings;
SELECT DISTINCT assigned_room_type FROM hotel_bookings;

-- 2.4 Validity : Determine whether the dataset contains invalid values that violate business rules.

-- 2.4.1 Check for invalid dates
SELECT COUNT(*) AS invalid_dates
FROM hotel_bookings
WHERE arrival_date_year < 2015 
   OR arrival_date_year > 2017
   OR arrival_date_day_of_month < 1 
   OR arrival_date_day_of_month > 31;
   
-- 2.4.2 Negative ADR
SELECT COUNT(*) AS negative_adr
FROM hotel_bookings
WHERE adr < 0;
SELECT *
FROM hotel_bookings
WHERE adr < 0;

-- 2.5 Negative Adults,children,babies and Booking Metrics Validity
SELECT
    SUM(CASE WHEN adults < 0 THEN 1 ELSE 0 END) AS negative_adults,
    SUM(CASE WHEN children < 0 THEN 1 ELSE 0 END) AS negative_children,
    SUM(CASE WHEN babies < 0 THEN 1 ELSE 0 END) AS negative_babies,
     SUM(CASE WHEN lead_time < 0 THEN 1 ELSE 0 END) AS negative_lead_time,
    SUM(CASE WHEN days_in_waiting_list < 0 THEN 1 ELSE 0 END) AS negative_waiting_days
FROM hotel_bookings;

-- 2.6 Business Rule Validation
SELECT COUNT(*) AS zero_guest_bookings
FROM hotel_bookings
WHERE adults + children + babies = 0;
-- ==========================================================
-- Phase 3 : Data Cleaning
-- ==========================================================

DROP TABLE IF EXISTS hotel_bookings_cleaned;

-- 3.1 Remove exact duplicate records while preserving the raw dataset.
CREATE TABLE hotel_bookings_cleaned AS
SELECT DISTINCT *
FROM hotel_bookings;

SELECT COUNT(*) AS cleaned_rows
FROM hotel_bookings_cleaned;

-- 3.2 Replace missing categorical values with meaningful labels
UPDATE hotel_bookings_cleaned
SET
    country = CASE
        WHEN country IS NULL THEN 'Unknown'
        ELSE country
    END,
    agent = CASE
        WHEN agent IS NULL THEN 'No Agent'
        ELSE agent
    END,
    company = CASE
        WHEN company IS NULL THEN 'No Company'
        ELSE company
    END;
    
-- -- 3.3 Replace the single negative ADR value with the average ADR
    SELECT ROUND(AVG(adr), 2) AS average_adr
FROM hotel_bookings_cleaned
WHERE adr >= 0;
-- Replace the invalid negative ADR with the calculated average ADR
UPDATE hotel_bookings_cleaned
SET adr = 106.37
WHERE adr < 0;

-- 3.4 Final Data Quality Validation
SELECT
    COUNT(*) AS total_rows,
    SUM(country IS NULL) AS missing_country,
    SUM(agent IS NULL) AS missing_agent,
    SUM(company IS NULL) AS missing_company,
    SUM(adr < 0) AS invalid_adr
FROM hotel_bookings_cleaned;
