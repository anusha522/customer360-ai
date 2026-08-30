"""Page 3: Ask Customer 360 — AI decision-support interface."""
import streamlit as st
from utils.snowflake import (
    call_ask_customer_360, get_customer_list, resolve_customer_from_question,
)


EXAMPLE_QUESTIONS = [
    "Why is this customer likely to churn?",
    "What should the relationship manager do next?",
    "Which customers need attention today?",
    "Which high-value customers have negative sentiment?",
    "What happened during the customer's recent calls?",
    "Why has this customer's sentiment declined?",
    "Which customers have an open claim and a renewal coming up?",
    "Summarize this customer's relationship with us.",
]


def _render_disambiguation(matches, question):
    """Render a disambiguation UI when multiple customers match the question."""
    st.warning(f"Multiple customers match your question. Please select one:")
    for _, row in matches.iterrows():
        label = (f"{row['FULL_NAME']} — {row['CUSTOMER_ID']} — "
                 f"{row['CHURN_RISK_CATEGORY']} risk — {int(row['CHURN_RISK_SCORE'])}/100")
        if st.button(label, key=f"disambig_{row['CUSTOMER_ID']}", use_container_width=True):
            st.session_state["_disambig_cust"] = row["CUSTOMER_ID"]
            st.session_state["_disambig_question"] = question
            st.session_state["_auto_submit"] = True
            st.rerun()


def render():
    st.markdown("""
    <div style="margin-bottom:16px;">
        <h2 style="color:#1B2A4A;margin-bottom:4px;">Ask Customer 360</h2>
        <div style="font-size:0.95em;color:#555;">
            Ask questions about customers, policies, claims and conversations.
            The AI queries Snowflake data and transcript intelligence to provide evidence-based answers.
        </div>
    </div>
    """, unsafe_allow_html=True)

    # ── Scope selection ──
    col_scope, col_cust = st.columns([1, 2])
    with col_scope:
        cust_mode = st.radio("Scope", ["All Customers", "Specific Customer"],
                             key="ask_mode", horizontal=True)
    selected_cust = None
    if cust_mode == "Specific Customer":
        with col_cust:
            try:
                cust_list = get_customer_list()
                options = [""] + [f"{r['CUSTOMER_ID']} — {r['FULL_NAME']}" for _, r in cust_list.iterrows()]
                sel = st.selectbox("Select customer", options, key="ask_cust_select",
                                   label_visibility="collapsed")
                if sel:
                    selected_cust = sel.split(" — ")[0].strip()
            except Exception:
                selected_cust = st.text_input("Customer ID", key="ask_cust_id")

    # ── Pre-fill from example button (BEFORE widget renders) ──
    if "_selected_example" in st.session_state:
        st.session_state["ask_question"] = st.session_state.pop("_selected_example")
        st.session_state["_auto_submit"] = True

    # ── Pre-fill from disambiguation selection ──
    disambig_cust = st.session_state.pop("_disambig_cust", None)
    disambig_question = st.session_state.pop("_disambig_question", None)
    if disambig_cust and disambig_question:
        selected_cust = disambig_cust
        st.session_state["ask_question"] = disambig_question
        # Clear disambiguation UI now that a selection was made
        st.session_state.pop("_ask_disambig", None)

    # ── Question input (with key so value persists across reruns) ──
    question = st.text_area(
        "Your question",
        height=80,
        placeholder="e.g., Why is this customer likely to churn and what should we do?",
        label_visibility="collapsed",
        key="ask_question",
    )

    st.markdown("**Try these:**")
    cols = st.columns(4)
    for i, ex in enumerate(EXAMPLE_QUESTIONS):
        with cols[i % 4]:
            if st.button(ex, key=f"ex_{i}", use_container_width=True):
                st.session_state["_selected_example"] = ex
                st.rerun()

    # ── Submit: either button click or auto-submit from example/disambiguation ──
    auto = st.session_state.pop("_auto_submit", False)
    clicked = st.button("Get Answer", type="primary", use_container_width=True)

    # ── Generate answer on submit ──
    if clicked or auto:
        if not question or not question.strip():
            st.warning("Please enter a question.")
        else:
            q = question.strip()
            # Clear any previous disambiguation UI
            st.session_state.pop("_ask_disambig", None)

            # ── Customer disambiguation (only when no customer explicitly selected) ──
            if not selected_cust:
                resolution = resolve_customer_from_question(q)

                if resolution["status"] == "id_match":
                    selected_cust = resolution["customer_id"]
                elif resolution["status"] == "exact_match":
                    selected_cust = resolution["customer_id"]
                elif resolution["status"] == "ambiguous":
                    st.session_state["_ask_disambig"] = {
                        "matches": resolution["matches"].head(10),
                        "question": q,
                    }
                    _render_disambiguation(resolution["matches"].head(10), q)
                    return
                elif resolution["status"] == "no_match":
                    st.error("No customer matching that name was found. Please select a customer from the dropdown or provide a Customer ID (e.g. CUST-0340).")
                    return
                # "aggregate" → selected_cust stays None, handled normally

            scope_label = f"Customer: {selected_cust}" if selected_cust else "All Customers (Top 15)"
            st.markdown(f"""
            <div style="background:#f8f9fa;border-radius:6px;padding:8px 12px;margin:8px 0;font-size:0.85em;">
                <strong>Scope:</strong> {scope_label} &nbsp;|&nbsp;
                <strong>Engine:</strong> Cortex COMPLETE (llama3.1-70b) + Snowflake Data
            </div>
            """, unsafe_allow_html=True)

            with st.spinner("Querying Snowflake data and generating AI answer..."):
                try:
                    answer = call_ask_customer_360(q, selected_cust)
                except Exception as e:
                    st.error(f"Error: {str(e)[:300]}")
                    answer = None

            if answer:
                st.session_state["_ask_answer"] = answer
                st.session_state["_ask_question_text"] = q
                st.session_state["_ask_scope"] = scope_label
                st.session_state["_ask_cust"] = selected_cust
            else:
                st.warning("No answer generated. Try rephrasing the question or selecting a customer.")

    # ── Display persisted disambiguation (re-render buttons so clicks register) ──
    disambig_data = st.session_state.get("_ask_disambig")
    if disambig_data:
        _render_disambiguation(disambig_data["matches"], disambig_data["question"])

    # ── Display persisted answer ──
    answer = st.session_state.get("_ask_answer")
    if answer:
        scope_label = st.session_state.get("_ask_scope", "")
        asked_cust = st.session_state.get("_ask_cust")
        asked_q = st.session_state.get("_ask_question_text", "")

        st.markdown("---")

        st.markdown(f"""
        <div style="background:#f0f4ff;border:1px solid #d0d8f0;border-radius:6px;
                    padding:6px 14px;margin-bottom:12px;">
            <span style="font-size:0.75em;color:#3498db;font-weight:600;">
                AI-Generated Answer &nbsp;|&nbsp; Based on Snowflake customer data and interaction evidence</span>
        </div>
        """, unsafe_allow_html=True)

        st.markdown(answer)

        if asked_cust:
            st.markdown("---")
            st.markdown("##### Follow-up Actions")
            fc1, fc2, fc3 = st.columns(3)
            with fc1:
                if st.button("View Customer 360", key="followup_c360", use_container_width=True):
                    st.session_state["selected_customer_id"] = asked_cust
                    st.session_state["current_page"] = "Customer 360"
                    st.session_state["_nav_sync"] = "Customer 360"
                    st.session_state.pop("_ask_answer", None)
                    st.rerun()
            with fc2:
                fu_phone_key = f"fu_phone_{asked_cust}"
                phone_result = st.session_state.get(fu_phone_key)
                if st.button("Generate Phone Script", key="followup_phone", use_container_width=True):
                    with st.spinner("Generating with Cortex AI..."):
                        try:
                            from utils.snowflake import call_generate_communication
                            script = call_generate_communication(asked_cust, "phone")
                            if script:
                                st.session_state[fu_phone_key] = script
                                phone_result = script
                        except Exception as e:
                            st.error(str(e)[:200])
                if phone_result:
                    st.markdown(f"""
                    <div style="background:#fffef5;border:1px solid #f0e6c0;border-radius:6px;padding:8px 12px;margin-bottom:8px;">
                        <span style="font-size:0.75em;color:#b8860b;">AI-Generated Draft — Review before sending</span>
                    </div>
                    """, unsafe_allow_html=True)
                    st.markdown(phone_result)
            with fc3:
                fu_email_key = f"fu_email_{asked_cust}"
                email_result = st.session_state.get(fu_email_key)
                if st.button("Generate Email", key="followup_email", use_container_width=True):
                    with st.spinner("Generating with Cortex AI..."):
                        try:
                            from utils.snowflake import call_generate_communication
                            email = call_generate_communication(asked_cust, "email")
                            if email:
                                st.session_state[fu_email_key] = email
                                email_result = email
                        except Exception as e:
                            st.error(str(e)[:200])
                if email_result:
                    st.markdown(f"""
                    <div style="background:#fffef5;border:1px solid #f0e6c0;border-radius:6px;padding:8px 12px;margin-bottom:8px;">
                        <span style="font-size:0.75em;color:#b8860b;">AI-Generated Draft — Review before sending</span>
                    </div>
                    """, unsafe_allow_html=True)
                    st.markdown(email_result)
