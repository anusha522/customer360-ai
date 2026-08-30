"""Page 2: Customer 360 — the primary application screen."""
import streamlit as st
import pandas as pd
from components.customer_header import render_customer_header
from components.kpi_cards import render_kpi_row
from components.risk_panel import render_risk_panel
from components.transcript_panel import render_transcript_panel
from components.nba_card import render_nba_card
from components.communication_panel import render_communication_panel
from utils.snowflake import (
    get_customer_360, get_customer_policies, get_customer_claims,
    get_customer_interactions, get_customer_transcripts,
    get_churn_signals, get_next_best_action,
    call_transcript_intelligence, call_customer_ai_summary,
)
from utils.formatting import (
    fmt_currency, fmt_number, sentiment_icon, claim_status_style,
    payment_status_style, risk_color
)


def render():
    customer_id = st.session_state.get("selected_customer_id")

    if not customer_id:
        st.markdown("## Customer 360")
        st.info("Select a customer from the sidebar to view their 360-degree profile.")
        if st.button("Load Demo"):
            st.session_state["selected_customer_id"] = "CUST-0340"
            st.rerun()
        return

    with st.spinner("Loading customer profile..."):
        try:
            c = get_customer_360(customer_id)
        except Exception as e:
            st.error(f"Error loading customer: {str(e)[:200]}")
            return

    if c is None:
        st.error(f"Customer {customer_id} not found.")
        return

    # ── Customer Header ──
    render_customer_header(c)

    # ── KPI Cards ──
    sentiment_val = c.get("AVG_SENTIMENT_SCORE")
    sentiment_str = f"{sentiment_val:.2f}" if sentiment_val and not pd.isna(sentiment_val) else "N/A"

    render_kpi_row([
        {"label": "Policies", "value": fmt_number(c["NUM_POLICIES"]), "color": "#1B2A4A"},
        {"label": "Annual Premium", "value": fmt_currency(c["TOTAL_ANNUAL_PREMIUM"]), "color": "#2C3E6B"},
        {"label": "Open Claims", "value": fmt_number(c["OPEN_CLAIMS"]),
         "color": "#e74c3c" if c["OPEN_CLAIMS"] > 0 else "#27ae60"},
        {"label": "Avg Sentiment", "value": sentiment_str,
         "color": "#e74c3c" if sentiment_val and sentiment_val < -0.1 else "#27ae60"},
        {"label": "Lifetime Value", "value": fmt_currency(c["CUSTOMER_LIFETIME_VALUE"]), "color": "#27ae60"},
        {"label": "Days to Renewal", "value": str(int(c["DAYS_UNTIL_RENEWAL"])) if c.get("DAYS_UNTIL_RENEWAL") and not pd.isna(c["DAYS_UNTIL_RENEWAL"]) else "N/A",
         "color": "#e74c3c" if c.get("DAYS_UNTIL_RENEWAL") and not pd.isna(c["DAYS_UNTIL_RENEWAL"]) and c["DAYS_UNTIL_RENEWAL"] <= 60 else "#1B2A4A"},
    ])

    # ── Immediate: Why this customer needs attention + Next Best Action ──
    if c["CHURN_RISK_CATEGORY"] in ("HIGH", "MEDIUM"):
        st.markdown("")
        col_risk, col_nba = st.columns([1, 1])

        with col_risk:
            st.markdown("##### Why This Customer Needs Attention")
            try:
                signals = get_churn_signals(customer_id)
                render_risk_panel(signals)
            except Exception as e:
                st.warning(f"Could not load risk signals: {str(e)[:200]}")

            # AI interpretation
            st.markdown(f"""
            <div style="background:#f0f4ff;border-radius:6px;padding:10px 14px;margin-top:8px;
                        border-left:3px solid #3498db;">
                <div style="font-size:0.7em;text-transform:uppercase;letter-spacing:0.5px;color:#3498db;
                            font-weight:600;margin-bottom:4px;">AI Interpretation</div>
                <div style="font-size:0.85em;color:#555;">
                    The combination of {int(c.get('NEGATIVE_INTERACTION_COUNT', 0))} negative interaction(s),
                    {int(c.get('CANCELLATION_INTERACTION_COUNT', 0))} cancellation signal(s),
                    {int(c.get('OPEN_CLAIMS', 0))} open claim(s),
                    and {'an approaching renewal in ' + str(int(c['DAYS_UNTIL_RENEWAL'])) + ' days' if c.get('DAYS_UNTIL_RENEWAL') and not pd.isna(c['DAYS_UNTIL_RENEWAL']) and c['DAYS_UNTIL_RENEWAL'] <= 90 else 'no imminent renewal'}
                    {'creates an elevated churn risk requiring immediate attention.' if c['CHURN_RISK_CATEGORY'] == 'HIGH' else 'suggests moderate churn risk that should be monitored.'}
                </div>
            </div>
            """, unsafe_allow_html=True)

        with col_nba:
            st.markdown("##### Next Best Action")
            try:
                nba = get_next_best_action(customer_id)
                render_nba_card(nba, c)
            except Exception as e:
                st.warning(f"Could not load NBA: {str(e)[:200]}")

        # ── Visual customer journey ──
        st.markdown("")
        st.markdown(f"""
        <div style="background:white;border-radius:10px;padding:16px 20px;box-shadow:0 1px 4px rgba(0,0,0,0.06);
                    margin-bottom:8px;">
            <div style="display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:4px;
                        font-size:0.85em;">
                <div style="text-align:center;flex:1;">
                    <div style="background:#1B2A4A;color:white;border-radius:6px;padding:6px 10px;font-weight:600;">
                        Customer Signals</div>
                    <div style="font-size:0.85em;color:#888;margin-top:4px;">{int(c['NUM_INTERACTIONS'])} interactions, {int(c['NEGATIVE_INTERACTION_COUNT'])} negative</div>
                </div>
                <div style="color:#ccc;font-size:1.2em;">&rarr;</div>
                <div style="text-align:center;flex:1;">
                    <div style="background:{risk_color(c['CHURN_RISK_CATEGORY'])};color:white;border-radius:6px;padding:6px 10px;font-weight:600;">
                        Risk: {c['CHURN_RISK_CATEGORY']} ({int(c['CHURN_RISK_SCORE'])})</div>
                    <div style="font-size:0.85em;color:#888;margin-top:4px;">Health: {int(c['CUSTOMER_HEALTH_SCORE'])}/100</div>
                </div>
                <div style="color:#ccc;font-size:1.2em;">&rarr;</div>
                <div style="text-align:center;flex:1;">
                    <div style="background:#3498db;color:white;border-radius:6px;padding:6px 10px;font-weight:600;">
                        AI Analysis</div>
                    <div style="font-size:0.85em;color:#888;margin-top:4px;">Structured + transcript evidence</div>
                </div>
                <div style="color:#ccc;font-size:1.2em;">&rarr;</div>
                <div style="text-align:center;flex:1;">
                    <div style="background:#f39c12;color:white;border-radius:6px;padding:6px 10px;font-weight:600;">
                        Recommendation</div>
                    <div style="font-size:0.85em;color:#888;margin-top:4px;">{nba['RECOMMENDED_ACTION'][:40] + '...' if nba is not None and len(str(nba.get('RECOMMENDED_ACTION',''))) > 40 else (nba['RECOMMENDED_ACTION'] if nba is not None else 'Monitor')}</div>
                </div>
                <div style="color:#ccc;font-size:1.2em;">&rarr;</div>
                <div style="text-align:center;flex:1;">
                    <div style="background:#27ae60;color:white;border-radius:6px;padding:6px 10px;font-weight:600;">
                        Take Action</div>
                    <div style="font-size:0.85em;color:#888;margin-top:4px;">Personalized outreach</div>
                </div>
            </div>
        </div>
        """, unsafe_allow_html=True)

    st.markdown("---")

    # ── Detail Tabs ──
    tab_pol, tab_claims, tab_interact, tab_transcripts, tab_ai, tab_comm = st.tabs([
        "Policies",
        "Claims",
        "Interactions",
        "Transcript Intelligence",
        "AI Relationship Summary",
        "Personalized Communication"
    ])

    with tab_pol:
        st.markdown("##### Policy Portfolio")
        try:
            policies = get_customer_policies(customer_id)
            if len(policies) > 0:
                for _, p in policies.iterrows():
                    renewal = str(p.get("RENEWAL_DATE", ""))[:10] if p.get("RENEWAL_DATE") and not pd.isna(p.get("RENEWAL_DATE")) else "N/A"
                    ps = str(p["PAYMENT_STATUS"])
                    is_problem = ps in ("Overdue", "Delinquent", "Late")
                    border = "#e74c3c" if is_problem else "#27ae60" if p["POLICY_STATUS"] == "Active" else "#f39c12"

                    st.markdown(f"""
                    <div style="background:white;border-radius:8px;padding:14px 18px;margin-bottom:10px;
                                border-left:4px solid {border};box-shadow:0 1px 3px rgba(0,0,0,0.06);">
                        <div style="display:flex;justify-content:space-between;align-items:center;">
                            <div>
                                <strong>{p['POLICY_ID']}</strong> — {p['POLICY_TYPE']}
                                <span style="background:{'#27ae60' if p['POLICY_STATUS']=='Active' else '#f39c12'};
                                      color:white;padding:1px 8px;border-radius:3px;font-size:0.8em;margin-left:8px;">
                                    {p['POLICY_STATUS']}</span>
                            </div>
                            <div style="text-align:right;"><strong>{fmt_currency(p['PREMIUM_AMOUNT'])}</strong>/yr</div>
                        </div>
                        <div style="font-size:0.85em;color:#666;margin-top:6px;">
                            Coverage: {fmt_currency(p['COVERAGE_AMOUNT'])} &nbsp;|&nbsp;
                            Deductible: {fmt_currency(p['DEDUCTIBLE'])} &nbsp;|&nbsp;
                            Payment: {payment_status_style(ps)} &nbsp;|&nbsp;
                            Renewal: {renewal}
                        </div>
                    </div>
                    """, unsafe_allow_html=True)
            else:
                st.info("No policies found.")
        except Exception as e:
            st.warning(f"Could not load policies: {str(e)[:200]}")

    with tab_claims:
        st.markdown("##### Claims History")
        try:
            claims = get_customer_claims(customer_id)
            if len(claims) > 0:
                for _, cl in claims.iterrows():
                    status = str(cl["CLAIM_STATUS"])
                    is_open = status in ("Pending", "Under Review")
                    is_delayed = cl.get("PROCESSING_DAYS") and int(cl["PROCESSING_DAYS"]) > 30
                    severity = str(cl.get("CLAIM_SEVERITY", ""))
                    border = "#e74c3c" if is_open or status == "Rejected" else "#f39c12" if is_delayed else "#27ae60"

                    flags = []
                    if is_open:
                        flags.append("Open")
                    if is_delayed:
                        flags.append("Delayed")
                    if severity == "High":
                        flags.append("High Severity")

                    st.markdown(f"""
                    <div style="background:white;border-radius:8px;padding:14px 18px;margin-bottom:10px;
                                border-left:4px solid {border};box-shadow:0 1px 3px rgba(0,0,0,0.06);">
                        <div style="display:flex;justify-content:space-between;align-items:center;">
                            <div>
                                <strong>{cl['CLAIM_ID']}</strong> — {cl['CLAIM_TYPE']}
                                ({cl.get('POLICY_TYPE', 'N/A')})
                                &nbsp; {claim_status_style(status)}
                                {''.join(f' <span style="background:#fee;color:#c00;padding:1px 6px;border-radius:3px;font-size:0.8em;margin-left:4px;">{f}</span>' for f in flags)}
                            </div>
                            <div style="text-align:right;"><strong>{fmt_currency(cl['CLAIM_AMOUNT'])}</strong></div>
                        </div>
                        <div style="font-size:0.85em;color:#666;margin-top:6px;">
                            Date: {str(cl['CLAIM_DATE'])[:10]} &nbsp;|&nbsp;
                            Approved: {fmt_currency(cl['APPROVED_AMOUNT']) if cl.get('APPROVED_AMOUNT') and not pd.isna(cl['APPROVED_AMOUNT']) else 'Pending'} &nbsp;|&nbsp;
                            Processing: {cl['PROCESSING_DAYS']} days &nbsp;|&nbsp;
                            Severity: {severity}
                        </div>
                        <div style="font-size:0.85em;color:#888;margin-top:4px;font-style:italic;">
                            {cl['CLAIM_DESCRIPTION']}
                        </div>
                    </div>
                    """, unsafe_allow_html=True)
            else:
                st.info("No claims found.")
        except Exception as e:
            st.warning(f"Could not load claims: {str(e)[:200]}")

    with tab_interact:
        st.markdown("##### Interaction Timeline")
        try:
            interactions = get_customer_interactions(customer_id)
            if len(interactions) > 0:
                for _, ix in interactions.iterrows():
                    sent = str(ix["SENTIMENT"])
                    si = sentiment_icon(sent)
                    sc = ix.get("SENTIMENT_SCORE", 0)
                    sc_str = f"{sc:.2f}" if sc and not pd.isna(sc) else "N/A"
                    color = "#e74c3c" if sent == "Negative" else "#27ae60" if sent == "Positive" else "#f39c12"

                    st.markdown(f"""
                    <div style="display:flex;gap:12px;margin-bottom:10px;padding:10px 14px;
                                background:white;border-radius:6px;border-left:3px solid {color};
                                box-shadow:0 1px 2px rgba(0,0,0,0.04);">
                        <div style="min-width:90px;font-size:0.85em;color:#888;">
                            {str(ix['INTERACTION_DATE'])[:10]}<br/>
                            <span style="font-size:0.9em;">{ix['CHANNEL']}</span>
                        </div>
                        <div style="flex:1;">
                            <div style="font-weight:600;font-size:0.9em;">
                                {ix['INTERACTION_TYPE']} — {ix['SUBJECT']}</div>
                            <div style="font-size:0.8em;color:#888;margin-top:2px;">
                                {si} {sent} ({sc_str}) &nbsp;|&nbsp;
                                Intent: {ix.get('CUSTOMER_INTENT', 'N/A')} &nbsp;|&nbsp;
                                {ix['RESOLUTION_STATUS']}
                            </div>
                        </div>
                    </div>
                    """, unsafe_allow_html=True)
            else:
                st.info("No interactions found.")
        except Exception as e:
            st.warning(f"Could not load interactions: {str(e)[:200]}")

    with tab_transcripts:
        st.markdown("##### Transcript Intelligence")
        st.markdown("""
        <div style="font-size:0.8em;color:#888;margin-bottom:8px;">
            What the customer actually said — analyzed by Cortex AI
        </div>
        """, unsafe_allow_html=True)

        transcripts = None
        try:
            transcripts = get_customer_transcripts(customer_id)
        except Exception:
            pass

        ti_key = f"ti_result_{customer_id}"
        intelligence = st.session_state.get(ti_key)

        if st.button("Analyze Transcripts with Cortex AI", key=f"ti_{customer_id}"):
            with st.spinner("Running Cortex AI transcript analysis..."):
                try:
                    result = call_transcript_intelligence(customer_id)
                    if result:
                        st.session_state[ti_key] = result
                        intelligence = result
                    else:
                        st.warning("No transcript analysis generated. Please try again.")
                except Exception as e:
                    st.error(f"Transcript analysis error: {str(e)[:200]}")

        if intelligence:
            st.markdown(f"""
            <div style="background:#f0f4ff;border:1px solid #d0d8f0;border-radius:6px;
                        padding:4px 12px;margin-bottom:8px;">
                <span style="font-size:0.75em;color:#3498db;font-weight:600;">
                    AI-Generated Analysis &nbsp;|&nbsp; Based on Snowflake customer data and interaction evidence</span>
            </div>
            """, unsafe_allow_html=True)

        render_transcript_panel(transcripts, intelligence)

    with tab_ai:
        st.markdown("##### AI Relationship Summary")
        st.markdown("""
        <div style="font-size:0.8em;color:#888;margin-bottom:12px;">
            Comprehensive AI analysis combining structured data and unstructured transcript intelligence.
        </div>
        """, unsafe_allow_html=True)

        ai_key = f"ai_result_{customer_id}"
        summary = st.session_state.get(ai_key)

        if st.button("Generate AI Summary", key=f"ai_{customer_id}"):
            with st.spinner("Generating AI summary using Cortex COMPLETE..."):
                try:
                    result = call_customer_ai_summary(customer_id)
                    if result:
                        st.session_state[ai_key] = result
                        summary = result
                    else:
                        st.warning("Could not generate summary.")
                except Exception as e:
                    st.error(f"AI summary error: {str(e)[:200]}")

        if summary:
            st.markdown(f"""
            <div style="background:#f0f4ff;border:1px solid #d0d8f0;border-radius:8px;
                        padding:4px 12px;margin-bottom:8px;">
                <span style="font-size:0.75em;color:#3498db;font-weight:600;">
                    AI-Generated Content &nbsp;|&nbsp; Based on Snowflake customer data and interaction evidence</span>
            </div>
            """, unsafe_allow_html=True)
            st.markdown(summary)
        else:
            st.info("Click the button above to generate an AI-powered relationship summary.")

    with tab_comm:
        render_communication_panel(customer_id)
