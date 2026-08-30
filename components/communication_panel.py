"""Personalized communication panel for Customer360 AI."""
import streamlit as st
from utils.snowflake import call_generate_communication


def render_communication_panel(customer_id: str):
    """Render communication generation with phone/email/SMS tabs."""
    st.markdown("""
    <div style="background:#f8f9fa;border-radius:8px;padding:12px 16px;margin-bottom:12px;
                border-left:4px solid #8e44ad;">
        <div style="font-size:0.9em;font-weight:600;color:#8e44ad;">
            \U0001f4ac Personalized Communication Generator
        </div>
        <div style="font-size:0.8em;color:#888;margin-top:2px;">
            AI-generated drafts — review before sending
        </div>
    </div>
    """, unsafe_allow_html=True)

    tab_phone, tab_email, tab_sms = st.tabs(["\U0001f4de Phone Script", "\U0001f4e7 Email", "\U0001f4f1 SMS"])

    for tab, channel, label in [
        (tab_phone, "phone", "Phone Script"),
        (tab_email, "email", "Email"),
        (tab_sms, "sms", "SMS"),
    ]:
        with tab:
            btn_key = f"gen_{channel}_{customer_id}"
            if st.button(f"Generate {label}", key=btn_key):
                with st.spinner(f"Generating {label.lower()} using Cortex AI..."):
                    try:
                        result = call_generate_communication(customer_id, channel)
                        if result:
                            st.markdown(f"""
                            <div style="background:#fffef5;border:1px solid #f0e6c0;border-radius:6px;
                                        padding:12px 16px;margin-top:8px;">
                                <div style="font-size:0.7em;color:#b8860b;text-transform:uppercase;
                                            margin-bottom:8px;">
                                    \u26a0\ufe0f AI-Generated Draft — Review Before Sending</div>
                            </div>
                            """, unsafe_allow_html=True)
                            st.markdown(result)
                        else:
                            st.warning("No communication generated. Please try again.")
                    except Exception as e:
                        st.error(f"Error generating communication: {str(e)[:200]}")
