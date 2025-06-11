# 🚚 Logistics Client - Power BI Dashboard Project

Project Video Demo : https://www.linkedin.com/posts/xyzainm_powerbi-logisticsanalytics-automation-activity-7327285466838253569-bjFG?utm_source=share&utm_medium=member_desktop&rcm=ACoAADl1dEcB-SNXE2ySJqDrVh7vol8oEzZyGI0

---

## 📝 Project Background

This Power BI project was designed for one of our logistics clients who were facing challenges in monitoring their operational efficiency, delivery delays, and profitability across multiple hubs, carriers, and warehouses.

The client's existing reporting system was heavily manual, spreadsheet-based, and lacked real-time visibility — causing delays in decision-making.

---

## 🎯 Project Objectives

- ✅ Build a fully automated, near real-time reporting system.
- ✅ Create a scalable solution that supports growing data volumes.
- ✅ Enable leadership to analyze operational KPIs instantly.
- ✅ Reduce manual reporting errors and eliminate dependency on Excel.

---

## 🔧 Tools & Technologies

- **Power BI Desktop & Power BI Service** (Data Modeling, DAX, Visualizations)
- **Microsoft Azure SQL Database** (Data Storage & Processing)
- **CargoWise ERP** (Primary data source for logistics data)
- **.NET Custom Scripts** (Data Extraction Layer)
- **Azure Data Factory (ADF)** (Data Orchestration)
- **SQL Server / T-SQL** (Data Cleansing, Transformation & Modeling)
- **Power Query** (ETL inside Power BI)
- **DAX (Data Analysis Expressions)**

---

## 🔄 Data Flow & Automation Pipeline

This solution involves a fully automated end-to-end ETL pipeline, designed to fetch, store, transform, and visualize logistics data seamlessly:

1️⃣ **Data Extraction from CargoWise**
- Using custom-built `.NET scripts`, data is extracted from the client's CargoWise ERP system.

2️⃣ **Ingestion into Microsoft Azure**
- Extracted data is pushed into Azure every 30 minutes.
- The data lands into **Azure SQL Database** where relational database models (RDBs) have been designed.

3️⃣ **SQL Data Transformation**
- Inside Azure SQL DB, we run multiple SQL transformation scripts to cleanse, join, and shape the data into well-structured tables ready for reporting.

4️⃣ **Power BI Data Connection**
- Power BI directly connects to Azure SQL Database.
- Data is refreshed automatically, allowing dashboards to stay updated every 30 minutes without manual intervention.

5️⃣ **Dashboard Visualization**
- The cleansed, transformed data is visualized using multiple Power BI dashboards providing near-real-time operational insights.

---

## 📊 Key Features of the Dashboard

### 1️⃣ Shipment Performance Overview
- Total Orders Delivered
- On-Time Delivery %
- Average Delay (Days)
- Delay Root Cause Breakdown

### 2️⃣ Profitability Analysis
- Shipment-level profit margins
- Product category profitability
- Route profitability comparisons

### 3️⃣ Warehouse Utilization
- Inventory levels
- Inbound vs Outbound movement trends
- Capacity utilization by location

### 4️⃣ Carrier Performance Monitoring
- On-time delivery rates by logistics provider
- Delay reasons heatmaps

### 5️⃣ Executive Summary View
- High-level KPIs for leadership team
- Automated monthly trend comparison

---

## 📈 Business Impact

- ⏰ Reporting time reduced by **85%**
- 📊 Leadership now has **real-time visibility** into key KPIs
- 📉 Shipment delays reduced by **12%**
- 💰 Warehouse optimization led to significant cost savings

---

## 🎥 Demo Video

> ⚠ If file size exceeds GitHub limit, video will be hosted externally.

[🎞️ Click to Watch Dashboard Walkthrough](https://www.linkedin.com/posts/xyzainm_powerbi-logisticsanalytics-automation-activity-7327285466838253569-bjFG?utm_source=share&utm_medium=member_desktop&rcm=ACoAADl1dEcB-SNXE2ySJqDrVh7vol8oEzZyGI0))

---

## 📁 Project Files

## 📁 Project Files

| File/Folder | Description |
|-------------|-------------|
| `LogisticsDashboard.pbip` | Complete Power BI file |
| `assets/data_pipeline.png` | Full end-to-end data pipeline flow diagram |
| `assets/sample_data.xlsx` | Sample anonymized dataset used for dashboard creation |
| `assets/sample_sql_queries.sql` | Sample SQL queries used for data extraction and transformation from Azure SQL Database to Power BI |
| `README.md` | Complete project documentation |
| `Video Demo | Demo video |

---

## 🗺️ Additional Documentation

- The **Data Pipeline Flow Diagram** has been included (`assets/data_pipeline.png`) to demonstrate the entire end-to-end architecture of this project.
- **Sample Data File** (`assets/sample_data.xlsx`) is provided to help reviewers understand the data structure used.
- **Sample SQL Queries** (`assets/sample_sql_queries.sql`) have been included to give a glimpse of the transformations and data fetching logic applied inside Azure SQL Database before connecting to Power BI.

---


---

## 🚀 Power BI & Data Concepts Applied

- Automated ETL Pipeline (CargoWise → .NET → Azure SQL → Power BI)
- Relational Database Design
- Power Query ETL Logic
- Advanced SQL Joins & T-SQL Scripts
- DAX Formulas for KPIs:
  - `CALCULATE()`
  - `FILTER()`
  - `SWITCH()`
  - `IF()`
  - `RANKX()`
- Drill-down visualizations & custom tooltips
- Scheduled Auto-refresh every 30 minutes
- Highly scalable and modular architecture

---

## 👨‍💻 Author

- **Zain Ul Hassan**
- Data Analyst | Power BI Developer | Logistics Analytics Expert
- 🌐 [LinkedIn Profile](https://www.linkedin.com/in/xyzainm/)
- 📧 Email: zainulhassan167@gmail.com

---

> ✅ *This project showcases my full-stack data analytics capabilities: from backend data pipelines to SQL transformations and real-time dashboarding using Power BI.*

---
