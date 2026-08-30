-- ============================================================
-- Customer360 AI — Snowflake Setup
-- Step 1: Database, Schema, and Table Definitions
-- ============================================================
-- Run this script first to create the database structure.
-- Then run 02_generate_data.sql to populate with synthetic data.
-- Then run 03_views_and_functions.sql to create intelligence objects.
-- ============================================================

CREATE DATABASE IF NOT EXISTS CUSTOMER_360_DB;
CREATE SCHEMA IF NOT EXISTS CUSTOMER_360_DB.C360;

USE DATABASE CUSTOMER_360_DB;
USE SCHEMA C360;

-- ============================================================
-- Table 1: CUSTOMERS
-- ============================================================
CREATE OR REPLACE TABLE CUSTOMERS (
    CUSTOMER_ID VARCHAR(20) PRIMARY KEY,
    FIRST_NAME VARCHAR(50),
    LAST_NAME VARCHAR(50),
    DATE_OF_BIRTH DATE,
    GENDER VARCHAR(10),
    CITY VARCHAR(100),
    STATE VARCHAR(2),
    POSTAL_CODE VARCHAR(10),
    CUSTOMER_SINCE DATE,
    CUSTOMER_SEGMENT VARCHAR(30),
    ANNUAL_INCOME NUMBER(12,2),
    EMPLOYMENT_STATUS VARCHAR(30),
    PREFERRED_CHANNEL VARCHAR(20),
    CUSTOMER_LIFETIME_VALUE NUMBER(12,2),
    CURRENT_CUSTOMER_STATUS VARCHAR(20)
);

-- ============================================================
-- Table 2: POLICIES
-- ============================================================
CREATE OR REPLACE TABLE POLICIES (
    POLICY_ID VARCHAR(20) PRIMARY KEY,
    CUSTOMER_ID VARCHAR(20) REFERENCES CUSTOMERS(CUSTOMER_ID),
    POLICY_TYPE VARCHAR(20),
    POLICY_STATUS VARCHAR(20),
    START_DATE DATE,
    END_DATE DATE,
    PREMIUM_AMOUNT NUMBER(12,2),
    COVERAGE_AMOUNT NUMBER(14,2),
    PAYMENT_FREQUENCY VARCHAR(20),
    PAYMENT_STATUS VARCHAR(20),
    DEDUCTIBLE NUMBER(10,2),
    RISK_SCORE NUMBER(5,2),
    RENEWAL_DATE DATE
);

-- ============================================================
-- Table 3: CLAIMS
-- ============================================================
CREATE OR REPLACE TABLE CLAIMS (
    CLAIM_ID VARCHAR(20) PRIMARY KEY,
    CUSTOMER_ID VARCHAR(20) REFERENCES CUSTOMERS(CUSTOMER_ID),
    POLICY_ID VARCHAR(20) REFERENCES POLICIES(POLICY_ID),
    CLAIM_DATE DATE,
    CLAIM_TYPE VARCHAR(30),
    CLAIM_STATUS VARCHAR(20),
    CLAIM_AMOUNT NUMBER(12,2),
    APPROVED_AMOUNT NUMBER(12,2),
    CLAIM_SEVERITY VARCHAR(15),
    PROCESSING_DAYS NUMBER(5),
    CLAIM_DESCRIPTION VARCHAR(500)
);

-- ============================================================
-- Table 4: CUSTOMER_INTERACTIONS
-- ============================================================
CREATE OR REPLACE TABLE CUSTOMER_INTERACTIONS (
    INTERACTION_ID VARCHAR(20) PRIMARY KEY,
    CUSTOMER_ID VARCHAR(20) REFERENCES CUSTOMERS(CUSTOMER_ID),
    INTERACTION_DATE TIMESTAMP,
    CHANNEL VARCHAR(20),
    INTERACTION_TYPE VARCHAR(30),
    AGENT_ID VARCHAR(15),
    SUBJECT VARCHAR(200),
    RESOLUTION_STATUS VARCHAR(20),
    SENTIMENT VARCHAR(15),
    SENTIMENT_SCORE FLOAT,
    CUSTOMER_INTENT VARCHAR(30),
    TRANSCRIPT_ID VARCHAR(20)
);

-- ============================================================
-- Table 5: CALL_TRANSCRIPTS
-- ============================================================
CREATE OR REPLACE TABLE CALL_TRANSCRIPTS (
    TRANSCRIPT_ID VARCHAR(20) PRIMARY KEY,
    CUSTOMER_ID VARCHAR(20) REFERENCES CUSTOMERS(CUSTOMER_ID),
    INTERACTION_ID VARCHAR(20),
    CALL_DATE TIMESTAMP,
    TRANSCRIPT_TEXT VARCHAR(5000),
    SUMMARY VARCHAR(1000),
    CUSTOMER_INTENT VARCHAR(30),
    SENTIMENT VARCHAR(15),
    SENTIMENT_SCORE FLOAT,
    KEY_TOPICS VARCHAR(500),
    RESOLUTION VARCHAR(200),
    FOLLOW_UP_REQUIRED BOOLEAN
);
