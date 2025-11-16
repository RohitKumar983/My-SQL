-- Employee Management System Database Schema
-- Created for SQL Project Demonstration

CREATE DATABASE employee_management_system;
USE employee_management_system;

-- Departments Table
CREATE TABLE departments (
    dept_id INT PRIMARY KEY AUTO_INCREMENT,
    dept_name VARCHAR(100) NOT NULL UNIQUE,
    dept_head_id INT,
    location VARCHAR(100),
    budget DECIMAL(15,2),
    created_date DATE DEFAULT (CURRENT_DATE)
);

-- Employees Table
CREATE TABLE employees (
    emp_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15),
    hire_date DATE NOT NULL,
    job_title VARCHAR(100) NOT NULL,
    dept_id INT,
    manager_id INT,
    salary DECIMAL(10,2) NOT NULL,
    status ENUM('Active', 'Inactive', 'Terminated') DEFAULT 'Active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id),
    FOREIGN KEY (manager_id) REFERENCES employees(emp_id)
);

-- Projects Table
CREATE TABLE projects (
    project_id INT PRIMARY KEY AUTO_INCREMENT,
    project_name VARCHAR(200) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE,
    budget DECIMAL(15,2),
    status ENUM('Planning', 'In Progress', 'Completed', 'On Hold') DEFAULT 'Planning',
    dept_id INT,
    project_manager_id INT,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id),
    FOREIGN KEY (project_manager_id) REFERENCES employees(emp_id)
);

-- Employee Projects Junction Table
CREATE TABLE employee_projects (
    emp_id INT,
    project_id INT,
    role VARCHAR(100),
    allocation_percentage DECIMAL(5,2) DEFAULT 100.00,
    start_date DATE NOT NULL,
    end_date DATE,
    PRIMARY KEY (emp_id, project_id),
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id) ON DELETE CASCADE,
    FOREIGN KEY (project_id) REFERENCES projects(project_id) ON DELETE CASCADE
);

-- Salary History Table
CREATE TABLE salaries (
    salary_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_id INT NOT NULL,
    salary_amount DECIMAL(10,2) NOT NULL,
    effective_date DATE NOT NULL,
    end_date DATE,
    salary_type ENUM('Base', 'Bonus', 'Commission') DEFAULT 'Base',
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id) ON DELETE CASCADE
);

-- Add foreign key constraint for department head
ALTER TABLE departments 
ADD FOREIGN KEY (dept_head_id) REFERENCES employees(emp_id);

-- Create Indexes for Performance
CREATE INDEX idx_emp_dept ON employees(dept_id);
CREATE INDEX idx_emp_manager ON employees(manager_id);
CREATE INDEX idx_emp_email ON employees(email);
CREATE INDEX idx_project_dept ON projects(dept_id);
CREATE INDEX idx_salary_emp ON salaries(emp_id);
CREATE INDEX idx_salary_date ON salaries(effective_date);