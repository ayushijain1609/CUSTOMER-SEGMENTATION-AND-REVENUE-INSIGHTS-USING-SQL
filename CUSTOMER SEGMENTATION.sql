DROP DATABASE IF EXISTS ecommerce_db_clean;
CREATE DATABASE ecommerce_db_clean;
USE ecommerce_db_clean;

CREATE TABLE customers (
    CustomerID INT PRIMARY KEY,
    Country VARCHAR(100)
);

CREATE TABLE invoices (
    InvoiceNo INT PRIMARY KEY,
    CustomerID INT,
    InvoiceDate DATETIME,
    InvoiceTotal INT,
    NumItems INT,
    FOREIGN KEY (CustomerID) REFERENCES customers(CustomerID)
);

CREATE TABLE products (
    StockCode INT PRIMARY KEY,
    Description VARCHAR(225),
    UnitPrice INT
);

CREATE TABLE invoice_detail (
    InvoiceNo INT,
    StockCode INT,
    Quantity INT,
    UnitPrice INT,
    LineTotal INT,
    FOREIGN KEY (InvoiceNo) REFERENCES invoices(InvoiceNo),
    FOREIGN KEY (StockCode) REFERENCES products(StockCode)
);


SELECT * FROM customers;
SELECT * FROM invoices;
SELECT * FROM products;
SELECT * FROM invoice_detail;



-- 1. View first 10 customers
SELECT * FROM customers LIMIT 10;

-- 2. Count total invoices
SELECT COUNT(*) AS total_invoices FROM invoices;

-- 3. Get all unique countries
SELECT DISTINCT Country FROM customers

-- 4. Find the invoice with the highest total
SELECT InvoiceNo, InvoiceTotal
FROM invoices
ORDER BY InvoiceTotal DESC
LIMIT 1;

-- 5. Count number of products
SELECT COUNT(*) AS total_products FROM products;


-- 6. Join invoices with customers (who bought what)
SELECT i.InvoiceNo, i.InvoiceDate, c.Country, i.InvoiceTotal
FROM invoices i
JOIN customers c ON i.CustomerID = c.CustomerID
LIMIT 10;

-- 7. Join invoice_detail with products (which items were bought)
SELECT d.InvoiceNo, p.Description, d.Quantity, d.LineTotal
FROM invoice_detail d
JOIN products p ON d.StockCode = p.StockCode
LIMIT 10;

-- 8. Full invoice with customer + product details
SELECT i.InvoiceNo, c.Country, p.Description, d.Quantity, d.LineTotal
FROM invoice_detail d
JOIN invoices i ON d.InvoiceNo = i.InvoiceNo
JOIN customers c ON i.CustomerID = c.CustomerID
JOIN products p ON d.StockCode = p.StockCode
LIMIT 10;



-- 9. Total revenue
SELECT SUM(InvoiceTotal) AS total_revenue FROM invoices;

-- 10. Revenue by country
SELECT c.Country, SUM(i.InvoiceTotal) AS revenue
FROM invoices i
JOIN customers c ON i.CustomerID = c.CustomerID
GROUP BY c.Country
ORDER BY revenue DESC;

-- 11. Top 5 customers by spending
SELECT i.CustomerID, SUM(i.InvoiceTotal) AS total_spent
FROM invoices i
GROUP BY i.CustomerID
ORDER BY total_spent DESC
LIMIT 5;

-- 12. Average order size
SELECT AVG(NumItems) AS avg_items_per_order FROM invoices;

-- 13. Customers with more than 10 invoices
SELECT CustomerID, COUNT(*) AS invoice_count
FROM invoices
GROUP BY CustomerID
HAVING COUNT(*) > 10;



-- 14. Find customers who spent above the average invoice total
SELECT CustomerID, SUM(InvoiceTotal) AS total_spent
FROM invoices
GROUP BY CustomerID
HAVING SUM(InvoiceTotal) > (
    SELECT AVG(InvoiceTotal) FROM invoices
);

-- 15. Get most expensive product
SELECT *
FROM products
WHERE UnitPrice = (SELECT MAX(UnitPrice) FROM products);



-- 16. Running total of revenue over time
SELECT InvoiceDate,
       SUM(InvoiceTotal) OVER (ORDER BY InvoiceDate) AS running_total
FROM invoices
ORDER BY InvoiceDate;

-- 17. Rank customers by spending
SELECT CustomerID,
       SUM(InvoiceTotal) AS total_spent,
       RANK() OVER (ORDER BY SUM(InvoiceTotal) DESC) AS rank_spender
FROM invoices
GROUP BY CustomerID;

-- 18. Average order total per customer with comparison
SELECT CustomerID,
       InvoiceTotal,
       AVG(InvoiceTotal) OVER (PARTITION BY CustomerID) AS avg_order_value
FROM invoices;




-- 19. CTE: Revenue per customer
WITH customer_revenue AS (
    SELECT CustomerID, SUM(InvoiceTotal) AS revenue
    FROM invoices
    GROUP BY CustomerID
)
SELECT * FROM customer_revenue
ORDER BY revenue DESC;

-- 20. CTE + Window: Top 3 customers per country
WITH customer_country_revenue AS (
    SELECT c.Country, i.CustomerID, SUM(i.InvoiceTotal) AS revenue
    FROM invoices i
    JOIN customers c ON i.CustomerID = c.CustomerID
    GROUP BY c.Country, i.CustomerID
),
ranked_customers AS (
    SELECT Country, CustomerID, revenue,
           RANK() OVER (PARTITION BY Country ORDER BY revenue DESC) AS rank_in_country
    FROM customer_country_revenue
)
SELECT *
FROM ranked_customers
WHERE rank_in_country <= 3
ORDER BY Country, rank_in_country;


-- 21. Month-wise revenue trend
SELECT DATE_FORMAT(InvoiceDate, '%Y-%m') AS month,
       SUM(InvoiceTotal) AS monthly_revenue
FROM invoices
GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
ORDER BY month;

-- 22. Product popularity (by total quantity sold)
SELECT p.Description, SUM(d.Quantity) AS total_sold
FROM invoice_detail d
JOIN products p ON d.StockCode = p.StockCode
GROUP BY p.Description
ORDER BY total_sold DESC
LIMIT 10;

-- 23. Average spend per country per invoice
SELECT c.Country,
       AVG(i.InvoiceTotal) AS avg_invoice_total
FROM invoices i
JOIN customers c ON i.CustomerID = c.CustomerID
GROUP BY c.Country
ORDER BY avg_invoice_total DESC;

-- 24. Customers who never placed an invoice
SELECT *
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM invoices i WHERE i.CustomerID = c.CustomerID
);
