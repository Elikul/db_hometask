-- Задание 1

select (last_name ||' '|| first_name ||' '|| middle_name) as fio, 
		dob, 
		date_part('year', age(dob)) as years
from person
where date_part('year', age(dob)) > 65
order by years, fio;

-- Задание 2

select count(pos.pos_id)
from position as pos
left join employee as e on pos.pos_id = e.pos_id
where e.emp_id is null;

-- Задание 3

select 
    name, 
    employees_id, 
    assigned_id, 
    cardinality(
        array(select distinct unnest(array_cat(employees_id, array[assigned_id])))
    ) as emp_count
from projects
order by emp_count desc;

-- Задание 4

with ChangeSalary as (
    select 
        emp_id,
        salary,
        lag(salary) over (partition by emp_id order by effective_from) as prev_salary,
        (salary - lag(salary) over (partition by emp_id order by effective_from)) * 100.0 / 
        lag(salary) over (partition by emp_id order by effective_from) as change_percent
    from employee_salary
)
select emp_id,
	   salary, 
	   prev_salary, 
	   change_percent
from ChangeSalary
where change_percent = 25;

-- Задание 5

select date_part('year', created_at) as year,
       round(avg(amount), 2) as avg_amount
FROM projects
GROUP BY date_part('year', created_at)
ORDER by avg_amount desc;

-- Задание 6

select (p.last_name ||' '|| p.first_name ||' '|| p.middle_name) as fio, 
       es.salary
from employee as e, 
	 person as p, 
	 employee_salary as es
where e.person_id = p.person_id and 
      e.emp_id = es.emp_id and
      (
      	es.salary = (select max(salary) from employee_salary) or
      	es.salary = (select min(salary) from employee_salary)
      )
order by es.salary desc;

-- Задание 7

with LastSalary as (
    select emp_id,
           salary,
           effective_from,
           row_number() over (partition by emp_id order by effective_from desc) as rn
    from employee_salary
)
select 
    e.emp_id,
    ls.salary,
    string_agg(gs.grade::text, ', ') as grades_as_string
from employee e
left join LastSalary as ls on e.emp_id = ls.emp_id and ls.rn = 1
left join grade_salary as gs on ls.salary between gs.min_salary and gs.max_salary
group by e.emp_id, ls.salary 
order by e.emp_id desc;

-- Задание 8

create view InfoOfEmployee as
with LastSalary as (
    select emp_id,
           salary,
           effective_from,
           row_number() over (partition by emp_id order by effective_from desc) as rn
    from employee_salary
)
select 
    (p.last_name ||' '|| p.first_name ||' '|| p.middle_name) as "фио",
    pos.pos_title as "должность",
    s.unit_title as "подразделение",
    date_part('year', age(p.dob)) as "кол-во лет",
    date_part('year', age(e.hire_date)) * 12 + date_part('month',age(e.hire_date)) as "кол-во месяцев",
    ls.salary as "оклад",
    coalesce(pr.project_ids, array[]::integer[]) as "массив с проектами"
from employee as e
join person as p on e.person_id = p.person_id
join position as pos on e.pos_id = pos.pos_id
join structure as s on pos.unit_id = s.unit_id
join LastSalary as ls on e.emp_id = ls.emp_id and ls.rn = 1
join (
	   select distinct unnest(array_cat(employees_id, array[assigned_id])) as emp_id, 
	          array_agg(distinct project_id) as project_ids
       from projects
       group by employees_id, assigned_id
      ) as pr on e.emp_id = pr.emp_id
order by "кол-во месяцев" desc;