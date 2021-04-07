select * from backup20201118_ttadempgetleave;
select 
emp_id, emp_no, full_name, u.user_name, 
start_date, end_date,
grade_code, grade_order, employ_code, cost_code,
position_id, pos_code,pos_name_en, pos_level, parent_path, 
dept_id,dept_code,
jobstatuscode, jobtitle_code, grade_category, worklocation_code,
is_main, empcompany_status,
gender, v.user_id, taxno, status, lastreqno, email, photo, phone, birthplace, birthdate, maritalstatus, address, company_id,   
spv_parent, spv_pos, spv_path, spv_level, mgr_parent, mgr_pos, mgr_path, mgr_level
-- personalarea_code, personalsubarea_code, payrollarea_code, employeegroup_code, customfield1
from view_employee v
inner join tclmuser u on u.user_id = v.user_id
-- where full_name like '%%'
-- where emp_id like '%%'
where emp_no like '%2012051%'
-- where user_id like '%%'
-- where user_name like '%%';

