"""Snowflake connection and query utilities for Customer360 AI."""
import streamlit as st
import pandas as pd

DB = "CUSTOMER_360_DB"
SCHEMA = "C360"

def get_connection():
    """Return a Snowflake connection, compatible with SiS and local Streamlit."""
    # Try Snowflake-in-Snowflake (Streamlit in Snowflake)
    try:
        from snowflake.snowpark.context import get_active_session
        session = get_active_session()
        return session.connection
    except Exception:
        pass

    # Local Streamlit: use snowflake-connector-python via secrets
    import snowflake.connector
    secrets = st.secrets.get("connections", {}).get("snowflake", {})
    if secrets:
        return snowflake.connector.connect(
            account=secrets.get("account", ""),
            user=secrets.get("user", ""),
            password=secrets.get("password", ""),
            authenticator=secrets.get("authenticator", "snowflake"),
            database=secrets.get("database", DB),
            schema=secrets.get("schema", SCHEMA),
            warehouse=secrets.get("warehouse", "COMPUTE_WH"),
        )
    # Fallback to st.connection
    return st.connection("snowflake", type="snowflake").raw_connection


def _escape(val):
    """Escape a string value for safe SQL interpolation."""
    if val is None:
        return "NULL"
    return "'" + str(val).replace("\\", "\\\\").replace("'", "''") + "'"


def _bind(sql: str, params) -> str:
    """Replace %s placeholders with escaped parameter values."""
    if not params:
        return sql
    if isinstance(params, (list, tuple)):
        for p in params:
            sql = sql.replace("%s", _escape(p), 1)
    return sql


def run_query(sql: str, params=None) -> pd.DataFrame:
    """Execute a SQL query and return a DataFrame."""
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(_bind(sql, params))
        cols = [desc[0] for desc in cur.description]
        rows = cur.fetchall()
        return pd.DataFrame(rows, columns=cols)
    finally:
        cur.close()


def run_scalar(sql: str, params=None):
    """Execute a query and return a single scalar value."""
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(_bind(sql, params))
        row = cur.fetchone()
        return row[0] if row else None
    finally:
        cur.close()


@st.cache_data(ttl=300)
def get_executive_kpis() -> dict:
    """Fetch executive dashboard KPIs."""
    df = run_query(f"""
        SELECT
            COUNT(*) AS total_customers,
            SUM(CASE WHEN CHURN_RISK_CATEGORY = 'HIGH' THEN 1 ELSE 0 END) AS high_risk,
            SUM(CASE WHEN AVG_SENTIMENT_SCORE < -0.1 THEN 1 ELSE 0 END) AS negative_sentiment,
            ROUND(AVG(CUSTOMER_HEALTH_SCORE), 1) AS avg_health,
            SUM(TOTAL_ANNUAL_PREMIUM) AS total_premium,
            SUM(OPEN_CLAIMS) AS total_open_claims,
            SUM(NUM_POLICIES) AS total_policies
        FROM {DB}.{SCHEMA}.CUSTOMER_360_VIEW
    """)
    row = df.iloc[0]
    action_count = run_scalar(f"""
        SELECT COUNT(*) FROM {DB}.{SCHEMA}.NEXT_BEST_ACTION WHERE PRIORITY = 'HIGH'
    """)
    return {
        "total_customers": int(row["TOTAL_CUSTOMERS"]),
        "total_policies": int(row["TOTAL_POLICIES"]),
        "open_claims": int(row["TOTAL_OPEN_CLAIMS"]),
        "high_risk": int(row["HIGH_RISK"]),
        "negative_sentiment": int(row["NEGATIVE_SENTIMENT"]),
        "action_required": int(action_count or 0),
        "total_premium": float(row["TOTAL_PREMIUM"]),
        "avg_health": float(row["AVG_HEALTH"]),
    }


@st.cache_data(ttl=300)
def get_risk_distribution() -> pd.DataFrame:
    return run_query(f"""
        SELECT CHURN_RISK_CATEGORY, COUNT(*) AS COUNT
        FROM {DB}.{SCHEMA}.CUSTOMER_360_VIEW
        GROUP BY CHURN_RISK_CATEGORY
        ORDER BY CASE CHURN_RISK_CATEGORY WHEN 'HIGH' THEN 1 WHEN 'MEDIUM' THEN 2 ELSE 3 END
    """)


@st.cache_data(ttl=300)
def get_sentiment_distribution() -> pd.DataFrame:
    return run_query(f"""
        SELECT
            CASE WHEN AVG_SENTIMENT_SCORE > 0.1 THEN 'Positive'
                 WHEN AVG_SENTIMENT_SCORE < -0.1 THEN 'Negative'
                 ELSE 'Neutral' END AS SENTIMENT_CATEGORY,
            COUNT(*) AS COUNT
        FROM {DB}.{SCHEMA}.CUSTOMER_360_VIEW
        GROUP BY SENTIMENT_CATEGORY
        ORDER BY CASE SENTIMENT_CATEGORY WHEN 'Positive' THEN 1 WHEN 'Neutral' THEN 2 ELSE 3 END
    """)


@st.cache_data(ttl=300)
def get_claims_overview() -> pd.DataFrame:
    return run_query(f"""
        SELECT CLAIM_STATUS, COUNT(*) AS COUNT, ROUND(AVG(PROCESSING_DAYS), 1) AS AVG_DAYS
        FROM {DB}.{SCHEMA}.CLAIMS
        GROUP BY CLAIM_STATUS
        ORDER BY COUNT DESC
    """)


@st.cache_data(ttl=300)
def get_attention_customers() -> pd.DataFrame:
    return run_query(f"""
        SELECT CUSTOMER_ID, FULL_NAME, CUSTOMER_SEGMENT, CHURN_RISK_SCORE,
               CHURN_RISK_CATEGORY, CUSTOMER_HEALTH_SCORE, ACTION_TRIGGER,
               RECOMMENDED_ACTION, PRIORITY, SUGGESTED_CHANNEL, EXPECTED_OUTCOME,
               REASON, CUSTOMER_LIFETIME_VALUE
        FROM {DB}.{SCHEMA}.NEXT_BEST_ACTION
        ORDER BY CASE PRIORITY WHEN 'HIGH' THEN 1 WHEN 'MEDIUM' THEN 2 ELSE 3 END,
                 CHURN_RISK_SCORE DESC
    """)


@st.cache_data(ttl=300)
def get_customer_list() -> pd.DataFrame:
    return run_query(f"""
        SELECT CUSTOMER_ID, FULL_NAME, CUSTOMER_SEGMENT, CHURN_RISK_CATEGORY, CHURN_RISK_SCORE
        FROM {DB}.{SCHEMA}.CUSTOMER_360_VIEW
        ORDER BY FULL_NAME
    """)


def get_customer_360(customer_id: str) -> pd.Series:
    df = run_query(f"""
        SELECT * FROM {DB}.{SCHEMA}.CUSTOMER_360_VIEW
        WHERE CUSTOMER_ID = %s
    """, (customer_id,))
    return df.iloc[0] if len(df) > 0 else None


def get_customer_policies(customer_id: str) -> pd.DataFrame:
    return run_query(f"""
        SELECT POLICY_ID, POLICY_TYPE, POLICY_STATUS, PREMIUM_AMOUNT, COVERAGE_AMOUNT,
               PAYMENT_FREQUENCY, PAYMENT_STATUS, DEDUCTIBLE, RISK_SCORE, RENEWAL_DATE
        FROM {DB}.{SCHEMA}.POLICIES WHERE CUSTOMER_ID = %s
        ORDER BY POLICY_STATUS, POLICY_TYPE
    """, (customer_id,))


def get_customer_claims(customer_id: str) -> pd.DataFrame:
    return run_query(f"""
        SELECT c.CLAIM_ID, c.POLICY_ID, p.POLICY_TYPE, c.CLAIM_DATE, c.CLAIM_TYPE,
               c.CLAIM_STATUS, c.CLAIM_AMOUNT, c.APPROVED_AMOUNT, c.CLAIM_SEVERITY,
               c.PROCESSING_DAYS, c.CLAIM_DESCRIPTION
        FROM {DB}.{SCHEMA}.CLAIMS c
        JOIN {DB}.{SCHEMA}.POLICIES p ON c.POLICY_ID = p.POLICY_ID
        WHERE c.CUSTOMER_ID = %s
        ORDER BY c.CLAIM_DATE DESC
    """, (customer_id,))


def get_customer_interactions(customer_id: str) -> pd.DataFrame:
    return run_query(f"""
        SELECT INTERACTION_ID, INTERACTION_DATE, CHANNEL, INTERACTION_TYPE, SUBJECT,
               RESOLUTION_STATUS, SENTIMENT, SENTIMENT_SCORE, CUSTOMER_INTENT, TRANSCRIPT_ID
        FROM {DB}.{SCHEMA}.CUSTOMER_INTERACTIONS
        WHERE CUSTOMER_ID = %s
        ORDER BY INTERACTION_DATE DESC
    """, (customer_id,))


def get_customer_transcripts(customer_id: str) -> pd.DataFrame:
    return run_query(f"""
        SELECT TRANSCRIPT_ID, CALL_DATE, TRANSCRIPT_TEXT, SUMMARY,
               CUSTOMER_INTENT, SENTIMENT, SENTIMENT_SCORE, KEY_TOPICS,
               RESOLUTION, FOLLOW_UP_REQUIRED
        FROM {DB}.{SCHEMA}.CALL_TRANSCRIPTS
        WHERE CUSTOMER_ID = %s
        ORDER BY CALL_DATE DESC
        LIMIT 5
    """, (customer_id,))


def get_churn_signals(customer_id: str) -> pd.Series:
    df = run_query(f"""
        SELECT * FROM {DB}.{SCHEMA}.CHURN_SIGNALS_EXPLAINED
        WHERE CUSTOMER_ID = %s
    """, (customer_id,))
    return df.iloc[0] if len(df) > 0 else None


def get_next_best_action(customer_id: str) -> pd.Series:
    df = run_query(f"""
        SELECT * FROM {DB}.{SCHEMA}.NEXT_BEST_ACTION
        WHERE CUSTOMER_ID = %s
    """, (customer_id,))
    return df.iloc[0] if len(df) > 0 else None


def call_transcript_intelligence(customer_id: str) -> str:
    return run_scalar(f"""
        SELECT {DB}.{SCHEMA}.FN_TRANSCRIPT_INTELLIGENCE(%s)
    """, (customer_id,))


def call_customer_ai_summary(customer_id: str) -> str:
    return run_scalar(f"""
        SELECT {DB}.{SCHEMA}.FN_CUSTOMER_AI_SUMMARY(%s)
    """, (customer_id,))


def call_generate_communication(customer_id: str, channel: str) -> str:
    return run_scalar(f"""
        SELECT {DB}.{SCHEMA}.FN_GENERATE_COMMUNICATION(%s, %s)
    """, (customer_id, channel))


def call_ask_customer_360(question: str, customer_id: str = None) -> str:
    if customer_id:
        return run_scalar(f"""
            SELECT {DB}.{SCHEMA}.FN_ASK_CUSTOMER_360(%s, %s)
        """, (question, customer_id))
    else:
        return run_scalar(f"""
            SELECT {DB}.{SCHEMA}.FN_ASK_CUSTOMER_360(%s, NULL)
        """, (question,))


import re

# Pattern to detect CUST-xxxx IDs in free text
_CUST_ID_RE = re.compile(r'\bCUST-\d{3,}\b', re.IGNORECASE)

# Words that signal an aggregate/portfolio question (not about a specific person)
_AGGREGATE_SIGNALS = [
    "which customers", "what customers", "how many customers", "all customers",
    "top customers", "highest risk", "most at risk", "portfolio", "across all",
    "total", "overall", "summary of all", "list all", "show all", "everyone",
]

# Patterns that indicate the question is about a specific person (not aggregate)
_PERSON_QUERY_RE = re.compile(
    r'\b(?:why is|tell me about|about|is|for)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\b'
)


def resolve_customer_from_question(question: str) -> dict:
    """Attempt to identify a customer from the question text.

    Returns dict with:
      - status: "id_match" | "exact_match" | "ambiguous" | "no_match" | "aggregate"
      - customer_id: str or None
      - matches: DataFrame of matching customers (for ambiguous)
    """
    q_lower = question.lower()

    # Check for aggregate question signals first
    for signal in _AGGREGATE_SIGNALS:
        if signal in q_lower:
            return {"status": "aggregate", "customer_id": None, "matches": None}

    # Check for explicit CUST-xxxx ID in the question
    id_match = _CUST_ID_RE.search(question)
    if id_match:
        cid = id_match.group(0).upper()
        verify = run_query(f"""
            SELECT CUSTOMER_ID, FULL_NAME FROM {DB}.{SCHEMA}.CUSTOMER_360_VIEW
            WHERE CUSTOMER_ID = %s
        """, (cid,))
        if len(verify) > 0:
            return {"status": "id_match", "customer_id": cid, "matches": verify}
        return {"status": "no_match", "customer_id": None, "matches": None}

    # Extract potential name tokens from the question
    # Get the customer list to match against
    cust_df = get_customer_list()

    # Try exact full-name match (case-insensitive)
    for _, row in cust_df.iterrows():
        if row["FULL_NAME"].lower() in q_lower:
            exact = cust_df[cust_df["FULL_NAME"].str.lower() == row["FULL_NAME"].lower()]
            if len(exact) == 1:
                return {"status": "exact_match", "customer_id": exact.iloc[0]["CUSTOMER_ID"], "matches": exact}
            else:
                # Multiple customers with same full name
                return {"status": "ambiguous", "customer_id": None, "matches": exact}

    # Try first-name match (case-insensitive)
    first_names = cust_df.copy()
    first_names["FIRST_NAME"] = first_names["FULL_NAME"].str.split(" ").str[0]
    for fn in first_names["FIRST_NAME"].unique():
        if fn.lower() in q_lower.split():
            matches = first_names[first_names["FIRST_NAME"].str.lower() == fn.lower()]
            if len(matches) == 1:
                return {"status": "exact_match", "customer_id": matches.iloc[0]["CUSTOMER_ID"], "matches": matches}
            else:
                return {"status": "ambiguous", "customer_id": None, "matches": matches}

    # No customer name detected in the database.
    # If the question looks like it's asking about a specific person, return no_match.
    # If it looks like a general/aggregate question, treat as aggregate.
    person_match = _PERSON_QUERY_RE.search(question)
    if person_match:
        return {"status": "no_match", "customer_id": None, "matches": None}
    return {"status": "aggregate", "customer_id": None, "matches": None}


@st.cache_data(ttl=300)
def get_analytics_data() -> dict:
    """Fetch all analytics chart data."""
    risk_by_segment = run_query(f"""
        SELECT CUSTOMER_SEGMENT, CHURN_RISK_CATEGORY, COUNT(*) AS COUNT
        FROM {DB}.{SCHEMA}.CUSTOMER_360_VIEW
        GROUP BY CUSTOMER_SEGMENT, CHURN_RISK_CATEGORY
        ORDER BY CUSTOMER_SEGMENT
    """)
    claims_by_type = run_query(f"""
        SELECT CLAIM_TYPE, COUNT(*) AS COUNT FROM {DB}.{SCHEMA}.CLAIMS GROUP BY CLAIM_TYPE ORDER BY COUNT DESC
    """)
    interactions_by_channel = run_query(f"""
        SELECT CHANNEL, COUNT(*) AS COUNT FROM {DB}.{SCHEMA}.CUSTOMER_INTERACTIONS GROUP BY CHANNEL ORDER BY COUNT DESC
    """)
    health_dist = run_query(f"""
        SELECT
            CASE WHEN CUSTOMER_HEALTH_SCORE >= 80 THEN 'Excellent (80-100)'
                 WHEN CUSTOMER_HEALTH_SCORE >= 60 THEN 'Good (60-79)'
                 WHEN CUSTOMER_HEALTH_SCORE >= 40 THEN 'Fair (40-59)'
                 ELSE 'Poor (0-39)' END AS HEALTH_BAND,
            COUNT(*) AS COUNT
        FROM {DB}.{SCHEMA}.CUSTOMER_360_VIEW
        GROUP BY HEALTH_BAND ORDER BY HEALTH_BAND
    """)
    pain_points = run_query(f"""
        SELECT INTERACTION_TYPE, COUNT(*) AS COUNT
        FROM {DB}.{SCHEMA}.CUSTOMER_INTERACTIONS
        WHERE SENTIMENT = 'Negative'
        GROUP BY INTERACTION_TYPE ORDER BY COUNT DESC LIMIT 8
    """)
    return {
        "risk_by_segment": risk_by_segment,
        "claims_by_type": claims_by_type,
        "interactions_by_channel": interactions_by_channel,
        "health_distribution": health_dist,
        "pain_points": pain_points,
    }
