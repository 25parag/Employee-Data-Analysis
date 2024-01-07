-- 1) Identify the department with the highest average salary, providing valuable insights into compensation trends within our organization.
SELECT 
    d.dept_name, ROUND(AVG(s.salary), 2) AS avg_salary
FROM
    departments AS d
        JOIN
    dept_emp AS de ON d.dept_no = de.dept_no
        JOIN
    salaries AS s ON de.emp_no = s.emp_no
        JOIN
    employees AS E ON E.emp_no = de.emp_no
WHERE
    (de.emp_no , de.from_date) IN (SELECT 
            emp_no, MAX(from_date)
        FROM
            dept_emp
        GROUP BY emp_no)
        AND (s.emp_no , s.from_date) IN (SELECT 
            emp_no, MAX(from_date)
        FROM
            salaries
        GROUP BY emp_no)
GROUP BY d.dept_name
ORDER BY avg_salary DESC
LIMIT 1;


-- 2) Identify the department with the lowest percentage of female employees, providing insights into the gender diversity within our organization.
SELECT 
    D.dept_name,
    ROUND((SUM(CASE
                WHEN E.gender = 'F' THEN 1
                ELSE 0
            END) / COUNT(E.gender)) * 100,
            2) AS female_percent
FROM
    departments AS D
        JOIN
    dept_emp AS DE ON D.dept_no = DE.dept_no
        JOIN
    employees AS E ON E.emp_no = DE.emp_no
WHERE
    (DE.emp_no , DE.from_date) IN (SELECT 
            emp_no, MAX(from_date)
        FROM
            dept_emp
        GROUP BY emp_no)
GROUP BY D.dept_name
ORDER BY female_percent ASC
LIMIT 1;


-- 3) Identify the job title that exhibits the highest concentration of female employees within our organization.
SELECT 
    t.title, COUNT(e.emp_no) AS female_employee_count
FROM
    titles t
        JOIN
    employees e ON t.emp_no = e.emp_no
WHERE
    e.gender = 'F'
        AND (t.emp_no , t.from_date) IN (SELECT 
            emp_no, MAX(from_date) AS latest_date
        FROM
            titles
        GROUP BY emp_no)
GROUP BY t.title
ORDER BY female_employee_count DESC
LIMIT 1;


-- 4) Identify the department with the lowest average salaries.
SELECT 
    D.dept_name, ROUND(AVG(S.salary), 2) AS avg_salary
FROM
    departments AS D
        JOIN
    dept_emp AS DE ON D.dept_no = DE.dept_no
        JOIN
    salaries AS S ON S.emp_no = DE.emp_no
WHERE
    (S.emp_no , S.from_date) IN (SELECT 
            emp_no, MAX(from_date)
        FROM
            salaries
        GROUP BY emp_no)
        AND (DE.emp_no , DE.from_date) IN (SELECT 
            emp_no, MAX(from_date)
        FROM
            dept_emp
        GROUP BY emp_no)
GROUP BY D.dept_name
ORDER BY avg_salary ASC
LIMIT 1;


-- 5) Examine salary disparities between genders within departments
SELECT 
    D.dept_name,
    ROUND(MAX(salary_male - salary_female), 2) AS max_salary_gap
FROM
    departments AS D
        JOIN
    (SELECT 
        DE.dept_no,
            AVG(CASE
                WHEN E.gender = 'M' THEN S.salary
            END) AS salary_male,
            AVG(CASE
                WHEN E.gender = 'F' THEN S.salary
            END) AS salary_female
    FROM
        dept_emp AS DE
    JOIN employees AS E ON DE.emp_no = E.emp_no
    JOIN salaries AS S ON DE.emp_no = S.emp_no
    WHERE
        (S.emp_no , S.from_date) IN (SELECT 
                emp_no, MAX(from_date)
            FROM
                salaries
            GROUP BY emp_no)
            AND (DE.emp_no , DE.from_date) IN (SELECT 
                emp_no, MAX(from_date)
            FROM
                dept_emp
            GROUP BY emp_no)
    GROUP BY DE.dept_no) AS gender_salary ON D.dept_no = gender_salary.dept_no
GROUP BY D.dept_name
ORDER BY max_salary_gap DESC
;


-- 6) Identify the department with the highest concentration of employees earning salaries below 50,000.
SELECT 
    D.dept_name, COUNT(E.emp_no) AS employees
FROM
    departments AS D
        JOIN
    dept_emp AS DE ON D.dept_no = DE.dept_no
        JOIN
    employees AS E ON E.emp_no = DE.emp_no
        JOIN
    salaries AS S ON S.emp_no = E.emp_no
WHERE
    (S.emp_no , S.from_date) IN (SELECT 
            emp_no, MAX(from_date)
        FROM
            salaries
        GROUP BY emp_no)
        AND S.salary < 50000
GROUP BY D.dept_name
ORDER BY employees DESC
LIMIT 1;


-- 7) Explore the salary evolution over time for a specific employee? (For example - with Employee ID "10005,").
 SELECT
    emp_no,
	salary,
    from_date,

ROW_NUMBER() OVER w AS row_num

FROM salaries

WHERE emp_no = 10005

WINDOW w AS (PARTITION BY emp_no ORDER BY from_date);


-- 8) Quantify the distribution of managerial roles in terms of gender, providing the total count for both male and female managers across the organization.
SELECT


    e.gender, COUNT(dm.emp_no) AS manager_count


FROM


    employees e


        JOIN


    dept_manager dm ON e.emp_no = dm.emp_no


GROUP BY gender;


-- 9) Extract current employment status of individuals from this data?
SELECT 
    e.emp_no,
    e.first_name,
    e.last_name,
    CASE
        WHEN MAX(de.to_date) > SYSDATE() THEN 'Is still employed'
        ELSE 'Not an employee anymore'
    END AS employment_status
FROM
    employees e
        JOIN
    dept_emp de ON de.emp_no = e.emp_no
GROUP BY de.emp_no;


-- 10) Determine the top earners within each department by identifying employees with the highest salaries?
WITH RankedSalaries AS (
    SELECT
        S.emp_no,
        de.dept_no,
        S.salary,
        DENSE_RANK() OVER (PARTITION BY de.dept_no ORDER BY S.salary DESC) AS salary_rank
    FROM
        salaries AS S
        JOIN dept_emp AS de ON S.emp_no = de.emp_no
    WHERE
        S.to_date = '9999-01-01' -- Assuming '9999-01-01' indicates the current date for ongoing salaries.
)

SELECT
    R.dept_no,
    R.emp_no,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.gender,
    R.salary
FROM
    RankedSalaries AS R
    JOIN employees AS e ON R.emp_no = e.emp_no
WHERE
    R.salary_rank = 1;

-- 11) Identify employees who have undergone departmental transitions within the organization?
SELECT 
    e.emp_no,
    CONCAT(e.first_name," ",e.last_name) AS emp_name,
    de.from_date AS transfer_date,
    de.dept_no AS from_department,
    de.to_date AS transfer_out_date,
    de2.dept_no AS to_department
FROM
    dept_emp de
        JOIN
    dept_emp de2 ON de.emp_no = de2.emp_no
        AND de.to_date = de2.from_date
        JOIN
    employees e ON de.emp_no = e.emp_no
ORDER BY emp_no;


-- 12) Who are current managers in each department?
SELECT
    dm.dept_no,
    dm.emp_no AS manager_id,
    CONCAT(e.first_name, ' ', e.last_name) AS manager_name
FROM
    dept_manager dm
    JOIN employees e ON dm.emp_no = e.emp_no
WHERE
    dm.to_date = '9999-01-01'; -- Assuming '9999-01-01' indicates the current date for ongoing management.

-- 13) Track the changes in average salaries over the years within a specific department to understand how compensation trends have evolved.
SELECT 
    de.dept_no,
    YEAR(s.from_date) AS year,
    ROUND(AVG(s.salary), 0) AS average_salary
FROM
    salaries AS s
        JOIN
    dept_emp AS de ON S.emp_no = de.emp_no
WHERE
    de.dept_no = 'd001'
GROUP BY year
ORDER BY year;


-- 14) What is the employee turnover rate in each department?
SELECT
    de.dept_no,
    COUNT(DISTINCT e.emp_no) AS num_employees,
    COUNT(DISTINCT CASE WHEN de.to_date != '9999-01-01' THEN e.emp_no END) AS num_departures,
    COUNT(DISTINCT CASE WHEN de.to_date = '9999-01-01' THEN e.emp_no END) AS num_current_employees,
    ROUND((COUNT(DISTINCT CASE WHEN de.to_date != '9999-01-01' THEN e.emp_no END) / COUNT(DISTINCT e.emp_no)) * 100, 2)  AS turnover_rate
FROM
    dept_emp AS de
    JOIN employees AS e ON de.emp_no = e.emp_no
GROUP BY
    de.dept_no;

-- 15) How does the average salary vary with age for each gender?
SELECT
    e.gender,
    FLOOR(DATEDIFF(CURDATE(), e.birth_date)/365) AS age,
    AVG(S.salary) AS average_salary
FROM
    employees AS e
    JOIN salaries AS S ON e.emp_no = S.emp_no
WHERE
    S.to_date = '9999-01-01'
GROUP BY
    e.gender, age
    ORDER BY age;


-- 16) How has the headcount in a specific department changed over the last five years?
SELECT
    de.dept_no,
    YEAR(de.from_date) AS year,
    COUNT(DISTINCT CASE WHEN de.to_date = '9999-01-01' THEN de.emp_no END) AS num_employees
FROM
    dept_emp de
    WHERE de.dept_no = 'd005'
GROUP BY
    de.dept_no, year;


-- 17) Identify the job title with the longest average tenure among employees in the organization.
SELECT
    t.title,
    MAX(TIMESTAMPDIFF(YEAR, e.hire_date, CURDATE())) AS max_retention_period
FROM
    titles AS t
JOIN
    employees AS e ON t.emp_no = e.emp_no
GROUP BY
    t.title
ORDER BY
    max_retention_period DESC
LIMIT 1;

