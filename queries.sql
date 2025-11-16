-- Complex SQL Queries for Employee Management System
USE employee_management_system;

-- 1. Employee Details with Department and Manager Information
SELECT 
    e.emp_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.job_title,
    d.dept_name,
    CONCAT(m.first_name, ' ', m.last_name) AS manager_name,
    e.salary,
    e.hire_date
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
LEFT JOIN employees m ON e.manager_id = m.emp_id
ORDER BY d.dept_name, e.last_name;

-- 2. Department-wise Employee Count and Average Salary
SELECT 
    d.dept_name,
    COUNT(e.emp_id) AS employee_count,
    ROUND(AVG(e.salary), 2) AS avg_salary,
    MIN(e.salary) AS min_salary,
    MAX(e.salary) AS max_salary,
    SUM(e.salary) AS total_salary_cost
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id AND e.status = 'Active'
GROUP BY d.dept_id, d.dept_name
ORDER BY employee_count DESC;

-- 3. Project Status Report with Team Information
SELECT 
    p.project_name,
    p.status,
    p.start_date,
    p.end_date,
    p.budget,
    d.dept_name,
    CONCAT(pm.first_name, ' ', pm.last_name) AS project_manager,
    COUNT(ep.emp_id) AS team_size,
    ROUND(AVG(ep.allocation_percentage), 2) AS avg_allocation
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
LEFT JOIN employees pm ON p.project_manager_id = pm.emp_id
LEFT JOIN employee_projects ep ON p.project_id = ep.project_id
GROUP BY p.project_id
ORDER BY p.start_date DESC;

-- 4. Employees with Multiple Projects
SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.job_title,
    COUNT(ep.project_id) AS project_count,
    SUM(ep.allocation_percentage) AS total_allocation,
    GROUP_CONCAT(p.project_name SEPARATOR ', ') AS projects
FROM employees e
JOIN employee_projects ep ON e.emp_id = ep.emp_id
JOIN projects p ON ep.project_id = p.project_id
GROUP BY e.emp_id
HAVING project_count > 1
ORDER BY project_count DESC;

-- 5. Salary Growth Analysis
SELECT 
    e.emp_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    s1.salary_amount AS initial_salary,
    s2.salary_amount AS current_salary,
    ROUND(((s2.salary_amount - s1.salary_amount) / s1.salary_amount) * 100, 2) AS growth_percentage,
    DATEDIFF(s2.effective_date, s1.effective_date) AS days_between
FROM employees e
JOIN salaries s1 ON e.emp_id = s1.emp_id
JOIN salaries s2 ON e.emp_id = s2.emp_id
WHERE s1.effective_date = (
    SELECT MIN(effective_date) 
    FROM salaries 
    WHERE emp_id = e.emp_id
)
AND s2.effective_date = (
    SELECT MAX(effective_date) 
    FROM salaries 
    WHERE emp_id = e.emp_id
)
AND s1.effective_date != s2.effective_date
ORDER BY growth_percentage DESC;

-- 6. Top Performers by Department (Highest Salary in Each Department)
WITH dept_max_salary AS (
    SELECT dept_id, MAX(salary) as max_salary
    FROM employees
    WHERE status = 'Active'
    GROUP BY dept_id
)
SELECT 
    d.dept_name,
    CONCAT(e.first_name, ' ', e.last_name) AS top_performer,
    e.job_title,
    e.salary,
    RANK() OVER (ORDER BY e.salary DESC) as overall_rank
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
JOIN dept_max_salary dms ON e.dept_id = dms.dept_id AND e.salary = dms.max_salary
WHERE e.status = 'Active'
ORDER BY e.salary DESC;

-- 7. Project Budget vs Department Budget Analysis
SELECT 
    d.dept_name,
    d.budget as dept_budget,
    COUNT(p.project_id) as project_count,
    COALESCE(SUM(p.budget), 0) as total_project_budget,
    ROUND((COALESCE(SUM(p.budget), 0) / d.budget) * 100, 2) as budget_utilization_percent
FROM departments d
LEFT JOIN projects p ON d.dept_id = p.dept_id
GROUP BY d.dept_id, d.dept_name, d.budget
ORDER BY budget_utilization_percent DESC;

-- 8. Employee Tenure and Experience Analysis
SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.job_title,
    d.dept_name,
    e.hire_date,
    DATEDIFF(CURDATE(), e.hire_date) AS days_employed,
    ROUND(DATEDIFF(CURDATE(), e.hire_date) / 365.25, 1) AS years_employed,
    CASE 
        WHEN DATEDIFF(CURDATE(), e.hire_date) < 365 THEN 'New Employee'
        WHEN DATEDIFF(CURDATE(), e.hire_date) < 1095 THEN 'Experienced'
        WHEN DATEDIFF(CURDATE(), e.hire_date) < 1825 THEN 'Senior'
        ELSE 'Veteran'
    END AS experience_level
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.status = 'Active'
ORDER BY days_employed DESC;

-- 9. Monthly Hiring Trends
SELECT 
    YEAR(hire_date) as hire_year,
    MONTH(hire_date) as hire_month,
    MONTHNAME(hire_date) as month_name,
    COUNT(*) as employees_hired,
    ROUND(AVG(salary), 2) as avg_starting_salary
FROM employees
GROUP BY YEAR(hire_date), MONTH(hire_date)
ORDER BY hire_year DESC, hire_month DESC;

-- 10. Cross-Department Project Collaboration
SELECT 
    p.project_name,
    COUNT(DISTINCT e.dept_id) as departments_involved,
    GROUP_CONCAT(DISTINCT d.dept_name ORDER BY d.dept_name SEPARATOR ', ') as collaborating_departments,
    COUNT(ep.emp_id) as total_team_members
FROM projects p
JOIN employee_projects ep ON p.project_id = ep.project_id
JOIN employees e ON ep.emp_id = e.emp_id
JOIN departments d ON e.dept_id = d.dept_id
GROUP BY p.project_id, p.project_name
HAVING departments_involved > 1
ORDER BY departments_involved DESC, total_team_members DESC;