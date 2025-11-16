-- DEMO QUERIES FOR DB FIDDLE RIGHT PANEL
-- Copy these to RIGHT PANEL and run one by one

-- 1. Employee Performance Dashboard
SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.job_title,
    d.dept_name,
    e.salary,
    pr.technical_score,
    pr.overall_rating,
    COUNT(ep.project_id) AS active_projects,
    COALESCE(SUM(ep.allocation_percentage), 0) AS total_allocation
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
LEFT JOIN performance_reviews pr ON e.emp_id = pr.emp_id
LEFT JOIN employee_projects ep ON e.emp_id = ep.emp_id
WHERE e.status = 'Active'
GROUP BY e.emp_id, e.first_name, e.last_name, e.job_title, d.dept_name, e.salary, pr.technical_score, pr.overall_rating
ORDER BY e.salary DESC;

-- 2. Department-wise Analytics
SELECT 
    d.dept_name,
    COUNT(e.emp_id) AS employee_count,
    ROUND(AVG(e.salary), 2) AS avg_salary,
    MAX(e.salary) AS max_salary,
    MIN(e.salary) AS min_salary,
    SUM(e.salary) AS total_salary_cost,
    d.budget,
    ROUND((SUM(e.salary) / d.budget) * 100, 2) AS salary_budget_ratio
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id AND e.status = 'Active'
GROUP BY d.dept_id, d.dept_name, d.budget
ORDER BY employee_count DESC;

-- 3. Project Status & Team Analysis
SELECT 
    p.project_name,
    p.status,
    p.budget,
    d.dept_name,
    COUNT(ep.emp_id) AS team_size,
    ROUND(AVG(ep.allocation_percentage), 2) AS avg_allocation,
    GROUP_CONCAT(CONCAT(e.first_name, ' ', e.last_name) SEPARATOR ', ') AS team_members
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
LEFT JOIN employee_projects ep ON p.project_id = ep.project_id
LEFT JOIN employees e ON ep.emp_id = e.emp_id
GROUP BY p.project_id, p.project_name, p.status, p.budget, d.dept_name
ORDER BY p.budget DESC;

-- 4. Top Performers Analysis
SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.job_title,
    d.dept_name,
    e.salary,
    pr.technical_score,
    pr.overall_rating,
    RANK() OVER (ORDER BY pr.technical_score DESC) AS performance_rank,
    CASE 
        WHEN pr.technical_score >= 9.0 THEN 'Exceptional'
        WHEN pr.technical_score >= 8.0 THEN 'High Performer'
        WHEN pr.technical_score >= 7.0 THEN 'Good Performer'
        ELSE 'Needs Improvement'
    END AS performance_category
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
LEFT JOIN performance_reviews pr ON e.emp_id = pr.emp_id
WHERE e.status = 'Active' AND pr.technical_score IS NOT NULL
ORDER BY pr.technical_score DESC;

-- 5. Workload Distribution Analysis
SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.job_title,
    COUNT(ep.project_id) AS project_count,
    COALESCE(SUM(ep.allocation_percentage), 0) AS total_allocation,
    CASE 
        WHEN COALESCE(SUM(ep.allocation_percentage), 0) = 0 THEN 'Available'
        WHEN COALESCE(SUM(ep.allocation_percentage), 0) <= 50 THEN 'Light Load'
        WHEN COALESCE(SUM(ep.allocation_percentage), 0) <= 80 THEN 'Moderate Load'
        WHEN COALESCE(SUM(ep.allocation_percentage), 0) <= 100 THEN 'Full Load'
        ELSE 'Overallocated'
    END AS workload_status,
    GROUP_CONCAT(p.project_name SEPARATOR ', ') AS current_projects
FROM employees e
LEFT JOIN employee_projects ep ON e.emp_id = ep.emp_id
LEFT JOIN projects p ON ep.project_id = p.project_id AND p.status IN ('Planning', 'In Progress')
WHERE e.status = 'Active'
GROUP BY e.emp_id, e.first_name, e.last_name, e.job_title
ORDER BY total_allocation DESC;

-- 6. Salary Analysis with Growth Potential
SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.job_title,
    d.dept_name,
    e.salary AS current_salary,
    (SELECT AVG(salary) FROM employees WHERE dept_id = e.dept_id AND status = 'Active') AS dept_avg_salary,
    ROUND(e.salary / (SELECT AVG(salary) FROM employees WHERE dept_id = e.dept_id AND status = 'Active'), 2) AS salary_ratio,
    DATEDIFF(CURDATE(), e.hire_date) / 365.25 AS years_employed,
    CASE 
        WHEN e.salary < (SELECT AVG(salary) FROM employees WHERE dept_id = e.dept_id AND status = 'Active') * 0.8 
        THEN 'Below Market'
        WHEN e.salary > (SELECT AVG(salary) FROM employees WHERE dept_id = e.dept_id AND status = 'Active') * 1.2 
        THEN 'Above Market'
        ELSE 'Market Rate'
    END AS salary_position
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.status = 'Active'
ORDER BY salary_ratio DESC;