-- QUICK DEMO VERSION FOR ONLINE TESTING
-- Copy this to DB Fiddle LEFT PANEL

-- Basic Tables
CREATE TABLE departments (
    dept_id INT PRIMARY KEY AUTO_INCREMENT,
    dept_name VARCHAR(100) NOT NULL,
    location VARCHAR(100),
    budget DECIMAL(15,2)
);

CREATE TABLE employees (
    emp_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    hire_date DATE NOT NULL,
    job_title VARCHAR(100) NOT NULL,
    dept_id INT,
    salary DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'Active',
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE projects (
    project_id INT PRIMARY KEY AUTO_INCREMENT,
    project_name VARCHAR(200) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    budget DECIMAL(15,2),
    status VARCHAR(20) DEFAULT 'Planning',
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE employee_projects (
    emp_id INT,
    project_id INT,
    role VARCHAR(100),
    allocation_percentage DECIMAL(5,2) DEFAULT 100.00,
    start_date DATE NOT NULL,
    PRIMARY KEY (emp_id, project_id),
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id),
    FOREIGN KEY (project_id) REFERENCES projects(project_id)
);

CREATE TABLE performance_reviews (
    review_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_id INT NOT NULL,
    technical_score DECIMAL(3,2),
    overall_rating VARCHAR(20),
    review_date DATE,
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);

-- Sample Data
INSERT INTO departments (dept_name, location, budget) VALUES
('Information Technology', 'Bangalore', 2000000.00),
('Human Resources', 'Mumbai', 500000.00),
('Finance', 'Delhi', 800000.00),
('Marketing', 'Pune', 1200000.00);

INSERT INTO employees (first_name, last_name, email, hire_date, job_title, dept_id, salary) VALUES
('Rahul', 'Sharma', 'rahul.sharma@company.com', '2020-01-15', 'Senior Developer', 1, 95000.00),
('Priya', 'Singh', 'priya.singh@company.com', '2019-03-20', 'Tech Lead', 1, 120000.00),
('Amit', 'Kumar', 'amit.kumar@company.com', '2021-06-10', 'Financial Analyst', 3, 65000.00),
('Sneha', 'Patel', 'sneha.patel@company.com', '2020-09-05', 'HR Manager', 2, 75000.00),
('Vikash', 'Gupta', 'vikash.gupta@company.com', '2018-11-12', 'Marketing Head', 4, 110000.00),
('Anita', 'Verma', 'anita.verma@company.com', '2022-02-28', 'Software Engineer', 1, 78000.00),
('Rohit', 'Jain', 'rohit.jain@company.com', '2021-04-18', 'DevOps Engineer', 1, 88000.00);

INSERT INTO projects (project_name, start_date, end_date, budget, status, dept_id) VALUES
('E-commerce Platform', '2023-01-15', '2023-12-30', 1500000.00, 'In Progress', 1),
('HR Management System', '2023-03-01', '2023-09-15', 800000.00, 'In Progress', 2),
('Financial Dashboard', '2023-07-01', '2023-11-30', 600000.00, 'Planning', 3),
('Digital Marketing Campaign', '2023-02-15', '2023-08-31', 400000.00, 'Completed', 4);

INSERT INTO employee_projects (emp_id, project_id, role, allocation_percentage, start_date) VALUES
(1, 1, 'Backend Developer', 80.00, '2023-01-15'),
(2, 1, 'Tech Lead', 90.00, '2023-01-15'),
(6, 1, 'Frontend Developer', 100.00, '2023-01-20'),
(7, 1, 'DevOps Engineer', 60.00, '2023-02-01'),
(4, 2, 'Project Manager', 75.00, '2023-03-01'),
(5, 4, 'Campaign Manager', 100.00, '2023-02-15');

INSERT INTO performance_reviews (emp_id, technical_score, overall_rating, review_date) VALUES
(1, 8.5, 'Exceeds', '2023-07-15'),
(2, 9.2, 'Exceeds', '2023-07-15'),
(3, 7.8, 'Meets', '2023-07-15'),
(4, 8.0, 'Meets', '2023-07-15'),
(5, 8.7, 'Exceeds', '2023-07-15');