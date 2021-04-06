select pd.form_no, ph.form_no, ed.form_no 
-- pd.lib_name_en, pd.lib_name_id, ed.lib_name_en, ed.lib_name_id 
from tpmdperformance_pland pd
inner join tpmdperformance_planh ph
on ph.form_no = pd.form_no
and ph.reviewer_empid = pd.reviewer_empid 
and isfinal = 1
inner join tpmdperformance_evald ed
on pd.lib_code = ed.lib_code 
and ed.weight != 0
where ph.form_no = 'PEF-2010-0001'
and ed.lib_type = 'PERSKPI'
