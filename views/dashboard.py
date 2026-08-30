"""Page 1: Executive Dashboard for Customer360 AI."""
import streamlit as st
from components.kpi_cards import render_kpi_row
from utils.snowflake import (
    get_executive_kpis, get_risk_distribution, get_sentiment_distribution,
    get_claims_overview, get_attention_customers
)
from utils.formatting import fmt_currency, fmt_number, risk_icon


def render():
    st.markdown("""
    <div style="margin-bottom:20px;">
        <h2 style="color:#1B2A4A;margin-bottom:4px;">Executive Dashboard</h2>
        <div style="font-size:0.95em;color:#555;">
            AI-powered Customer 360 for proactive retention and personalized customer engagement.
        </div>
        <div style="display:flex;gap:8px;margin-top:10px;flex-wrap:wrap;">
            <span style="background:#1B2A4A;color:white;padding:3px 12px;border-radius:20px;font-size:0.75em;letter-spacing:0.5px;">UNIFY</span>
            <span style="color:#aaa;">&rarr;</span>
            <span style="background:#2C3E6B;color:white;padding:3px 12px;border-radius:20px;font-size:0.75em;letter-spacing:0.5px;">UNDERSTAND</span>
            <span style="color:#aaa;">&rarr;</span>
            <span style="background:#3498db;color:white;padding:3px 12px;border-radius:20px;font-size:0.75em;letter-spacing:0.5px;">PREDICT</span>
            <span style="color:#aaa;">&rarr;</span>
            <span style="background:#f39c12;color:white;padding:3px 12px;border-radius:20px;font-size:0.75em;letter-spacing:0.5px;">RECOMMEND</span>
            <span style="color:#aaa;">&rarr;</span>
            <span style="background:#27ae60;color:white;padding:3px 12px;border-radius:20px;font-size:0.75em;letter-spacing:0.5px;">ACT</span>
        </div>
    </div>
    """, unsafe_allow_html=True)

    try:
        kpis = get_executive_kpis()
    except Exception as e:
        st.error(f"Failed to load dashboard data: {str(e)[:200]}")
        return

    render_kpi_row([
        {"label": "Total Customers", "value": fmt_number(kpis["total_customers"]), "color": "#1B2A4A"},
        {"label": "High Risk Customers", "value": fmt_number(kpis["high_risk"]), "color": "#e74c3c"},
        {"label": "Actions Required", "value": fmt_number(kpis["action_required"]),
         "color": "#e74c3c", "delta": "HIGH priority"},
        {"label": "Open Claims", "value": fmt_number(kpis["open_claims"]), "color": "#f39c12"},
        {"label": "Negative Sentiment", "value": fmt_number(kpis["negative_sentiment"]), "color": "#e74c3c"},
        {"label": "Avg Health Score", "value": f"{kpis['avg_health']}/100", "color": "#3498db"},
    ])

    st.markdown("")

    col1, col2, col3 = st.columns(3)

    with col1:
        st.markdown("##### Risk Distribution")
        try:
            risk_df = get_risk_distribution()
            colors = {"HIGH": "#e74c3c", "MEDIUM": "#f39c12", "LOW": "#27ae60"}
            for _, row in risk_df.iterrows():
                cat = row["CHURN_RISK_CATEGORY"]
                cnt = int(row["COUNT"])
                pct = cnt / kpis["total_customers"] * 100
                color = colors.get(cat, "#95a5a6")
                st.markdown(f"""
                <div style="display:flex;align-items:center;margin-bottom:8px;">
                    <div style="width:80px;font-weight:600;color:{color};">{risk_icon(cat)} {cat}</div>
                    <div style="flex:1;background:#eee;border-radius:4px;height:20px;margin:0 10px;">
                        <div style="background:{color};width:{pct}%;height:100%;border-radius:4px;"></div>
                    </div>
                    <div style="width:60px;text-align:right;font-weight:600;">{cnt}</div>
                </div>
                """, unsafe_allow_html=True)
        except Exception:
            st.warning("Could not load risk distribution.")

    with col2:
        st.markdown("##### Sentiment Distribution")
        try:
            sent_df = get_sentiment_distribution()
            colors = {"Positive": "#27ae60", "Neutral": "#f39c12", "Negative": "#e74c3c"}
            for _, row in sent_df.iterrows():
                cat = row["SENTIMENT_CATEGORY"]
                cnt = int(row["COUNT"])
                pct = cnt / kpis["total_customers"] * 100
                color = colors.get(cat, "#95a5a6")
                st.markdown(f"""
                <div style="display:flex;align-items:center;margin-bottom:8px;">
                    <div style="width:80px;font-weight:600;color:{color};">{cat}</div>
                    <div style="flex:1;background:#eee;border-radius:4px;height:20px;margin:0 10px;">
                        <div style="background:{color};width:{pct}%;height:100%;border-radius:4px;"></div>
                    </div>
                    <div style="width:60px;text-align:right;font-weight:600;">{cnt}</div>
                </div>
                """, unsafe_allow_html=True)
        except Exception:
            st.warning("Could not load sentiment data.")

    with col3:
        st.markdown("##### Claims Overview")
        try:
            claims_df = get_claims_overview()
            for _, row in claims_df.iterrows():
                status = row["CLAIM_STATUS"]
                cnt = int(row["COUNT"])
                avg = row["AVG_DAYS"]
                if status in ("Pending", "Under Review"):
                    color = "#f39c12"
                elif status == "Rejected":
                    color = "#e74c3c"
                else:
                    color = "#27ae60"
                st.markdown(f"""
                <div style="display:flex;justify-content:space-between;padding:4px 0;border-bottom:1px solid #f0f0f0;">
                    <span style="color:{color};font-weight:600;">{status}</span>
                    <span>{cnt} <span style="font-size:0.8em;color:#888;">({avg}d avg)</span></span>
                </div>
                """, unsafe_allow_html=True)
        except Exception:
            st.warning("Could not load claims data.")

    st.markdown("---")

    try:
        attention_df = get_attention_customers()
        high_priority = attention_df[attention_df["PRIORITY"] == "HIGH"].head(15)

        if len(high_priority) > 0:
            high_value_at_risk = high_priority[high_priority["CUSTOMER_LIFETIME_VALUE"] >= 20000]

            # AI insight panel
            top_triggers = high_priority["ACTION_TRIGGER"].value_counts()
            trigger_summary = ", ".join(
                t.replace("_", " ").lower() for t in top_triggers.head(3).index
            )
            st.markdown(f"""
            <div style="background:linear-gradient(135deg,#1B2A4A,#2C3E6B);border-radius:10px;padding:16px 20px;
                        margin-bottom:20px;color:white;">
                <div style="font-size:0.7em;text-transform:uppercase;letter-spacing:1px;opacity:0.7;margin-bottom:6px;">
                    AI Executive Insight &nbsp;
                    <span style="background:rgba(255,255,255,0.15);padding:1px 8px;border-radius:3px;font-size:0.9em;">
                        Based on Snowflake data</span>
                </div>
                <div style="font-size:1.05em;line-height:1.5;">
                    <strong>{len(high_priority)}</strong> customers require HIGH priority intervention.
                    {f'<strong>{len(high_value_at_risk)}</strong> are high-value customers (CLV&nbsp;>&nbsp;$20K) representing significant revenue at risk.' if len(high_value_at_risk) > 0 else ''}
                    The dominant signals are <strong>{trigger_summary}</strong>.
                </div>
            </div>
            """, unsafe_allow_html=True)

            st.markdown("##### Customers Requiring Attention")

            display_df = high_priority[["CUSTOMER_ID", "FULL_NAME", "CHURN_RISK_SCORE",
                                        "CUSTOMER_HEALTH_SCORE", "ACTION_TRIGGER",
                                        "RECOMMENDED_ACTION", "PRIORITY"]].copy()
            display_df.columns = ["ID", "Customer", "Churn Risk", "Health",
                                  "Main Issue", "Recommended Action", "Priority"]
            display_df["Main Issue"] = display_df["Main Issue"].str.replace("_", " ").str.title()

            st.dataframe(display_df, hide_index=True)

            st.markdown("")
            cols = st.columns([2, 1])
            with cols[0]:
                sel = st.selectbox(
                    "Open Customer 360",
                    [""] + [f"{r['CUSTOMER_ID']} — {r['FULL_NAME']}" for _, r in high_priority.iterrows()],
                    key="dash_select"
                )
            with cols[1]:
                st.markdown("")
                st.markdown("")
                if st.button("View Customer 360", type="primary", key="dash_open"):
                    if sel:
                        cid = sel.split(" — ")[0].strip()
                        st.session_state["selected_customer_id"] = cid
                        st.session_state["current_page"] = "Customer 360"
                        st.rerun()
        else:
            st.success("No HIGH priority actions required at this time.")

    except Exception as e:
        st.warning(f"Could not load attention data: {str(e)[:200]}")
