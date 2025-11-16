-- Database Triggers for Employee Management System
USE employee_management_system;

DELIMITER //

-- 1. Trigger to automatically update employee salary in salaries table when employee salary is updated
CREATE TRIGGER tr_employee_salary_update
AFTER UPDATE ON employees
FOR EACH ROW
BEGIN
    -- Only insert if salary actually changed
    IF OLD.salary != NEW.salary THEN
        INSERT INTO salaries (emp_id, salary_amount, effective_date, salary_type)
        VALUES (NEW.emp_id, NEW.salary, CURDATE(), 'Base');
    END IF;
END //

-- 2. Trigger to prevent deletion of employees who are project managers
CREATE TRIGGER tr_prevent_manager_deletion
BEFORE DELETE ON employees
FOR EACH ROW
BEGIN
    DECLARE v_project_count INT DEFAULT 0;
    
    SELECT COUNT(*) INTO v_project_count
    FROM projects
    WHERE project_manager_id = OLD.emp_id AND status IN ('Planning', 'In Progress');
    
    IF v_project_count > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Cannot delete employee who is managing active projects';
    END IF;
END //

-- 3. Trigger to validate project dates
CREATE TRIGGER tr_validate_project_dates
BEFORE INSERT ON projects
FOR EACH ROW
BEGIN
    IF NEW.end_date IS NOT NULL AND NEW.end_date <= NEW.start_date THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Project end date must be after start date';
    END IF;
END //

-- 4. Trigger to update project dates validation on update
CREATE TRIGGER tr_validate_project_dates_update
BEFORE UPDATE ON projects
FOR EACH ROW
BEGIN
    IF NEW.end_date IS NOT NULL AND NEW.end_date <= NEW.start_date THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Project end date must be after start date';
    END IF;
END //

-- 5. Trigger to validate employee allocation doesn't exceed 100%
CREATE TRIGGER tr_validate_allocation
BEFORE INSERT ON employee_projects
FOR EACH ROW
BEGIN
    DECLARE v_total_allocation DECIMAL(5,2) DEFAULT 0;
    
    SELECT COALESCE(SUM(allocation_percentage), 0) INTO v_total_allocation
    FROM employee_projects ep
    JOIN projects p ON ep.project_id = p.project_id
    WHERE ep.emp_id = NEW.emp_id 
    AND (ep.end_date IS NULL OR ep.end_date > CURDATE())
    AND p.status IN ('Planning', 'In Progress');
    
    IF (v_total_allocation + NEW.allocation_percentage) > 100 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Total employee allocation cannot exceed 100%';
    END IF;
END //

-- 6. Trigger to validate allocation update
CREATE TRIGGER tr_validate_allocation_update
BEFORE UPDATE ON employee_projects
FOR EACH ROW
BEGIN
    DECLARE v_total_allocation DECIMAL(5,2) DEFAULT 0;
    
    SELECT COALESCE(SUM(allocation_percentage), 0) INTO v_total_allocation
    FROM employee_projects ep
    JOIN projects p ON ep.project_id = p.project_id
    WHERE ep.emp_id = NEW.emp_id 
    AND ep.project_id != NEW.project_id
    AND (ep.end_date IS NULL OR ep.end_date > CURDATE())
    AND p.status IN ('Planning', 'In Progress');
    
    IF (v_total_allocation + NEW.allocation_percentage) > 100 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Total employee allocation cannot exceed 100%';
    END IF;
END //

-- 7. Trigger to prevent salary decrease without proper authorization
CREATE TRIGGER tr_prevent_salary_decrease
BEFORE UPDATE ON employees
FOR EACH ROW
BEGIN
    -- Prevent salary decrease of more than 10% without special handling
    IF NEW.salary < (OLD.salary * 0.9) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Salary decrease of more than 10% requires special authorization';
    END IF;
END //

-- 8. Trigger to automatically set employee status to inactive when terminated
CREATE TRIGGER tr_auto_inactive_status
BEFORE UPDATE ON employees
FOR EACH ROW
BEGIN
    IF NEW.status = 'Terminated' THEN
        -- End all active project assignments
        UPDATE employee_projects 
        SET end_date = CURDATE() 
        WHERE emp_id = NEW.emp_id AND end_date IS NULL;
    END IF;
END //

-- 9. Trigger to validate department budget allocation
CREATE TRIGGER tr_validate_department_budget
BEFORE UPDATE ON departments
FOR EACH ROW
BEGIN
    DECLARE v_total_salaries DECIMAL(15,2) DEFAULT 0;
    
    SELECT COALESCE(SUM(salary), 0) INTO v_total_salaries
    FROM employees
    WHERE dept_id = NEW.dept_id AND status = 'Active';
    
    -- Budget should be at least 1.5 times the total salaries for operational costs
    IF NEW.budget < (v_total_salaries * 1.5) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Department budget should be at least 1.5 times total employee salaries';
    END IF;
END //

-- 10. Trigger to log important changes (audit trail)
CREATE TABLE audit_log (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    table_name VARCHAR(50),
    operation VARCHAR(10),
    record_id INT,
    old_values JSON,
    new_values JSON,
    changed_by VARCHAR(100),
    change_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER tr_audit_employee_changes
AFTER UPDATE ON employees
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, operation, record_id, old_values, new_values, changed_by)
    VALUES (
        'employees',
        'UPDATE',
        NEW.emp_id,
        JSON_OBJECT(
            'salary', OLD.salary,
            'job_title', OLD.job_title,
            'dept_id', OLD.dept_id,
            'status', OLD.status
        ),
        JSON_OBJECT(
            'salary', NEW.salary,
            'job_title', NEW.job_title,
            'dept_id', NEW.dept_id,
            'status', NEW.status
        ),
        USER()
    );
END //

DELIMITER ;

-- Example of trigger testing:
/*
-- Test salary update trigger
UPDATE employees SET salary = 80000 WHERE emp_id = 1;

-- Test allocation validation (this should fail if total > 100%)
INSERT INTO employee_projects (emp_id, project_id, role, allocation_percentage, start_date)
VALUES (2, 2, 'Developer', 50.00, '2023-08-01');

-- Test project date validation (this should fail)
INSERT INTO projects (project_name, start_date, end_date, dept_id)
VALUES ('Invalid Project', '2023-12-01', '2023-11-01', 1);

-- View audit log
SELECT * FROM audit_log ORDER BY change_timestamp DESC;
*/