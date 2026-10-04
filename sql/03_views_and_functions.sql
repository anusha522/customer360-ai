-- ============================================================
-- Customer360 AI — Views and Cortex AI Functions
-- Step 3: Customer 360 View, Churn Analysis, NBA, AI Functions
-- ============================================================
-- Prerequisites: Run 01_tables.sql and 02_generate_data.sql first.
-- Requires: Snowflake Cortex AI (COMPLETE, SENTIMENT, SUMMARIZE)
-- ============================================================

USE DATABASE CUSTOMER_360_DB;
USE SCHEMA C360;

-- ============================================================
-- Customer 360 Unified View
-- Aggregates policy, claim, interaction, and transcript metrics
-- with explainable churn risk score and customer health score.
-- ============================================================
CREATE OR REPLACE VIEW CUSTOMER_360_VIEW AS
WITH policy_metrics AS (
    SELECT
        CUSTOMER_ID,
        COUNT(*) AS num_policies,
        SUM(CASE WHEN POLICY_STATUS = 'Active' THEN PREMIUM_AMOUNT ELSE 0 END) AS total_annual_premium,
        SUM(COVERAGE_AMOUNT) AS total_coverage,
        COUNT(CASE WHEN POLICY_STATUS = 'Pending Renewal' THEN 1 END) AS pending_renewal_count,
        MIN(CASE WHEN RENEWAL_DATE IS NOT NULL AND RENEWAL_DATE >= CURRENT_DATE() THEN RENEWAL_DATE END) AS next_renewal_date,
        SUM(CASE WHEN PAYMENT_STATUS IN ('Late','Overdue','Delinquent') THEN 1 ELSE 0 END) AS payment_issues_count
    FROM POLICIES GROUP BY CUSTOMER_ID
),
claim_metrics AS (
    SELECT
        CUSTOMER_ID,
        COUNT(*) AS num_claims,
        COUNT(CASE WHEN CLAIM_STATUS IN ('Pending','Under Review') THEN 1 END) AS open_claims,
        COUNT(CASE WHEN CLAIM_STATUS = 'Rejected' THEN 1 END) AS rejected_claims,
        SUM(CLAIM_AMOUNT) AS total_claim_amount,
        SUM(COALESCE(APPROVED_AMOUNT, 0)) AS total_approved_amount,
        ROUND(AVG(PROCESSING_DAYS), 1) AS avg_processing_days,
        MAX(CLAIM_DATE) AS latest_claim_date,
        COUNT(CASE WHEN PROCESSING_DAYS > 30 THEN 1 END) AS delayed_claims,
        MAX(CASE WHEN CLAIM_STATUS IN ('Pending','Under Review') THEN CLAIM_AMOUNT END) AS largest_open_claim
    FROM CLAIMS GROUP BY CUSTOMER_ID
),
interaction_metrics AS (
    SELECT
        CUSTOMER_ID,
        COUNT(*) AS num_interactions,
        MAX(INTERACTION_DATE) AS latest_interaction_date,
        ROUND(AVG(SENTIMENT_SCORE), 3) AS avg_sentiment_score,
        COUNT(CASE WHEN SENTIMENT = 'Negative' THEN 1 END) AS negative_interaction_count,
        COUNT(CASE WHEN INTERACTION_TYPE = 'Cancellation' THEN 1 END) AS cancellation_interaction_count,
        COUNT(CASE WHEN INTERACTION_TYPE = 'Payment Issue' THEN 1 END) AS payment_interaction_count,
        COUNT(CASE WHEN INTERACTION_TYPE = 'Complaint' THEN 1 END) AS complaint_count,
        COUNT(CASE WHEN RESOLUTION_STATUS IN ('Unresolved','Escalated') THEN 1 END) AS unresolved_count,
        AVG(CASE WHEN INTERACTION_DATE >= DATEADD('day', -90, CURRENT_TIMESTAMP()) THEN SENTIMENT_SCORE END) AS recent_sentiment_score,
        COUNT(CASE WHEN INTERACTION_DATE >= DATEADD('day', -90, CURRENT_TIMESTAMP()) THEN 1 END) AS recent_interaction_count
    FROM CUSTOMER_INTERACTIONS GROUP BY CUSTOMER_ID
),
transcript_metrics AS (
    SELECT
        CUSTOMER_ID,
        COUNT(*) AS num_transcripts,
        COUNT(CASE WHEN FOLLOW_UP_REQUIRED = TRUE THEN 1 END) AS pending_followups,
        COUNT(CASE WHEN SENTIMENT = 'Negative' THEN 1 END) AS negative_transcript_count,
        COUNT(CASE WHEN CUSTOMER_INTENT = 'Churn' THEN 1 END) AS churn_intent_count,
        COUNT(CASE WHEN CUSTOMER_INTENT = 'Escalation' THEN 1 END) AS escalation_count
    FROM CALL_TRANSCRIPTS GROUP BY CUSTOMER_ID
),
churn_signals AS (
    SELECT
        c.CUSTOMER_ID,
        LEAST(COALESCE(im.negative_interaction_count, 0) * 4, 20) AS sentiment_signal,
        LEAST(COALESCE(im.complaint_count, 0) * 5, 15) AS complaint_signal,
        LEAST(COALESCE(im.cancellation_interaction_count, 0) * 10, 20) AS cancellation_signal,
        LEAST((COALESCE(cm.open_claims, 0) + COALESCE(cm.delayed_claims, 0)) * 5, 15) AS claim_signal,
        LEAST(COALESCE(pm.payment_issues_count, 0) * 5, 10) AS payment_signal,
        CASE WHEN pm.next_renewal_date IS NOT NULL AND pm.next_renewal_date <= DATEADD('day', 60, CURRENT_DATE()) THEN 10
             WHEN pm.next_renewal_date IS NOT NULL AND pm.next_renewal_date <= DATEADD('day', 120, CURRENT_DATE()) THEN 5
             ELSE 0 END AS renewal_signal,
        LEAST(COALESCE(im.unresolved_count, 0) * 3, 10) AS unresolved_signal,
        LEAST(COALESCE(tm.churn_intent_count, 0) * 8, 15) AS churn_transcript_signal,
        CASE WHEN im.recent_sentiment_score IS NOT NULL AND im.avg_sentiment_score IS NOT NULL
                  AND im.recent_sentiment_score < im.avg_sentiment_score - 0.1 THEN 5 ELSE 0 END AS deterioration_signal
    FROM CUSTOMERS c
    LEFT JOIN policy_metrics pm ON c.CUSTOMER_ID = pm.CUSTOMER_ID
    LEFT JOIN claim_metrics cm ON c.CUSTOMER_ID = cm.CUSTOMER_ID
    LEFT JOIN interaction_metrics im ON c.CUSTOMER_ID = im.CUSTOMER_ID
    LEFT JOIN transcript_metrics tm ON c.CUSTOMER_ID = tm.CUSTOMER_ID
)
SELECT
    c.CUSTOMER_ID, c.FIRST_NAME, c.LAST_NAME,
    c.FIRST_NAME || ' ' || c.LAST_NAME AS FULL_NAME,
    c.DATE_OF_BIRTH, c.GENDER, c.CITY, c.STATE, c.POSTAL_CODE,
    c.CUSTOMER_SINCE, c.CUSTOMER_SEGMENT, c.ANNUAL_INCOME,
    c.EMPLOYMENT_STATUS, c.PREFERRED_CHANNEL,
    c.CUSTOMER_LIFETIME_VALUE, c.CURRENT_CUSTOMER_STATUS,
    COALESCE(pm.num_policies, 0) AS NUM_POLICIES,
    COALESCE(pm.total_annual_premium, 0) AS TOTAL_ANNUAL_PREMIUM,
    COALESCE(pm.total_coverage, 0) AS TOTAL_COVERAGE,
    COALESCE(pm.pending_renewal_count, 0) AS PENDING_RENEWAL_COUNT,
    pm.next_renewal_date AS NEXT_RENEWAL_DATE,
    COALESCE(pm.payment_issues_count, 0) AS PAYMENT_ISSUES_COUNT,
    COALESCE(cm.num_claims, 0) AS NUM_CLAIMS,
    COALESCE(cm.open_claims, 0) AS OPEN_CLAIMS,
    COALESCE(cm.rejected_claims, 0) AS REJECTED_CLAIMS,
    COALESCE(cm.total_claim_amount, 0) AS TOTAL_CLAIM_AMOUNT,
    COALESCE(cm.total_approved_amount, 0) AS TOTAL_APPROVED_AMOUNT,
    cm.avg_processing_days AS AVG_CLAIM_PROCESSING_DAYS,
    cm.latest_claim_date AS LATEST_CLAIM_DATE,
    COALESCE(cm.delayed_claims, 0) AS DELAYED_CLAIMS,
    cm.largest_open_claim AS LARGEST_OPEN_CLAIM,
    COALESCE(im.num_interactions, 0) AS NUM_INTERACTIONS,
    im.latest_interaction_date AS LATEST_INTERACTION_DATE,
    im.avg_sentiment_score AS AVG_SENTIMENT_SCORE,
    COALESCE(im.negative_interaction_count, 0) AS NEGATIVE_INTERACTION_COUNT,
    COALESCE(im.cancellation_interaction_count, 0) AS CANCELLATION_INTERACTION_COUNT,
    COALESCE(im.payment_interaction_count, 0) AS PAYMENT_INTERACTION_COUNT,
    COALESCE(im.complaint_count, 0) AS COMPLAINT_COUNT,
    COALESCE(im.unresolved_count, 0) AS UNRESOLVED_COUNT,
    im.recent_sentiment_score AS RECENT_SENTIMENT_SCORE,
    COALESCE(im.recent_interaction_count, 0) AS RECENT_INTERACTION_COUNT,
    COALESCE(tm.num_transcripts, 0) AS NUM_TRANSCRIPTS,
    COALESCE(tm.pending_followups, 0) AS PENDING_FOLLOWUPS,
    COALESCE(tm.negative_transcript_count, 0) AS NEGATIVE_TRANSCRIPT_COUNT,
    COALESCE(tm.churn_intent_count, 0) AS CHURN_INTENT_COUNT,
    COALESCE(tm.escalation_count, 0) AS ESCALATION_COUNT,
    CASE WHEN pm.next_renewal_date IS NOT NULL
         THEN DATEDIFF('day', CURRENT_DATE(), pm.next_renewal_date) ELSE NULL END AS DAYS_UNTIL_RENEWAL,
    -- Churn risk score (0-100) from 9 signals
    LEAST(cs.sentiment_signal + cs.complaint_signal + cs.cancellation_signal +
          cs.claim_signal + cs.payment_signal + cs.renewal_signal +
          cs.unresolved_signal + cs.churn_transcript_signal + cs.deterioration_signal, 100) AS CHURN_RISK_SCORE,
    CASE
        WHEN LEAST(cs.sentiment_signal + cs.complaint_signal + cs.cancellation_signal +
             cs.claim_signal + cs.payment_signal + cs.renewal_signal +
             cs.unresolved_signal + cs.churn_transcript_signal + cs.deterioration_signal, 100) >= 40 THEN 'HIGH'
        WHEN LEAST(cs.sentiment_signal + cs.complaint_signal + cs.cancellation_signal +
             cs.claim_signal + cs.payment_signal + cs.renewal_signal +
             cs.unresolved_signal + cs.churn_transcript_signal + cs.deterioration_signal, 100) >= 20 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS CHURN_RISK_CATEGORY,
    -- Customer health score (0-100)
    GREATEST(0, LEAST(100,
        50
        + CASE WHEN im.avg_sentiment_score > 0.3 THEN 15 WHEN im.avg_sentiment_score > 0 THEN 5
               WHEN im.avg_sentiment_score > -0.2 THEN -5 ELSE -15 END
        + CASE WHEN cm.open_claims = 0 OR cm.open_claims IS NULL THEN 10 ELSE -5 END
        + CASE WHEN pm.payment_issues_count = 0 OR pm.payment_issues_count IS NULL THEN 10 ELSE -10 END
        + CASE WHEN im.complaint_count = 0 OR im.complaint_count IS NULL THEN 10 ELSE -5 * LEAST(im.complaint_count, 3) END
        + CASE WHEN im.cancellation_interaction_count = 0 OR im.cancellation_interaction_count IS NULL THEN 5 ELSE -10 END
        + CASE WHEN DATEDIFF('year', c.CUSTOMER_SINCE, CURRENT_DATE()) >= 5 THEN 10
               WHEN DATEDIFF('year', c.CUSTOMER_SINCE, CURRENT_DATE()) >= 2 THEN 5 ELSE 0 END
    )) AS CUSTOMER_HEALTH_SCORE
FROM CUSTOMERS c
LEFT JOIN policy_metrics pm ON c.CUSTOMER_ID = pm.CUSTOMER_ID
LEFT JOIN claim_metrics cm ON c.CUSTOMER_ID = cm.CUSTOMER_ID
LEFT JOIN interaction_metrics im ON c.CUSTOMER_ID = im.CUSTOMER_ID
LEFT JOIN transcript_metrics tm ON c.CUSTOMER_ID = tm.CUSTOMER_ID
LEFT JOIN churn_signals cs ON c.CUSTOMER_ID = cs.CUSTOMER_ID;

-- ============================================================
-- Explainable Churn Signals View
-- ============================================================
CREATE OR REPLACE VIEW CHURN_SIGNALS_EXPLAINED AS
WITH signals AS (
    SELECT c.CUSTOMER_ID, cv.FULL_NAME, cv.CUSTOMER_SEGMENT, cv.CUSTOMER_LIFETIME_VALUE,
        cv.CHURN_RISK_SCORE, cv.CHURN_RISK_CATEGORY, cv.CUSTOMER_HEALTH_SCORE,
        cv.NEGATIVE_INTERACTION_COUNT, cv.AVG_SENTIMENT_SCORE, cv.RECENT_SENTIMENT_SCORE,
        CASE WHEN cv.NEGATIVE_INTERACTION_COUNT >= 3 THEN 'HIGH' WHEN cv.NEGATIVE_INTERACTION_COUNT >= 1 THEN 'MEDIUM' ELSE 'LOW' END AS SENTIMENT_SIGNAL_LEVEL,
        cv.COMPLAINT_COUNT,
        CASE WHEN cv.COMPLAINT_COUNT >= 3 THEN 'HIGH' WHEN cv.COMPLAINT_COUNT >= 1 THEN 'MEDIUM' ELSE 'LOW' END AS COMPLAINT_SIGNAL_LEVEL,
        cv.CANCELLATION_INTERACTION_COUNT, cv.CHURN_INTENT_COUNT,
        CASE WHEN cv.CANCELLATION_INTERACTION_COUNT >= 2 THEN 'HIGH' WHEN cv.CANCELLATION_INTERACTION_COUNT >= 1 THEN 'MEDIUM' ELSE 'LOW' END AS CANCELLATION_SIGNAL_LEVEL,
        cv.OPEN_CLAIMS, cv.DELAYED_CLAIMS, cv.LARGEST_OPEN_CLAIM,
        CASE WHEN cv.OPEN_CLAIMS >= 2 OR cv.DELAYED_CLAIMS >= 2 THEN 'HIGH' WHEN cv.OPEN_CLAIMS >= 1 OR cv.DELAYED_CLAIMS >= 1 THEN 'MEDIUM' ELSE 'LOW' END AS CLAIM_SIGNAL_LEVEL,
        cv.PAYMENT_ISSUES_COUNT,
        CASE WHEN cv.PAYMENT_ISSUES_COUNT >= 2 THEN 'HIGH' WHEN cv.PAYMENT_ISSUES_COUNT >= 1 THEN 'MEDIUM' ELSE 'LOW' END AS PAYMENT_SIGNAL_LEVEL,
        cv.DAYS_UNTIL_RENEWAL, cv.NEXT_RENEWAL_DATE,
        CASE WHEN cv.DAYS_UNTIL_RENEWAL IS NOT NULL AND cv.DAYS_UNTIL_RENEWAL <= 60 THEN 'HIGH'
             WHEN cv.DAYS_UNTIL_RENEWAL IS NOT NULL AND cv.DAYS_UNTIL_RENEWAL <= 120 THEN 'MEDIUM' ELSE 'LOW' END AS RENEWAL_SIGNAL_LEVEL,
        cv.UNRESOLVED_COUNT, cv.ESCALATION_COUNT,
        CASE WHEN cv.UNRESOLVED_COUNT >= 3 THEN 'HIGH' WHEN cv.UNRESOLVED_COUNT >= 1 THEN 'MEDIUM' ELSE 'LOW' END AS UNRESOLVED_SIGNAL_LEVEL,
        CASE WHEN cv.RECENT_SENTIMENT_SCORE IS NOT NULL AND cv.AVG_SENTIMENT_SCORE IS NOT NULL
                  AND cv.RECENT_SENTIMENT_SCORE < cv.AVG_SENTIMENT_SCORE - 0.1 THEN TRUE ELSE FALSE END AS SENTIMENT_DETERIORATING,
        ARRAY_CONSTRUCT_COMPACT(
            CASE WHEN cv.CANCELLATION_INTERACTION_COUNT >= 1 THEN 'CANCELLATION INTENT: Customer has ' || cv.CANCELLATION_INTERACTION_COUNT || ' cancellation-related interaction(s)' END,
            CASE WHEN cv.NEGATIVE_INTERACTION_COUNT >= 1 THEN 'NEGATIVE SENTIMENT: ' || cv.NEGATIVE_INTERACTION_COUNT || ' negative interaction(s), avg sentiment score ' || ROUND(cv.AVG_SENTIMENT_SCORE, 2)::VARCHAR END,
            CASE WHEN cv.OPEN_CLAIMS >= 1 THEN 'OPEN CLAIMS: ' || cv.OPEN_CLAIMS || ' open claim(s)' || COALESCE(', largest $' || cv.LARGEST_OPEN_CLAIM::VARCHAR, '') END,
            CASE WHEN cv.DELAYED_CLAIMS >= 1 THEN 'DELAYED CLAIMS: ' || cv.DELAYED_CLAIMS || ' claim(s) with processing > 30 days' END,
            CASE WHEN cv.DAYS_UNTIL_RENEWAL IS NOT NULL AND cv.DAYS_UNTIL_RENEWAL <= 120 THEN 'RENEWAL APPROACHING: Policy renewal in ' || cv.DAYS_UNTIL_RENEWAL || ' days (' || cv.NEXT_RENEWAL_DATE::VARCHAR || ')' END,
            CASE WHEN cv.PAYMENT_ISSUES_COUNT >= 1 THEN 'PAYMENT ISSUES: ' || cv.PAYMENT_ISSUES_COUNT || ' policy/policies with payment problems' END,
            CASE WHEN cv.COMPLAINT_COUNT >= 1 THEN 'COMPLAINTS: ' || cv.COMPLAINT_COUNT || ' complaint(s) recorded' END,
            CASE WHEN cv.UNRESOLVED_COUNT >= 1 THEN 'UNRESOLVED ISSUES: ' || cv.UNRESOLVED_COUNT || ' unresolved/escalated interaction(s)' END,
            CASE WHEN cv.RECENT_SENTIMENT_SCORE IS NOT NULL AND cv.AVG_SENTIMENT_SCORE IS NOT NULL
                      AND cv.RECENT_SENTIMENT_SCORE < cv.AVG_SENTIMENT_SCORE - 0.1
                 THEN 'SENTIMENT DETERIORATION: Recent sentiment (' || ROUND(cv.RECENT_SENTIMENT_SCORE, 2)::VARCHAR || ') is worse than overall average (' || ROUND(cv.AVG_SENTIMENT_SCORE, 2)::VARCHAR || ')' END
        ) AS CHURN_DRIVERS
    FROM CUSTOMERS c JOIN CUSTOMER_360_VIEW cv ON c.CUSTOMER_ID = cv.CUSTOMER_ID
)
SELECT * FROM signals;

-- ============================================================
-- Next Best Action View
-- Deterministic rules engine mapping customer signals to actions
-- ============================================================
CREATE OR REPLACE VIEW NEXT_BEST_ACTION AS
WITH base AS (
    SELECT cv.*,
        CASE
            WHEN cv.OPEN_CLAIMS >= 1 AND cv.LARGEST_OPEN_CLAIM >= 10000 AND cv.COMPLAINT_COUNT >= 1 THEN 'ESCALATE_CLAIM'
            WHEN cv.CANCELLATION_INTERACTION_COUNT >= 2 AND cv.CUSTOMER_LIFETIME_VALUE >= 20000 THEN 'RETENTION_OUTREACH'
            WHEN cv.CANCELLATION_INTERACTION_COUNT >= 1 AND cv.DAYS_UNTIL_RENEWAL IS NOT NULL AND cv.DAYS_UNTIL_RENEWAL <= 60 THEN 'RENEWAL_RETENTION'
            WHEN cv.DELAYED_CLAIMS >= 1 AND cv.OPEN_CLAIMS >= 1 THEN 'EXPEDITE_CLAIM'
            WHEN cv.PAYMENT_ISSUES_COUNT >= 1 AND cv.NUM_POLICIES >= 2 THEN 'PAYMENT_ASSISTANCE'
            WHEN cv.NEGATIVE_INTERACTION_COUNT >= 3 AND cv.DAYS_UNTIL_RENEWAL IS NOT NULL AND cv.DAYS_UNTIL_RENEWAL <= 90 THEN 'PROACTIVE_CALL'
            WHEN cv.COMPLAINT_COUNT >= 2 THEN 'SERVICE_RECOVERY'
            WHEN cv.UNRESOLVED_COUNT >= 2 THEN 'RESOLVE_ISSUES'
            WHEN cv.OPEN_CLAIMS >= 1 THEN 'CLAIM_FOLLOWUP'
            WHEN cv.DAYS_UNTIL_RENEWAL IS NOT NULL AND cv.DAYS_UNTIL_RENEWAL <= 90 AND cv.CHURN_RISK_CATEGORY != 'LOW' THEN 'RENEWAL_REVIEW'
            WHEN cv.PAYMENT_ISSUES_COUNT >= 1 THEN 'PAYMENT_RESOLUTION'
            ELSE 'NO_ACTION'
        END AS ACTION_TRIGGER
    FROM CUSTOMER_360_VIEW cv
)
SELECT
    CUSTOMER_ID, FULL_NAME, CUSTOMER_SEGMENT, CUSTOMER_LIFETIME_VALUE,
    CHURN_RISK_SCORE, CHURN_RISK_CATEGORY, CUSTOMER_HEALTH_SCORE, ACTION_TRIGGER,
    CASE ACTION_TRIGGER
        WHEN 'ESCALATE_CLAIM' THEN 'Assign dedicated claims specialist and escalate open claim'
        WHEN 'RETENTION_OUTREACH' THEN 'Schedule relationship-manager outreach with retention offer'
        WHEN 'RENEWAL_RETENTION' THEN 'Proactive retention call before renewal with incentive review'
        WHEN 'EXPEDITE_CLAIM' THEN 'Expedite delayed claim processing'
        WHEN 'PAYMENT_ASSISTANCE' THEN 'Contact customer to arrange payment plan and prevent policy lapse'
        WHEN 'PROACTIVE_CALL' THEN 'Proactive call to address concerns before renewal'
        WHEN 'SERVICE_RECOVERY' THEN 'Service recovery call with supervisor follow-up'
        WHEN 'RESOLVE_ISSUES' THEN 'Resolve outstanding issues and confirm resolution'
        WHEN 'CLAIM_FOLLOWUP' THEN 'Follow up on open claim status'
        WHEN 'RENEWAL_REVIEW' THEN 'Offer personalized policy review before renewal'
        WHEN 'PAYMENT_RESOLUTION' THEN 'Resolve payment issue to prevent service disruption'
        ELSE 'No immediate action required'
    END AS RECOMMENDED_ACTION,
    CASE
        WHEN CHURN_RISK_CATEGORY = 'HIGH' THEN 'HIGH'
        WHEN CHURN_RISK_CATEGORY = 'MEDIUM' AND ACTION_TRIGGER NOT IN ('NO_ACTION','CLAIM_FOLLOWUP') THEN 'MEDIUM'
        WHEN ACTION_TRIGGER = 'NO_ACTION' THEN 'LOW'
        ELSE 'MEDIUM'
    END AS PRIORITY,
    CASE ACTION_TRIGGER
        WHEN 'ESCALATE_CLAIM' THEN 'Customer has an open high-value claim ($' || COALESCE(LARGEST_OPEN_CLAIM::VARCHAR, 'N/A') || ') and has filed ' || COMPLAINT_COUNT || ' complaint(s).'
        WHEN 'RETENTION_OUTREACH' THEN 'High-value customer (CLV $' || CUSTOMER_LIFETIME_VALUE::VARCHAR || ') has ' || CANCELLATION_INTERACTION_COUNT || ' cancellation interaction(s).'
        WHEN 'RENEWAL_RETENTION' THEN 'Customer has expressed cancellation intent and policy renewal is in ' || COALESCE(DAYS_UNTIL_RENEWAL::VARCHAR, 'N/A') || ' days.'
        WHEN 'EXPEDITE_CLAIM' THEN 'Customer has ' || DELAYED_CLAIMS || ' delayed claim(s) exceeding normal processing time.'
        WHEN 'PAYMENT_ASSISTANCE' THEN 'Customer has payment issues across ' || PAYMENT_ISSUES_COUNT || ' policy/policies while maintaining ' || NUM_POLICIES || ' active policies.'
        WHEN 'PROACTIVE_CALL' THEN 'Customer has ' || NEGATIVE_INTERACTION_COUNT || ' negative interactions and renewal approaching in ' || COALESCE(DAYS_UNTIL_RENEWAL::VARCHAR, 'N/A') || ' days.'
        WHEN 'SERVICE_RECOVERY' THEN 'Customer has ' || COMPLAINT_COUNT || ' complaints. Service recovery needed.'
        WHEN 'RESOLVE_ISSUES' THEN 'Customer has ' || UNRESOLVED_COUNT || ' unresolved/escalated issues.'
        WHEN 'CLAIM_FOLLOWUP' THEN 'Customer has ' || OPEN_CLAIMS || ' open claim(s) requiring status update.'
        WHEN 'RENEWAL_REVIEW' THEN 'Renewal approaching in ' || COALESCE(DAYS_UNTIL_RENEWAL::VARCHAR, 'N/A') || ' days.'
        WHEN 'PAYMENT_RESOLUTION' THEN 'Customer has ' || PAYMENT_ISSUES_COUNT || ' payment issue(s).'
        ELSE 'Customer metrics are within acceptable ranges.'
    END AS REASON,
    CASE
        WHEN ACTION_TRIGGER IN ('ESCALATE_CLAIM','RETENTION_OUTREACH','RENEWAL_RETENTION','PROACTIVE_CALL','SERVICE_RECOVERY') THEN 'Phone'
        WHEN ACTION_TRIGGER IN ('PAYMENT_ASSISTANCE','PAYMENT_RESOLUTION') THEN PREFERRED_CHANNEL
        WHEN ACTION_TRIGGER IN ('EXPEDITE_CLAIM','RESOLVE_ISSUES','CLAIM_FOLLOWUP') THEN 'Phone'
        WHEN ACTION_TRIGGER = 'RENEWAL_REVIEW' THEN 'Email'
        ELSE PREFERRED_CHANNEL
    END AS SUGGESTED_CHANNEL,
    CASE ACTION_TRIGGER
        WHEN 'ESCALATE_CLAIM' THEN 'Faster claim resolution, reduced complaint volume, improved sentiment'
        WHEN 'RETENTION_OUTREACH' THEN 'Retain high-value customer, prevent CLV loss of $' || CUSTOMER_LIFETIME_VALUE::VARCHAR
        WHEN 'RENEWAL_RETENTION' THEN 'Secure policy renewal, prevent premium revenue loss of $' || TOTAL_ANNUAL_PREMIUM::VARCHAR || '/year'
        WHEN 'EXPEDITE_CLAIM' THEN 'Improved processing time, reduced complaint risk'
        WHEN 'PAYMENT_ASSISTANCE' THEN 'Prevent policy lapse, maintain ' || NUM_POLICIES || ' active policies'
        WHEN 'PROACTIVE_CALL' THEN 'Address concerns before renewal, improve sentiment'
        WHEN 'SERVICE_RECOVERY' THEN 'Rebuild customer trust, reduce complaint escalation'
        WHEN 'RESOLVE_ISSUES' THEN 'Clear unresolved items, improve customer experience'
        WHEN 'CLAIM_FOLLOWUP' THEN 'Proactive communication improves satisfaction'
        WHEN 'RENEWAL_REVIEW' THEN 'Increase renewal probability'
        WHEN 'PAYMENT_RESOLUTION' THEN 'Resolve payment issues, prevent coverage gap'
        ELSE 'Continue monitoring'
    END AS EXPECTED_OUTCOME,
    OPEN_CLAIMS, DELAYED_CLAIMS, LARGEST_OPEN_CLAIM, COMPLAINT_COUNT,
    CANCELLATION_INTERACTION_COUNT, NEGATIVE_INTERACTION_COUNT, UNRESOLVED_COUNT,
    PAYMENT_ISSUES_COUNT, DAYS_UNTIL_RENEWAL, NEXT_RENEWAL_DATE,
    TOTAL_ANNUAL_PREMIUM, NUM_POLICIES, AVG_SENTIMENT_SCORE, RECENT_SENTIMENT_SCORE,
    PREFERRED_CHANNEL
FROM base WHERE ACTION_TRIGGER != 'NO_ACTION';

-- ============================================================
-- Cortex AI Functions
-- Require: Snowflake Cortex with llama3.1-70b model
-- ============================================================

-- Transcript Intelligence: Deep AI analysis of customer call transcripts
CREATE OR REPLACE FUNCTION FN_TRANSCRIPT_INTELLIGENCE(P_CUSTOMER_ID VARCHAR)
RETURNS VARCHAR LANGUAGE SQL AS
$$
    SELECT SNOWFLAKE.CORTEX.COMPLETE('llama3.1-70b',
        'You are an insurance customer intelligence analyst. Analyze the following call transcripts for a customer and provide a structured analysis.

TRANSCRIPTS:
' || (SELECT LISTAGG('--- Transcript ' || TRANSCRIPT_ID || ' (Date: ' || CALL_DATE::VARCHAR || ', Stored Sentiment: ' || SENTIMENT || ') ---\n' || TRANSCRIPT_TEXT || '\n\n', '')
     WITHIN GROUP (ORDER BY CALL_DATE DESC)
     FROM (SELECT * FROM CALL_TRANSCRIPTS WHERE CUSTOMER_ID = P_CUSTOMER_ID ORDER BY CALL_DATE DESC LIMIT 5)) ||
'
Provide your analysis in this exact format:
OVERALL SENTIMENT: [Positive/Neutral/Negative]
SENTIMENT TREND: [Improving/Stable/Deteriorating]
KEY CONCERNS:
- [concern 1]
- [concern 2]
CANCELLATION SIGNALS: [None/Low/Medium/High] - [brief explanation]
COMPETITOR MENTIONS: [Yes/No] - [details if yes]
UNRESOLVED ISSUES:
- [issue 1]
CUSTOMER PAIN POINTS:
- [pain point 1]
FOLLOW-UP NEEDED: [Yes/No] - [what specifically]
KEY EVIDENCE:
- [most important quote or fact]
- [second most important]
Do not invent information. Only reference what appears in the transcripts.')
$$;

-- Customer AI Summary: Full structured summary combining all data
CREATE OR REPLACE FUNCTION FN_CUSTOMER_AI_SUMMARY(P_CUSTOMER_ID VARCHAR)
RETURNS VARCHAR LANGUAGE SQL AS
$$
    SELECT SNOWFLAKE.CORTEX.COMPLETE('llama3.1-70b',
        'You are an insurance customer intelligence analyst. Generate a comprehensive customer summary using ONLY the data provided. Follow the exact output format.
RULES:
- Only state facts present in the data.
- Label AI interpretations as "AI INTERPRETATION:" to distinguish from data facts.
- Be specific with claim IDs, dollar amounts, dates.
- Do not invent information.

CUSTOMER DATA:
' || (SELECT 'Name: ' || FULL_NAME || '\nID: ' || CUSTOMER_ID || '\nSegment: ' || CUSTOMER_SEGMENT || '\nCustomer Since: ' || CUSTOMER_SINCE::VARCHAR || '\nStatus: ' || CURRENT_CUSTOMER_STATUS || '\nCLV: $' || CUSTOMER_LIFETIME_VALUE::VARCHAR || '\nPolicies: ' || NUM_POLICIES || ' (Premium: $' || TOTAL_ANNUAL_PREMIUM::VARCHAR || '/yr)\nClaims: ' || NUM_CLAIMS || ' total, ' || OPEN_CLAIMS || ' open, ' || DELAYED_CLAIMS || ' delayed\nLargest Open Claim: $' || COALESCE(LARGEST_OPEN_CLAIM::VARCHAR, 'None') || '\nInteractions: ' || NUM_INTERACTIONS || ' total, ' || NEGATIVE_INTERACTION_COUNT || ' negative, ' || COMPLAINT_COUNT || ' complaints\nCancellation Interactions: ' || CANCELLATION_INTERACTION_COUNT || '\nAvg Sentiment: ' || COALESCE(ROUND(AVG_SENTIMENT_SCORE, 3)::VARCHAR, 'N/A') || '\nChurn Risk: ' || CHURN_RISK_SCORE || '/100 (' || CHURN_RISK_CATEGORY || ')\nHealth Score: ' || CUSTOMER_HEALTH_SCORE || '/100\nDays Until Renewal: ' || COALESCE(DAYS_UNTIL_RENEWAL::VARCHAR, 'N/A')
     FROM CUSTOMER_360_VIEW WHERE CUSTOMER_ID = P_CUSTOMER_ID) ||
'\nCLAIMS: ' || COALESCE((SELECT LISTAGG(CLAIM_ID || ': ' || CLAIM_TYPE || ' $' || CLAIM_AMOUNT::VARCHAR || ' - ' || CLAIM_STATUS || ' (' || PROCESSING_DAYS || 'd)\n', '') FROM CLAIMS WHERE CUSTOMER_ID = P_CUSTOMER_ID), 'None') ||
'\nPOLICIES: ' || COALESCE((SELECT LISTAGG(POLICY_ID || ': ' || POLICY_TYPE || ' ' || POLICY_STATUS || ' $' || PREMIUM_AMOUNT::VARCHAR || ' Payment:' || PAYMENT_STATUS || '\n', '') FROM POLICIES WHERE CUSTOMER_ID = P_CUSTOMER_ID), 'None') ||
'\nRECENT INTERACTIONS: ' || COALESCE((SELECT LISTAGG(INTERACTION_DATE::VARCHAR || ' ' || INTERACTION_TYPE || ' ' || SENTIMENT || ' ' || SUBJECT || '\n', '') WITHIN GROUP (ORDER BY INTERACTION_DATE DESC) FROM (SELECT * FROM CUSTOMER_INTERACTIONS WHERE CUSTOMER_ID = P_CUSTOMER_ID ORDER BY INTERACTION_DATE DESC LIMIT 8)), 'None') ||
'\nTRANSCRIPT SUMMARIES: ' || COALESCE((SELECT LISTAGG(CALL_DATE::VARCHAR || ': ' || SUMMARY || '\n', '') WITHIN GROUP (ORDER BY CALL_DATE DESC) FROM (SELECT * FROM CALL_TRANSCRIPTS WHERE CUSTOMER_ID = P_CUSTOMER_ID ORDER BY CALL_DATE DESC LIMIT 5)), 'None') ||
'\nNEXT BEST ACTION: ' || COALESCE((SELECT RECOMMENDED_ACTION || ' | Priority: ' || PRIORITY || ' | Reason: ' || REASON FROM NEXT_BEST_ACTION WHERE CUSTOMER_ID = P_CUSTOMER_ID), 'No action recommended') ||
'

OUTPUT FORMAT:
## CUSTOMER SUMMARY
[2-3 sentence overview]
## WHY THIS CUSTOMER NEEDS ATTENTION
[Bullet list with data evidence]
## EVIDENCE
[Key data points]
## AI INTERPRETATION
[Your analysis clearly labeled]
## NEXT BEST ACTION
[Recommended action]
## EXPECTED OUTCOME
[What we expect to achieve]')
$$;

-- Generate Personalized Communication (phone/email/SMS)
CREATE OR REPLACE FUNCTION FN_GENERATE_COMMUNICATION(P_CUSTOMER_ID VARCHAR, P_CHANNEL VARCHAR)
RETURNS VARCHAR LANGUAGE SQL AS
$$
    SELECT SNOWFLAKE.CORTEX.COMPLETE('llama3.1-70b',
        'You are a customer relationship manager at an insurance company. Generate a personalized ' || P_CHANNEL || ' communication.
RULES: Only reference facts in the data. Do NOT invent discounts, dates, or promises. Be empathetic. For phone: call script. For email: complete email. For sms: under 300 characters.

CUSTOMER DATA:
' || (SELECT 'Name: ' || FULL_NAME || '\nSegment: ' || CUSTOMER_SEGMENT || '\nCustomer Since: ' || CUSTOMER_SINCE::VARCHAR || '\nCLV: $' || CUSTOMER_LIFETIME_VALUE::VARCHAR || '\nPolicies: ' || NUM_POLICIES || '\nOpen Claims: ' || OPEN_CLAIMS || COALESCE(' (largest: $' || LARGEST_OPEN_CLAIM::VARCHAR || ')', '') || '\nComplaints: ' || COMPLAINT_COUNT || '\nCancellation Interactions: ' || CANCELLATION_INTERACTION_COUNT || '\nAvg Sentiment: ' || COALESCE(ROUND(AVG_SENTIMENT_SCORE, 2)::VARCHAR, 'N/A') || '\nPayment Issues: ' || PAYMENT_ISSUES_COUNT || '\nDays Until Renewal: ' || COALESCE(DAYS_UNTIL_RENEWAL::VARCHAR, 'N/A') || '\nChurn Risk: ' || CHURN_RISK_CATEGORY
     FROM CUSTOMER_360_VIEW WHERE CUSTOMER_ID = P_CUSTOMER_ID) ||
'\nRECENT INTERACTIONS: ' || COALESCE((SELECT LISTAGG('- ' || INTERACTION_DATE::VARCHAR || ': ' || INTERACTION_TYPE || ' (' || SENTIMENT || ') - ' || SUBJECT || '\n', '') WITHIN GROUP (ORDER BY INTERACTION_DATE DESC) FROM (SELECT * FROM CUSTOMER_INTERACTIONS WHERE CUSTOMER_ID = P_CUSTOMER_ID ORDER BY INTERACTION_DATE DESC LIMIT 5)), 'None') ||
'\nRECOMMENDED ACTION: ' || COALESCE((SELECT RECOMMENDED_ACTION FROM NEXT_BEST_ACTION WHERE CUSTOMER_ID = P_CUSTOMER_ID), 'General check-in') ||
'\n\nGenerate the ' || P_CHANNEL || ' communication now.')
$$;

-- Natural Language Q&A: Answer questions about customers using Snowflake data
CREATE OR REPLACE FUNCTION FN_ASK_CUSTOMER_360(P_QUESTION VARCHAR, P_CUSTOMER_ID VARCHAR DEFAULT NULL)
RETURNS VARCHAR LANGUAGE SQL AS
$$
    SELECT SNOWFLAKE.CORTEX.COMPLETE('llama3.1-70b',
        'You are a Customer 360 intelligence assistant for an insurance company. Answer the user question using ONLY the data provided below.
RULES: 1. Only state facts from the data. 2. Distinguish DATA FACTS from INTERPRETATION. 3. Explain reasoning. 4. Do not fabricate data. 5. Be concise.

CUSTOMER DATA:
' ||
        CASE
            WHEN P_CUSTOMER_ID IS NOT NULL THEN
                COALESCE((SELECT '--- PROFILE ---\n' || 'ID: ' || CUSTOMER_ID || '\nName: ' || FULL_NAME || '\nSegment: ' || CUSTOMER_SEGMENT || '\nCLV: $' || CUSTOMER_LIFETIME_VALUE::VARCHAR || '\nPolicies: ' || NUM_POLICIES || ' ($' || TOTAL_ANNUAL_PREMIUM::VARCHAR || '/yr)\nClaims: ' || NUM_CLAIMS || ' total, ' || OPEN_CLAIMS || ' open\nInteractions: ' || NUM_INTERACTIONS || ', ' || NEGATIVE_INTERACTION_COUNT || ' negative\nComplaints: ' || COMPLAINT_COUNT || '\nCancellations: ' || CANCELLATION_INTERACTION_COUNT || '\nSentiment: ' || COALESCE(ROUND(AVG_SENTIMENT_SCORE, 3)::VARCHAR, 'N/A') || '\nChurn Risk: ' || CHURN_RISK_SCORE || '/100 (' || CHURN_RISK_CATEGORY || ')\nHealth: ' || CUSTOMER_HEALTH_SCORE || '/100\nRenewal: ' || COALESCE(DAYS_UNTIL_RENEWAL::VARCHAR, 'N/A') || ' days\n'
                FROM CUSTOMER_360_VIEW WHERE CUSTOMER_ID = P_CUSTOMER_ID), 'Customer not found.') ||
                '\nINTERACTIONS:\n' || COALESCE((SELECT LISTAGG(INTERACTION_DATE::VARCHAR || ' | ' || INTERACTION_TYPE || ' | ' || SUBJECT || ' | ' || SENTIMENT || ' | ' || RESOLUTION_STATUS || '\n', '') WITHIN GROUP (ORDER BY INTERACTION_DATE DESC) FROM (SELECT * FROM CUSTOMER_INTERACTIONS WHERE CUSTOMER_ID = P_CUSTOMER_ID ORDER BY INTERACTION_DATE DESC LIMIT 8)), 'None') ||
                '\nCLAIMS:\n' || COALESCE((SELECT LISTAGG(CLAIM_ID || ': ' || CLAIM_TYPE || ' $' || CLAIM_AMOUNT::VARCHAR || ' ' || CLAIM_STATUS || ' ' || PROCESSING_DAYS || 'd | ' || CLAIM_DESCRIPTION || '\n', '') FROM CLAIMS WHERE CUSTOMER_ID = P_CUSTOMER_ID), 'None') ||
                '\nPOLICIES:\n' || COALESCE((SELECT LISTAGG(POLICY_ID || ': ' || POLICY_TYPE || ' ' || POLICY_STATUS || ' $' || PREMIUM_AMOUNT::VARCHAR || ' Payment:' || PAYMENT_STATUS || ' Renewal:' || COALESCE(RENEWAL_DATE::VARCHAR, 'N/A') || '\n', '') FROM POLICIES WHERE CUSTOMER_ID = P_CUSTOMER_ID), 'None') ||
                '\nTRANSCRIPTS:\n' || COALESCE((SELECT LISTAGG(CALL_DATE::VARCHAR || ' | ' || CUSTOMER_INTENT || ' | ' || SENTIMENT || ' | ' || SUMMARY || '\n', '') WITHIN GROUP (ORDER BY CALL_DATE DESC) FROM (SELECT * FROM CALL_TRANSCRIPTS WHERE CUSTOMER_ID = P_CUSTOMER_ID ORDER BY CALL_DATE DESC LIMIT 5)), 'None') ||
                '\nNBA: ' || COALESCE((SELECT RECOMMENDED_ACTION || ' (' || PRIORITY || ') - ' || REASON FROM NEXT_BEST_ACTION WHERE CUSTOMER_ID = P_CUSTOMER_ID), 'No action')
            ELSE
                '--- TOP HIGH-RISK CUSTOMERS ---\n' ||
                COALESCE((SELECT LISTAGG(CUSTOMER_ID || ' | ' || FULL_NAME || ' | ' || CUSTOMER_SEGMENT || ' | CLV:$' || CUSTOMER_LIFETIME_VALUE::VARCHAR || ' | Risk:' || CHURN_RISK_SCORE::VARCHAR || ' | Claims:' || OPEN_CLAIMS || ' | Sentiment:' || ROUND(AVG_SENTIMENT_SCORE, 2)::VARCHAR || ' | Renewal:' || COALESCE(DAYS_UNTIL_RENEWAL::VARCHAR, 'N/A') || 'd\n', '') WITHIN GROUP (ORDER BY CHURN_RISK_SCORE DESC) FROM (SELECT * FROM CUSTOMER_360_VIEW ORDER BY CHURN_RISK_SCORE DESC LIMIT 15)), 'None') ||
                '\nSTATS: ' || COALESCE((SELECT 'Total:' || COUNT(*)::VARCHAR || ' High:' || SUM(CASE WHEN CHURN_RISK_CATEGORY='HIGH' THEN 1 ELSE 0 END)::VARCHAR || ' Med:' || SUM(CASE WHEN CHURN_RISK_CATEGORY='MEDIUM' THEN 1 ELSE 0 END)::VARCHAR || ' Low:' || SUM(CASE WHEN CHURN_RISK_CATEGORY='LOW' THEN 1 ELSE 0 END)::VARCHAR FROM CUSTOMER_360_VIEW), 'No data') ||
                '\nACTIONS:\n' || COALESCE((SELECT LISTAGG(CUSTOMER_ID || ' | ' || FULL_NAME || ' | ' || RECOMMENDED_ACTION || ' | ' || PRIORITY || '\n', '') WITHIN GROUP (ORDER BY CASE PRIORITY WHEN 'HIGH' THEN 1 ELSE 2 END, CHURN_RISK_SCORE DESC) FROM (SELECT * FROM NEXT_BEST_ACTION WHERE PRIORITY = 'HIGH' ORDER BY CHURN_RISK_SCORE DESC LIMIT 10)), 'None')
        END ||
        '\n\nQUESTION: ' || P_QUESTION || '\n\nProvide a clear, structured answer. If recommending an action, explain why based on the data.')
$$;
