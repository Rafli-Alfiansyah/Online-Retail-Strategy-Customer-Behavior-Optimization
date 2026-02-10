# Online Retail Strategy & Customer Behavior Optimization

![ai-generated-retail-store-selling-merchandise-with-shopping-carts-indoors-generated-by-ai-free-photo](https://github.com/user-attachments/assets/d8f47b35-24d7-429b-a2b3-b23c95c75ccf)

## Project Overview

This project focuses on transforming raw transactional data from a UK-based online retail platform into actionable business strategies. By leveraging **SQL** for robust data engineering and **Power BI** for interactive storytelling, the analysis identifies high-value customer segments and seasonal trends to optimize marketing efficiency and inventory management.

## Technical Stack

* **Database Management:** MySQL (Data Cleaning, ETL, and RFM Modeling).
* **Business Intelligence:** Power BI (Data Visualization and Interactive Dashboards).
* **Analytical Framework:** RFM (Recency, Frequency, Monetary) Analysis.
* **Domain Context:** Retail & Development Economics.

## Dataset Specifications

* **Volume:** 541,191 rows of transactional data.
* **Timeline:** December 2010 – December 2011.
* **Geographic Reach:** 38 countries (Primary markets: UK, Ireland, and Germany).

## Data Engineering Pipeline

The project involved a rigorous ETL process implemented via SQL to ensure data integrity:

1. **Standardization:** Converted string-based timestamps into proper `DATETIME` formats.
2. **Sanitization:** Filtered out negative quantities and unit prices (returns/cancellations) to prevent revenue distortion.
3. **Missing Value Handling:** Categorized anonymous transactions as "Guest" users to preserve total revenue metrics while isolating registered users for behavioral tracking.
4. **Feature Engineering:** Engineered a dedicated `Revenue` column and created specialized tables for behavioral and financial analysis.

## Analytics Methodology: RFM Modeling

To understand the customer lifecycle, I implemented an **RFM Model** using statistical quintiles (`NTILE-5`):

* **Recency:** Days since the last purchase.
* **Frequency:** Total number of distinct transactions.
* **Monetary:** Total lifetime spend.

Customers were categorized into segments such as **Champions**, **Loyal Customers**, **At Risk**, and **Lost** to facilitate targeted marketing interventions.

## Key Insights & Recommendations

* **Seasonality Risk:** December accounts for **44% of total annual revenue**, indicating a heavy reliance on Q4. *Recommendation: Launch Mid-Year campaigns in Q1/Q2 to stabilize cash flow.*
* **Retention Strategy:** Identified a significant "At Risk" segment. *Recommendation: Implement automated win-back email campaigns with personalized discounts.*
* **Logistics Optimization:** High overheads from "Postage" and "Amazon Fees" were identified. *Recommendation: Review shipping thresholds to improve net margins.*

## 📁 Project Structure

* `Online_Retail_Analysis.sql`: Full SQL script containing ETL, EDA, and RFM logic.
* `Strategy_Presentation.pdf`: Detailed business case study and strategic roadmap.
* `Dashboard_Preview.png`: High-resolution captures of the Power BI reporting suite.
