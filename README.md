# 🛍️ Retail Analysis

**Project Description**  
This project explores a real-world **Online Retail** dataset using **SQL**, **Python**, and data visualization tools like **Tableau** and **Power BI**. The goal is to uncover sales trends, customer behavior, inventory issues, and drive business insights through data.

---

## 📂 Project Structure

### `01_cleaning_retail.sql`
- Cleans the raw retail dataset by removing invalid values
- Standardizes product descriptions
- Adds calculated fields: `Revenue`, `Year`, `Month`, `Weekday`
- Checks for NULLs, duplicates, outliers, and invalid logic

### `02_eda_retail.sql`
- Performs Exploratory Data Analysis grouped into:
  - **Revenue Analysis**: Sales trends by time and geography
  - **Customer Analysis**: Spending, order frequency, churn/retention
  - **RFM Segmentation**: Classifying customers into loyalty segments
  - **Inventory & Supply Chain**: Stockouts, overstock risks, simple demand forecast

---

## 🛠️ Tools Used

- **BigQuery SQL** for data cleaning and analysis
- **Python (Pandas, Matplotlib, Seaborn)** for deeper data wrangling and charting 
- **Tableau / Power BI** for interactive dashboards 

---

## 📊 Key Insights

- Identified top revenue-generating countries and products
- Revealed customer retention rates and spending behavior
- Segmented customers with **RFM scores** and labeled by loyalty level
- Flagged potential **stockout** and **overstocked** items
- Estimated product-level demand using simple moving averages

---

## 🧠 Next Steps

- Visualize key KPIs in **Tableau** and **Power BI**
- Build **Python notebooks** for trend detection and clustering
- Add **automated reporting** using scheduled queries or scripts

---

## 📁 Dataset Info

- Source: Online Retail Transaction data (from UCI Machine Learning Repo)
- Fields: `InvoiceNo`, `StockCode`, `Description`, `Quantity`, `InvoiceDate`, `UnitPrice`, `CustomerID`, `Country`

---

## 👩‍💻 Author

Vu Quynh Nga Nguyen  
Zurich, Switzerland | 2025

---

> “Data is a precious thing and will last longer than the systems themselves.” – *Tim Berners-Lee*
