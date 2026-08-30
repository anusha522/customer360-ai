"""Page 5: Customer Analytics — Management analytical views."""
import streamlit as st
from utils.snowflake import get_analytics_data, get_risk_distribution, get_sentiment_distribution


def render():
    st.markdown("## Customer Analytics")
    st.markdown("Analytical views for management decision-making")

    try:
        data = get_analytics_data()
        risk_df = get_risk_distribution()
        sent_df = get_sentiment_distribution()
    except Exception as e:
        st.error(f"Failed to load analytics: {str(e)[:200]}")
        return

    col1, col2 = st.columns(2)

    with col1:
        st.markdown("##### Churn Risk Distribution")
        if len(risk_df) > 0:
            chart_df = risk_df.set_index("CHURN_RISK_CATEGORY")
            st.bar_chart(chart_df["COUNT"])

    with col2:
        st.markdown("##### Sentiment Distribution")
        if len(sent_df) > 0:
            chart_df = sent_df.set_index("SENTIMENT_CATEGORY")
            st.bar_chart(chart_df["COUNT"])

    st.markdown("---")
    col3, col4 = st.columns(2)

    with col3:
        st.markdown("##### Customer Health Distribution")
        health_df = data["health_distribution"]
        if len(health_df) > 0:
            chart_df = health_df.set_index("HEALTH_BAND")
            st.bar_chart(chart_df["COUNT"])

    with col4:
        st.markdown("##### Top Negative Sentiment Drivers")
        pain_df = data["pain_points"]
        if len(pain_df) > 0:
            chart_df = pain_df.set_index("INTERACTION_TYPE")
            st.bar_chart(chart_df["COUNT"])

    st.markdown("---")
    col5, col6 = st.columns(2)

    with col5:
        st.markdown("##### Claims by Type")
        claims_df = data["claims_by_type"]
        if len(claims_df) > 0:
            chart_df = claims_df.set_index("CLAIM_TYPE")
            st.bar_chart(chart_df["COUNT"])

    with col6:
        st.markdown("##### Interactions by Channel")
        channel_df = data["interactions_by_channel"]
        if len(channel_df) > 0:
            chart_df = channel_df.set_index("CHANNEL")
            st.bar_chart(chart_df["COUNT"])

    st.markdown("---")
    st.markdown("##### Risk by Customer Segment")
    risk_seg = data["risk_by_segment"]
    if len(risk_seg) > 0:
        pivot = risk_seg.pivot_table(index="CUSTOMER_SEGMENT", columns="CHURN_RISK_CATEGORY",
                                      values="COUNT", fill_value=0)
        for col in ["HIGH", "MEDIUM", "LOW"]:
            if col not in pivot.columns:
                pivot[col] = 0
        pivot = pivot[["HIGH", "MEDIUM", "LOW"]]
        st.bar_chart(pivot)
