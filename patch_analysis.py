# Import python packages
import streamlit as st
import pandas as pd
from snowflake.snowpark.context import get_active_session

st.set_page_config(
    page_title="Snowflake CI: Patch Analysis",
    page_icon="❄️",
    layout="wide",
    initial_sidebar_state="expanded",
)

# Write directly to the app main page
st.title(f":snowflake: Competitive Intelligence :snowflake:")
st.subheader(f"_Patch Analysis_")

# Get the current credentials
session = get_active_session()

def intro():
    import streamlit as st

    st.sidebar.success("Select a view from above.")

    st.markdown(
        """
        **👈 Select a view from the dropdown on the left**

    """
    )

def ae():
    import streamlit as st
    import time
    import numpy as np

    st.markdown(f'# Account Executive')

    # Navigation to select the account
    def get_aes():
        query = f"select distinct account_owner_name_c as NAME from fivetran.salesforce.account where is_deleted = false order by 1 ASC"
        return session.sql(query).collect()

    def get_accounts_by_ae(ae_name):
        query = f"select id, name from fivetran.salesforce.account where account_owner_name_c = '{ae_name}'"
        df = session.sql(query).collect()
        return df

    def compete_by_account(account):
        query = f"SELECT competition FROM TABLE(compete_by_account('{account}'))"
        return session.sql(query).collect()

    # Fetch distinct values for filtering
    distinct_aes = get_aes()

    # Account selection
    df = pd.DataFrame(distinct_aes)

    # Create a select box using the DataFrame
    selected_ae = st.selectbox(
        'Choose an account executive:',
        options=df['NAME'].tolist(),
        #format_func=lambda x: df[df['NAME'] == x]['NAME'].iloc[0],
        index=None, 
        placeholder="Select Account Executive..."
    )
    
    # Display the selection
    st.write("You selected:", selected_ae)
    
    st.subheader("Accounts: ")
    accounts = get_accounts_by_ae(selected_ae)

    def process_account(account):
        st.write(account.NAME)
        processed_result = compete_by_account(account.ID)
        st.write(processed_result)
        return processed_result

    if accounts:
        st.write("Processing accounts...")
        for account in accounts:
            process_account(account)
        st.success("All accounts processed!")
    else:
        st.error("No accounts found to process.")

    
    st.button("Re-run")

def se():
    import streamlit as st
    import time
    import numpy as np

    st.markdown(f'# Sales Engineer')
    st.write(
        """
        SE patch analysis:
        """
    )
    
    st.button("Re-run")

def account():
    import streamlit as st
    import time
    import numpy as np

    st.markdown(f'# Account Detail')
    st.write(
        """
        Detailed analysis of a single account:
"""
    )

    # Navigation to select the account
    def get_accounts(rep):
        query = f"select distinct name, id as account_id from fivetran.salesforce.account where account_owner_name_c = '{rep}' order by name"
        # return pd.read_sql(query, session)
        return session.sql(query).collect()

    def opportunities_by_account(account):
        query = f"SELECT * FROM TABLE(compete_from_opportunities('{account}'))"
        return session.sql(query).collect()

    def tasks_by_account(account):
        query = f"SELECT * FROM TABLE(compete_from_tasks('{account}'))"
        return session.sql(query).collect()

    def usecases_by_account(account):
        query = f"SELECT * FROM TABLE(compete_from_use_cases('{account}'))"
        return session.sql(query).collect()

    def compete_by_account(account):
        query = f"SELECT * FROM TABLE(compete_by_account('{account}'))"
        return session.sql(query).collect()

    # Fetch distinct values for filtering
    distinct_accounts = get_accounts('Rosie Haines')

    # Account selection
    df = pd.DataFrame(distinct_accounts)

    # Create a select box using the DataFrame
    selected_account = st.selectbox(
        'Choose an account:',
        options=df['ACCOUNT_ID'].tolist(),
        format_func=lambda x: df[df['ACCOUNT_ID'] == x]['NAME'].iloc[0]
    )

    # Display the selected option's corresponding NAME
    st.write('You selected account:', df[df['ACCOUNT_ID'] == selected_account]['NAME'].iloc[0], 'which is Salesforce ID: ', selected_account)

    st.subheader("Opportunities: ")
    with st.spinner("Analysing Opps…"):
        filtered_df = opportunities_by_account(selected_account)
        st.dataframe(filtered_df,
            column_config={
            # "ACCOUNT_URL": st.column_config.LinkColumn("Account"),
            "CLOSE_DATE": "Close Date",
            "PRIMARY_COMPETITOR": "Primary Competitor",
            "LLM_COMPETITION": "LLM Competiton",
            "LLM_SENTIMENT": "LLM Sentiment",
            "LLM_EXPLANATION": "LLM Explanation",
            "NOTES": "Notes",
        },
        column_order=("CLOSE_DATE", "PRIMARY_COMPETITOR", 
                      "LLM_COMPETITION", "LLM_SENTIMENT", "LLM_EXPLANATION", "NOTES"),
        hide_index=True)
    st.success('Done!')

    st.subheader("Tasks: ")
    with st.spinner("Analysing Tasks…"):
        filtered_df = tasks_by_account(selected_account)
        st.dataframe(filtered_df,
            column_config={
            "CREATED_DATE": "Create Date",
            "LLM_COMPETITION": "LLM Competiton",
            "LLM_SENTIMENT": "LLM Sentiment",
            "LLM_EXPLANATION": "LLM Explanation",
            "NOTES": "Notes",
        },
        column_order=("CREATED_DATE", "LLM_COMPETITION", 
                      "LLM_SENTIMENT", "LLM_EXPLANATION", "NOTES"),
        hide_index=True)
    st.success('Done!')

    st.subheader("Use Cases: ")
    with st.spinner("Analysing Use Cases…"):
        filtered_df = usecases_by_account(selected_account)
        st.dataframe(filtered_df,
            column_config={
            "LLM_COMPETITION": "LLM Competiton",
            "LLM_SENTIMENT": "LLM Sentiment",
            "LLM_EXPLANATION": "LLM Explanation",
            "USE_CASES": "Use Cases",
        },
        hide_index=True)
    st.success('Done!')

    st.subheader("Final Result: ")
    with st.spinner("Final Analysis…"):
        filtered_df = compete_by_account(selected_account)
        st.dataframe(filtered_df,
                 column_config={
            "COMPETITION": "Competition"
        },
        hide_index=True)
    st.success('Done!')
        
    # page = st.sidebar.selectbox("Select something else", ["RVP", "DM", "Rep"])
    
    # progress_bar = st.sidebar.progress(0)
    # status_text = st.sidebar.empty()
    # last_rows = np.random.randn(1, 1)
    # chart = st.line_chart(last_rows)

    # for i in range(1, 101):
    #     new_rows = last_rows[-1, :] + np.random.randn(5, 1).cumsum(axis=0)
    #     status_text.text("%i%% Complete" % i)
    #     chart.add_rows(new_rows)
    #     progress_bar.progress(i)
    #     last_rows = new_rows
    #     time.sleep(0.05)

    # progress_bar.empty()

    # Streamlit widgets automatically run the script from top to bottom. Since
    # this button is not connected to any other logic, it just causes a plain
    # rerun.
    st.button("Re-run")

page_names_to_funcs = {
    "—": intro,
    "Account": account,
    "AE": ae,
    "SE": se
}

view = st.sidebar.selectbox("Choose a view", page_names_to_funcs.keys())
page_names_to_funcs[view]()