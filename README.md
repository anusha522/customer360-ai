# Customer360 AI

AI-powered customer intelligence and retention platform for insurance, built with Snowflake + Cortex AI + Streamlit.

## Architecture

```
Source Tables (5)          Dynamic Tables (3)              Streamlit App (14 files)
CUSTOMERS ──────┐
POLICIES ───────┤
CLAIMS ─────────┼──→ CUSTOMER_360_VIEW ──┬──→ app.py (entry point)
INTERACTIONS ───┤         (churn scoring) ├──→ views/ (5 pages)
TRANSCRIPTS ────┘                        ├──→ components/ (6 widgets)
                 CHURN_SIGNALS_EXPLAINED ─┘   utils/ (DB + formatting)
                 NEXT_BEST_ACTION ───────┘

AI Functions (4) — SQL UDFs calling SNOWFLAKE.CORTEX.COMPLETE (llama3.1-70b)
```

## Setup

Run the SQL files in order:

```sql
-- 1. Create tables
@sql/01_tables.sql

-- 2. Create dynamic tables (replaces views)
@sql/02_dynamic_tables.sql

-- 3. Create AI functions
@sql/03_functions.sql
```

Then deploy the Streamlit app:

```sql
CREATE STAGE IF NOT EXISTS CUSTOMER_360_DB.C360.CUSTOMER360_APP_STAGE;
-- Upload all Python files to @CUSTOMER360_APP_STAGE/CUSTOMER360_AI/

CREATE STREAMLIT IF NOT EXISTS CUSTOMER_360_DB.C360.CUSTOMER360_AI
  ROOT_LOCATION = '@CUSTOMER_360_DB.C360.CUSTOMER360_APP_STAGE/CUSTOMER360_AI'
  MAIN_FILE = 'app.py'
  QUERY_WAREHOUSE = COMPUTE_WH
  TITLE = 'Customer360 AI';
```

## Pages

| Page | Description |
|------|-------------|
| Executive Dashboard | KPIs, risk distribution, high-priority customer list |
| Customer 360 | Full customer profile with 6 detail tabs |
| Ask Customer 360 | Natural language Q&A over customer data |
| Action Center | Filterable priority work queue |
| Customer Analytics | Management-level analytical charts |

## Built With

- **Snowflake** — Data warehouse, dynamic tables, SQL functions
- **Cortex AI** — `SNOWFLAKE.CORTEX.COMPLETE` with `llama3.1-70b`
- **Streamlit-in-Snowflake** — Application framework
- **Cortex Code (CoCo)** — AI-powered IDE that generated all code
