import sqlite3 as sql
import os
import pandas as pd


# this File grab datasets from Brazilian E-Commerce Public Dataset by Olist folder and 
# by using a for loop append them into Brazilian_E-commerce.db Database
# you can find created database in SQL_Database 


folder_path = './SQL_Database'
if not os.path.exists(folder_path):
    os.makedirs(folder_path)

connection = sql.connect("SQL_Database/Brazilian_E-commerce.db")


# Load Data 
path = "Brazilian E-Commerce Public Dataset by Olist/"
csv_files_names = [
"customers",
"geolocation",
"order_items",
"order_payments",
"order_reviews",
"orders",
"products",
"sellers",
"product_category_name_translation",
]



for name in csv_files_names:
    filename = f"{name}.csv"
    dataframe_name = pd.read_csv(path+filename)


    # Load database to sqlite
    # fail, replace, append
    dataframe_name.to_sql(f"{name}", connection, if_exists="replace")


    print(dataframe_name.head(1))





connection.close()
