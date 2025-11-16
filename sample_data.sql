-- Sample Data for Employee Management System
USE employee_management_system;

-- Insert Departments
INSERT INTO departments (dept_name, location, budget) VALUES
('Human Resources', 'New York', 500000.00),
('Information Technology', 'San Francisco', 2000000.00),
('Finance', 'Chicago', 800000.00),
('Marketing', 'Los Angeles', 1200000.00),
('Operations', 'Dallas', 1500000.00);

-- Insert Employees
INSERT INTO employees (first_name, last_name, email, phone, hire_date, job_title, dept_id, salary) VALUES
('John', 'Smith', 'john.smith@company.com', '555-0101', '2020-01-15', 'HR Manager', 1, 75000.00),
('Sarah', 'Johnson', 'sarah.johnson@company.com', '555-0102', '2019-03-20', 'Senior Developer', 2, 95000.00),
('Michael', 'Brown', 'michael.brown@company.com', '555-0103', '2021-06-10', 'Financial Analyst', 3, 65000.00),
('Emily', 'Davis', 'emily.davis@company.com', '555-0104', '2020-09-05', 'Marketing Specialist', 4, 58000.00),
('David', 'Wilson', 'david.wilson@company.com', '555-0105', '2018-11-12', 'Operations Manager', 5, 82000.00),
('Lisa', 'Anderson', 'lisa.anderson@company.com', '555-0106', '2022-02-28', 'Software Engineer', 2, 78000.00),
('Robert', 'Taylor', 'robert.taylor@company.com', '555-0107', '2021-04-18', 'HR Specialist', 1, 52000.00),
('Jennifer', 'Martinez', 'jennifer.martinez@company.com', '555-0108', '2020-07-22', 'Senior Analyst', 3, 72000.00),
('William', 'Garcia', 'william.garcia@company.com', '555-0109', '2019-12-03', 'Marketing Manager', 4, 85000.00),
('Amanda', 'Rodriguez', 'amanda.rodriguez@company.com', '555-0110', '2021-08-15', 'DevOps Engineer', 2, 88000.00);

-- Update manager relationships
UPDATE employees SET manager_id = 1 WHERE emp_id = 7; -- Robert reports to John
UPDATE employees SET manager_id = 2 WHERE emp_id IN (6, 10); -- Lisa and Amanda report to Sarah
UPDATE employees SET manager_id = 3 WHERE emp_id = 8; -- Jennifer reports to Michael
UPDATE employees SET manager_id = 9 WHERE emp_id = 4; -- Emily reports to William

-- Update department heads
UPDATE departments SET dept_head_id = 1 WHERE dept_id = 1; -- John heads HR
UPDATE departments SET dept_head_id = 2 WHERE dept_id = 2; -- Sarah heads IT
UPDATE departments SET dept_head_id = 3 WHERE dept_id = 3; -- Michael heads Finance
UPDATE departments SET dept_head_id = 9 WHERE dept_id = 4; -- William heads Marketing
UPDATE departments SET dept_head_id = 5 WHERE dept_id = 5; -- David heads Operations

-- Insert Projects
INSERT INTO projects (project_name, description, start_date, end_date, budget, status, dept_id, project_manager_id) VALUES
('Employee Portal Redesign', 'Modernize the employee self-service portal', '2023-01-15', '2023-06-30', 150000.00, 'Completed', 2, 2),
('Financial Reporting System', 'Implement new financial reporting dashboard', '2023-03-01', '2023-09-15', 200000.00, 'In Progress', 3, 3),
('Marketing Campaign Q3', 'Launch new product marketing campaign', '2023-07-01', '2023-09-30', 80000.00, 'In Progress', 4, 9),
('HR Management System', 'Upgrade HR management software', '2023-02-15', '2023-08-31', 120000.00, 'In Progress', 1, 1),
('Supply Chain Optimization', 'Optimize supply chain processes', '2023-04-01', '2023-12-31', 300000.00, 'Planning', 5, 5);

-- Insert Employee Project Assignments
INSERT INTO employee_projects (emp_id, project_id, role, allocation_percentage, start_date) VALUES
(2, 1, 'Lead Developer', 80.00, '2023-01-15'),
(6, 1, 'Frontend Developer', 100.00, '2023-01-20'),
(10, 1, 'DevOps Engineer', 50.00, '2023-02-01'),
(3, 2, 'Project Manager', 90.00, '2023-03-01'),
(8, 2, 'Business Analyst', 75.00, '2023-03-15'),
(9, 3, 'Campaign Manager', 100.00, '2023-07-01'),
(4, 3, 'Marketing Specialist', 80.00, '2023-07-01'),
(1, 4, 'Project Sponsor', 25.00, '2023-02-15'),
(7, 4, 'HR Coordinator', 60.00, '2023-02-15'),
(5, 5, 'Operations Lead', 70.00, '2023-04-01');

-- Insert Salary History
INSERT INTO salaries (emp_id, salary_amount, effective_date, salary_type) VALUES
(1, 70000.00, '2020-01-15', 'Base'),
(1, 75000.00, '2021-01-15', 'Base'),
(2, 85000.00, '2019-03-20', 'Base'),
(2, 90000.00, '2020-03-20', 'Base'),
(2, 95000.00, '2021-03-20', 'Base'),
(3, 60000.00, '2021-06-10', 'Base'),
(3, 65000.00, '2022-06-10', 'Base'),
(4, 55000.00, '2020-09-05', 'Base'),
(4, 58000.00, '2021-09-05', 'Base'),
(5, 78000.00, '2018-11-12', 'Base'),
(5, 82000.00, '2020-11-12', 'Base');