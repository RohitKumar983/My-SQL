-- Copy this to DB Fiddle LEFT PANEL (Schema)

CREATE TABLE departments (
    dept_id INT PRIMARY KEY AUTO_INCREMENT,
    dept_name VARCHAR(100) NOT NULL UNIQUE,
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
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

-- Sample Data
INSERT INTO departments (dept_name, location, budget) VALUES
('Human Resources', 'New York', 500000.00),
('Information Technology', 'San Francisco', 2000000.00),
('Finance', 'Chicago', 800000.00),
('Marketing', 'Los Angeles', 1200000.00);

INSERT INTO employees (first_name, last_name, email, hire_date, job_title, dept_id, salary) VALUES
('John', 'Smith', 'john.smith@company.com', '2020-01-15', 'HR Manager', 1, 75000.00),
('Sarah', 'Johnson', 'sarah.johnson@company.com', '2019-03-20', 'Senior Developer', 2, 95000.00),
('Michael', 'Brown', 'michael.brown@company.com', '2021-06-10', 'Financial Analyst', 3, 65000.00),
('Emily', 'Davis', 'emily.davis@company.com', '2020-09-05', 'Marketing Specialist', 4, 58000.00),
('David', 'Wilson', 'david.wilson@company.com', '2018-11-12', 'Operations Manager', 1, 82000.00);