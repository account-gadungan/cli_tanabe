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

select * from tpmdperformance_evald ed
where form_no = 'PEF-2104-0005' and weight <> 0 and lib_type like '%kpi%';

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

inner join tpmdperformance_evald ed
on pd.lib_code = ed.lib_code 
and ed.weight != 0

select * from view_employee where Full_Name like '%dedi kus%'; -- DO200586
