"""Customer header component for Customer360 AI."""
import streamlit as st
from utils.formatting import fmt_currency, fmt_score, risk_color, risk_icon, health_color
import pandas as pd


def render_customer_header(c: pd.Series):
    """Render the customer profile header with risk and health badges."""
    rc = risk_color(c["CHURN_RISK_CATEGORY"])
    ri = risk_icon(c["CHURN_RISK_CATEGORY"])
    hc = health_color(c["CUSTOMER_HEALTH_SCORE"])

    st.markdown(f"""
    <div style="background:linear-gradient(135deg,#1B2A4A 0%,#2C3E6B 100%);
                border-radius:12px;padding:24px 28px;color:white;margin-bottom:20px;">
        <div style="display:flex;justify-content:space-between;align-items:flex-start;flex-wrap:wrap;">
            <div>
                <div style="font-size:1.8em;font-weight:700;">{c['FULL_NAME']}</div>
                <div style="font-size:0.95em;opacity:0.85;margin-top:4px;">
                    {c['CUSTOMER_ID']} &nbsp;|&nbsp; {c['CUSTOMER_SEGMENT']} &nbsp;|&nbsp;
                    Customer since {str(c['CUSTOMER_SINCE'])[:10]} &nbsp;|&nbsp;
                    Status: {c['CURRENT_CUSTOMER_STATUS']}
                </div>
                <div style="margin-top:8px;font-size:0.9em;opacity:0.8;">
                    Lifetime Value: <strong>{fmt_currency(c['CUSTOMER_LIFETIME_VALUE'])}</strong>
                    &nbsp;&nbsp;|&nbsp;&nbsp;
                    Preferred Channel: <strong>{c['PREFERRED_CHANNEL']}</strong>
                </div>
            </div>
            <div style="display:flex;gap:16px;margin-top:8px;">
                <div style="background:rgba(255,255,255,0.12);border-radius:8px;padding:12px 18px;text-align:center;
                            border:1px solid {rc};">
                    <div style="font-size:0.7em;text-transform:uppercase;letter-spacing:1px;opacity:0.8;">Churn Risk</div>
                    <div style="font-size:1.5em;font-weight:700;color:{rc};">
                        {ri} {c['CHURN_RISK_CATEGORY']}</div>
                    <div style="font-size:0.85em;opacity:0.9;">{fmt_score(c['CHURN_RISK_SCORE'])}</div>
                </div>
                <div style="background:rgba(255,255,255,0.12);border-radius:8px;padding:12px 18px;text-align:center;
                            border:1px solid {hc};">
                    <div style="font-size:0.7em;text-transform:uppercase;letter-spacing:1px;opacity:0.8;">Health Score</div>
                    <div style="font-size:1.5em;font-weight:700;color:{hc};">
                        {fmt_score(c['CUSTOMER_HEALTH_SCORE'])}</div>
                </div>
            </div>
        </div>
    </div>
    """, unsafe_allow_html=True)
