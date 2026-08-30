"""Transcript intelligence panel for Customer360 AI."""
import streamlit as st
import pandas as pd
from utils.formatting import sentiment_icon


def render_transcript_panel(transcripts: pd.DataFrame, intelligence: str = None):
    """Render transcript intelligence and expandable transcript excerpts."""

    if intelligence:
        st.markdown("""
        <div style="background:#f0f4ff;border-radius:8px;padding:16px 20px;
                    border-left:4px solid #3498db;margin-bottom:16px;">
            <div style="font-size:0.7em;text-transform:uppercase;letter-spacing:1px;color:#3498db;
                        font-weight:600;margin-bottom:8px;">
                \U0001f916 AI Transcript Analysis &nbsp;
                <span style="background:#e8f0fe;padding:2px 8px;border-radius:3px;font-size:0.85em;
                             color:#555;">AI-Generated</span>
            </div>
        </div>
        """, unsafe_allow_html=True)

        sections = intelligence.split("\n\n")
        for section in sections:
            section = section.strip()
            if not section:
                continue
            if section.startswith("OVERALL SENTIMENT:") or section.startswith("SENTIMENT TREND:"):
                st.markdown(f"**{section}**")
            elif section.startswith("KEY CONCERNS:") or section.startswith("CUSTOMER PAIN POINTS:") or \
                 section.startswith("UNRESOLVED ISSUES:") or section.startswith("KEY EVIDENCE:"):
                st.markdown(section)
            elif section.startswith("CANCELLATION SIGNALS:") or section.startswith("COMPETITOR MENTIONS:") or \
                 section.startswith("FOLLOW-UP NEEDED:"):
                st.markdown(f"**{section}**")
            else:
                st.markdown(section)

    if transcripts is not None and len(transcripts) > 0:
        st.markdown("---")
        st.markdown("##### Call Transcripts")
        for _, t in transcripts.iterrows():
            si = sentiment_icon(t["SENTIMENT"])
            date_str = str(t["CALL_DATE"])[:10]
            fu = "\U0001f534 Follow-up Required" if t.get("FOLLOW_UP_REQUIRED") else ""

            with st.expander(
                f"{si} {date_str} | {t['CUSTOMER_INTENT']} | {t['SENTIMENT']} | {t.get('KEY_TOPICS', '')[:60]}"
            ):
                col1, col2 = st.columns([2, 1])
                with col1:
                    st.markdown(f"**Summary:** {t['SUMMARY']}")
                    st.markdown(f"**Resolution:** {t['RESOLUTION']}")
                    if fu:
                        st.warning(fu)
                with col2:
                    st.markdown(f"**Intent:** {t['CUSTOMER_INTENT']}")
                    st.markdown(f"**Topics:** {t.get('KEY_TOPICS', 'N/A')}")
                    st.markdown(f"**Sentiment Score:** {t['SENTIMENT_SCORE']:.2f}")

                st.markdown("**Transcript:**")
                text = str(t["TRANSCRIPT_TEXT"]).replace("\\n", "\n")
                st.text_area("Transcript", text, height=200, key=f"tx_{t['TRANSCRIPT_ID']}", disabled=True,
                            label_visibility="collapsed")
    elif transcripts is not None:
        st.info("No call transcripts available for this customer.")
