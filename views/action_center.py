"""Page 4: Action Center — Operational work queue."""
import streamlit as st
import pandas as pd
from utils.snowflake import get_attention_customers
from utils.formatting import fmt_currency, risk_icon, priority_badge


def render():
    st.markdown("""
    <div style="margin-bottom:12px;">
        <h2 style="color:#1B2A4A;margin-bottom:4px;">Action Center</h2>
        <div style="font-size:0.95em;color:#555;">
            Who should I contact and what should I do? Prioritized by risk and business impact.
        </div>
    </div>
    """, unsafe_allow_html=True)

    try:
        all_actions = get_attention_customers()
    except Exception as e:
        st.error(f"Failed to load action data: {str(e)[:200]}")
        return

    if len(all_actions) == 0:
        st.success("No customers require intervention at this time.")
        return

    col_f1, col_f2, col_f3, col_f4 = st.columns(4)

    with col_f1:
        priorities = ["All"] + sorted(all_actions["PRIORITY"].unique().tolist())
        sel_priority = st.selectbox("Priority", priorities, key="ac_priority")
    with col_f2:
        risk_cats = ["All"] + sorted(all_actions["CHURN_RISK_CATEGORY"].unique().tolist())
        sel_risk = st.selectbox("Risk Level", risk_cats, key="ac_risk")
    with col_f3:
        segments = ["All"] + sorted(all_actions["CUSTOMER_SEGMENT"].unique().tolist())
        sel_segment = st.selectbox("Segment", segments, key="ac_segment")
    with col_f4:
        triggers = ["All"] + sorted(all_actions["ACTION_TRIGGER"].unique().tolist())
        sel_trigger = st.selectbox("Trigger", triggers, key="ac_trigger")

    filtered = all_actions.copy()
    if sel_priority != "All":
        filtered = filtered[filtered["PRIORITY"] == sel_priority]
    if sel_risk != "All":
        filtered = filtered[filtered["CHURN_RISK_CATEGORY"] == sel_risk]
    if sel_segment != "All":
        filtered = filtered[filtered["CUSTOMER_SEGMENT"] == sel_segment]
    if sel_trigger != "All":
        filtered = filtered[filtered["ACTION_TRIGGER"] == sel_trigger]

    high_count = len(filtered[filtered["PRIORITY"] == "HIGH"])
    med_count = len(filtered[filtered["PRIORITY"] == "MEDIUM"])

    st.markdown(f"""
    <div style="display:flex;gap:16px;margin:12px 0;">
        <div style="background:#fff5f5;border-radius:6px;padding:8px 16px;border-left:3px solid #e74c3c;">
            <strong style="color:#e74c3c;">{high_count}</strong> HIGH priority
        </div>
        <div style="background:#fffbf0;border-radius:6px;padding:8px 16px;border-left:3px solid #f39c12;">
            <strong style="color:#f39c12;">{med_count}</strong> MEDIUM priority
        </div>
        <div style="background:#f8f9fa;border-radius:6px;padding:8px 16px;">
            <strong>{len(filtered)}</strong> total actions
        </div>
    </div>
    """, unsafe_allow_html=True)

    for _, row in filtered.head(30).iterrows():
        p = str(row["PRIORITY"]).upper()
        if p == "HIGH":
            border, bg = "#e74c3c", "#fff5f5"
        elif p == "MEDIUM":
            border, bg = "#f39c12", "#fffbf0"
        else:
            border, bg = "#27ae60", "#f0fff0"

        ri = risk_icon(row["CHURN_RISK_CATEGORY"])

        st.markdown(f"""
        <div style="background:{bg};border-radius:8px;padding:14px 18px;margin-bottom:10px;
                    border-left:4px solid {border};box-shadow:0 1px 3px rgba(0,0,0,0.04);">
            <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;">
                <div>
                    <strong style="font-size:1.05em;">{row['FULL_NAME']}</strong>
                    <span style="font-size:0.85em;color:#888;margin-left:8px;">{row['CUSTOMER_ID']}</span>
                    <span style="font-size:0.85em;margin-left:8px;">{ri} {row['CHURN_RISK_CATEGORY']} ({int(row['CHURN_RISK_SCORE'])})</span>
                    <span style="font-size:0.85em;color:#888;margin-left:8px;">{row['CUSTOMER_SEGMENT']}</span>
                </div>
                <div>{priority_badge(p)}</div>
            </div>
            <div style="font-size:0.9em;color:#444;margin-top:8px;">
                <strong>Action:</strong> {row['RECOMMENDED_ACTION']}
            </div>
            <div style="font-size:0.85em;color:#666;margin-top:4px;">
                <strong>Why:</strong> {row['REASON']}
            </div>
            <div style="font-size:0.85em;color:#888;margin-top:4px;">
                Channel: {row['SUGGESTED_CHANNEL']} &nbsp;|&nbsp;
                CLV: {fmt_currency(row['CUSTOMER_LIFETIME_VALUE'])} &nbsp;|&nbsp;
                Health: {int(row['CUSTOMER_HEALTH_SCORE'])}/100
            </div>
        </div>
        """, unsafe_allow_html=True)

    if len(filtered) > 0:
        st.markdown("---")
        st.markdown("##### Open Customer 360")
        cust_options = [f"{r['CUSTOMER_ID']} — {r['FULL_NAME']}" for _, r in filtered.head(30).iterrows()]
        sel = st.selectbox("Select a customer to view details", [""] + cust_options, key="ac_select")
        if sel:
            cid = sel.split(" — ")[0].strip()
            if st.button("Open Customer 360", type="primary"):
                st.session_state["selected_customer_id"] = cid
                st.session_state["current_page"] = "Customer 360"
                st.rerun()
