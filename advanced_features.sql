-- ADVANCED ENTERPRISE FEATURES FOR COGNIZANT INTERVIEW
USE employee_management_system;

-- 1. PERFORMANCE MANAGEMENT SYSTEM
CREATE TABLE performance_reviews (
    review_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_id INT NOT NULL,
    review_period VARCHAR(20),
    reviewer_id INT,
    technical_score DECIMAL(3,2),
    communication_score DECIMAL(3,2),
    leadership_score DECIMAL(3,2),
    overall_rating ENUM('Exceeds', 'Meets', 'Below', 'Unsatisfactory'),
    goals_achieved INT,
    total_goals INT,
    review_date DATE,
    comments TEXT,
    promotion_recommended BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id),
    FOREIGN KEY (reviewer_id) REFERENCES employees(emp_id)
);

-- 2. ATTENDANCE & LEAVE MANAGEMENT
CREATE TABLE attendance (
    attendance_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_id INT NOT NULL,
    date DATE NOT NULL,
    check_in TIME,
    check_out TIME,
    hours_worked DECIMAL(4,2),
    status ENUM('Present', 'Absent', 'Late', 'Half Day', 'WFH') DEFAULT 'Present',
    location VARCHAR(100),
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id),
    UNIQUE KEY unique_emp_date (emp_id, date)
);

CREATE TABLE leave_requests (
    leave_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_id INT NOT NULL,
    leave_type ENUM('Sick', 'Casual', 'Annual', 'Maternity', 'Emergency'),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    days_requested INT,
    reason TEXT,
    status ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending',
    approved_by INT,
    applied_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved_date TIMESTAMP NULL,
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id),
    FOREIGN KEY (approved_by) REFERENCES employees(emp_id)
);

-- 3. SKILLS & CERTIFICATIONS TRACKING
CREATE TABLE skills (
    skill_id INT PRIMARY KEY AUTO_INCREMENT,
    skill_name VARCHAR(100) NOT NULL UNIQUE,
    category VARCHAR(50),
    description TEXT
);

CREATE TABLE employee_skills (
    emp_id INT,
    skill_id INT,
    proficiency_level ENUM('Beginner', 'Intermediate', 'Advanced', 'Expert'),
    years_experience DECIMAL(3,1),
    last_used_date DATE,
    certified BOOLEAN DEFAULT FALSE,
    certification_date DATE,
    PRIMARY KEY (emp_id, skill_id),
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id),
    FOREIGN KEY (skill_id) REFERENCES skills(skill_id)
);

-- 4. PAYROLL & BENEFITS SYSTEM
CREATE TABLE payroll (
    payroll_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_id INT NOT NULL,
    pay_period_start DATE,
    pay_period_end DATE,
    base_salary DECIMAL(10,2),
    overtime_hours DECIMAL(5,2) DEFAULT 0,
    overtime_rate DECIMAL(8,2),
    bonus DECIMAL(10,2) DEFAULT 0,
    deductions DECIMAL(10,2) DEFAULT 0,
    tax_deduction DECIMAL(10,2),
    insurance_deduction DECIMAL(8,2),
    net_pay DECIMAL(10,2),
    pay_date DATE,
    status ENUM('Draft', 'Processed', 'Paid') DEFAULT 'Draft',
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);

-- 5. ADVANCED ANALYTICS VIEWS
CREATE VIEW v_employee_performance_dashboard AS
SELECT 
    e.emp_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.job_title,
    d.dept_name,
    pr.overall_rating,
    pr.technical_score,
    AVG(a.hours_worked) AS avg_daily_hours,
    COUNT(CASE WHEN a.status = 'Present' THEN 1 END) AS days_present,
    COUNT(CASE WHEN a.status = 'Absent' THEN 1 END) AS days_absent,
    (COUNT(CASE WHEN a.status = 'Present' THEN 1 END) / COUNT(a.attendance_id)) * 100 AS attendance_percentage,
    COUNT(es.skill_id) AS total_skills,
    COUNT(CASE WHEN es.proficiency_level IN ('Advanced', 'Expert') THEN 1 END) AS advanced_skills
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
LEFT JOIN performance_reviews pr ON e.emp_id = pr.emp_id 
    AND pr.review_date = (SELECT MAX(review_date) FROM performance_reviews WHERE emp_id = e.emp_id)
LEFT JOIN attendance a ON e.emp_id = a.emp_id 
    AND a.date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
LEFT JOIN employee_skills es ON e.emp_id = es.emp_id
WHERE e.status = 'Active'
GROUP BY e.emp_id, e.first_name, e.last_name, e.job_title, d.dept_name, pr.overall_rating, pr.technical_score;

-- 6. COMPLEX STORED PROCEDURES
DELIMITER //

CREATE PROCEDURE CalculateMonthlyPayroll(
    IN p_month INT,
    IN p_year INT
)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_emp_id INT;
    DECLARE v_base_salary DECIMAL(10,2);
    DECLARE v_overtime_hours DECIMAL(5,2);
    DECLARE v_total_hours DECIMAL(6,2);
    DECLARE v_net_pay DECIMAL(10,2);
    
    DECLARE emp_cursor CURSOR FOR 
        SELECT emp_id, salary FROM employees WHERE status = 'Active';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    START TRANSACTION;
    
    OPEN emp_cursor;
    
    payroll_loop: LOOP
        FETCH emp_cursor INTO v_emp_id, v_base_salary;
        IF done THEN
            LEAVE payroll_loop;
        END IF;
        
        -- Calculate total hours worked
        SELECT COALESCE(SUM(hours_worked), 0) INTO v_total_hours
        FROM attendance 
        WHERE emp_id = v_emp_id 
        AND MONTH(date) = p_month 
        AND YEAR(date) = p_year;
        
        -- Calculate overtime (assuming 8 hours/day, 22 working days)
        SET v_overtime_hours = GREATEST(0, v_total_hours - 176);
        
        -- Calculate net pay
        SET v_net_pay = v_base_salary + (v_overtime_hours * (v_base_salary/176) * 1.5) - (v_base_salary * 0.12);
        
        -- Insert payroll record
        INSERT INTO payroll (
            emp_id, pay_period_start, pay_period_end, base_salary, 
            overtime_hours, net_pay, status
        ) VALUES (
            v_emp_id,
            DATE(CONCAT(p_year, '-', p_month, '-01')),
            LAST_DAY(DATE(CONCAT(p_year, '-', p_month, '-01'))),
            v_base_salary,
            v_overtime_hours,
            v_net_pay,
            'Processed'
        );
        
    END LOOP;
    
    CLOSE emp_cursor;
    COMMIT;
    
    SELECT CONCAT('Payroll processed for ', ROW_COUNT(), ' employees') AS message;
END //

-- 7. MACHINE LEARNING READY ANALYTICS
CREATE PROCEDURE PredictEmployeeAttrition()
BEGIN
    SELECT 
        e.emp_id,
        CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
        DATEDIFF(CURDATE(), e.hire_date) / 365.25 AS tenure_years,
        e.salary,
        (SELECT AVG(salary) FROM employees WHERE dept_id = e.dept_id) AS dept_avg_salary,
        (e.salary / (SELECT AVG(salary) FROM employees WHERE dept_id = e.dept_id)) AS salary_ratio,
        COALESCE(pr.overall_rating, 'No Review') AS last_rating,
        COUNT(DISTINCT ep.project_id) AS project_count,
        AVG(a.hours_worked) AS avg_hours_worked,
        COUNT(lr.leave_id) AS leave_requests_count,
        CASE 
            WHEN DATEDIFF(CURDATE(), e.hire_date) < 365 AND e.salary < (SELECT AVG(salary) FROM employees WHERE dept_id = e.dept_id) * 0.9 THEN 'High Risk'
            WHEN COALESCE(pr.overall_rating, '') = 'Below' THEN 'High Risk'
            WHEN COUNT(lr.leave_id) > 10 THEN 'Medium Risk'
            ELSE 'Low Risk'
        END AS attrition_risk
    FROM employees e
    LEFT JOIN performance_reviews pr ON e.emp_id = pr.emp_id 
        AND pr.review_date = (SELECT MAX(review_date) FROM performance_reviews WHERE emp_id = e.emp_id)
    LEFT JOIN employee_projects ep ON e.emp_id = ep.emp_id
    LEFT JOIN attendance a ON e.emp_id = a.emp_id AND a.date >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
    LEFT JOIN leave_requests lr ON e.emp_id = lr.emp_id AND lr.applied_date >= DATE_SUB(CURDATE(), INTERVAL 365 DAY)
    WHERE e.status = 'Active'
    GROUP BY e.emp_id, e.first_name, e.last_name, e.salary, e.hire_date, pr.overall_rating
    ORDER BY 
        CASE 
            WHEN attrition_risk = 'High Risk' THEN 1
            WHEN attrition_risk = 'Medium Risk' THEN 2
            ELSE 3
        END;
END //

DELIMITER ;

-- 8. SAMPLE ADVANCED DATA
INSERT INTO skills (skill_name, category) VALUES
('Python', 'Programming'),
('Machine Learning', 'AI/ML'),
('AWS', 'Cloud'),
('Docker', 'DevOps'),
('React', 'Frontend'),
('Node.js', 'Backend'),
('SQL', 'Database'),
('Kubernetes', 'DevOps');

INSERT INTO employee_skills (emp_id, skill_id, proficiency_level, years_experience) VALUES
(2, 1, 'Expert', 5.0),
(2, 3, 'Advanced', 3.0),
(2, 4, 'Intermediate', 2.0),
(6, 5, 'Advanced', 4.0),
(6, 6, 'Expert', 6.0),
(10, 3, 'Expert', 4.0),
(10, 8, 'Advanced', 3.0);

INSERT INTO performance_reviews (emp_id, review_period, reviewer_id, technical_score, communication_score, leadership_score, overall_rating, goals_achieved, total_goals, review_date) VALUES
(2, '2023-Q2', 1, 9.2, 8.5, 8.8, 'Exceeds', 8, 10, '2023-07-15'),
(6, '2023-Q2', 2, 8.7, 9.0, 7.5, 'Meets', 7, 10, '2023-07-15'),
(3, '2023-Q2', 1, 8.9, 8.2, 8.0, 'Meets', 9, 10, '2023-07-15');

-- 9. REAL-TIME DASHBOARD QUERIES
-- Top Performers by Department
SELECT 
    d.dept_name,
    COUNT(e.emp_id) as total_employees,
    COUNT(CASE WHEN pr.overall_rating = 'Exceeds' THEN 1 END) as top_performers,
    ROUND((COUNT(CASE WHEN pr.overall_rating = 'Exceeds' THEN 1 END) / COUNT(e.emp_id)) * 100, 2) as top_performer_percentage
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id AND e.status = 'Active'
LEFT JOIN performance_reviews pr ON e.emp_id = pr.emp_id 
    AND pr.review_date = (SELECT MAX(review_date) FROM performance_reviews WHERE emp_id = e.emp_id)
GROUP BY d.dept_id, d.dept_name
ORDER BY top_performer_percentage DESC;