import os
import pandas as pd
import pymysql

# CSV files with table mapping
csv_files = [
    ('customers.csv', 'customers'),
    ('invoices.csv', 'invoices'),
    ('products.csv', 'products'),
    ('invoice_details.csv', 'invoice_detail')
]

# MySQL connection
conn = pymysql.connect(
    host="localhost",
    user="root",
    password="A@ap17gp34",
    database="ecommerce_db_clean"
)
cursor = conn.cursor()

# Path to CSVs
folder_path = r"C:\Users\91730\OneDrive\Desktop\Projects\SQL\first_project\Ecommerce"

for csv_file, table_name in csv_files:
    file_path = os.path.join(folder_path, csv_file)
    df = pd.read_csv(file_path)

    # Handle InvoiceDate column
    if "InvoiceDate" in df.columns:
        df["InvoiceDate"] = pd.to_datetime(df["InvoiceDate"], errors="coerce", infer_datetime_format=True)

    # Replace NaN with None
    df = df.where(pd.notnull(df), None)

    # Match schema column names
    df.columns = [col.strip().replace(" ", "_") for col in df.columns]

    # Insert query
    placeholders = ", ".join(["%s"] * len(df.columns))
    sql = f"INSERT IGNORE INTO `{table_name}` ({', '.join(['`' + col + '`' for col in df.columns])}) VALUES ({placeholders})"

    cursor.executemany(sql, df.values.tolist())
    conn.commit()

cursor.close()
conn.close()
print("✅ Data loaded successfully into ecommerce_db_clean!")
