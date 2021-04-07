select distinct h.form_no, h.reviewee_empid 
,(select full_name from view_employee where emp_id = h.reviewee_empid) empname
from tpmdperformance_pland d 
inner join tpmdperformance_planh h on d.form_no = h.form_no 
where 1=1 
and (lib_name_en is null or lib_name_en = '' or lib_name_id is null or lib_name_id = '') 
-- and d.form_no = 'PEF-2010-0094'
and weight <> 0 and lib_type like '%kpi%'
order by empname;

select distinct h.form_no, h.reviewee_empid 
,(select full_name from view_employee where emp_id = h.reviewee_empid) empname
from tpmdperformance_evald d 
inner join tpmdperformance_evalh h on d.form_no = h.form_no 
where 1=1 
and (lib_name_en is null or lib_name_en = '' or lib_name_id is null or lib_name_id = '') 
-- and d.form_no = 'PEF-2010-0094'
and weight <> 0 and lib_type like '%kpi%'
order by empname;

set @form_no = (
select form_no from tpmdperformance_planh 
where reviewee_empid = (select emp_id from view_employee where Full_Name like '%wahyuni ars%') 
and period_code like '%2020%' limit 1);

set @form_no = 'PEF-2104-0109';

select user_name from tclmuser where user_id = (select user_id from view_employee where Full_Name like '%wahyuni ars%');
select Full_Name , emp_id from view_employee where Full_Name like '%sarif%';

select * from tpmdperformance_planh tp where reviewee_empid = 'DO200779';
select * from tpmdperformance_pland tp where form_no = 'PEF-2103-0002';



select user_name from tclmuser where user_id = (select user_id from view_employee where Full_Name like '%irawan%');
select * from tpmdperformance_planh tp where reviewee_empid ='DO200759';

select @form_no;

update tpmdperformance_evald ed
inner join 
(
	select distinct lib_code, lib_name_en 
	from tpmdperformance_evald te 
	where form_no = @form_no 
	and weight <> 0 
	and lib_type like '%kpi%' 
	and (lib_name_en is not null or lib_name_en != '')
) x on ed.lib_code = x.lib_code
set ed.lib_name_en = x.lib_name_en, ed.lib_name_id = x.lib_name_en
where form_no = @form_no and weight <> 0 and lib_type like '%kpi%' and (ed.lib_name_en is null or ed.lib_name_en = ''  or lib_name_id is null or lib_name_id = '');

-- Advanced
update tpmdperformance_evald ed
inner join 
(
	select distinct lib_code, lib_name_en 
	from tpmdperformance_pland te 
	where form_no = @form_no
	and weight <> 0 
	and lib_type like '%kpi%' 
	and (lib_name_en is not null or lib_name_en != '')
) x on ed.lib_code = x.lib_code
set ed.lib_name_en = x.lib_name_en, ed.lib_name_id = x.lib_name_en
where form_no = @form_no and weight <> 0 and lib_type like '%kpi%' and (ed.lib_name_en is null or ed.lib_name_en = '' or lib_name_id is null or lib_name_id = '');

select * from tpmdperformance_pland tp where form_no = 'PEF-2104-0109'; -- DO200599
select * from tpmdperformance_planh tp where reviewee_empid = 'DO200599'

select * from tpmdperformance_evald te where form_no = @form_no and weight <> 0 and lib_type like '%kpi%' and (lib_name_en is null or lib_name_en = '' or lib_name_id is null or lib_name_id = '');
select distinct form_no from tpmdperformance_evald te where weight <> 0 and lib_type like '%kpi%' and (lib_name_en is null or lib_name_en = '');

select * from tpmdperformance_planh tp where reviewee_empid = 'DO200046';

select * from tpmdperformance_evald te where form_no = 'PEF-2103-0059' and weight <> 0 and lib_type like '%kpi%' and lib_name_en is null;

select distinct lib_code, lib_name_en from tpmdperformance_evald te where form_no = 'PEF-2103-0059' and weight <> 0 and lib_type like '%kpi%' and lib_name_en is not null;

update tpmdperformance_evald ed
inner join 
(
	select distinct lib_code, lib_name_en from tpmdperformance_evald te where form_no = 'PEF-2103-0059' and weight <> 0 and lib_type like '%kpi%' and lib_name_en is not null
) x on ed.lib_code = x.lib_code
set ed.lib_name_en = x.lib_name_en, ed.lib_name_id = x.lib_name_en
where form_no = 'PEF-2103-0059' and weight <> 0 and lib_type like '%kpi%';


update tpmdperformance_evald ed
inner join 
(
	select pd.lib_code , pd.lib_name_en
	-- , ed.lib_name_en, ed.lib_name_id 
	from tpmdperformance_pland pd
	where form_no in 
	(select form_no from tpmdperformance_planh tp where reviewee_empid = 'DO200586' and isfinal = 1 and period_code like '%2020')
	and reviewer_empid in (select reviewer_empid from tpmdperformance_planh tp where reviewee_empid = 'DO200586' and isfinal = 1 and period_code like '%2020')
	and weight <> 0
) x on ed.lib_code = x.lib_code
set ed.lib_name_en = x.lib_name_en, ed.lib_name_id = x.lib_name_en
where form_no = 'PEF-2104-0005' and weight <> 0 and lib_type like '%kpi%';

select * from tcltrequest ed where req_no = 'CPM-2103-0050';
select * from tpmdperformance_evalh ed where form_no = 'PEF-2010-0001';
select * from tpmdperformance_evald ed where form_no = 'PEF-2010-0001';

-- delete from tcltrequest where req_no = 'CPM-2103-0050';
-- delete from tpmdperformance_evalh where form_no = 'PEF-2104-0005';
-- delete from tpmdperformance_evald where form_no = 'PEF-2104-0005';

-- select * from tpmdperformance_evalH ed where form_no = 'PEF-2010-0001';

select * from tcltrequest where req_no = 'CPM-2103-0020';



-- DELETE from tpmdperformance_evalH where form_no = 'PEF-2010-0001';
-- DELETE from tpmdperformance_evald where form_no = 'PEF-2010-0001';
select * from tpmdperformance_evald where lib_name_en = '' and weight <> 0;
select distinct form_no from tpmdperformance_evald where lib_name_en = '' and weight <> 0;






select pd.lib_code , pd.lib_name_en
-- , ed.lib_name_en, ed.lib_name_id 
from tpmdperformance_pland pd
where form_no in 
(select form_no from tpmdperformance_planh tp where reviewee_empid = 'DO200586' and isfinal = 1 and period_code like '%2020')
and reviewer_empid in (select reviewer_empid from tpmdperformance_planh tp where reviewee_empid = 'DO200586' and isfinal = 1 and period_code like '%2020')
and weight <> 0;

select form_no from tpmdperformance_planh tp where reviewee_empid = 'DO200586' and isfinal = 1 and period_code like '%2020';
select reviewer_empid from tpmdperformance_planh tp where reviewee_empid = 'DO200586' and isfinal = 1 and period_code like '%2020';

select * from tpmdperformance_planh tp where reviewee_empid = 'DO200586' and isfinal = 1 and period_code like '%2020';


select * from view_employee where Full_Name like '%dedi kus%'; -- DO200586

