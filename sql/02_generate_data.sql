-- ============================================================
-- Customer360 AI — Synthetic Data Generation
-- Step 2: Generate ~500 customers, ~780 policies, ~700 claims,
--         ~2400 interactions, ~1100 call transcripts
-- ============================================================
-- Prerequisites: Run 01_tables.sql first.
-- ============================================================

USE DATABASE CUSTOMER_360_DB;
USE SCHEMA C360;

-- ============================================================
-- Generate 500 Customers
-- ============================================================
INSERT INTO CUSTOMERS
WITH
seq AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS rn,
           ABS(HASH(SEQ4())) AS h,
           ABS(HASH(SEQ4() * 3 + 7)) AS h2,
           ABS(HASH(SEQ4() * 7 + 13)) AS h3,
           ABS(HASH(SEQ4() * 11 + 17)) AS h4,
           ABS(HASH(SEQ4() * 13 + 23)) AS h5,
           ABS(HASH(SEQ4() * 17 + 29)) AS h6
    FROM TABLE(GENERATOR(ROWCOUNT => 500))
),
first_names_m AS (
    SELECT ROW_NUMBER() OVER (ORDER BY 1) AS idx, column1 AS fname FROM (VALUES
        ('James'),('John'),('Robert'),('Michael'),('William'),
        ('David'),('Richard'),('Joseph'),('Thomas'),('Charles'),
        ('Christopher'),('Daniel'),('Matthew'),('Anthony'),('Mark'),
        ('Donald'),('Steven'),('Paul'),('Andrew'),('Joshua'),
        ('Kenneth'),('Kevin'),('Brian'),('George'),('Timothy'))
),
first_names_f AS (
    SELECT ROW_NUMBER() OVER (ORDER BY 1) AS idx, column1 AS fname FROM (VALUES
        ('Mary'),('Patricia'),('Jennifer'),('Linda'),('Barbara'),
        ('Elizabeth'),('Susan'),('Jessica'),('Sarah'),('Karen'),
        ('Lisa'),('Nancy'),('Betty'),('Margaret'),('Sandra'),
        ('Ashley'),('Dorothy'),('Kimberly'),('Emily'),('Donna'),
        ('Michelle'),('Carol'),('Amanda'),('Melissa'),('Deborah'))
),
last_names AS (
    SELECT ROW_NUMBER() OVER (ORDER BY 1) AS idx, column1 AS lname FROM (VALUES
        ('Smith'),('Johnson'),('Williams'),('Brown'),('Jones'),('Garcia'),('Miller'),
        ('Davis'),('Rodriguez'),('Martinez'),('Hernandez'),('Lopez'),('Gonzalez'),
        ('Wilson'),('Anderson'),('Thomas'),('Taylor'),('Moore'),('Jackson'),('Martin'),
        ('Lee'),('Perez'),('Thompson'),('White'),('Harris'),('Sanchez'),('Clark'),
        ('Ramirez'),('Lewis'),('Robinson'),('Walker'),('Young'),('Allen'),('King'),
        ('Wright'),('Scott'),('Torres'),('Nguyen'),('Hill'),('Flores'),('Green'),
        ('Adams'),('Nelson'),('Baker'),('Hall'),('Rivera'),('Campbell'),('Mitchell'),
        ('Carter'),('Roberts'))
),
cities AS (
    SELECT ROW_NUMBER() OVER (ORDER BY 1) AS idx, column1 AS city, column2 AS st, column3 AS postal FROM (VALUES
        ('New York','NY','10001'),('Los Angeles','CA','90001'),('Chicago','IL','60601'),
        ('Houston','TX','77001'),('Phoenix','AZ','85001'),('Philadelphia','PA','19101'),
        ('San Antonio','TX','78201'),('San Diego','CA','92101'),('Dallas','TX','75201'),
        ('San Jose','CA','95101'),('Austin','TX','78701'),('Jacksonville','FL','32201'),
        ('Fort Worth','TX','76101'),('Columbus','OH','43201'),('Charlotte','NC','28201'),
        ('Indianapolis','IN','46201'),('San Francisco','CA','94101'),('Seattle','WA','98101'),
        ('Denver','CO','80201'),('Nashville','TN','37201'),('Oklahoma City','OK','73101'),
        ('Portland','OR','97201'),('Las Vegas','NV','89101'),('Memphis','TN','38101'),
        ('Louisville','KY','40201'),('Baltimore','MD','21201'),('Milwaukee','WI','53201'),
        ('Albuquerque','NM','87101'),('Tucson','AZ','85701'),('Fresno','CA','93701'),
        ('Sacramento','CA','95801'),('Mesa','AZ','85201'),('Kansas City','MO','64101'),
        ('Atlanta','GA','30301'),('Omaha','NE','68101'),('Raleigh','NC','27601'),
        ('Miami','FL','33101'),('Tampa','FL','33601'),('Minneapolis','MN','55401'),
        ('New Orleans','LA','70112'))
)
SELECT
    'CUST-' || LPAD(s.rn::VARCHAR, 4, '0'),
    CASE WHEN MOD(s.h, 2) = 0 THEN m.fname ELSE f.fname END,
    ln.lname,
    DATEADD('day', -(7300 + MOD(s.h2, 18250)), CURRENT_DATE()),
    CASE WHEN MOD(s.h, 2) = 0 THEN 'M' ELSE 'F' END,
    c.city, c.st, c.postal,
    DATEADD('day', -(365 + MOD(s.h3, 6935)), CURRENT_DATE()),
    CASE
        WHEN MOD(s.h, 100) < 15 THEN 'Premium'
        WHEN MOD(s.h, 100) < 45 THEN 'Standard'
        WHEN MOD(s.h, 100) < 60 THEN 'Young Professional'
        WHEN MOD(s.h, 100) < 80 THEN 'Family'
        WHEN MOD(s.h, 100) < 90 THEN 'Retiree'
        ELSE 'High Value'
    END,
    CASE
        WHEN MOD(s.h, 100) < 15 THEN 120000 + MOD(s.h2, 230000)
        WHEN MOD(s.h, 100) < 45 THEN 45000 + MOD(s.h2, 50000)
        WHEN MOD(s.h, 100) < 60 THEN 55000 + MOD(s.h2, 65000)
        WHEN MOD(s.h, 100) < 80 THEN 65000 + MOD(s.h2, 85000)
        WHEN MOD(s.h, 100) < 90 THEN 35000 + MOD(s.h2, 50000)
        ELSE 150000 + MOD(s.h2, 350000)
    END,
    CASE MOD(s.h3, 5) WHEN 0 THEN 'Employed' WHEN 1 THEN 'Self-Employed' WHEN 2 THEN 'Employed' WHEN 3 THEN 'Retired' ELSE 'Employed' END,
    CASE MOD(s.h4, 5) WHEN 0 THEN 'Phone' WHEN 1 THEN 'Email' WHEN 2 THEN 'Chat' WHEN 3 THEN 'Web' ELSE 'Branch' END,
    CASE
        WHEN MOD(s.h, 100) < 15 THEN 15000 + MOD(s.h5, 60000)
        WHEN MOD(s.h, 100) < 45 THEN 3000 + MOD(s.h5, 17000)
        WHEN MOD(s.h, 100) < 60 THEN 2000 + MOD(s.h5, 13000)
        WHEN MOD(s.h, 100) < 80 THEN 5000 + MOD(s.h5, 25000)
        WHEN MOD(s.h, 100) < 90 THEN 8000 + MOD(s.h5, 32000)
        ELSE 25000 + MOD(s.h5, 75000)
    END,
    CASE
        WHEN MOD(s.h6, 100) < 80 THEN 'Active'
        WHEN MOD(s.h6, 100) < 93 THEN 'At Risk'
        ELSE 'Inactive'
    END
FROM seq s
JOIN first_names_m m ON m.idx = MOD(s.h2, 25) + 1
JOIN first_names_f f ON f.idx = MOD(s.h3, 25) + 1
JOIN last_names ln ON ln.idx = MOD(s.h4, 50) + 1
JOIN cities c ON c.idx = MOD(s.h5, 40) + 1;

-- ============================================================
-- Generate ~780 Policies
-- ============================================================
INSERT INTO POLICIES
WITH
customer_list AS (
    SELECT CUSTOMER_ID, CUSTOMER_SINCE, CUSTOMER_SEGMENT,
           ROW_NUMBER() OVER (ORDER BY CUSTOMER_ID) AS cust_rn
    FROM CUSTOMERS
),
policy_assignments AS (
    SELECT c.CUSTOMER_ID, c.CUSTOMER_SINCE, c.CUSTOMER_SEGMENT,
        p.idx AS policy_num,
        ABS(HASH(c.CUSTOMER_ID || '-' || p.idx)) AS h,
        ABS(HASH(c.CUSTOMER_ID || '-' || p.idx || 'x')) AS h2,
        ABS(HASH(c.CUSTOMER_ID || '-' || p.idx || 'y')) AS h3,
        ABS(HASH(c.CUSTOMER_ID || '-' || p.idx || 'z')) AS h4
    FROM customer_list c
    CROSS JOIN (SELECT 1 AS idx UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4) p
    WHERE p.idx <= CASE
        WHEN c.CUSTOMER_SEGMENT IN ('Premium','High Value') THEN CASE WHEN MOD(ABS(HASH(c.CUSTOMER_ID)), 10) < 4 THEN 3 ELSE 2 END
        WHEN c.CUSTOMER_SEGMENT = 'Family' THEN CASE WHEN MOD(ABS(HASH(c.CUSTOMER_ID)), 10) < 5 THEN 2 ELSE 1 END
        ELSE CASE WHEN MOD(ABS(HASH(c.CUSTOMER_ID)), 10) < 3 THEN 2 ELSE 1 END
    END
),
numbered AS (SELECT *, ROW_NUMBER() OVER (ORDER BY CUSTOMER_ID, policy_num) AS rn FROM policy_assignments)
SELECT
    'POL-' || LPAD(rn::VARCHAR, 5, '0'),
    CUSTOMER_ID,
    CASE MOD(h, 4) WHEN 0 THEN 'Auto' WHEN 1 THEN 'Home' WHEN 2 THEN 'Life' ELSE 'Health' END,
    CASE WHEN MOD(h2, 100) < 70 THEN 'Active' WHEN MOD(h2, 100) < 85 THEN 'Expired' WHEN MOD(h2, 100) < 92 THEN 'Pending Renewal' ELSE 'Cancelled' END,
    DATEADD('day', MOD(h3, 1460), CUSTOMER_SINCE),
    DATEADD('year', 1, DATEADD('day', MOD(h3, 1460), CUSTOMER_SINCE)),
    CASE MOD(h, 4) WHEN 0 THEN 800+MOD(h2,2200) WHEN 1 THEN 1200+MOD(h2,3800) WHEN 2 THEN 500+MOD(h2,4500) ELSE 2000+MOD(h2,8000) END,
    CASE MOD(h, 4) WHEN 0 THEN 25000+MOD(h3,75000) WHEN 1 THEN 100000+MOD(h3,400000) WHEN 2 THEN 50000+MOD(h3,950000) ELSE 10000+MOD(h3,90000) END,
    CASE MOD(h4, 3) WHEN 0 THEN 'Monthly' WHEN 1 THEN 'Quarterly' ELSE 'Annual' END,
    CASE WHEN MOD(h4, 100) < 75 THEN 'Current' WHEN MOD(h4, 100) < 88 THEN 'Late' WHEN MOD(h4, 100) < 95 THEN 'Overdue' ELSE 'Delinquent' END,
    CASE MOD(h, 4) WHEN 0 THEN 500+MOD(h4,1500) WHEN 1 THEN 1000+MOD(h4,4000) WHEN 2 THEN 0 ELSE 250+MOD(h4,2750) END,
    ROUND(1 + MOD(h2, 90) / 10.0, 1),
    CASE WHEN MOD(h2, 100) < 70 THEN DATEADD('day', MOD(h3, 365), CURRENT_DATE()) ELSE NULL END
FROM numbered;

-- ============================================================
-- Generate ~700 Claims
-- ============================================================
INSERT INTO CLAIMS
WITH
policy_list AS (
    SELECT POLICY_ID, CUSTOMER_ID, POLICY_TYPE, START_DATE, END_DATE, COVERAGE_AMOUNT, POLICY_STATUS,
           ROW_NUMBER() OVER (ORDER BY POLICY_ID) AS pol_rn
    FROM POLICIES WHERE POLICY_STATUS IN ('Active','Expired','Pending Renewal')
),
claim_gen AS (
    SELECT p.*, c.idx AS claim_num,
        ABS(HASH(p.POLICY_ID || '-C' || c.idx)) AS h,
        ABS(HASH(p.POLICY_ID || '-C' || c.idx || 'a')) AS h2,
        ABS(HASH(p.POLICY_ID || '-C' || c.idx || 'b')) AS h3,
        ABS(HASH(p.POLICY_ID || '-C' || c.idx || 'c')) AS h4
    FROM policy_list p
    CROSS JOIN (SELECT 1 AS idx UNION ALL SELECT 2) c
    WHERE c.idx <= CASE
        WHEN MOD(ABS(HASH(p.POLICY_ID)), 100) < 55 THEN 1
        WHEN MOD(ABS(HASH(p.POLICY_ID)), 100) < 80 THEN 0
        ELSE 2
    END
),
claim_types_by_policy AS (
    SELECT *,
        CASE
            WHEN POLICY_TYPE = 'Auto' THEN CASE MOD(h, 3) WHEN 0 THEN 'Accident' WHEN 1 THEN 'Theft' ELSE 'Weather Damage' END
            WHEN POLICY_TYPE = 'Home' THEN CASE MOD(h, 3) WHEN 0 THEN 'Property Damage' WHEN 1 THEN 'Weather Damage' ELSE 'Theft' END
            WHEN POLICY_TYPE = 'Health' THEN 'Medical'
            ELSE CASE MOD(h, 2) WHEN 0 THEN 'Medical' ELSE 'Accident' END
        END AS ct
    FROM claim_gen
),
numbered AS (SELECT *, ROW_NUMBER() OVER (ORDER BY POLICY_ID, claim_num) AS rn FROM claim_types_by_policy),
descriptions AS (
    SELECT n.*,
        CASE ct
            WHEN 'Accident' THEN CASE MOD(h2, 4)
                WHEN 0 THEN 'Rear-end collision at intersection. Vehicle sustained moderate bumper and trunk damage. No injuries reported.'
                WHEN 1 THEN 'Multi-vehicle accident on highway during rain. Front-end damage and airbag deployment. Minor injuries treated at scene.'
                WHEN 2 THEN 'Side collision in parking lot. Door panel and mirror damage. Police report filed.'
                ELSE 'Single-vehicle accident. Hit guardrail due to icy road conditions. Significant front-end damage requiring tow.' END
            WHEN 'Theft' THEN CASE MOD(h2, 3)
                WHEN 0 THEN 'Vehicle stolen from residential driveway overnight. Police report filed.'
                WHEN 1 THEN 'Break-in and theft of personal belongings from locked vehicle. Window smashed. Electronics and tools stolen.'
                ELSE 'Catalytic converter theft from parked vehicle. Discovered upon starting car.' END
            WHEN 'Property Damage' THEN CASE MOD(h2, 4)
                WHEN 0 THEN 'Water damage from burst pipe in upstairs bathroom. Ceiling and flooring in living room affected.'
                WHEN 1 THEN 'Kitchen fire caused by electrical malfunction. Significant damage to cabinets, appliances, and smoke damage throughout.'
                WHEN 2 THEN 'Tree fell on roof during storm. Structural damage to roof and water intrusion in attic.'
                ELSE 'Vandalism to exterior property. Broken windows and graffiti damage. Security camera footage provided.' END
            WHEN 'Weather Damage' THEN CASE MOD(h2, 3)
                WHEN 0 THEN 'Hail damage to roof and siding. Multiple shingles displaced and gutters damaged.'
                WHEN 1 THEN 'Flooding from heavy rainfall. Basement flooded with 3 feet of water. Furnace and water heater damaged.'
                ELSE 'Wind damage from severe thunderstorm. Fence destroyed and shed roof torn off.' END
            WHEN 'Medical' THEN CASE MOD(h2, 4)
                WHEN 0 THEN 'Emergency room visit for chest pain. CT scan and blood work performed. Diagnosed with acid reflux.'
                WHEN 1 THEN 'Scheduled knee replacement surgery. Pre-authorization obtained. 3-day hospital stay expected.'
                WHEN 2 THEN 'Urgent care visit for broken wrist from fall. X-ray and casting performed.'
                ELSE 'Specialist referral for ongoing back pain. MRI and physical therapy sessions required.' END
        END AS desc_text
    FROM numbered n
)
SELECT
    'CLM-' || LPAD(rn::VARCHAR, 5, '0'),
    CUSTOMER_ID, POLICY_ID,
    DATEADD('day', MOD(h3, GREATEST(DATEDIFF('day', START_DATE, LEAST(END_DATE, CURRENT_DATE())), 30)), START_DATE),
    ct,
    CASE WHEN MOD(h2,100)<45 THEN 'Resolved' WHEN MOD(h2,100)<65 THEN 'Pending' WHEN MOD(h2,100)<78 THEN 'Under Review' WHEN MOD(h2,100)<88 THEN 'Approved' ELSE 'Rejected' END,
    CASE WHEN MOD(h4,100)<40 THEN 1000+MOD(h3,4000) WHEN MOD(h4,100)<70 THEN 5000+MOD(h3,15000) WHEN MOD(h4,100)<90 THEN 15000+MOD(h3,35000) ELSE 35000+MOD(h3,65000) END,
    CASE
        WHEN MOD(h2, 100) >= 88 THEN 0
        WHEN MOD(h2, 100) < 45 THEN ROUND((0.7 + MOD(h4, 30)/100.0) * (CASE WHEN MOD(h4,100)<40 THEN 1000+MOD(h3,4000) WHEN MOD(h4,100)<70 THEN 5000+MOD(h3,15000) WHEN MOD(h4,100)<90 THEN 15000+MOD(h3,35000) ELSE 35000+MOD(h3,65000) END), 2)
        WHEN MOD(h2, 100) < 78 THEN NULL
        ELSE ROUND((0.8 + MOD(h4, 20)/100.0) * (CASE WHEN MOD(h4,100)<40 THEN 1000+MOD(h3,4000) WHEN MOD(h4,100)<70 THEN 5000+MOD(h3,15000) WHEN MOD(h4,100)<90 THEN 15000+MOD(h3,35000) ELSE 35000+MOD(h3,65000) END), 2)
    END,
    CASE WHEN MOD(h4, 100) < 50 THEN 'Low' WHEN MOD(h4, 100) < 85 THEN 'Medium' ELSE 'High' END,
    CASE WHEN MOD(h2,100)<45 THEN 5+MOD(h4,40) WHEN MOD(h2,100)<78 THEN 1+MOD(h4,60) WHEN MOD(h2,100)<88 THEN 10+MOD(h4,25) ELSE 15+MOD(h4,30) END,
    desc_text
FROM descriptions;

-- ============================================================
-- Generate ~2400 Customer Interactions
-- ============================================================
INSERT INTO CUSTOMER_INTERACTIONS
WITH
customer_list AS (
    SELECT CUSTOMER_ID, CUSTOMER_SEGMENT, CURRENT_CUSTOMER_STATUS, PREFERRED_CHANNEL,
           ROW_NUMBER() OVER (ORDER BY CUSTOMER_ID) AS cust_rn
    FROM CUSTOMERS
),
interaction_gen AS (
    SELECT c.CUSTOMER_ID, c.CUSTOMER_SEGMENT, c.CURRENT_CUSTOMER_STATUS, c.PREFERRED_CHANNEL,
        i.idx,
        ABS(HASH(c.CUSTOMER_ID || '-I' || i.idx)) AS h,
        ABS(HASH(c.CUSTOMER_ID || '-I' || i.idx || 'a')) AS h2,
        ABS(HASH(c.CUSTOMER_ID || '-I' || i.idx || 'b')) AS h3,
        ABS(HASH(c.CUSTOMER_ID || '-I' || i.idx || 'c')) AS h4,
        ABS(HASH(c.CUSTOMER_ID || '-I' || i.idx || 'd')) AS h5
    FROM customer_list c
    CROSS JOIN (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS idx FROM TABLE(GENERATOR(ROWCOUNT => 8))) i
    WHERE i.idx <= CASE
        WHEN c.CURRENT_CUSTOMER_STATUS = 'At Risk' THEN 5 + MOD(ABS(HASH(c.CUSTOMER_ID || 'cnt')), 4)
        WHEN c.CUSTOMER_SEGMENT IN ('Premium','High Value') THEN 4 + MOD(ABS(HASH(c.CUSTOMER_ID || 'cnt')), 3)
        ELSE 3 + MOD(ABS(HASH(c.CUSTOMER_ID || 'cnt')), 4)
    END
),
interaction_types AS (
    SELECT ROW_NUMBER() OVER (ORDER BY 1) AS idx, column1 AS itype FROM (VALUES
        ('Complaint'),('Claim Inquiry'),('Policy Question'),('Renewal'),
        ('Cancellation'),('Payment Issue'),('Coverage Question'),('General Inquiry'))
),
subjects AS (
    SELECT ig.*, it.itype AS it_name,
        CASE it.itype
            WHEN 'Complaint' THEN CASE MOD(ig.h3, 5)
                WHEN 0 THEN 'Complaint about claim processing delay' WHEN 1 THEN 'Dissatisfied with customer service experience'
                WHEN 2 THEN 'Complaint about premium increase' WHEN 3 THEN 'Issue with claim denial' ELSE 'Unhappy with policy terms' END
            WHEN 'Claim Inquiry' THEN CASE MOD(ig.h3, 4)
                WHEN 0 THEN 'Status update on pending claim' WHEN 1 THEN 'Question about claim documentation'
                WHEN 2 THEN 'Follow-up on claim payment' ELSE 'Requesting expedited claim processing' END
            WHEN 'Policy Question' THEN CASE MOD(ig.h3, 4)
                WHEN 0 THEN 'Inquiry about policy coverage details' WHEN 1 THEN 'Question about adding coverage'
                WHEN 2 THEN 'Policy terms clarification' ELSE 'Asking about policy limits' END
            WHEN 'Renewal' THEN CASE MOD(ig.h3, 3)
                WHEN 0 THEN 'Renewal quote request' WHEN 1 THEN 'Questioning renewal premium increase' ELSE 'Renewal process inquiry' END
            WHEN 'Cancellation' THEN CASE MOD(ig.h3, 3)
                WHEN 0 THEN 'Requesting policy cancellation' WHEN 1 THEN 'Considering cancellation due to price' ELSE 'Exploring alternatives before cancelling' END
            WHEN 'Payment Issue' THEN CASE MOD(ig.h3, 4)
                WHEN 0 THEN 'Payment failed - card declined' WHEN 1 THEN 'Requesting payment plan adjustment'
                WHEN 2 THEN 'Late payment fee dispute' ELSE 'Auto-pay setup assistance' END
            WHEN 'Coverage Question' THEN CASE MOD(ig.h3, 3)
                WHEN 0 THEN 'Asking about additional coverage options' WHEN 1 THEN 'Coverage gap concern' ELSE 'Understanding deductible amounts' END
            ELSE CASE MOD(ig.h3, 3)
                WHEN 0 THEN 'General account inquiry' WHEN 1 THEN 'Address update request' ELSE 'Document request' END
        END AS subj
    FROM interaction_gen ig
    JOIN interaction_types it ON it.idx = MOD(ig.h2, 8) + 1
),
numbered AS (SELECT *, ROW_NUMBER() OVER (ORDER BY CUSTOMER_ID, idx) AS rn FROM subjects)
SELECT
    'INT-' || LPAD(rn::VARCHAR, 6, '0'),
    CUSTOMER_ID,
    DATEADD('hour', MOD(h4, 720), DATEADD('day', -MOD(h3, 365), CURRENT_TIMESTAMP())),
    CASE MOD(h, 5) WHEN 0 THEN 'Phone' WHEN 1 THEN 'Email' WHEN 2 THEN 'Chat' WHEN 3 THEN 'Web' ELSE 'Branch' END,
    it_name,
    'AGT-' || LPAD(MOD(h4, 50 + 1)::VARCHAR, 3, '0'),
    subj,
    CASE WHEN MOD(h5, 100) < 55 THEN 'Resolved' WHEN MOD(h5, 100) < 75 THEN 'Pending' WHEN MOD(h5, 100) < 90 THEN 'Escalated' ELSE 'Unresolved' END,
    CASE
        WHEN it_name IN ('Complaint','Cancellation') THEN CASE WHEN MOD(h5, 100) < 70 THEN 'Negative' WHEN MOD(h5, 100) < 90 THEN 'Neutral' ELSE 'Positive' END
        WHEN it_name IN ('Payment Issue','Claim Inquiry') THEN CASE WHEN MOD(h5, 100) < 40 THEN 'Negative' WHEN MOD(h5, 100) < 75 THEN 'Neutral' ELSE 'Positive' END
        WHEN it_name = 'General Inquiry' THEN CASE WHEN MOD(h5, 100) < 10 THEN 'Negative' WHEN MOD(h5, 100) < 50 THEN 'Neutral' ELSE 'Positive' END
        ELSE CASE WHEN MOD(h5, 100) < 20 THEN 'Negative' WHEN MOD(h5, 100) < 55 THEN 'Neutral' ELSE 'Positive' END
    END,
    CASE
        WHEN it_name IN ('Complaint','Cancellation') THEN ROUND(-0.3 - MOD(h4, 60) / 100.0, 2)
        WHEN it_name IN ('Payment Issue','Claim Inquiry') THEN ROUND(-0.1 + MOD(h4, 60) / 100.0 - 0.3, 2)
        WHEN it_name = 'General Inquiry' THEN ROUND(0.2 + MOD(h4, 60) / 100.0, 2)
        ELSE ROUND(MOD(h4, 80) / 100.0 - 0.2, 2)
    END,
    CASE it_name
        WHEN 'Complaint' THEN 'Escalation' WHEN 'Claim Inquiry' THEN 'Information' WHEN 'Policy Question' THEN 'Information'
        WHEN 'Renewal' THEN 'Retention' WHEN 'Cancellation' THEN 'Churn' WHEN 'Payment Issue' THEN 'Resolution'
        WHEN 'Coverage Question' THEN 'Upsell' ELSE 'General'
    END,
    NULL  -- TRANSCRIPT_ID linked after transcripts are created
FROM numbered;

-- ============================================================
-- Generate ~1100 Call Transcripts
-- Batch 1: All Phone and Chat interactions (~980)
-- Batch 2: ~15% of Email/Web/Branch interactions (~120)
-- Then link transcript IDs back to interactions table.
-- ============================================================

INSERT INTO CALL_TRANSCRIPTS
WITH
phone_interactions AS (
    SELECT
        ci.INTERACTION_ID, ci.CUSTOMER_ID, ci.INTERACTION_DATE, ci.INTERACTION_TYPE,
        ci.SENTIMENT, ci.SENTIMENT_SCORE,
        ROW_NUMBER() OVER (ORDER BY ci.INTERACTION_ID) AS rn,
        ABS(HASH(ci.INTERACTION_ID || 'tx')) AS h,
        ABS(HASH(ci.INTERACTION_ID || 'ty')) AS h2
    FROM CUSTOMER_INTERACTIONS ci
    WHERE ci.CHANNEL IN ('Phone','Chat')
),
transcript_templates AS (
    SELECT pi.*,
    CASE
      -- COMPLAINT transcripts (6 variants)
      WHEN INTERACTION_TYPE = 'Complaint' AND MOD(h, 6) = 0 THEN
        'Agent: Thank you for calling. How can I help you today?\nCustomer: I am extremely frustrated. I filed a claim over ' || (20 + MOD(h2, 25))::VARCHAR || ' days ago and I still have not received any update. This is unacceptable.\nAgent: I sincerely apologize for the delay. Let me pull up your claim right away.\nCustomer: Every time I call, I get the same response. I need answers now. I have bills to pay and I cannot wait any longer.\nAgent: I completely understand your frustration. I can see your claim is currently under review. Let me escalate this to our senior claims team.\nCustomer: You said that last time too. I am seriously considering switching to another insurance company. My friend recommended State coverage and they process claims in 5 days.\nAgent: I do not want to lose you as a customer. Let me personally follow up with the claims supervisor and ensure you get a call back within 24 hours with a resolution.\nCustomer: Fine, but this is my last attempt. If I do not hear back tomorrow, I am cancelling everything.'
      WHEN INTERACTION_TYPE = 'Complaint' AND MOD(h, 6) = 1 THEN
        'Agent: Good morning, thank you for calling. What can I assist you with?\nCustomer: My premium went up by ' || (15 + MOD(h2, 30))::VARCHAR || ' percent and nobody told me why. I just got the bill and I am shocked.\nAgent: I understand your concern. Let me review your policy details.\nCustomer: I have been a loyal customer for ' || (3 + MOD(h2, 12))::VARCHAR || ' years with no claims, and this is how I get treated? A massive increase with no explanation?\nAgent: I can see that the increase is related to a general rate adjustment in your area. Let me check if there are any discounts we can apply.\nCustomer: My neighbor has the same coverage with your competitor for much less. I need you to do better or I am leaving.\nAgent: I value your loyalty. Let me review your policy for any bundling discounts or loyalty adjustments. Can I put you on a brief hold?\nCustomer: Make it quick. I have already started getting quotes from other companies.'
      WHEN INTERACTION_TYPE = 'Complaint' AND MOD(h, 6) = 2 THEN
        'Agent: Thank you for calling. How may I help you?\nCustomer: I want to speak to a manager. My claim was denied and the reason makes no sense.\nAgent: I am sorry to hear that. Can you share your claim number so I can review the details?\nCustomer: The claim number is CLM-' || LPAD(MOD(h2, 700)::VARCHAR, 5, '0') || '. They said my damage was not covered but I have been paying for comprehensive coverage.\nAgent: Let me look into this. I see the denial was related to a policy exclusion for gradual wear.\nCustomer: That is ridiculous. This was storm damage, not wear and tear. The adjuster barely looked at it.\nAgent: I understand this is frustrating. I can file an appeal and request a re-inspection. Would you like me to proceed?\nCustomer: Yes, and I want a different adjuster this time. The first one was completely unhelpful.'
      WHEN INTERACTION_TYPE = 'Complaint' AND MOD(h, 6) = 3 THEN
        'Agent: Welcome to customer service. How can I assist you today?\nCustomer: I have been on hold for 45 minutes. This is terrible service.\nAgent: I sincerely apologize for the long wait time. How can I help you?\nCustomer: I called last week about my policy and was told someone would call me back. Nobody ever did.\nAgent: That should not have happened. Let me look at the notes on your account.\nCustomer: There are probably no notes because nobody cares about follow-through. I am paying over $' || (200 + MOD(h2, 300))::VARCHAR || ' a month and I cannot even get a callback.\nAgent: You are right to be upset. I am going to personally handle this and make sure it gets resolved today. What was the original issue?\nCustomer: I need to update my coverage but every time I try, something goes wrong or I get transferred to another department.'
      WHEN INTERACTION_TYPE = 'Complaint' AND MOD(h, 6) = 4 THEN
        'Agent: Thank you for calling. How may I help?\nCustomer: I was double-charged on my premium this month. I need this fixed immediately.\nAgent: I apologize for the billing error. Let me check your payment history.\nCustomer: This is the second time this has happened. Last time it took three weeks to get my refund.\nAgent: I can see the duplicate charge. I will process the refund right away. It should appear in 3-5 business days.\nCustomer: That is not good enough. I have overdraft fees because of your mistake.\nAgent: I completely understand. Let me escalate this to our billing department to expedite the refund and I will also submit a request to reimburse your overdraft fees.\nCustomer: Please do. This cannot keep happening.'
      WHEN INTERACTION_TYPE = 'Complaint' AND MOD(h, 6) = 5 THEN
        'Agent: Good afternoon. How can I help you today?\nCustomer: I need to file a formal complaint. Your claims adjuster was extremely rude to me during the home inspection.\nAgent: I am very sorry to hear that. That is not the level of service we expect. Can you tell me what happened?\nCustomer: He questioned everything I said, implied I was exaggerating the damage, and rushed through the inspection in 10 minutes for a major water damage claim.\nAgent: That is completely unacceptable. I will file a formal complaint against the adjuster and assign a new one to your claim.\nCustomer: Good. And I want a thorough re-inspection. The estimate he provided does not even cover half the damage.\nAgent: Absolutely. I will arrange for a senior adjuster to visit within the next 48 hours. Is there a preferred time?\nCustomer: Mornings work best. And I want everything documented this time.'

      -- CANCELLATION transcripts (4 variants)
      WHEN INTERACTION_TYPE = 'Cancellation' AND MOD(h, 4) = 0 THEN
        'Agent: Thank you for calling. How can I help you?\nCustomer: I want to cancel all my policies effective immediately.\nAgent: I am sorry to hear that. May I ask what prompted this decision?\nCustomer: I have had nothing but problems. My claim has been pending for weeks, my premium keeps going up, and nobody follows through on promises.\nAgent: I understand your frustration. You have been a valued customer and I would like the opportunity to address these issues.\nCustomer: I already have quotes from two other companies. Both are cheaper and have better reviews for claims processing.\nAgent: I appreciate you letting me know. Before you make a final decision, let me see what we can do. I can offer a policy review and potentially adjust your premium.\nCustomer: Unless you can match $' || (100 + MOD(h2, 150))::VARCHAR || ' per month and process my claim this week, I am done.'
      WHEN INTERACTION_TYPE = 'Cancellation' AND MOD(h, 4) = 1 THEN
        'Agent: Good afternoon. What can I assist you with?\nCustomer: I am calling to cancel my auto policy.\nAgent: I am sorry to hear that. Can you share why you are considering cancellation?\nCustomer: I got a much better rate from a competitor. Your renewal quote is ' || (20 + MOD(h2, 35))::VARCHAR || ' percent higher than what they offered.\nAgent: I see. Let me review your current policy and see if we have any options to bring that down.\nCustomer: I have already made my decision. I just need the cancellation processed.\nAgent: I understand. Before I process this, I should mention that cancelling mid-term may result in a fee. Also, we do have a price-match program for long-term customers.\nCustomer: Really? Nobody mentioned that before. What would that look like for my policy?'
      WHEN INTERACTION_TYPE = 'Cancellation' AND MOD(h, 4) = 2 THEN
        'Agent: Thank you for calling. How may I help you today?\nCustomer: I want to know the cancellation process for my home insurance.\nAgent: Of course, I can help with that. May I ask what is driving the decision?\nCustomer: I recently had a claim that was denied unfairly. I paid premiums for years and when I finally needed help, the claim was rejected.\nAgent: I am sorry about that experience. Would you like me to look into the claim denial? Sometimes these can be appealed.\nCustomer: I already appealed and was denied again. I feel like I was paying for nothing.\nAgent: I understand how disappointing that must be. If you decide to proceed, I can process the cancellation. The effective date would be the end of your current billing period.\nCustomer: Go ahead and cancel it. I will find a company that actually honors their commitments.'
      WHEN INTERACTION_TYPE = 'Cancellation' AND MOD(h, 4) = 3 THEN
        'Agent: Welcome. How can I assist you?\nCustomer: I need to cancel my policy because I am moving out of state.\nAgent: I understand. We do offer coverage in most states. Where are you moving to?\nCustomer: I am moving to a state where your rates are much higher than local providers. It does not make sense to keep it.\nAgent: That is a fair point. Let me check what rates we can offer in your new location. We sometimes have relocation adjustments.\nCustomer: I have already compared. Your rate is about 30 percent higher than what I was quoted locally.\nAgent: I see. Let me process the cancellation for you then. You will receive a prorated refund for the unused portion of your premium.\nCustomer: Thank you. I did enjoy the service for the most part, just the pricing does not work anymore.'

      -- CLAIM INQUIRY transcripts (4 variants)
      WHEN INTERACTION_TYPE = 'Claim Inquiry' AND MOD(h, 4) = 0 THEN
        'Agent: Thank you for calling. How can I help?\nCustomer: I need an update on my claim. It has been ' || (15 + MOD(h2, 30))::VARCHAR || ' days and I have not heard anything.\nAgent: Let me pull up your claim. I see it is currently in the review stage.\nCustomer: What does that mean exactly? How much longer will it take?\nAgent: The review process typically takes 5-10 business days. Your claim was assigned to an adjuster last week.\nCustomer: So you are saying it could be another two weeks? I have repair costs piling up.\nAgent: I understand that is difficult. Let me see if I can expedite the review. In the meantime, I can provide you with information about advance payment options.\nCustomer: That would help. Can you also send me an email with the timeline so I have something in writing?'
      WHEN INTERACTION_TYPE = 'Claim Inquiry' AND MOD(h, 4) = 1 THEN
        'Agent: Good morning. How can I assist you?\nCustomer: I submitted additional documents for my claim last week and wanted to confirm they were received.\nAgent: Let me check. Yes, I can see the documents were uploaded. They are currently being reviewed.\nCustomer: Great. Will this speed up the process? I was told the delay was because of missing paperwork.\nAgent: Now that we have everything, the review should move forward. I would estimate a decision within 7-10 business days.\nCustomer: That is reasonable. Can I get an email notification when there is a decision?\nAgent: Absolutely. I will set that up for you right now. Is there anything else I can help with?\nCustomer: No, that is all. Thank you for being helpful.'
      WHEN INTERACTION_TYPE = 'Claim Inquiry' AND MOD(h, 4) = 2 THEN
        'Agent: Thank you for calling. How may I help you?\nCustomer: My claim was approved but the amount is much lower than I expected. I need to understand why.\nAgent: I can help explain that. Let me review the claim details.\nCustomer: I claimed $' || (5000 + MOD(h2, 20000))::VARCHAR || ' but was only approved for about half of that. The damage costs are real.\nAgent: I see. The approved amount was based on the adjuster assessment minus your deductible. There were also some items classified as maintenance rather than damage.\nCustomer: That is not right. The repair shop quoted me the full amount. Can I dispute this?\nAgent: Yes, you can submit a supplemental claim with the repair shop estimate and any additional documentation.\nCustomer: I will do that. How long will the supplemental review take?'
      WHEN INTERACTION_TYPE = 'Claim Inquiry' AND MOD(h, 4) = 3 THEN
        'Agent: Hello, how can I help you today?\nCustomer: I want to file a new claim. My car was in an accident yesterday.\nAgent: I am sorry to hear that. Are you and everyone else okay?\nCustomer: Yes, everyone is fine. It was a fender bender in a parking lot. The other driver backed into me.\nAgent: Good to hear everyone is safe. Do you have a police report?\nCustomer: Yes, I filed one at the scene. I also have photos and the other driver''s information.\nAgent: Perfect. Let me start the claim process. I will need some details from you.\nCustomer: Sure. How long does the process usually take?'

      -- RENEWAL transcripts (3 variants)
      WHEN INTERACTION_TYPE = 'Renewal' AND MOD(h, 3) = 0 THEN
        'Agent: Thank you for calling. How can I help?\nCustomer: I received my renewal notice and the premium went up significantly. I want to understand why.\nAgent: I can help with that. Let me review your renewal details.\nCustomer: My premium went from $' || (150 + MOD(h2, 200))::VARCHAR || ' to $' || (200 + MOD(h2, 300))::VARCHAR || ' per month. That is a huge jump.\nAgent: I can see the increase is due to a combination of factors including a recent claim, general rate adjustments, and some changes in risk assessment for your area.\nCustomer: But the claim was not even my fault. Why am I being penalized?\nAgent: I understand that feels unfair. Let me see what options we have. I might be able to adjust your coverage levels or apply some discounts.\nCustomer: Please do. Otherwise I will have to look at other options.'
      WHEN INTERACTION_TYPE = 'Renewal' AND MOD(h, 3) = 1 THEN
        'Agent: Good afternoon. What can I help you with?\nCustomer: My policy renews next month and I want to make sure everything is in order.\nAgent: Of course. Let me pull up your policy details.\nCustomer: I also want to see if there are any new discounts available. I have been claim-free for 3 years now.\nAgent: Congratulations on maintaining a clean record. Let me check what we can offer. I see you might qualify for our claims-free discount.\nCustomer: That sounds great. Also, I added a security system to my home. Does that help?\nAgent: Yes, it does. A security system can qualify you for an additional discount on your home policy. Let me calculate the new premium.\nCustomer: Wonderful. I appreciate you taking the time to look into this.'
      WHEN INTERACTION_TYPE = 'Renewal' AND MOD(h, 3) = 2 THEN
        'Agent: Thank you for calling. How may I assist you?\nCustomer: I am thinking about not renewing my policy. I want to know what happens if I let it lapse.\nAgent: I would be happy to explain. If your policy lapses, you would lose coverage and any future policies might have higher rates due to the gap in coverage.\nCustomer: I see. The reason I am considering it is purely financial. Things are tight right now.\nAgent: I understand. Let me look at some options. We might be able to adjust your coverage temporarily to lower the premium while keeping you protected.\nCustomer: That could work. What would the minimum coverage look like?\nAgent: For your auto policy, we could reduce to state minimum requirements. That would lower your monthly payment significantly.\nCustomer: Let me think about it. Can you send me a comparison of the two options?'

      -- PAYMENT ISSUE transcripts (3 variants)
      WHEN INTERACTION_TYPE = 'Payment Issue' AND MOD(h, 3) = 0 THEN
        'Agent: Thank you for calling. How can I assist you?\nCustomer: My payment was declined and I do not know why. I have enough funds in my account.\nAgent: Let me check your billing information. It appears the credit card on file expired last month.\nCustomer: Oh, I got a new card. I thought it would update automatically.\nAgent: Unfortunately, we need to update it manually. I can do that for you right now if you have the new card number.\nCustomer: Sure. Will I be charged a late fee since the payment failed?\nAgent: Since this is the first occurrence and you are updating immediately, I will waive the late fee for you.\nCustomer: Thank you, I appreciate that. Let me get the new card.'
      WHEN INTERACTION_TYPE = 'Payment Issue' AND MOD(h, 3) = 1 THEN
        'Agent: Good morning. What can I help you with?\nCustomer: I am having trouble making my payment. Can I set up a different payment schedule?\nAgent: I can certainly look into that. What kind of arrangement are you looking for?\nCustomer: I switched jobs and my pay schedule changed. I need to move my payment date from the 1st to the 15th.\nAgent: That is a common request and we can definitely accommodate it. I will update your billing cycle.\nCustomer: Great. Will there be any gap in coverage during the switch?\nAgent: No, your coverage remains continuous. The next payment will just be prorated for the adjusted dates.\nCustomer: Perfect. Thank you for making this easy.'
      WHEN INTERACTION_TYPE = 'Payment Issue' AND MOD(h, 3) = 2 THEN
        'Agent: Thank you for calling. How may I help?\nCustomer: I am behind on my payments and I am worried my policy will be cancelled.\nAgent: I appreciate you reaching out. Let me review your account.\nCustomer: I had some unexpected medical expenses. I intend to pay but I need some time.\nAgent: I understand. You are currently ' || (1 + MOD(h2, 3))::VARCHAR || ' payments behind. We can set up a payment plan to help you get caught up.\nCustomer: That would be a huge relief. What are the options?\nAgent: We can spread the past-due amount over the next 3-6 months in addition to your regular premium. This will keep your policy active.\nCustomer: Let us do 6 months. That is more manageable for me right now.'

      -- COVERAGE QUESTION transcripts (3 variants)
      WHEN INTERACTION_TYPE = 'Coverage Question' AND MOD(h, 3) = 0 THEN
        'Agent: Thank you for calling. How can I assist you?\nCustomer: I recently had a baby and I want to make sure my coverage is adequate for my growing family.\nAgent: Congratulations! Let me review your current policies.\nCustomer: I currently have auto and home insurance. I think I might need to add life insurance as well.\nAgent: That is a smart decision. With a growing family, life insurance provides important financial security. I can give you some quotes.\nCustomer: Yes please. I also want to increase my home coverage since we are doing some renovations.\nAgent: I can help with both. For life insurance, based on your income and family needs, I would recommend a term policy. For the home, we should update the replacement cost.\nCustomer: That sounds good. Can you send me the details to review with my spouse?'
      WHEN INTERACTION_TYPE = 'Coverage Question' AND MOD(h, 3) = 1 THEN
        'Agent: Good afternoon. What can I help you with?\nCustomer: I want to understand my deductible better. If I file a claim, how much will I pay out of pocket?\nAgent: Great question. Your current deductible for your home policy is $' || (500 + MOD(h2, 2000))::VARCHAR || '.\nCustomer: Is it worth increasing it to lower my premium?\nAgent: That depends on your financial situation. A higher deductible means lower monthly payments but more out of pocket if you file a claim.\nCustomer: What would the savings be if I doubled the deductible?\nAgent: Let me calculate that. You would save approximately $' || (15 + MOD(h2, 40))::VARCHAR || ' per month.\nCustomer: That is significant. Let me think about it.'
      WHEN INTERACTION_TYPE = 'Coverage Question' AND MOD(h, 3) = 2 THEN
        'Agent: Hello, how can I help you today?\nCustomer: I just bought a new car and need to add it to my policy.\nAgent: Congratulations on the new car! I can help you with that. What is the make and model?\nCustomer: It is a 2025 model. I want the same coverage as my other vehicle.\nAgent: Let me pull up your current auto policy. I see you have comprehensive and collision coverage. Would you like the same for the new vehicle?\nCustomer: Yes, and I also want to add gap insurance since I am financing.\nAgent: Smart choice. Gap insurance covers the difference between what you owe and the car''s value. Let me add both and give you the updated premium.\nCustomer: Great. Can you also check if I qualify for a multi-vehicle discount?'

      -- POLICY QUESTION transcripts (3 variants)
      WHEN INTERACTION_TYPE = 'Policy Question' AND MOD(h, 3) = 0 THEN
        'Agent: Thank you for calling. How may I help you?\nCustomer: I want to understand what is covered under my homeowner policy. I had some confusion recently.\nAgent: I would be happy to help clarify. What specific coverage are you asking about?\nCustomer: My basement flooded during a heavy rain. Is that covered?\nAgent: That depends on your policy. Standard homeowner policies typically cover sudden water damage from internal sources but not flooding from external sources. Do you have a flood endorsement?\nCustomer: I am not sure. Can you check?\nAgent: Let me look. Unfortunately, I do not see a flood endorsement on your policy. External flooding would not be covered under your current plan.\nCustomer: That is concerning. How much would it cost to add flood coverage?'
      WHEN INTERACTION_TYPE = 'Policy Question' AND MOD(h, 3) = 1 THEN
        'Agent: Good morning. What can I assist you with?\nCustomer: I want to add my teenager to my auto policy. They just got their license.\nAgent: I can help with that. Adding a young driver will affect your premium, but we do have some discounts available.\nCustomer: How much will it go up?\nAgent: Typically, adding a teen driver increases the premium by 40-60 percent. However, if they maintain good grades, we offer a good student discount of up to 15 percent.\nCustomer: That is steep but expected. Does my son taking a driver safety course help?\nAgent: Absolutely. Completion of an approved driver safety course can reduce the surcharge by up to 10 percent.\nCustomer: Good. Let us get him added and take advantage of both discounts.'
      WHEN INTERACTION_TYPE = 'Policy Question' AND MOD(h, 3) = 2 THEN
        'Agent: Thank you for calling. How can I help?\nCustomer: I am starting a home-based business and want to know if my homeowner policy covers business equipment.\nAgent: Good question. Standard homeowner policies typically have limited coverage for business property, usually around $2,500.\nCustomer: That is not enough. I have about $15,000 worth of equipment.\nAgent: In that case, I would recommend adding a home business endorsement or a separate business property policy.\nCustomer: What is the difference in cost?\nAgent: The endorsement is more affordable, typically $50-100 per year. A separate policy provides broader coverage but costs more.\nCustomer: The endorsement sounds like a good start. Can you add it to my policy?'

      -- GENERAL INQUIRY transcripts (3 variants)
      WHEN INTERACTION_TYPE = 'General Inquiry' AND MOD(h, 3) = 0 THEN
        'Agent: Thank you for calling. How can I help you?\nCustomer: I need to update my mailing address. I recently moved.\nAgent: I can update that for you. What is your new address?\nCustomer: I moved from downtown to the suburbs. Will this affect my premium?\nAgent: It could. Suburban areas often have lower rates due to reduced risk factors. Let me update your address and recalculate.\nCustomer: That would be great news if it goes down.\nAgent: Good news, your auto premium will decrease by about $' || (10 + MOD(h2, 30))::VARCHAR || ' per month due to the safer area.\nCustomer: Excellent. That is a nice bonus from the move.'
      WHEN INTERACTION_TYPE = 'General Inquiry' AND MOD(h, 3) = 1 THEN
        'Agent: Good afternoon. What can I assist you with?\nCustomer: I need a copy of my insurance card for my vehicle registration renewal.\nAgent: I can help with that. I can email you a digital copy right now.\nCustomer: Perfect. Can you also send proof of insurance for the last 6 months? The DMV needs it.\nAgent: Absolutely. I will send both to your email on file. Is that still current?\nCustomer: Yes, same email. How long will it take?\nAgent: You should receive it within a few minutes.\nCustomer: Great. Thank you for the quick help.'
      ELSE
        'Agent: Thank you for calling. How may I help you today?\nCustomer: I have a question about my account. I noticed a charge I do not recognize on my statement.\nAgent: Let me look into that for you. Can you tell me the date and amount of the charge?\nCustomer: It was for $' || (50 + MOD(h2, 200))::VARCHAR || '.\nAgent: I can see that charge. It appears to be a policy endorsement fee for the coverage change you requested.\nCustomer: Oh right, I did ask for that change. I forgot it would result in an additional charge.\nAgent: No problem. Is there anything else I can help with?\nCustomer: No, that clears it up. Thank you.'
    END AS transcript
    FROM phone_interactions pi
),
numbered AS (
    SELECT *, ROW_NUMBER() OVER (ORDER BY INTERACTION_ID) AS final_rn
    FROM transcript_templates WHERE transcript IS NOT NULL
)
SELECT
    'TRX-' || LPAD(final_rn::VARCHAR, 5, '0'),
    CUSTOMER_ID,
    INTERACTION_ID,
    INTERACTION_DATE,
    transcript,
    -- Summary
    CASE
        WHEN INTERACTION_TYPE = 'Complaint' THEN 'Customer expressed frustration regarding ' ||
            CASE MOD(h, 6)
                WHEN 0 THEN 'claim processing delays and threatened to switch providers.'
                WHEN 1 THEN 'an unexpected premium increase and is comparing competitor rates.'
                WHEN 2 THEN 'a denied claim and requested an appeal with a different adjuster.'
                WHEN 3 THEN 'poor follow-through and long hold times.'
                WHEN 4 THEN 'a duplicate billing error causing overdraft fees.'
                ELSE 'rude treatment by a claims adjuster during home inspection.' END
        WHEN INTERACTION_TYPE = 'Cancellation' THEN 'Customer ' ||
            CASE MOD(h, 4)
                WHEN 0 THEN 'wants to cancel all policies due to claim delays, premium increases, and broken promises. Has competitor quotes.'
                WHEN 1 THEN 'wants to cancel auto policy due to significantly better rate from competitor. Showed interest in price-match program.'
                WHEN 2 THEN 'wants to cancel home insurance after denied claim appeal. Feels premiums were paid for nothing.'
                ELSE 'wants to cancel due to relocation. Rates are uncompetitive in new state.' END
        WHEN INTERACTION_TYPE = 'Claim Inquiry' THEN 'Customer ' ||
            CASE MOD(h, 4)
                WHEN 0 THEN 'inquired about claim status after extended wait. Concerned about mounting repair costs.'
                WHEN 1 THEN 'confirmed document submission for claim. Satisfied with timeline provided.'
                WHEN 2 THEN 'questioned low approved claim amount. Plans to submit supplemental claim.'
                ELSE 'filing new auto claim for parking lot accident. Has police report and documentation.' END
        WHEN INTERACTION_TYPE = 'Renewal' THEN 'Customer ' ||
            CASE MOD(h, 3)
                WHEN 0 THEN 'upset about premium increase at renewal. Agent looking for discounts.'
                WHEN 1 THEN 'proactively managing renewal, asking about discounts for claims-free record.'
                ELSE 'considering not renewing due to financial constraints. Agent proposed reduced coverage.' END
        WHEN INTERACTION_TYPE = 'Payment Issue' THEN 'Customer ' ||
            CASE MOD(h, 3)
                WHEN 0 THEN 'had payment declined due to expired card. Agent waived late fee.'
                WHEN 1 THEN 'requested payment date change due to new job. Agent accommodated.'
                ELSE 'behind on payments due to medical expenses. Set up 6-month payment plan.' END
        WHEN INTERACTION_TYPE = 'Coverage Question' THEN 'Customer ' ||
            CASE MOD(h, 3)
                WHEN 0 THEN 'wants to add life insurance and increase home coverage after having a baby.'
                WHEN 1 THEN 'exploring deductible increase to lower premium.'
                ELSE 'adding new vehicle with comprehensive, collision, and gap insurance.' END
        WHEN INTERACTION_TYPE = 'Policy Question' THEN 'Customer ' ||
            CASE MOD(h, 3)
                WHEN 0 THEN 'asked about flood coverage after basement flooding. Currently not covered.'
                WHEN 1 THEN 'adding teenage driver to auto policy. Applying good student discount.'
                ELSE 'asked about home business equipment coverage. Agent recommended endorsement.' END
        ELSE 'Customer ' ||
            CASE MOD(h, 3)
                WHEN 0 THEN 'updated address after moving. Premium decreased due to safer area.'
                WHEN 1 THEN 'requested insurance cards and proof of coverage for DMV.'
                ELSE 'asked about unrecognized charge. Identified as policy endorsement fee.' END
    END,
    -- Customer intent
    CASE INTERACTION_TYPE
        WHEN 'Complaint' THEN 'Escalation' WHEN 'Cancellation' THEN 'Churn'
        WHEN 'Claim Inquiry' THEN 'Information' WHEN 'Renewal' THEN 'Retention'
        WHEN 'Payment Issue' THEN 'Resolution' WHEN 'Coverage Question' THEN 'Upsell'
        WHEN 'Policy Question' THEN 'Information' ELSE 'General' END,
    SENTIMENT,
    SENTIMENT_SCORE,
    -- Key topics
    CASE INTERACTION_TYPE
        WHEN 'Complaint' THEN 'claim delay, service quality, premium increase, claim denial'
        WHEN 'Cancellation' THEN 'cancellation, competitor comparison, pricing, service dissatisfaction'
        WHEN 'Claim Inquiry' THEN 'claim status, documentation, claim amount, processing time'
        WHEN 'Renewal' THEN 'renewal, premium change, discounts, coverage adjustment'
        WHEN 'Payment Issue' THEN 'payment, billing, payment plan, late fees'
        WHEN 'Coverage Question' THEN 'coverage options, deductible, new vehicle, family needs'
        WHEN 'Policy Question' THEN 'coverage details, endorsements, policy limits, additions'
        ELSE 'account management, documentation, general inquiry' END,
    -- Resolution
    CASE WHEN MOD(h2, 100) < 50 THEN 'Issue resolved during call'
         WHEN MOD(h2, 100) < 70 THEN 'Escalated to supervisor'
         WHEN MOD(h2, 100) < 85 THEN 'Follow-up scheduled'
         ELSE 'Pending resolution' END,
    -- Follow-up required
    CASE WHEN MOD(h2, 100) >= 50 THEN TRUE ELSE FALSE END
FROM numbered;

-- ============================================================
-- Batch 2: Additional transcripts from Email/Web/Branch (~120)
-- ============================================================
INSERT INTO CALL_TRANSCRIPTS
WITH
remaining_interactions AS (
    SELECT ci.INTERACTION_ID, ci.CUSTOMER_ID, ci.INTERACTION_DATE, ci.INTERACTION_TYPE,
        ci.SENTIMENT, ci.SENTIMENT_SCORE, ci.CHANNEL,
        ABS(HASH(ci.INTERACTION_ID || 'extra')) AS h,
        ABS(HASH(ci.INTERACTION_ID || 'extra2')) AS h2,
        ROW_NUMBER() OVER (ORDER BY ci.INTERACTION_ID) AS rn
    FROM CUSTOMER_INTERACTIONS ci
    LEFT JOIN CALL_TRANSCRIPTS ct ON ct.INTERACTION_ID = ci.INTERACTION_ID
    WHERE ct.TRANSCRIPT_ID IS NULL
      AND ci.CHANNEL IN ('Email','Web','Branch')
      AND MOD(ABS(HASH(ci.INTERACTION_ID || 'sel')), 100) < 15
    LIMIT 120
)
SELECT
    'TRX-' || LPAD(((SELECT COUNT(*) FROM CALL_TRANSCRIPTS) + rn)::VARCHAR, 5, '0'),
    CUSTOMER_ID, INTERACTION_ID, INTERACTION_DATE,
    CASE
        WHEN INTERACTION_TYPE = 'Complaint' THEN
            'Email from customer: I am writing to formally express my dissatisfaction with the handling of my recent claim. It has been over three weeks since I submitted all required documentation, and I have yet to receive any substantive update. Each time I call, I am told the claim is "in process" with no specific timeline. This level of service is unacceptable for the premiums I pay. I expect a resolution within the next five business days, or I will be forced to escalate this matter and consider alternative insurance providers.'
        WHEN INTERACTION_TYPE = 'Cancellation' THEN
            'Web form submission: I am requesting cancellation of my policy effective at the end of the current billing cycle. I have found better coverage at a lower price with another provider. Despite being a loyal customer, my premiums have increased steadily each year without corresponding improvements in service. The final straw was my recent claim experience, which was poorly handled from start to finish. Please confirm the cancellation and send details about any applicable refund.'
        WHEN INTERACTION_TYPE = 'Claim Inquiry' THEN
            'Email from customer: Following up on my claim submitted previously. I have not received the payment yet even though the claim was approved two weeks ago. Can you please provide a payment timeline? I have contractors waiting to begin repairs and I cannot delay any further. Please expedite the payment processing.'
        WHEN INTERACTION_TYPE = 'Renewal' THEN
            'Email from customer: I received my renewal notice and I am concerned about the proposed premium. I have been a claims-free customer for several years and I feel the increase is not justified. Before I decide whether to renew, could you please review my policy and let me know what discounts I may be eligible for? I would prefer to stay with your company but the pricing needs to be competitive.'
        WHEN INTERACTION_TYPE = 'Payment Issue' THEN
            'Email from customer: I am writing to report an issue with my automatic payment. The wrong amount was debited from my account this month. My monthly premium should be a fixed amount but I was charged significantly more. Please investigate and correct this billing error immediately. I also request a detailed billing statement for the past 12 months.'
        ELSE
            'Email from customer: I would like to request a comprehensive review of my current policies. My circumstances have changed recently and I want to ensure I have appropriate coverage. Specifically, I am interested in understanding my current coverage limits, any gaps in protection, and what additional coverage options are available. Please have a representative contact me at their earliest convenience.'
    END,
    'Customer ' || LOWER(INTERACTION_TYPE) || ' received via ' || LOWER(CHANNEL) || '. ' ||
        CASE SENTIMENT WHEN 'Negative' THEN 'Customer expressed dissatisfaction and urgency.'
             WHEN 'Neutral' THEN 'Standard inquiry handled professionally.'
             ELSE 'Positive interaction, customer satisfied with response.' END,
    CASE INTERACTION_TYPE WHEN 'Complaint' THEN 'Escalation' WHEN 'Cancellation' THEN 'Churn'
         WHEN 'Claim Inquiry' THEN 'Information' WHEN 'Renewal' THEN 'Retention'
         WHEN 'Payment Issue' THEN 'Resolution' ELSE 'General' END,
    SENTIMENT, SENTIMENT_SCORE,
    CASE INTERACTION_TYPE WHEN 'Complaint' THEN 'claim delay, service quality, escalation threat'
         WHEN 'Cancellation' THEN 'cancellation, competitor, premium increase'
         WHEN 'Claim Inquiry' THEN 'claim payment, processing time, follow-up'
         WHEN 'Renewal' THEN 'renewal, discounts, premium review'
         WHEN 'Payment Issue' THEN 'billing error, overcharge, payment history'
         ELSE 'policy review, coverage gaps, consultation request' END,
    CASE WHEN MOD(h2, 2) = 0 THEN 'Pending response' ELSE 'Response sent' END,
    CASE WHEN MOD(h, 2) = 0 THEN TRUE ELSE FALSE END
FROM remaining_interactions;

-- ============================================================
-- Link transcript IDs back to customer interactions
-- ============================================================
UPDATE CUSTOMER_INTERACTIONS ci
SET ci.TRANSCRIPT_ID = ct.TRANSCRIPT_ID
FROM CALL_TRANSCRIPTS ct
WHERE ci.INTERACTION_ID = ct.INTERACTION_ID;
