SELECT * from (
SELECT DISTINCT PLD.lib_name_en AS libname,
PLD.lib_code AS libcode, PLD.parent_code AS pcode, PLD.lib_depth AS depth, PLD.iscategory,
PLD.target,
'' achievement,
'' score,
PLD.weight,
'' weightedscore,
'' reviewer_empid,
PLD.achievement_type AS achscoretype,
PLD.lib_order,
PLD.lookup_code AS lookupscoretype,
AP.kpi_desc_en AS lib_desc_en
,pld.criteria,pld.initiative,pld.scheduleplan,pld.actionresult,pld.pointscriteria
FROM TPMDPERFORMANCE_PLANH PLANH
LEFT JOIN TPMDPERFORMANCE_PLAND PLD
ON (PLD.lib_code = PLD.lib_code
AND PLD.form_no = 'PEF-2103-0071'
AND PLD.request_no = 'FM-PMPLAN-2103-0071'
AND PLD.reviewer_empid IN ('DO200064')
)
LEFT JOIN TPMDPERIODKPILIB AP
ON PLD.lib_code = AP.kpilib_code AND PLANH.period_code=AP.period_code
AND PLD.company_code = AP.company_code
WHERE PLANH.period_code = 'PA_FY2020_60_40'
AND PLANH.company_code = 'mtindonesia'
AND PLANH.form_no = 'PEF-2103-0071'
AND PLANH.request_no = 'FM-PMPLAN-2103-0071'
AND PLANH.REVIEWER_EMPID = 'DO200064'
) tblperskpi
ORDER BY tblperskpi.lib_order, tblperskpi.depth, tblperskpi.libname; 

select * from TPMDPERFORMANCE_PLAND where achievement_type like '%perf%';
select * from TPMDPERFORMANCE_PLAND where form_no = 'PEF-2103-0071';

update TPMDPERFORMANCE_PLAND 
set achievement_type = 'QuestScore'
where achievement_type like '%perf%';


SELECT DISTINCT ED.lib_name_en AS libname, AP.appraisal_desc_en as description,
ED.lib_code AS libcode, ED.parent_code AS pcode, ED.lib_depth AS depth, ED.iscategory,
ED.target,
ED.achievement,
ED.score,
ED.weight,
ED.weightedscore,
ED.reviewer_empid,
ED.achievement_type AS achscoretype,
ED.lookup_code AS lookupscoretype
,(select negative_component from tpmmappraisal where appraisal_code = ED.lib_code) as negative_component
FROM TPMDPERFORMANCE_EVALH EH
LEFT JOIN TPMDPERFORMANCE_EVALD ED
ON ED.form_no = EH.form_no
AND ED.company_code = EH.company_code
LEFT JOIN TPMDPERIODAPPRLIB AP
ON ED.lib_code = AP.apprlib_code AND EH.period_code=AP.period_code
AND ED.company_code = AP.company_code
WHERE EH.period_code = 'PA_FY2020'
AND EH.company_code = 'mtindonesia'
AND EH.request_no = 'CPM-2103-0019'
AND EH.form_no = 'PEF-2010-0057'
AND upper(ED.lib_type) = 'APPRAISAL'
AND ED.reviewer_empid IN ('DO200689')
ORDER BY LIBCODE ;

select * from TPMDPERFORMANCE_planD where achievement_type like '%zero%';

update TPMDPERFORMANCE_EVALD 
set achievement_type = 'QuestScore ' 
where achievement_type like '%zero%';

select * from TPMDPERFORMANCE_EVALD where lib_desc_en like '%abs%';

select * from TPMDPERFORMANCE_EVALD order by created_date desc

select * from tpmdperformance_evalh te where form_no = 'PEF-2010-0038';

select lib_type, score, lib_desc_id from backup_eval_sjamsul

select * from backup_eval_sjamsul

select * from tpmdperformance_evald te where form_no = 'PEF-2006-0002'

select * from tpmdperformance_evalh te where form_no = 'PEF-2006-0002'

-- query buat nyari requst status dan form evaluation
select
	t.status request_status,
	te.form_no,
	te.head_status,
	(select full_name from view_employee where emp_id = te.reviewee_empid ) fn
from
	tcltrequest t
join tpmdperformance_evalh te on t.req_no = te.request_no 
where
	req_type = 'Performance.evaluation'
order by
	t.modified_date desc


select -- te.* 
(select full_name from view_employee where emp_id = te.reviewee_empid ) emp,form_no
,period_code
from tpmdperformance_evalh te where form_no in
(
	-- select form_no from TPMDPERFORMANCE_EVALD where lib_desc_en like '%abs%' and weight is null
	select form_no from TPMDPERFORMANCE_EVALD where achievement_type like '%zero%'
) 
-- order by reviewee_empid;
order by emp;

select distinct 
(select full_name from view_employee where emp_id = te.reviewee_empid ) emp,form_no
,period_code
from tpmdperformance_evalh te where form_no in
(
	-- select form_no from TPMDPERFORMANCE_EVALD where lib_desc_en like '%abs%' and weight is null
	select distinct lib_type from TPMDPERFORMANCE_EVALD where achievement_type like '%zero%'
) 
-- order by reviewee_empid;
order by emp;

select distinct lib_type from TPMDPERFORMANCE_EVALD where achievement_type like '%zero%';
select * from TPMDPERFORMANCE_EVALD where achievement_type like '%zero%';

delete from tcltrequest where req_no in(
	select distinct request_no
	from tpmdperformance_evalh te where form_no in
	(
		select form_no from TPMDPERFORMANCE_EVALD where lib_desc_en like '%abs%' and weight is null
	) 
)

delete from tpmdperformance_evalh where form_no in(
	select distinct form_no
	from tpmdperformance_evalh te where form_no in
	(
		select form_no from TPMDPERFORMANCE_EVALD where lib_desc_en like '%abs%' and weight is null
	) 
)

delete from tpmdperformance_evald where form_no in(
		select form_no from TPMDPERFORMANCE_EVALD where lib_desc_en like '%abs%' and weight is null 
)



javascript:WhatXML('DO200064;PA_FY2020;2021-03-31;PEF-2008-0009;;PEF-2008-0009;-');

select * from tpmdperformance_evalh te where form_no ='PEF-2008-0019';
select * from tpmdperformance_evald te where form_no ='PEF-2008-0019';
select * from tcltrequest t  where req_no ='CPM-2103-0015';


alter table tpmdperformance_pland add iscascade varchar(1);
alter table tpmdperiodcomponent add use_cascade varchar(1);

CREATE TABLE if not exists `tpmdgoalcascading` (
  `cascadefrom_formno` varchar(50) NOT NULL,
  `cascadefrom_empid` varchar(50) NOT NULL,
  `cascadeto_formno` varchar(50) DEFAULT NULL,
  `cascadeto_empid` varchar(50) NOT NULL,
  `lib_code` varchar(50) NOT NULL,
  `lib_type` varchar(50) DEFAULT NULL,
  `target` float DEFAULT NULL,
  `company_code` varchar(50) DEFAULT NULL,
  `polarization` varchar(10) NOT NULL,
  `consolidation` varchar(10) NOT NULL,
  `created_by` varchar(50) NOT NULL,
  `created_date` datetime NOT NULL,
  `modified_by` varchar(50) DEFAULT NULL,
  `modified_date` datetime DEFAULT NULL,
  PRIMARY KEY (`cascadefrom_formno`,`cascadefrom_empid`,`cascadeto_empid`,`lib_code`)
) ;

CREATE TABLE if not exists `tpmdperf_evalattachment` (
  `form_no` varchar(50) NOT NULL,
  `company_id` int(11) NOT NULL,
  `lib_type` varchar(10) NOT NULL,
  `reviewer_empid` varchar(50) NOT NULL,
  `reviewee_empid` varchar(50) NOT NULL,
  `period_code` varchar(50) NOT NULL,
  `file_attachment` varchar(255) DEFAULT NULL,
  `created_by` varchar(50) DEFAULT NULL,
  `created_date` datetime DEFAULT NULL,
  `modified_by` varchar(255) DEFAULT NULL,
  `modified_date` datetime DEFAULT NULL
) ;

alter table TPMDPERFORMANCE_MIDV
add if not exists attachment_file varchar(500);

alter table TPMDPERFORMANCE_MIDV
add  if not exists is_verified varchar(1);


alter table tpmdperformance_evalh
add if not exists use_point integer;

alter table tpmdperformance_evald
modify column target varchar(1500);


CREATE TABLE if not exists `tpmdevald_comppoint` (
  `form_no` varchar(50) NOT NULL,
  `request_no` varchar(50) DEFAULT NULL,
  `comp_code` varchar(50) NOT NULL,
  `comp_type` varchar(1) DEFAULT NULL
) ;


alter table tpmdperformance_evald
modify column target varchar(2500);

alter table tpmdperformance_evald
modify column lib_name_en varchar(2500);

alter table tpmdperformance_evald
modify column lib_name_id varchar(2500);

alter table tpmdperformance_evald
modify column lib_name_my varchar(2500);

alter table tpmdperformance_evald
modify column lib_name_th varchar(2500);

alter table tpmdperformance_evald
modify column lib_desc_en varchar(2500);

alter table tpmdperformance_evald
modify column lib_desc_id varchar(2500);
alter table tpmdperformance_evald
modify column lib_desc_my varchar(2500);
alter table tpmdperformance_evald
modify column lib_desc_th varchar(2500);

alter table tpmdperformance_evald
modify column notes varchar(2500);

alter table tpmdperformance_evald
modify column achievement varchar(2500);


select * from tpmdperformance_evalh te where reviewee_empid in (select emp_id from teodempcompany t2 where emp_no = '1995016');
select * from tpmdperformance_evalh te where form_no = 'PEF-2103-0059';
select * from tpmdperformance_evald where form_no = 'PEF-2103-0059' and lib_type = 'persKPI' order by weightedscore;
and achievement <> score ;

select * from tcltrequest t  where req_no = 'CPM-2104-0091';

create table evald_bu_marc as 
select * from tpmdperformance_evald;

select (
	select d.form_no, d.reviewer_empid,h.review_step,sum(weight) 
	from tpmdperformance_evalh d
	inner join tpmdperformance_evalh h on d.form_no = h.form_no 
	where 1=1 
	-- and d.form_no = 'PEF-2103-0059' 
	and lib_type = 'persKPI'
	group by d.form_no, d.reviewer_empid,h.review_step;
)

select * from evald_bu_marc where form_no = 'PEF-2103-0059' and lib_type = 'persKPI' order by weightedscore;
and achievement <> score;

update evald_bu_marc 
set score = achievement 
where form_no = 'PEF-2103-0059' and lib_type = 'persKPI';

select * from tpmdperformance_evald where form_no = 'PEF-2006-0002';