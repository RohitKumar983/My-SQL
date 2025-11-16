-- Database Views for Employee Management System
USE employee_management_system;

-- 1. Employee Summary View
CREATE VIEW v_employee_summary AS
SELECT 
    e.emp_id,
    CONCAT(e.first_name, ' ', e.last_name) AS full_name,
    e.email,
    e.job_title,
    d.dept_name,
    CONCAT(m.first_name, ' ', m.last_name) AS manager_name,
    e.salary,
    e.hire_date,
    ROUND(DATEDIFF(CURDATE(), e.hire_date) / 365.25, 1) AS years_employed,
    e.status,
    CASE 
        WHEN DATEDIFF(CURDATE(), e.hire_date) < 365 THEN 'New'
        WHEN DATEDIFF(CURDATE(), e.hire_date) < 1095 THEN 'Experienced'
        WHEN DATEDIFF(CURDATE(), e.hire_date) < 1825 THEN 'Senior'
        ELSE 'Veteran'
    END AS experience_level
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
LEFT JOIN employees m ON e.manager_id = m.emp_id;

-- 2. Department Statistics View
CREATE VIEW v_department_stats AS
SELECT 
    d.dept_id,
    d.dept_name,
    d.location,
    d.budget,
    CONCAT(dh.first_name, ' ', dh.last_name) AS department_head,
    COUNT(e.emp_id) AS employee_count,
    ROUND(AVG(e.salary), 2) AS avg_salary,
    MIN(e.salary) AS min_salary,
    MAX(e.salary) AS max_salary,
    SUM(e.salary) AS total_salary_cost,
    ROUND((SUM(e.salary) / d.budget) * 100, 2) AS salary_budget_ratio,
    COUNT(p.project_id) AS active_projects
FROM departments d
LEFT JOIN employees dh ON d.dept_head_id = dh.emp_id
LEFT JOIN employees e ON d.dept_id = e.dept_id AND e.status = 'Active'
LEFT JOIN projects p ON d.dept_id = p.dept_id AND p.status IN ('Planning', 'In Progress')
GROUP BY d.dept_id, d.dept_name, d.location, d.budget, dh.first_name, dh.last_name;

-- 3. Project Dashboard View
CREATE VIEW v_project_dashboard AS
SELECT 
    p.project_id,
    p.project_name,
    p.description,
    p.status,
    p.start_date,
    p.end_date,
    p.budget,
    d.dept_name,
    CONCAT(pm.first_name, ' ', pm.last_name) AS project_manager,
    COUNT(ep.emp_id) AS team_size,
    ROUND(AVG(ep.allocation_percentage), 2) AS avg_allocation,
    SUM(ep.allocation_percentage) AS total_allocation,
    DATEDIFF(COALESCE(p.end_date, CURDATE()), p.start_date) AS project_duration_days,
    CASE 
        WHEN p.status = 'Completed' THEN 'Completed'
        WHEN p.end_date < CURDATE() AND p.status != 'Completed' THEN 'Overdue'
        WHEN DATEDIFF(p.end_date, CURDATE()) <= 30 AND p.status IN ('Planning', 'In Progress') THEN 'Due Soon'
        ELSE 'On Track'
    END AS project_health
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
LEFT JOIN employees pm ON p.project_manager_id = pm.emp_id
LEFT JOIN employee_projects ep ON p.project_id = ep.project_id
GROUP BY p.project_id, p.project_name, p.description, p.status, p.start_date, p.end_date, 
         p.budget, d.dept_name, pm.first_name, pm.last_name;

-- 4. Employee Workload View
CREATE VIEW v_employee_workload AS
SELECT 
    e.emp_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.job_title,
    d.dept_name,
    COUNT(ep.project_id) AS active_projects,
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
LEFT JOIN departments d ON e.dept_id = d.dept_id
LEFT JOIN employee_projects ep ON e.emp_id = ep.emp_id AND (ep.end_date IS NULL OR ep.end_date > CURDATE())
LEFT JOIN projects p ON ep.project_id = p.project_id AND p.status IN ('Planning', 'In Progress')
WHERE e.status = 'Active'
GROUP BY e.emp_id, e.first_name, e.last_name, e.job_title, d.dept_name;

-- 5. Salary Analysis View
CREATE VIEW v_salary_analysis AS
SELECT 
    e.emp_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.job_title,
    d.dept_name,
    e.salary AS current_salary,
    s_first.salary_amount AS starting_salary,
    ROUND(((e.salary - s_first.salary_amount) / s_first.salary_amount) * 100, 2) AS salary_growth_percent,
    COUNT(s_all.salary_id) AS salary_changes,
    ROUND(DATEDIFF(CURDATE(), e.hire_date) / 365.25, 1) AS years_employed,
    ROUND(e.salary / (DATEDIFF(CURDATE(), e.hire_date) / 365.25), 2) AS salary_per_year_employed
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
LEFT JOIN salaries s_first ON e.emp_id = s_first.emp_id 
    AND s_first.effective_date = (SELECT MIN(effective_date) FROM salaries WHERE emp_id = e.emp_id)
LEFT JOIN salaries s_all ON e.emp_id = s_all.emp_id
WHERE e.status = 'Active'
GROUP BY e.emp_id, e.first_name, e.last_name, e.job_title, d.dept_name, 
         e.salary, s_first.salary_amount, e.hire_date;

-- 6. Project Team Composition View
CREATE VIEW v_project_teams AS
SELECT 
    p.project_id,
    p.project_name,
    p.status AS project_status,
    CONCAT(e.first_name, ' ', e.last_name) AS team_member,
    e.job_title,
    d.dept_name,
    ep.role AS project_role,
    ep.allocation_percentage,
    ep.start_date AS assignment_start,
    ep.end_date AS assignment_end,
    CASE 
        WHEN ep.end_date IS NULL THEN 'Active'
        WHEN ep.end_date > CURDATE() THEN 'Active'
        ELSE 'Completed'
    END AS assignment_status
FROM projects p
JOIN employee_projects ep ON p.project_id = ep.project_id
JOIN employees e ON ep.emp_id = e.emp_id
JOIN departments d ON e.dept_id = d.dept_id
ORDER BY p.project_id, ep.start_date;

-- 7. Management Hierarchy View
CREATE VIEW v_management_hierarchy AS
SELECT 
    e.emp_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.job_title,
    d.dept_name,
    CONCAT(m1.first_name, ' ', m1.last_name) AS direct_manager,
    CONCAT(m2.first_name, ' ', m2.last_name) AS manager_of_manager,
    (SELECT COUNT(*) FROM employees WHERE manager_id = e.emp_id AND status = 'Active') AS direct_reports,
    CASE 
        WHEN e.manager_id IS NULL THEN 'Executive'
        WHEN (SELECT COUNT(*) FROM employees WHERE manager_id = e.emp_id AND status = 'Active') > 0 THEN 'Manager'
        ELSE 'Individual Contributor'
    END AS management_level
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
LEFT JOIN employees m1 ON e.manager_id = m1.emp_id
LEFT JOIN employees m2 ON m1.manager_id = m2.emp_id
WHERE e.status = 'Active'
ORDER BY d.dept_name, management_level, e.last_name;

-- 8. Budget Utilization View
CREATE VIEW v_budget_utilization AS
SELECT 
    d.dept_name,
    d.budget AS department_budget,
    COALESCE(SUM(e.salary), 0) AS salary_costs,
    COALESCE(SUM(p.budget), 0) AS project_budgets,
    (COALESCE(SUM(e.salary), 0) + COALESCE(SUM(p.budget), 0)) AS total_allocated,
    d.budget - (COALESCE(SUM(e.salary), 0) + COALESCE(SUM(p.budget), 0)) AS remaining_budget,
    ROUND(((COALESCE(SUM(e.salary), 0) + COALESCE(SUM(p.budget), 0)) / d.budget) * 100, 2) AS utilization_percent,
    CASE 
        WHEN ((COALESCE(SUM(e.salary), 0) + COALESCE(SUM(p.budget), 0)) / d.budget) > 0.9 THEN 'High Utilization'
        WHEN ((COALESCE(SUM(e.salary), 0) + COALESCE(SUM(p.budget), 0)) / d.budget) > 0.7 THEN 'Moderate Utilization'
        ELSE 'Low Utilization'
    END AS utilization_status
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id AND e.status = 'Active'
LEFT JOIN projects p ON d.dept_id = p.dept_id AND p.status IN ('Planning', 'In Progress')
GROUP BY d.dept_id, d.dept_name, d.budget;

-- Example queries using views:
/*
-- Get employee summary
SELECT * FROM v_employee_summary WHERE dept_name = 'Information Technology';

-- Check department statistics
SELECT * FROM v_department_stats ORDER BY employee_count DESC;

-- View project dashboard
SELECT * FROM v_project_dashboard WHERE project_health = 'Due Soon';

-- Check employee workload
SELECT * FROM v_employee_workload WHERE workload_status = 'Available';

-- Analyze salaries
SELECT * FROM v_salary_analysis ORDER BY salary_growth_percent DESC;

-- View project teams
SELECT * FROM v_project_teams WHERE project_name = 'Employee Portal Redesign';

-- Check management hierarchy
SELECT * FROM v_management_hierarchy WHERE management_level = 'Manager';

-- Review budget utilization
SELECT * FROM v_budget_utilization ORDER BY utilization_percent DESC;
*/