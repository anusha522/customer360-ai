"""Next Best Action card component for Customer360 AI."""
import streamlit as st
import pandas as pd
from utils.formatting import priority_badge, risk_color, risk_icon


def render_nba_card(nba: pd.Series, customer: pd.Series = None):
    """Render a prominent Next Best Action card."""
    if nba is None:
        st.markdown("""
        <div style="background:#f0fff0;border-radius:8px;padding:16px 20px;border-left:4px solid #27ae60;">
            <div style="font-size:1em;font-weight:600;color:#27ae60;">
                \u2705 No Immediate Action Required</div>
            <div style="font-size:0.9em;color:#666;margin-top:4px;">
                Customer metrics are within acceptable ranges. Continue monitoring.</div>
        </div>
        """, unsafe_allow_html=True)
        return

    p = str(nba["PRIORITY"]).upper()
    if p == "HIGH":
        border, bg = "#e74c3c", "#fff5f5"
    elif p == "MEDIUM":
        border, bg = "#f39c12", "#fffbf0"
    else:
        border, bg = "#27ae60", "#f0fff0"

    st.markdown(f"""
    <div style="background:{bg};border-radius:10px;padding:20px 24px;border-left:5px solid {border};
                box-shadow:0 2px 8px rgba(0,0,0,0.06);margin-bottom:16px;">
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;">
            <div style="font-size:0.7em;text-transform:uppercase;letter-spacing:1px;color:{border};
                        font-weight:700;">Next Best Action</div>
            <div>{priority_badge(p)}</div>
        </div>
        <div style="font-size:1.2em;font-weight:700;color:#1B2A4A;margin-bottom:12px;">
            {nba['RECOMMENDED_ACTION']}
        </div>
        <div style="font-size:0.9em;color:#444;margin-bottom:8px;">
            <strong>Why:</strong> {nba['REASON']}
        </div>
        <div style="font-size:0.9em;color:#444;margin-bottom:8px;">
            <strong>Channel:</strong> {nba['SUGGESTED_CHANNEL']}
        </div>
        <div style="font-size:0.9em;color:#444;">
            <strong>Expected Outcome:</strong> {nba['EXPECTED_OUTCOME']}
        </div>
    </div>
    """, unsafe_allow_html=True)

    if customer is not None:
        with st.expander("Supporting Evidence"):
            evidence = []
            if customer.get("OPEN_CLAIMS") and int(customer["OPEN_CLAIMS"]) > 0:
                evidence.append(f"Open claims: {int(customer['OPEN_CLAIMS'])}")
                if customer.get("LARGEST_OPEN_CLAIM") and not pd.isna(customer["LARGEST_OPEN_CLAIM"]):
                    evidence.append(f"Largest open claim: ${customer['LARGEST_OPEN_CLAIM']:,.0f}")
            if customer.get("DELAYED_CLAIMS") and int(customer["DELAYED_CLAIMS"]) > 0:
                evidence.append(f"Delayed claims: {int(customer['DELAYED_CLAIMS'])}")
            if customer.get("COMPLAINT_COUNT") and int(customer["COMPLAINT_COUNT"]) > 0:
                evidence.append(f"Complaints: {int(customer['COMPLAINT_COUNT'])}")
            if customer.get("CANCELLATION_INTERACTION_COUNT") and int(customer["CANCELLATION_INTERACTION_COUNT"]) > 0:
                evidence.append(f"Cancellation interactions: {int(customer['CANCELLATION_INTERACTION_COUNT'])}")
            if customer.get("NEGATIVE_INTERACTION_COUNT") and int(customer["NEGATIVE_INTERACTION_COUNT"]) > 0:
                evidence.append(f"Negative interactions: {int(customer['NEGATIVE_INTERACTION_COUNT'])}")
            if customer.get("PAYMENT_ISSUES_COUNT") and int(customer["PAYMENT_ISSUES_COUNT"]) > 0:
                evidence.append(f"Payment issues: {int(customer['PAYMENT_ISSUES_COUNT'])}")
            if customer.get("DAYS_UNTIL_RENEWAL") and not pd.isna(customer["DAYS_UNTIL_RENEWAL"]):
                evidence.append(f"Renewal in {int(customer['DAYS_UNTIL_RENEWAL'])} days")

            if evidence:
                for e in evidence:
                    st.markdown(f"- {e}")
            else:
                st.write("No additional evidence.")
