# 📝 Data Pipeline Documentation

## 🚀 Project Overview

This project was developed for one of our logistics clients to help them create an end-to-end automated Power BI reporting system. The solution handles data extraction, storage, transformation, and visualization using modern cloud and BI technologies.

---

## 🔧 Step 1 — Data Extraction using .NET Scripts

- The client’s operational data is stored in **CargoWise ERP System**.
- We built custom **.NET extraction scripts** that pull the necessary data from CargoWise APIs.
- Data extracted includes:
  - Shipments
  - Warehouse details
  - Delivery schedules
  - Delays & Exceptions
  - Carrier details
  - Cost & Profit information

- The .NET scripts are scheduled to run **every 30 minutes** to pull incremental data updates.

---

## ☁️ Step 2 — Data Storage in Microsoft Azure SQL

- Extracted data is pushed into an **Azure SQL Database**.
- Tables are structured relationally to normalize the data for easier querying.
- Some key tables include:
  - `Shipments`
  - `Warehouses`
  - `Carriers`
  - `Costs`
  - `Delays`
  - `Clients`

- Primary keys and foreign keys are used to maintain data integrity.
- SQL Agent jobs help in pre-processing some tables during inserts.

---

## 🔄 Step 3 — Data Fetching using SQL

- Power BI uses **Direct Query and Scheduled Refreshes** to connect with Azure SQL.
- SQL queries are optimized to fetch only the required columns to reduce load and improve performance.
- Sample transformations include:
  - Joins between shipment and carrier tables.
  - Calculations for profit margins.
  - Delay categorizations.
  - Grouping shipments by warehouse regions.

---

## 📊 Step 4 — Power BI Data Modeling

- Imported data is further modeled inside Power BI:
  - Date tables
  - DAX calculations
  - Relationships setup
- Visualizations created include:
  - Shipment Volumes
  - Delay Analysis
  - Profit & Loss Summary
  - Carrier Performance
  - Regional Warehouse KPIs

---

## 🔁 Step 5 — Automation & Scheduling

- **Automation Frequency:** Every 30 minutes
- Flow of automation:
  1. .NET scripts run and fetch latest data from CargoWise.
  2. Data is pushed into Azure SQL Database.
  3. Power BI scheduled refresh pulls updated data from Azure SQL.
  4. Dashboards are automatically refreshed with the latest data.

---

## 🔐 Security & Access

- Azure SQL uses secured access via firewall and IP restrictions.
- Power BI access is controlled via Azure AD-based authentication.
- Role Level Security (RLS) is implemented inside Power BI for different departments.

---

## 🎯 Technology Stack Summary

| Technology | Purpose |
|-------------|---------|
| CargoWise ERP | Source System |
| .NET Scripts | Data Extraction |
| Azure SQL Database | Data Storage |
| SQL Server Agent | Data Preprocessing |
| Power BI | Reporting & Visualization |
| Azure Active Directory | Security & Authentication |

![DataPiplineFlowDiagram](https://github.com/user-attachments/assets/798d46fc-78ae-4784-82ca-2e791c68fde1)

---

> _This data pipeline has helped our client achieve near real-time monitoring of their logistics operations, improve delay forecasting, and optimize resource allocation._

