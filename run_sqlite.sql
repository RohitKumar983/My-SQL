-- SQLite Compatible Version (Simplified)
-- Run this in SQLite Browser or online SQLite tool

-- Create Tables
CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY AUTOINCREMENT,
    dept_name TEXT NOT NULL UNIQUE,
    dept_head_id INTEGER,
    location TEXT,
    budget REAL,
    created_date DATE DEFAULT (date('now'))
);

CREATE TABLE employees (
    emp_id INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    hire_date DATE NOT NULL,
    job_title TEXT NOT NULL,
    dept_id INTEGER,
    manager_id INTEGER,
    salary REAL NOT NULL,
    status TEXT DEFAULT 'Active',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id),
    FOREIGN KEY (manager_id) REFERENCES employees(emp_id)
);

-- Insert Sample Data
INSERT INTO departments (dept_name, location, budget) VALUES
('Human Resources', 'New York', 500000.00),
('Information Technology', 'San Francisco', 2000000.00),
('Finance', 'Chicago', 800000.00);

INSERT INTO employees (first_name, last_name, email, hire_date, job_title, dept_id, salary) VALUES
('John', 'Smith', 'john.smith@company.com', '2020-01-15', 'HR Manager', 1, 75000.00),
('Sarah', 'Johnson', 'sarah.johnson@company.com', '2019-03-20', 'Senior Developer', 2, 95000.00),
('Michael', 'Brown', 'michael.brown@company.com', '2021-06-10', 'Financial Analyst', 3, 65000.00);

-- Test Query
SELECT 
    e.first_name || ' ' || e.last_name AS employee_name,
    e.job_title,
    d.dept_name,
    e.salary
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;