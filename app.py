"""Customer360 AI — Unified Customer Intelligence & Next Best Action.

Main Streamlit application entry point.
"""
import streamlit as st

st.set_page_config(
    page_title="Customer360 AI",
    page_icon="\U0001f3af",
    layout="wide",
    initial_sidebar_state="expanded",
)

# -- Global CSS --
st.markdown("""
<style>
    /* Professional insurance/financial styling */
    .stApp {
        background-color: #f4f6f9;
    }
    section[data-testid="stSidebar"] {
        background: linear-gradient(180deg, #1B2A4A 0%, #233554 100%);
        color: white;
    }
    section[data-testid="stSidebar"] .stMarkdown p,
    section[data-testid="stSidebar"] .stMarkdown li,
    section[data-testid="stSidebar"] label {
        color: #ffffff !important;
    }
    section[data-testid="stSidebar"] .stSelectbox label,
    section[data-testid="stSidebar"] .stRadio label {
        color: #ffffff !important;
    }
    section[data-testid="stSidebar"] .stRadio div[role="radiogroup"] label p,
    section[data-testid="stSidebar"] .stRadio div[role="radiogroup"] label span {
        color: #ffffff !important;
    }
    section[data-testid="stSidebar"] .stMarkdown h5 {
        color: #ffffff !important;
    }
    section[data-testid="stSidebar"] .stButton > button {
        color: #ffffff !important;
        border-color: rgba(255,255,255,0.3) !important;
        background-color: rgba(255,255,255,0.1) !important;
    }
    section[data-testid="stSidebar"] .stButton > button:hover {
        background-color: rgba(255,255,255,0.2) !important;
        border-color: rgba(255,255,255,0.5) !important;
    }
    section[data-testid="stSidebar"] hr {
        border-color: rgba(255,255,255,0.15);
    }
    /* KPI and card styling */
    .stMarkdown h2 {
        color: #1B2A4A;
        font-weight: 700;
    }
    .stMarkdown h5 {
        color: #2C3E6B;
    }
    /* Tab styling */
    .stTabs [data-baseweb="tab-list"] {
        gap: 8px;
    }
    .stTabs [data-baseweb="tab"] {
        padding: 8px 16px;
    }
    /* Table styling */
    .stDataFrame {
        border-radius: 8px;
    }
    /* Button styling */
    .stButton > button {
        border-radius: 6px;
    }
    /* Hide Streamlit branding */
    #MainMenu {visibility: hidden;}
    footer {visibility: hidden;}
</style>
""", unsafe_allow_html=True)

# -- Import pages --
from views import dashboard, customer_360, ask_customer_360, action_center, analytics
from utils.snowflake import get_customer_list

# -- Navigation --
PAGES = {
    "Executive Dashboard": dashboard,
    "Customer 360": customer_360,
    "Ask Customer 360": ask_customer_360,
    "Action Center": action_center,
    "Customer Analytics": analytics,
}

PAGE_ICONS = {
    "Executive Dashboard": "\U0001f4ca",
    "Customer 360": "\U0001f464",
    "Ask Customer 360": "\U0001f4ac",
    "Action Center": "\U0001f3af",
    "Customer Analytics": "\U0001f4c8",
}

# -- Sidebar --
with st.sidebar:
    st.markdown("""
    <div style="text-align:center;padding:16px 0 8px;">
        <div style="font-size:1.5em;font-weight:700;color:white;">\U0001f3af Customer360 AI</div>
        <div style="font-size:0.85em;color:#8899aa;margin-top:4px;">
            Unified Customer Intelligence<br/>& Next Best Action
        </div>
        <div style="margin-top:8px;">
            <span style="background:#3498db;color:white;padding:2px 8px;border-radius:3px;font-size:0.7em;">
                Snowflake + Cortex AI</span>
        </div>
    </div>
    """, unsafe_allow_html=True)

    st.markdown("---")

    if "current_page" not in st.session_state:
        st.session_state["current_page"] = "Executive Dashboard"

    page_options = list(PAGES.keys())
    current_idx = page_options.index(st.session_state["current_page"]) if st.session_state["current_page"] in page_options else 0

    selected_page = st.radio(
        "Navigation",
        page_options,
        index=current_idx,
        format_func=lambda x: f"{PAGE_ICONS.get(x, '')} {x}",
        key="nav_radio",
    )
    st.session_state["current_page"] = selected_page

    st.markdown("---")

    if selected_page in ("Customer 360", "Ask Customer 360"):
        st.markdown("##### Select Customer")
        try:
            cust_list = get_customer_list()
            demo_option = "CUST-0340 — Emily Mitchell (Demo)"
            options_list = [f"{r['CUSTOMER_ID']} — {r['FULL_NAME']}" for _, r in cust_list.iterrows()]

            current_cid = st.session_state.get("selected_customer_id", "")
            default_idx = 0
            if current_cid:
                matching = [i + 1 for i, o in enumerate(options_list) if o.startswith(current_cid)]
                if matching:
                    default_idx = matching[0]

            sel = st.selectbox(
                "Customer",
                [""] + options_list,
                index=default_idx,
                key="sidebar_customer_select",
                label_visibility="collapsed",
            )
            if sel:
                cid = sel.split(" — ")[0].strip()
                st.session_state["selected_customer_id"] = cid
            else:
                st.session_state["selected_customer_id"] = None

        except Exception:
            cid_input = st.text_input("Customer ID", value=st.session_state.get("selected_customer_id", ""))
            if cid_input:
                st.session_state["selected_customer_id"] = cid_input

        if st.button("\U0001f3af Load Demo", use_container_width=True):
            st.session_state["selected_customer_id"] = "CUST-0340"
            st.session_state["current_page"] = "Customer 360"
            st.rerun()

        if st.session_state.get("selected_customer_id"):
            st.markdown(f"""
            <div style="background:rgba(255,255,255,0.08);border-radius:6px;padding:8px 12px;margin-top:8px;">
                <div style="font-size:0.75em;color:#8899aa;">Selected Customer</div>
                <div style="color:white;font-weight:600;">{st.session_state['selected_customer_id']}</div>
            </div>
            """, unsafe_allow_html=True)

    st.markdown("---")
    st.markdown("""
    <div style="font-size:0.7em;color:#556677;text-align:center;padding:8px 0;">
        Powered by Snowflake Cortex AI<br/>
        Database: CUSTOMER_360_DB.C360<br/>
        Model: llama3.1-70b
    </div>
    """, unsafe_allow_html=True)

# -- Render selected page --
PAGES[selected_page].render()
