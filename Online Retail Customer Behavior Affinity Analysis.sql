SET SQL_SAFE_UPDATES = 0;

-- ubah text / jadi -
UPDATE retail_data 
SET 
    InvoiceDate = STR_TO_DATE(InvoiceDate, '%d/%m/%Y %H:%i')
WHERE
    InvoiceDate LIKE '%/%';

-- cek kolom text InvoiceDate
SELECT 
    InvoiceDate
FROM
    retail_data
WHERE
    STR_TO_DATE(InvoiceDate, '%Y-%m-%d %H:%i:%s') IS NULL;

-- ubah tipe kolom InvoiceDate dari text jadi datetime
ALTER TABLE retail_data 
MODIFY COLUMN InvoiceDate DATETIME;

-- hapus transaksi gagal/return
DELETE FROM retail_data 
WHERE
    Quantity < 1;

-- buat tabel untuk RFM/cohorts (hanya keep clean CustomerID)
CREATE TABLE registered_sales AS SELECT InvoiceNo,
    StockCode,
    Description,
    Quantity,
    UnitPrice,
    (Quantity * UnitPrice) AS Revenue,
    InvoiceDate,
    CustomerID,
    Country FROM
    retail_data
WHERE
    CustomerID IS NOT NULL
        AND CustomerID <> '';

-- buat tabel untuk Business Performance (keep semua CustomerID)
CREATE TABLE all_sales AS SELECT InvoiceNo,
    StockCode,
    Description,
    Quantity,
    UnitPrice,
    (Quantity * UnitPrice) AS Revenue,
    InvoiceDate,
    CASE
        WHEN CustomerID IS NULL OR CustomerID = '' THEN 'Guest'
        ELSE CAST(CustomerID AS CHAR)
    END AS CustomerID,
    Country FROM
    retail_data;

-- total penjualan per bulan
SELECT 
    MONTHNAME(InvoiceDate) AS Month,
    SUM(Revenue) AS Total_Revenue
FROM
    all_sales
GROUP BY Month , MONTH(InvoiceDate)
ORDER BY MONTH(InvoiceDate);

-- negara penyumbang terbesar
SELECT 
    Country, SUM(Revenue) AS Total_Revenue
FROM
    all_sales
GROUP BY Country
ORDER BY Total_Revenue DESC;

-- top 10 produk berdasarkan kuantitas dan revenue
WITH Top_Quantity AS( 
    SELECT 
        ROW_NUMBER() OVER(ORDER BY SUM(Quantity) DESC) AS Number, 
        Description AS Product_Quantity, 
        SUM(Quantity) AS Total_Quantity
    FROM all_sales
    WHERE Description IS NOT NULL AND Description <> ''
    GROUP BY Product_Quantity
    LIMIT 10),
Top_Revenue AS(
    SELECT 
        ROW_NUMBER() OVER(ORDER BY SUM(Revenue) DESC) AS Number, 
        Description AS Product_Profit, 
        SUM(Revenue) AS Total_Revenue
    FROM all_sales
    WHERE Description IS NOT NULL AND Description <> ''
    GROUP BY Product_Profit
    LIMIT 10)
SELECT 
    Q.Number, 
    Q.Product_Quantity, 
    Q.Total_Quantity, 
    R.Product_Profit, 
    R.Total_Revenue
FROM Top_Quantity Q
JOIN Top_Revenue R ON Q.Number = R.Number;

-- recency, frequency, monetary
SELECT 
    CustomerID,
    DATEDIFF((SELECT 
                    MAX(InvoiceDate)
                FROM
                    registered_sales),
            MAX(InvoiceDate)) AS Recency,
    COUNT(DISTINCT InvoiceNo) AS Frequency,
    ROUND(SUM(Revenue), 2) AS Total_Revenue
FROM
    registered_sales
GROUP BY CustomerID
ORDER BY Recency , Frequency DESC , Total_Revenue DESC;

-- rfm scoring simple
WITH rfm_values AS(
SELECT 
    CustomerID,
    DATEDIFF((SELECT MAX(InvoiceDate)
			FROM registered_sales),
	MAX(InvoiceDate)) AS Recency,
    COUNT(DISTINCT InvoiceNo) AS Frequency,
    ROUND(SUM(Revenue), 2) AS Total_Revenue
FROM registered_sales
GROUP BY CustomerID),
rfm_score AS(
SELECT CustomerID, NTILE(5) OVER(ORDER BY Recency) AS R,
NTILE(5) OVER(ORDER BY Frequency DESC) AS F, Total_Revenue
FROM rfm_values),
rfm_segment AS(
SELECT *, CASE 
    WHEN R <= 1 AND F >= 5 THEN 'Champions'
    WHEN R <= 2 AND F >= 4 THEN 'Loyal Customers'
    WHEN R <= 3 AND F >= 3 THEN 'Potential Loyalist'
    WHEN R <= 4 AND F >= 2 THEN 'At Risk'
    WHEN R <= 5 AND F >= 1 THEN 'Lost'
    ELSE 'Other'
END AS Customer_Segment
FROM rfm_score)
SELECT Customer_Segment, SUM(Total_Revenue) AS Total_Segment_Revenue, AVG(Total_Revenue) AS Average_Segment_Revenue
FROM rfm_segment
GROUP BY Customer_Segment;

-- rfm scoring detail
WITH rfm_values AS(
SELECT 
    CustomerID,
    DATEDIFF((SELECT MAX(InvoiceDate)
			FROM registered_sales),
	MAX(InvoiceDate)) AS Recency,
    COUNT(DISTINCT InvoiceNo) AS Frequency,
    ROUND(SUM(Revenue), 2) AS Total_Revenue
FROM registered_sales
GROUP BY CustomerID),
rfm_score AS(
SELECT CustomerID, NTILE(5) OVER(ORDER BY Recency) AS R,
NTILE(5) OVER(ORDER BY Frequency DESC) AS F, Total_Revenue
FROM rfm_values),
rfm_segment AS(
SELECT *, CASE 
    WHEN R <= 1 AND F >= 5 THEN 'Champions'
    WHEN R <= 2 AND F >= 4 THEN 'Loyal Customers'
    WHEN R <= 3 AND F >= 3 THEN 'Potential Loyalist'
    WHEN R <= 4 AND F >= 2 THEN 'At Risk'
    WHEN R <= 5 AND F >= 1 THEN 'Lost'
    ELSE 'Other'
END AS Customer_Segment
FROM rfm_score)
SELECT Customer_Segment, SUM(Total_Revenue) OVER(PARTITION BY Customer_Segment) AS Segment_Revenue_Total,
AVG(Total_Revenue) OVER(PARTITION BY Customer_Segment) AS Average_Revenue_Total
FROM rfm_segment;

-- business & geo performance view
CREATE OR REPLACE VIEW v_business_performance AS
    SELECT 
        InvoiceDate,
        Country,
        Revenue,
        MONTH(InvoiceDate) AS Month_Num,
        MONTHNAME(InvoiceDate) AS Month_Name
    FROM all_sales;

-- product performance view 
CREATE OR REPLACE VIEW v_product_performance AS
    SELECT 
        Description,
        SUM(Quantity) AS Total_Quantity,
        SUM(Revenue) AS Total_Revenue
    FROM all_sales
    WHERE Description IS NOT NULL AND Description <> ''
    GROUP BY Description;

-- rfm segment detail
CREATE OR REPLACE VIEW v_customer_segmentation AS
WITH rfm_values AS (
    SELECT 
        CustomerID,
        DATEDIFF((SELECT MAX(InvoiceDate) FROM registered_sales), MAX(InvoiceDate)) AS Recency,
        COUNT(DISTINCT InvoiceNo) AS Frequency,
        ROUND(SUM(Revenue), 2) AS Total_Revenue
    FROM registered_sales
    GROUP BY CustomerID),
rfm_score AS (
    SELECT 
        CustomerID, Total_Revenue,
        NTILE(5) OVER(ORDER BY Recency) AS R,
        NTILE(5) OVER(ORDER BY Frequency DESC) AS F
    FROM rfm_values)
SELECT *,
    CASE 
        WHEN R <= 1 AND F >= 5 THEN 'Champions'
        WHEN R <= 2 AND F >= 4 THEN 'Loyal Customers'
        WHEN R <= 3 AND F >= 3 THEN 'Potential Loyalist'
        WHEN R <= 4 AND F >= 2 THEN 'At Risk'
        WHEN R <= 5 AND F >= 1 THEN 'Lost'
        ELSE 'Other'
    END AS Customer_Segment
FROM rfm_score;

SET SQL_SAFE_UPDATES = 1;