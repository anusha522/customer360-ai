"""KPI card components for Customer360 AI."""
import streamlit as st


def render_kpi_row(metrics: list[dict]):
    """Render a row of KPI cards.
    Each dict: {"label": str, "value": str, "delta": str|None, "color": str|None}
    """
    cols = st.columns(len(metrics))
    for col, m in zip(cols, metrics):
        color = m.get("color", "#1a1a2e")
        with col:
            st.markdown(f"""
            <div style="background:white;border-radius:8px;padding:16px 20px;
                        border-left:4px solid {color};box-shadow:0 1px 3px rgba(0,0,0,0.08);">
                <div style="font-size:0.8em;color:#666;text-transform:uppercase;letter-spacing:0.5px;">
                    {m['label']}</div>
                <div style="font-size:1.7em;font-weight:700;color:{color};margin:4px 0;">
                    {m['value']}</div>
                {f'<div style="font-size:0.8em;color:#888;">{m["delta"]}</div>' if m.get("delta") else ''}
            </div>
            """, unsafe_allow_html=True)


def render_mini_kpi(label: str, value: str, color: str = "#1B2A4A"):
    st.markdown(f"""
    <div style="text-align:center;padding:10px;">
        <div style="font-size:0.75em;color:#888;text-transform:uppercase;">{label}</div>
        <div style="font-size:1.4em;font-weight:700;color:{color};">{value}</div>
    </div>
    """, unsafe_allow_html=True)
