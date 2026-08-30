"""Page 3: Ask Customer 360 — AI decision-support interface."""
import streamlit as st
from utils.snowflake import call_ask_customer_360, get_customer_list


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

    # ── Question input ──
    question = st.text_area(
        "Your question",
        height=80,
        key="ask_question",
        placeholder="e.g., Why is this customer likely to churn and what should we do?",
        label_visibility="collapsed",
    )

    st.markdown("**Try these:**")
    cols = st.columns(4)
    for i, ex in enumerate(EXAMPLE_QUESTIONS):
        with cols[i % 4]:
            if st.button(ex, key=f"ex_{i}", use_container_width=True):
                st.session_state["ask_question"] = ex
                st.rerun()

    st.markdown("")
    if st.button("Get Answer", type="primary", use_container_width=True):
        if not question or not question.strip():
            st.warning("Please enter a question.")
            return

        scope_label = f"Customer: {selected_cust}" if selected_cust else "All Customers (Top 15)"

        st.markdown(f"""
        <div style="background:#f8f9fa;border-radius:6px;padding:8px 12px;margin:8px 0;font-size:0.85em;">
            <strong>Scope:</strong> {scope_label} &nbsp;|&nbsp;
            <strong>Engine:</strong> Cortex COMPLETE (llama3.1-70b) + Snowflake Data
        </div>
        """, unsafe_allow_html=True)

        with st.spinner("Querying Snowflake data and generating AI answer..."):
            try:
                answer = call_ask_customer_360(question.strip(), selected_cust)
            except Exception as e:
                st.error(f"Error: {str(e)[:300]}")
                return

        if not answer:
            st.warning("No answer generated. Try rephrasing the question or selecting a customer.")
            return

        st.markdown("---")

        # ── Answer ──
        st.markdown(f"""
        <div style="background:#f0f4ff;border:1px solid #d0d8f0;border-radius:6px;
                    padding:6px 14px;margin-bottom:12px;">
            <span style="font-size:0.75em;color:#3498db;font-weight:600;">
                AI-Generated Answer &nbsp;|&nbsp; Based on Snowflake customer data and interaction evidence</span>
        </div>
        """, unsafe_allow_html=True)

        st.markdown(answer)

        # ── Follow-up actions ──
        if selected_cust:
            st.markdown("---")
            st.markdown("##### Follow-up Actions")
            fc1, fc2, fc3 = st.columns(3)
            with fc1:
                if st.button("View Customer 360", key="followup_c360", use_container_width=True):
                    st.session_state["selected_customer_id"] = selected_cust
                    st.session_state["current_page"] = "Customer 360"
                    st.rerun()
            with fc2:
                if st.button("Generate Phone Script", key="followup_phone", use_container_width=True):
                    with st.spinner("Generating with Cortex AI..."):
                        try:
                            from utils.snowflake import call_generate_communication
                            script = call_generate_communication(selected_cust, "phone")
                            if script:
                                st.markdown(f"""
                                <div style="background:#fffef5;border:1px solid #f0e6c0;border-radius:6px;padding:8px 12px;margin-bottom:8px;">
                                    <span style="font-size:0.75em;color:#b8860b;">AI-Generated Draft — Review before sending</span>
                                </div>
                                """, unsafe_allow_html=True)
                                st.markdown(script)
                        except Exception as e:
                            st.error(str(e)[:200])
            with fc3:
                if st.button("Generate Email", key="followup_email", use_container_width=True):
                    with st.spinner("Generating with Cortex AI..."):
                        try:
                            from utils.snowflake import call_generate_communication
                            email = call_generate_communication(selected_cust, "email")
                            if email:
                                st.markdown(f"""
                                <div style="background:#fffef5;border:1px solid #f0e6c0;border-radius:6px;padding:8px 12px;margin-bottom:8px;">
                                    <span style="font-size:0.75em;color:#b8860b;">AI-Generated Draft — Review before sending</span>
                                </div>
                                """, unsafe_allow_html=True)
                                st.markdown(email)
                        except Exception as e:
                            st.error(str(e)[:200])
