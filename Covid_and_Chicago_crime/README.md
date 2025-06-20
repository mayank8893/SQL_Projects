## SQL Projects

### 1. COVID SQL Analysis

This project uses a COVID dataset to answer several real-world questions using SQL, such as:

- What’s the likelihood of death if someone contracts COVID in the U.S.?
- What percentage of the U.S. population was infected?
- Which countries had the highest infection rates?
- How did vaccination progress over time across different countries?

This project showcases my ability to write basic to intermediate SQL queries, including use of **CTEs** and **window functions** like `PARTITION BY`.

**See:** [`covid_sql_project.pdf`](covid_sql_project.pdf) for the full set of queries.

---

### 2. Data Cleaning in SQL

This project focuses on cleaning and preparing a messy real estate dataset using SQL. Key operations include:

- Converting `datetime` to standard `date` and updating the table
- Filling in missing property addresses via **SELF JOIN**
- Breaking out full address strings into separate `address`, `city`, and `state` columns using `SUBSTRING` and `PARSENAME`
- Replacing `Y/N` entries with `Yes/No` using `CASE` statements
- Removing duplicates with **CTEs**
- Deleting unused columns

This project highlights my practical skills in using SQL to clean and structure raw data for analysis.

**See:** [`data_cleaning.sql`](data_cleaning.sql) for all queries.

---

### 3. Chicago Crime Analysis

For this project, I used the publicly available `chicago_crime` dataset from **BigQuery** to analyze crime trends over the last 22 years. Questions explored include:

- Has crime increased year over year?
- Are certain months more prone to crime?
- What are the top 10 most frequent crime types?
- Which districts report the most crimes?
- How has theft changed over the years?

📄 **See:** [`chicago_crime.sql`](chicago_crime.sql) for SQL queries.

**Visualizations created using Tableau:**


I generated the following plots in tableau to explain the results.

<img width="799" alt="Screen Shot 2022-11-12 at 5 07 01 PM" src="https://user-images.githubusercontent.com/69361645/201496677-fd1a56ff-8558-49e1-86b8-cde1ab03c400.png">


<img width="768" alt="Screen Shot 2022-11-12 at 5 09 45 PM" src="https://user-images.githubusercontent.com/69361645/201496679-f90305a7-27ac-43e3-b31e-b4c6fa3925de.png">


<img width="635" alt="Screen Shot 2022-11-12 at 5 13 56 PM" src="https://user-images.githubusercontent.com/69361645/201496681-ca450210-9cf7-4443-93fd-4b70893e9e78.png">


<img width="799" alt="Screen Shot 2022-11-12 at 5 15 55 PM" src="https://user-images.githubusercontent.com/69361645/201496683-69a4f95b-c92e-4f39-ad8d-f52bcd9dc07e.png">


  
