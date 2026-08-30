"""Churn risk explanation panel for Customer360 AI."""
import streamlit as st
import pandas as pd
import json
from utils.formatting import risk_color, risk_icon


def render_risk_panel(signals: pd.Series):
    """Render explainable churn risk drivers."""
    if signals is None:
        st.info("No risk data available for this customer.")
        return

    rc = risk_color(signals["CHURN_RISK_CATEGORY"])
    ri = risk_icon(signals["CHURN_RISK_CATEGORY"])

    st.markdown(f"""
    <div style="background:white;border-radius:8px;padding:16px 20px;border-left:4px solid {rc};
                box-shadow:0 1px 3px rgba(0,0,0,0.08);margin-bottom:16px;">
        <div style="font-size:1.1em;font-weight:600;color:#1B2A4A;">
            {ri} Churn Risk: {signals['CHURN_RISK_CATEGORY']} ({int(signals['CHURN_RISK_SCORE'])}/100)
        </div>
    </div>
    """, unsafe_allow_html=True)

    drivers = signals.get("CHURN_DRIVERS")
    if drivers is None:
        st.write("No specific risk drivers identified.")
        return

    if isinstance(drivers, str):
        try:
            drivers = json.loads(drivers)
        except (json.JSONDecodeError, TypeError):
            drivers = [d.strip() for d in drivers.split(",") if d.strip()]

    if not drivers:
        st.success("No active risk signals for this customer.")
        return

    for driver in drivers:
        d = str(driver)
        if "CANCELLATION" in d.upper():
            icon, color = "\u26a0\ufe0f", "#e74c3c"
        elif "NEGATIVE SENTIMENT" in d.upper() or "DETERIORATION" in d.upper():
            icon, color = "\U0001f4c9", "#e74c3c"
        elif "OPEN CLAIM" in d.upper() or "DELAYED CLAIM" in d.upper():
            icon, color = "\U0001f4cb", "#f39c12"
        elif "RENEWAL" in d.upper():
            icon, color = "\u23f0", "#f39c12"
        elif "PAYMENT" in d.upper():
            icon, color = "\U0001f4b3", "#e67e22"
        elif "COMPLAINT" in d.upper():
            icon, color = "\U0001f4e2", "#e74c3c"
        elif "UNRESOLVED" in d.upper():
            icon, color = "\U0001f504", "#f39c12"
        else:
            icon, color = "\u2139\ufe0f", "#3498db"

        parts = d.split(":", 1)
        label = parts[0].strip() if len(parts) > 1 else "Signal"
        detail = parts[1].strip() if len(parts) > 1 else d

        st.markdown(f"""
        <div style="background:#fafafa;border-radius:6px;padding:10px 14px;margin-bottom:8px;
                    border-left:3px solid {color};">
            <div style="font-size:0.85em;">
                {icon} <strong style="color:{color};">{label}</strong>
            </div>
            <div style="font-size:0.85em;color:#555;margin-top:2px;">
                <em>Data Fact:</em> {detail}
            </div>
        </div>
        """, unsafe_allow_html=True)
