select * from tpmdperformance_planh tp where reviewee_empid = reviewee_empid 
and period_code like '%2020%';

select Full_Name , emp_id from view_employee where Full_Name like '%sarif%';
select * from tpmdperformance_planh tp where reviewee_empid = 'DO200779' and period_code like '%2020%';
select * from tpmdperformance_pland tp where form_no = 'PEF-2010-0094';

select Full_Name , emp_id from view_employee where Full_Name like '%melati%';
select * from tpmdperformance_planh tp where reviewee_empid = 'DO200006' and period_code like '%2020%';
select * from tpmdperformance_pland tp where form_no = 'PEF-2010-0094';


-- Single Approver yang sudah mengisi planD tapi blm muncul di pEvalnya.
select 
-- count (*)
distinct form_no
-- , t.req_no
, (select full_name from view_employee where emp_id = x.reviewee_empid) empname
, x.reviewee_empid
from tcltrequest t  
left outer join 
(
	select form_no, isfinal, period_code, reviewee_empid, request_no from tpmdperformance_planh where period_code like '%2020%'
) x on x.request_no = t.req_no
-- tpmdperformance_planh h on t.req_no = h.request_no
where req_type like '%plan%'
and period_code like '%2020%'
and (status = 3 or status = 9)
-- and (select count(form_no) from tpmdperformance_planh where form_no = h.form_no) = 1
-- and form_no = 'PEF-2010-0094'
-- and req_no = 'FM-PMPLAN-2103-0001';
order by empname;

select * from tpmdperformance_planh tp where reviewee_empid = 'DO200713';

select distinct form_no, isfinal, period_code, reviewee_empid, request_no, (select full_name from view_employee where emp_id = h.reviewee_empid) empname
from tpmdperformance_planh h where period_code like '%2020%'
and form_no not in
(
	select form_no
	-- count (*) 
	from 
	(
		select distinct form_no, isfinal, period_code, reviewee_empid, request_no from tpmdperformance_planh where period_code like '%2020%'
	) x 
	where isfinal = 1
) 
order by empname;
-- tpmdperformance_planh h on 
