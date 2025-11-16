-- ADVANCED DATA ANALYTICS & BUSINESS INTELLIGENCE QUERIES
USE employee_management_system;

-- 1. EMPLOYEE RETENTION ANALYSIS WITH COHORT ANALYSIS
WITH hire_cohorts AS (
    SELECT 
        DATE_FORMAT(hire_date, '%Y-%m') as hire_cohort,
        COUNT(*) as hired_count
    FROM employees 
    GROUP BY DATE_FORMAT(hire_date, '%Y-%m')
),
retention_data AS (
    SELECT 
        DATE_FORMAT(e.hire_date, '%Y-%m') as hire_cohort,
        TIMESTAMPDIFF(MONTH, e.hire_date, CURDATE()) as months_since_hire,
        COUNT(CASE WHEN e.status = 'Active' THEN 1 END) as still_active,
        COUNT(*) as total_hired
    FROM employees e
    GROUP BY DATE_FORMAT(e.hire_date, '%Y-%m'), TIMESTAMPDIFF(MONTH, e.hire_date, CURDATE())
)
SELECT 
    rd.hire_cohort,
    rd.months_since_hire,
    rd.still_active,
    rd.total_hired,
    ROUND((rd.still_active / rd.total_hired) * 100, 2) as retention_rate
FROM retention_data rd
ORDER BY rd.hire_cohort, rd.months_since_hire;

-- 2. PREDICTIVE SALARY MODELING
WITH salary_progression AS (
    SELECT 
        e.emp_id,
        e.job_title,
        e.dept_id,
        DATEDIFF(CURDATE(), e.hire_date) / 365.25 as years_experience,
        e.salary as current_salary,
        LAG(s.salary_amount) OVER (PARTITION BY e.emp_id ORDER BY s.effective_date) as previous_salary,
        s.salary_amount,
        s.effective_date,
        LEAD(s.effective_date) OVER (PARTITION BY e.emp_id ORDER BY s.effective_date) as next_review_date
    FROM employees e
    LEFT JOIN salaries s ON e.emp_id = s.emp_id
),
salary_growth_rates AS (
    SELECT 
        job_title,
        dept_id,
        AVG(years_experience) as avg_experience,
        AVG(current_salary) as avg_current_salary,
        AVG(CASE 
            WHEN previous_salary IS NOT NULL 
            THEN ((salary_amount - previous_salary) / previous_salary) * 100 
        END) as avg_growth_rate
    FROM salary_progression
    GROUP BY job_title, dept_id
)
SELECT 
    e.emp_id,
    CONCAT(e.first_name, ' ', e.last_name) as employee_name,
    e.job_title,
    d.dept_name,
    e.salary as current_salary,
    sgr.avg_growth_rate,
    ROUND(e.salary * (1 + (sgr.avg_growth_rate / 100)), 2) as predicted_next_salary,
    DATE_ADD(CURDATE(), INTERVAL 12 MONTH) as predicted_review_date
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
LEFT JOIN salary_growth_rates sgr ON e.job_title = sgr.job_title AND e.dept_id = sgr.dept_id
WHERE e.status = 'Active'
ORDER BY predicted_next_salary DESC;

-- 3. ADVANCED PROJECT PROFITABILITY ANALYSIS
WITH project_costs AS (
    SELECT 
        p.project_id,
        p.project_name,
        p.budget,
        SUM((e.salary / 12) * (ep.allocation_percentage / 100) * 
            DATEDIFF(COALESCE(ep.end_date, CURDATE()), ep.start_date) / 30) as labor_cost,
        COUNT(DISTINCT ep.emp_id) as team_size,
        AVG(ep.allocation_percentage) as avg_allocation
    FROM projects p
    LEFT JOIN employee_projects ep ON p.project_id = ep.project_id
    LEFT JOIN employees e ON ep.emp_id = e.emp_id
    GROUP BY p.project_id, p.project_name, p.budget
),
project_roi AS (
    SELECT 
        *,
        budget - labor_cost as profit_margin,
        CASE 
            WHEN labor_cost > 0 THEN ((budget - labor_cost) / labor_cost) * 100
            ELSE 0
        END as roi_percentage,
        CASE 
            WHEN budget > 0 THEN (labor_cost / budget) * 100
            ELSE 0
        END as cost_utilization
    FROM project_costs
)
SELECT 
    project_name,
    budget,
    ROUND(labor_cost, 2) as actual_labor_cost,
    ROUND(profit_margin, 2) as profit_margin,
    ROUND(roi_percentage, 2) as roi_percentage,
    ROUND(cost_utilization, 2) as cost_utilization_percent,
    team_size,
    ROUND(avg_allocation, 2) as avg_team_allocation,
    CASE 
        WHEN roi_percentage > 50 THEN 'Highly Profitable'
        WHEN roi_percentage > 20 THEN 'Profitable'
        WHEN roi_percentage > 0 THEN 'Break Even'
        ELSE 'Loss Making'
    END as profitability_status
FROM project_roi
ORDER BY roi_percentage DESC;

-- 4. WORKFORCE OPTIMIZATION ANALYSIS
WITH workload_analysis AS (
    SELECT 
        e.emp_id,
        CONCAT(e.first_name, ' ', e.last_name) as employee_name,
        e.job_title,
        d.dept_name,
        e.salary,
        COALESCE(SUM(ep.allocation_percentage), 0) as current_allocation,
        COUNT(ep.project_id) as active_projects,
        AVG(CASE WHEN pr.overall_rating = 'Exceeds' THEN 5
                 WHEN pr.overall_rating = 'Meets' THEN 4
                 WHEN pr.overall_rating = 'Below' THEN 2
                 ELSE 3 END) as performance_score
    FROM employees e
    LEFT JOIN departments d ON e.dept_id = d.dept_id
    LEFT JOIN employee_projects ep ON e.emp_id = ep.emp_id 
        AND (ep.end_date IS NULL OR ep.end_date > CURDATE())
    LEFT JOIN projects p ON ep.project_id = p.project_id 
        AND p.status IN ('Planning', 'In Progress')
    LEFT JOIN performance_reviews pr ON e.emp_id = pr.emp_id
    WHERE e.status = 'Active'
    GROUP BY e.emp_id, e.first_name, e.last_name, e.job_title, d.dept_name, e.salary
),
optimization_recommendations AS (
    SELECT 
        *,
        100 - current_allocation as available_capacity,
        salary / NULLIF(current_allocation, 0) * 100 as cost_per_full_allocation,
        CASE 
            WHEN current_allocation < 50 AND performance_score >= 4 THEN 'Underutilized High Performer'
            WHEN current_allocation > 100 THEN 'Overallocated - Risk of Burnout'
            WHEN current_allocation < 30 THEN 'Significantly Underutilized'
            WHEN current_allocation BETWEEN 80 AND 100 AND performance_score >= 4 THEN 'Optimally Utilized'
            ELSE 'Standard Allocation'
        END as optimization_category
    FROM workload_analysis
)
SELECT 
    employee_name,
    job_title,
    dept_name,
    ROUND(current_allocation, 2) as current_allocation_percent,
    ROUND(available_capacity, 2) as available_capacity_percent,
    active_projects,
    ROUND(performance_score, 2) as performance_score,
    ROUND(cost_per_full_allocation, 2) as cost_efficiency_score,
    optimization_category,
    CASE 
        WHEN optimization_category = 'Underutilized High Performer' 
        THEN 'Assign to high-priority projects'
        WHEN optimization_category = 'Overallocated - Risk of Burnout' 
        THEN 'Reduce workload or hire additional resources'
        WHEN optimization_category = 'Significantly Underutilized' 
        THEN 'Review role requirements or reassign'
        ELSE 'Maintain current allocation'
    END as recommendation
FROM optimization_recommendations
ORDER BY 
    CASE optimization_category
        WHEN 'Overallocated - Risk of Burnout' THEN 1
        WHEN 'Underutilized High Performer' THEN 2
        WHEN 'Significantly Underutilized' THEN 3
        ELSE 4
    END, performance_score DESC;

-- 5. SKILLS GAP ANALYSIS FOR STRATEGIC PLANNING
WITH skill_demand AS (
    SELECT 
        s.skill_name,
        s.category,
        COUNT(es.emp_id) as employees_with_skill,
        AVG(CASE 
            WHEN es.proficiency_level = 'Expert' THEN 4
            WHEN es.proficiency_level = 'Advanced' THEN 3
            WHEN es.proficiency_level = 'Intermediate' THEN 2
            ELSE 1
        END) as avg_proficiency_score,
        COUNT(CASE WHEN es.proficiency_level IN ('Advanced', 'Expert') THEN 1 END) as advanced_practitioners
    FROM skills s
    LEFT JOIN employee_skills es ON s.skill_id = es.skill_id
    LEFT JOIN employees e ON es.emp_id = e.emp_id AND e.status = 'Active'
    GROUP BY s.skill_id, s.skill_name, s.category
),
department_skill_matrix AS (
    SELECT 
        d.dept_name,
        s.skill_name,
        COUNT(es.emp_id) as dept_skill_count,
        COUNT(e.emp_id) as total_dept_employees,
        ROUND((COUNT(es.emp_id) / COUNT(e.emp_id)) * 100, 2) as skill_penetration_rate
    FROM departments d
    CROSS JOIN skills s
    LEFT JOIN employees e ON d.dept_id = e.dept_id AND e.status = 'Active'
    LEFT JOIN employee_skills es ON e.emp_id = es.emp_id AND s.skill_id = es.skill_id
    GROUP BY d.dept_id, d.dept_name, s.skill_id, s.skill_name
)
SELECT 
    sd.skill_name,
    sd.category,
    sd.employees_with_skill,
    sd.advanced_practitioners,
    ROUND(sd.avg_proficiency_score, 2) as avg_proficiency,
    CASE 
        WHEN sd.employees_with_skill = 0 THEN 'Critical Gap'
        WHEN sd.advanced_practitioners < 2 THEN 'Skill Shortage'
        WHEN sd.avg_proficiency_score < 2.5 THEN 'Training Needed'
        ELSE 'Adequate Coverage'
    END as skill_status,
    CASE 
        WHEN sd.employees_with_skill = 0 THEN 'Immediate hiring or training required'
        WHEN sd.advanced_practitioners < 2 THEN 'Develop internal expertise or hire specialists'
        WHEN sd.avg_proficiency_score < 2.5 THEN 'Implement skill development programs'
        ELSE 'Maintain current skill levels'
    END as recommendation
FROM skill_demand sd
ORDER BY 
    CASE 
        WHEN sd.employees_with_skill = 0 THEN 1
        WHEN sd.advanced_practitioners < 2 THEN 2
        WHEN sd.avg_proficiency_score < 2.5 THEN 3
        ELSE 4
    END, sd.skill_name;

-- 6. EXECUTIVE DASHBOARD - KEY METRICS
SELECT 
    'Workforce Overview' as metric_category,
    JSON_OBJECT(
        'total_employees', (SELECT COUNT(*) FROM employees WHERE status = 'Active'),
        'total_departments', (SELECT COUNT(*) FROM departments),
        'active_projects', (SELECT COUNT(*) FROM projects WHERE status IN ('Planning', 'In Progress')),
        'avg_salary', (SELECT ROUND(AVG(salary), 2) FROM employees WHERE status = 'Active'),
        'total_payroll_monthly', (SELECT ROUND(SUM(salary), 2) FROM employees WHERE status = 'Active')
    ) as metrics

UNION ALL

SELECT 
    'Performance Metrics' as metric_category,
    JSON_OBJECT(
        'top_performers', (SELECT COUNT(*) FROM performance_reviews pr 
                          JOIN employees e ON pr.emp_id = e.emp_id 
                          WHERE e.status = 'Active' AND pr.overall_rating = 'Exceeds'),
        'avg_performance_score', (SELECT ROUND(AVG(
            CASE pr.overall_rating
                WHEN 'Exceeds' THEN 5
                WHEN 'Meets' THEN 4
                WHEN 'Below' THEN 2
                ELSE 3
            END), 2) FROM performance_reviews pr 
            JOIN employees e ON pr.emp_id = e.emp_id 
            WHERE e.status = 'Active'),
        'employees_needing_improvement', (SELECT COUNT(*) FROM performance_reviews pr 
                                        JOIN employees e ON pr.emp_id = e.emp_id 
                                        WHERE e.status = 'Active' AND pr.overall_rating = 'Below')
    ) as metrics

UNION ALL

SELECT 
    'Project Health' as metric_category,
    JSON_OBJECT(
        'projects_on_track', (SELECT COUNT(*) FROM projects WHERE status = 'In Progress'),
        'projects_overdue', (SELECT COUNT(*) FROM projects 
                           WHERE status IN ('Planning', 'In Progress') 
                           AND end_date < CURDATE()),
        'total_project_budget', (SELECT ROUND(SUM(budget), 2) FROM projects 
                               WHERE status IN ('Planning', 'In Progress')),
        'avg_team_size', (SELECT ROUND(AVG(team_count), 2) FROM 
                         (SELECT COUNT(ep.emp_id) as team_count 
                          FROM projects p 
                          LEFT JOIN employee_projects ep ON p.project_id = ep.project_id 
                          WHERE p.status IN ('Planning', 'In Progress') 
                          GROUP BY p.project_id) as team_sizes)
    ) as metrics;