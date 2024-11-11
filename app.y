import streamlit as st
import pandas as pd
import requests
import re
from datetime import datetime

# URL for the log data
url = "http://13.201.41.180:8050/"  # Replace with actual URL if different

# Function to fetch log data from the URL
def fetch_log_data(url):
    try:
        response = requests.get(url)
        response.raise_for_status()  # Check if the request was successful
        return response.text
    except requests.exceptions.RequestException as e:
        st.error(f"Error fetching data: {e}")
        return None

# Function to parse and modify log data based on code
def parse_log_data(log_text):
    # Regex to capture key fields from log entries
    log_pattern = re.compile(
        r"Timestamp: (?P<timestamp>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}), "
        r"Customer ID: (?P<customer_id>[^,]+), "
        r"Customer Name: (?P<customer_name>[^,]+), "
        r"Code: (?P<code>[^,]+), "
        r"Message: (?P<message>.+)"
    )
    
    # Parse each matching line
    log_data = []
    for match in log_pattern.finditer(log_text):
        code = match.group("code")
        message = match.group("message").strip()
        
        # Replace message based on code
        if code == "1006":
            message = "Valid Passport"
        elif code == "1005":
            message = "Unverified Passport"
        
        log_data.append({
            "Timestamp": match.group("timestamp"),
            "Customer ID": match.group("customer_id"),
            "Customer Name": match.group("customer_name"),
            "Code": code,
            "Message": message
        })
    
    return pd.DataFrame(log_data)

# Fetch and parse the log data
log_text = fetch_log_data(url)
if log_text:
    df = parse_log_data(log_text)

    # Process the parsed data
    if not df.empty:
        # Convert timestamp to datetime
        df['Timestamp'] = pd.to_datetime(df['Timestamp'], errors='coerce')

        # Display parsed data
        st.title("Log Data Viewer")
        st.write("### Parsed Log Entries")
        st.dataframe(df)

        # Display counts by 'Code' column as a bar chart
        st.write("### Message Count by Code")
        code_counts = df['Code'].value_counts()
        st.bar_chart(code_counts)
        
        # Display log entries over time as a line chart
        st.write("### Log Entries Over Time")
        df['Date'] = df['Timestamp'].dt.date
        date_counts = df.groupby('Date').size()
        st.line_chart(date_counts)
    else:
        st.write("No log data available.")
else:
    st.write("Unable to fetch log data.")
