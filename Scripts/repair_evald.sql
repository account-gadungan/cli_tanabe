delimiter //
create procedure repair_evald()
begin
	
	declare done INT default false;
	declare z varchar(255);
	declare cur1 cursor for

	select distinct h.form_no
	from tpmdperformance_evald d 
	inner join tpmdperformance_evalh h on d.form_no = h.form_no 
	where (lib_name_en is null or lib_name_en = '' or lib_name_id is null or lib_name_id = '') 
	and weight <> 0 and lib_type like '%kpi%';
	
	declare continue HANDLER for not found set done = true;


	open cur1;
	
		read_loop: loop
			fetch cur1 into z;
		
			if done then 
				leave read_loop;
			end if;
			
			update tpmdperformance_evald ed
			inner join 
			(
				select distinct lib_code, lib_name_en 
				from tpmdperformance_pland te 
				where form_no = z
				and weight <> 0 
				and lib_type like '%kpi%' 
				and (lib_name_en is not null or lib_name_en != '')
			) x on ed.lib_code = x.lib_code
			set ed.lib_name_en = x.lib_name_en, ed.lib_name_id = x.lib_name_en
			where form_no = z and weight <> 0 and lib_type like '%kpi%' and (ed.lib_name_en is null or ed.lib_name_en = '' or lib_name_id is null or lib_name_id = '');
			
		end loop;

	close cur1;

end;
//

delimiter ;
-- drop procedure us;

call repair_evald;

select distinct h.form_no
from tpmdperformance_evald d 
inner join tpmdperformance_evalh h on d.form_no = h.form_no 
where (lib_name_en is null or lib_name_en = '' or lib_name_id is null or lib_name_id = '') 
and weight <> 0 and lib_type like '%kpi%';

select * from tpmdperformance_evald ed where form_no ='PEF-2103-0144' 
and weight <> 0 and lib_type like '%kpi%' and (ed.lib_name_en is null or ed.lib_name_en = '' or lib_name_id is null or lib_name_id = '');

select * from tpmdperformance_pland te where form_no ='PEF-2103-0144' and lib_type like 'PERSKPI';

select distinct lib_code, lib_name_en 
from tpmdperformance_pland te 
where form_no = 'PEF-2103-0144'
and weight <> 0 
and lib_type like '%kpi%' 
and (lib_name_en is not null or lib_name_en != '')
