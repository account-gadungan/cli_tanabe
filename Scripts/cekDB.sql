-- Membetulkan Form no yang berbeda antara plan dan eval

set @e = 
(
	select emp_id from view_employee v
	inner join tclmuser u on v.user_id = u.user_id 
	where user_name = '2017019'
);
-- set @e = (select emp_id from view_employee where Full_Name like 'Lia Setyowati');

select Full_Name , emp_id from view_employee where emp_id = @e;
-- select Full_Name , emp_id from view_employee where Full_Name like 'Dody Bahar%';

select * from tpmdperformance_evalh tp where reviewee_empid = @e and period_code like '%2020%';
-- select * from tpmdperformance_evalh tp where reviewee_empid = 'DO200825' and period_code like '%2020%';

select * from tpmdperformance_planh tp where reviewee_empid = @e and period_code like '%2020%';

set @f = (
	select form_no from tpmdperformance_planh tp where reviewee_empid = @e and period_code like '%2020%' limit 1
);

set @t = 
(	
	select request_no from tpmdperformance_evalh tp where reviewee_empid = @e and period_code like '%2020%' 
);
set @f = 'PEF-2104-0114';

'PEF-2104-0114' = 'PEF-2010-0052' -- kendy

select * from tpmdperformance_pland tp where form_no = @f and lib_type like 'PERSKPI%' and weight <> 0 order by target;
select * from tpmdperformance_evald tp where form_no = @f and lib_type like 'PERSKPI%' and weight <> 0 order by target;

select * from tcltrequest where req_no = @t;
select * from tcltrequest where req_no = 'CPM-2103-0047';

select distinct target, lib_name_en from tpmdperformance_pland where target like '%aso%';

select * from tpmdperformance_evalh tp where form_no = 'PEF-2103-0030';
select * from tpmdperformance_evald tp where form_no = 'PEF-2103-0030' and lib_type like 'PERSKPI%' and weight <> 0 order by reviewer_empid;
select * from tpmdperformance_evald tp where form_no = 'PEF-2103-0030' and weight <> 0 order by reviewer_empid;
select target, actionresult from tpmdperformance_evald tp where form_no = 'PEF-2103-0030' and weight <> 0 order by reviewer_empid;
select * from tpmdperformance_pland tp where form_no = 'PEF-2104-0089' and lib_type like 'PERSKPI%' and weight <> 0 order by target;
select distinct target, lib_name_en from tpmdperformance_pland tp where form_no = 'PEF-2008-0007' and lib_type like 'PERSKPI%' and weight <> 0 order by target;
select * from tpmdperformance_planh tp where reviewee_empid ='DO200628';

select * from tcltrequest t where req_no = 'CPM-2104-0107';
select * from tcltrequest t where reqemp='DO200046' and req_type like '%eval%';



select distinct target, lib_name_en from tpmdperformance_pland tp where target like '%aso%';
-- delete from tpmdperformance_evalh where form_no = 'PEF-2103-0027';
-- delete from tpmdperformance_evald where form_no = 'PEF-2103-0027';

select distinct pd1.form_no, pd1.target,pd1.lib_name_en, pd2.form_no, pd2.target,pd2.lib_name_en
from tpmdperformance_pland pd1 
inner join tpmdperformance_pland pd2 on pd1.target = pd2.target
where pd2.lib_name_en <> ''
and pd2.lib_type like 'PERSKPI'
and pd1.form_no = 'PEF-2103-0119';

select * from teomposition where pos_name_en like 'Distribution Officer';
select * from teodempcompany t where position_id = 705;

call us;