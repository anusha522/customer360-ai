"""Formatting and display utilities for Customer360 AI."""
import pandas as pd


def fmt_currency(value, decimals=0) -> str:
    if value is None or pd.isna(value):
        return "N/A"
    if decimals == 0:
        return f"${value:,.0f}"
    return f"${value:,.{decimals}f}"


def fmt_number(value) -> str:
    if value is None or pd.isna(value):
        return "N/A"
    return f"{value:,}"


def fmt_pct(value, decimals=1) -> str:
    if value is None or pd.isna(value):
        return "N/A"
    return f"{value:.{decimals}f}%"


def fmt_score(value, max_val=100) -> str:
    if value is None or pd.isna(value):
        return "N/A"
    return f"{int(value)}/{max_val}"


def risk_color(risk_category: str) -> str:
    colors = {"HIGH": "#e74c3c", "MEDIUM": "#f39c12", "LOW": "#27ae60"}
    return colors.get(str(risk_category).upper(), "#95a5a6")


def risk_icon(risk_category: str) -> str:
    icons = {"HIGH": "\U0001f534", "MEDIUM": "\U0001f7e0", "LOW": "\U0001f7e2"}
    return icons.get(str(risk_category).upper(), "\u26aa")


def sentiment_color(sentiment: str) -> str:
    colors = {"Positive": "#27ae60", "Neutral": "#f39c12", "Negative": "#e74c3c"}
    return colors.get(str(sentiment), "#95a5a6")


def sentiment_icon(sentiment: str) -> str:
    s = str(sentiment).lower()
    if s == "positive":
        return "\U0001f7e2"
    if s == "negative":
        return "\U0001f534"
    return "\U0001f7e1"


def priority_badge(priority: str) -> str:
    p = str(priority).upper()
    if p == "HIGH":
        return f'<span style="background:#e74c3c;color:white;padding:2px 8px;border-radius:4px;font-weight:600;font-size:0.85em;">HIGH</span>'
    if p == "MEDIUM":
        return f'<span style="background:#f39c12;color:white;padding:2px 8px;border-radius:4px;font-weight:600;font-size:0.85em;">MEDIUM</span>'
    return f'<span style="background:#27ae60;color:white;padding:2px 8px;border-radius:4px;font-weight:600;font-size:0.85em;">LOW</span>'


def health_color(score) -> str:
    if score is None:
        return "#95a5a6"
    s = int(score)
    if s >= 80:
        return "#27ae60"
    if s >= 60:
        return "#2ecc71"
    if s >= 40:
        return "#f39c12"
    return "#e74c3c"


def claim_status_style(status: str) -> str:
    s = str(status)
    if s in ("Pending", "Under Review"):
        return f'<span style="background:#f39c12;color:white;padding:2px 6px;border-radius:3px;font-size:0.85em;">{s}</span>'
    if s == "Rejected":
        return f'<span style="background:#e74c3c;color:white;padding:2px 6px;border-radius:3px;font-size:0.85em;">{s}</span>'
    if s == "Approved":
        return f'<span style="background:#3498db;color:white;padding:2px 6px;border-radius:3px;font-size:0.85em;">{s}</span>'
    return f'<span style="background:#27ae60;color:white;padding:2px 6px;border-radius:3px;font-size:0.85em;">{s}</span>'


def payment_status_style(status: str) -> str:
    s = str(status)
    if s in ("Overdue", "Delinquent"):
        return f'<span style="background:#e74c3c;color:white;padding:2px 6px;border-radius:3px;font-size:0.85em;">{s}</span>'
    if s == "Late":
        return f'<span style="background:#f39c12;color:white;padding:2px 6px;border-radius:3px;font-size:0.85em;">{s}</span>'
    return f'<span style="color:#27ae60;font-weight:600;">{s}</span>'
