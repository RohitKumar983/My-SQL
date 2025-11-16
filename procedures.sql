-- Stored Procedures and Functions for Employee Management System
USE employee_management_system;

DELIMITER //

-- 1. Procedure to Add New Employee
CREATE PROCEDURE AddEmployee(
    IN p_first_name VARCHAR(50),
    IN p_last_name VARCHAR(50),
    IN p_email VARCHAR(100),
    IN p_phone VARCHAR(15),
    IN p_job_title VARCHAR(100),
    IN p_dept_id INT,
    IN p_manager_id INT,
    IN p_salary DECIMAL(10,2)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    INSERT INTO employees (first_name, last_name, email, phone, hire_date, job_title, dept_id, manager_id, salary)
    VALUES (p_first_name, p_last_name, p_email, p_phone, CURDATE(), p_job_title, p_dept_id, p_manager_id, p_salary);
    
    -- Add initial salary record
    INSERT INTO salaries (emp_id, salary_amount, effective_date, salary_type)
    VALUES (LAST_INSERT_ID(), p_salary, CURDATE(), 'Base');
    
    COMMIT;
    
    SELECT CONCAT('Employee ', p_first_name, ' ', p_last_name, ' added successfully with ID: ', LAST_INSERT_ID()) AS message;
END //

-- 2. Procedure to Update Employee Salary
CREATE PROCEDURE UpdateEmployeeSalary(
    IN p_emp_id INT,
    IN p_new_salary DECIMAL(10,2),
    IN p_effective_date DATE
)
BEGIN
    DECLARE v_current_salary DECIMAL(10,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Get current salary
    SELECT salary INTO v_current_salary FROM employees WHERE emp_id = p_emp_id;
    
    -- Update employee table
    UPDATE employees SET salary = p_new_salary WHERE emp_id = p_emp_id;
    
    -- Add salary history record
    INSERT INTO salaries (emp_id, salary_amount, effective_date, salary_type)
    VALUES (p_emp_id, p_new_salary, p_effective_date, 'Base');
    
    COMMIT;
    
    SELECT CONCAT('Salary updated from $', v_current_salary, ' to $', p_new_salary, ' for employee ID: ', p_emp_id) AS message;
END //

-- 3. Procedure to Assign Employee to Project
CREATE PROCEDURE AssignEmployeeToProject(
    IN p_emp_id INT,
    IN p_project_id INT,
    IN p_role VARCHAR(100),
    IN p_allocation DECIMAL(5,2),
    IN p_start_date DATE
)
BEGIN
    DECLARE v_total_allocation DECIMAL(5,2) DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Check current total allocation for employee
    SELECT COALESCE(SUM(allocation_percentage), 0) INTO v_total_allocation
    FROM employee_projects 
    WHERE emp_id = p_emp_id AND (end_date IS NULL OR end_date > CURDATE());
    
    -- Check if new allocation would exceed 100%
    IF (v_total_allocation + p_allocation) > 100 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Total allocation cannot exceed 100%';
    END IF;
    
    INSERT INTO employee_projects (emp_id, project_id, role, allocation_percentage, start_date)
    VALUES (p_emp_id, p_project_id, p_role, p_allocation, p_start_date);
    
    COMMIT;
    
    SELECT CONCAT('Employee assigned to project successfully. Total allocation: ', (v_total_allocation + p_allocation), '%') AS message;
END //

-- 4. Function to Calculate Employee Bonus
CREATE FUNCTION CalculateBonus(p_emp_id INT, p_performance_rating DECIMAL(3,2))
RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_salary DECIMAL(10,2);
    DECLARE v_bonus DECIMAL(10,2);
    DECLARE v_years_employed DECIMAL(4,2);
    
    -- Get employee salary and years of employment
    SELECT 
        salary,
        ROUND(DATEDIFF(CURDATE(), hire_date) / 365.25, 2)
    INTO v_salary, v_years_employed
    FROM employees 
    WHERE emp_id = p_emp_id;
    
    -- Calculate bonus based on performance and tenure
    SET v_bonus = v_salary * (p_performance_rating / 10) * 0.1;
    
    -- Add tenure bonus
    IF v_years_employed >= 5 THEN
        SET v_bonus = v_bonus * 1.2;
    ELSEIF v_years_employed >= 2 THEN
        SET v_bonus = v_bonus * 1.1;
    END IF;
    
    RETURN v_bonus;
END //

-- 5. Procedure to Generate Department Report
CREATE PROCEDURE GenerateDepartmentReport(IN p_dept_id INT)
BEGIN
    SELECT 
        d.dept_name,
        d.location,
        d.budget,
        COUNT(e.emp_id) as employee_count,
        ROUND(AVG(e.salary), 2) as avg_salary,
        SUM(e.salary) as total_salary_cost,
        ROUND((SUM(e.salary) / d.budget) * 100, 2) as salary_budget_ratio,
        COUNT(p.project_id) as active_projects
    FROM departments d
    LEFT JOIN employees e ON d.dept_id = e.dept_id AND e.status = 'Active'
    LEFT JOIN projects p ON d.dept_id = p.dept_id AND p.status IN ('Planning', 'In Progress')
    WHERE d.dept_id = p_dept_id
    GROUP BY d.dept_id;
    
    -- Employee details for the department
    SELECT 
        CONCAT(e.first_name, ' ', e.last_name) as employee_name,
        e.job_title,
        e.salary,
        e.hire_date,
        ROUND(DATEDIFF(CURDATE(), e.hire_date) / 365.25, 1) as years_employed
    FROM employees e
    WHERE e.dept_id = p_dept_id AND e.status = 'Active'
    ORDER BY e.salary DESC;
END //

-- 6. Function to Get Employee Utilization
CREATE FUNCTION GetEmployeeUtilization(p_emp_id INT)
RETURNS DECIMAL(5,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_utilization DECIMAL(5,2) DEFAULT 0;
    
    SELECT COALESCE(SUM(allocation_percentage), 0)
    INTO v_utilization
    FROM employee_projects ep
    JOIN projects p ON ep.project_id = p.project_id
    WHERE ep.emp_id = p_emp_id 
    AND (ep.end_date IS NULL OR ep.end_date > CURDATE())
    AND p.status IN ('Planning', 'In Progress');
    
    RETURN v_utilization;
END //

-- 7. Procedure to Close Project
CREATE PROCEDURE CloseProject(
    IN p_project_id INT,
    IN p_end_date DATE
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Update project status
    UPDATE projects 
    SET status = 'Completed', end_date = p_end_date 
    WHERE project_id = p_project_id;
    
    -- End all employee assignments
    UPDATE employee_projects 
    SET end_date = p_end_date 
    WHERE project_id = p_project_id AND end_date IS NULL;
    
    COMMIT;
    
    SELECT CONCAT('Project ID ', p_project_id, ' closed successfully on ', p_end_date) AS message;
END //

DELIMITER ;

-- Example usage of procedures and functions:
/*
-- Add new employee
CALL AddEmployee('Jane', 'Doe', 'jane.doe@company.com', '555-0111', 'Software Engineer', 2, 2, 80000.00);

-- Update salary
CALL UpdateEmployeeSalary(1, 78000.00, '2023-01-01');

-- Assign to project
CALL AssignEmployeeToProject(1, 1, 'Team Lead', 75.00, '2023-01-15');

-- Calculate bonus
SELECT CalculateBonus(1, 8.5) AS bonus_amount;

-- Generate department report
CALL GenerateDepartmentReport(2);

-- Check employee utilization
SELECT GetEmployeeUtilization(2) AS utilization_percentage;

-- Close project
CALL CloseProject(1, '2023-06-30');
*/