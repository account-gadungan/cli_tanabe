select
	distinct Z.appraisal_name as libname,
	z.description,
	Z.apprlib_code as libcode,
	Z.order_no,
	Z.parent_code as pcode,
	Z.depth,
	Z.iscategory,
	(
        select
            negative_component
        from
            tpmmappraisal
        where
            appraisal_code = z.apprlib_code
    ) as negative_component,
	PA.target,
	'' achievement,
	'' score,
	case
		when PA.weight is not null then PA.weight
		when APPR.weight is not null then APPR.weight
		else '0'
	end weight,
	'0' weightedscore,
	'DO200653' reviewer_empid,
	case
		when PA.achievement_type is not null then PA.achievement_type
		else APPR.achievement_type
	end achscoretype,
	PA.lookup_code as lookupscoretype,
	PA.editable_weight as weightedit,
	PA.editable_target as targetedit
from
	(
        select
            A.apprlib_code, A.parent_code, A.order_no, A.appraisal_name_en appraisal_name, A.appraisal_desc_en description, A.appraisal_depth depth, A.iscategory
        from
            TPMDPERIODAPPRLIB A
        inner join TPMDPERIODAPPRAISAL PA on
            PA.period_code = A.period_code
            and PA.company_code = A.company_code
            and PA.reference_date = A.reference_date
            and PA.position_id = 681
            and PA.apprlib_code = A.apprlib_code
        where
            PA.period_code = 'PA_FY2020'
            and PA.company_code = 'mtindonesia'
            and PA.reference_date = {ts '2021-04-05 00:00:00' }

        union all
        
        select
            A.apprlib_code, A.parent_code, A.order_no, A.appraisal_name_en , A.appraisal_desc_en, A.appraisal_depth, A.iscategory
        from
            TPMDPERIODAPPRLIB A
        inner join 
        (
            select
                A.apprlib_code, A.parent_code, A.appraisal_name_en, A.appraisal_desc_en, A.appraisal_depth, A.iscategory
            from
                TPMDPERIODAPPRLIB A
            inner join TPMDPERIODAPPRAISAL PA on
                PA.period_code = A.period_code
                and PA.company_code = A.company_code
                and PA.reference_date = A.reference_date
                and PA.position_id = 681
                and PA.apprlib_code = A.apprlib_code
            where
                PA.period_code = 'PA_FY2020'
                and PA.company_code = 'mtindonesia'
                and PA.reference_date = {ts '2021-04-05 00:00:00' } 
        ) B on A.apprlib_code = B.parent_code
        where
            A.period_code = 'PA_FY2020'
            and A.company_code = 'mtindonesia'
            and A.reference_date = {ts '2021-04-05 00:00:00' } 
    ) Z left join TPMDPERIODAPPRLIB APPR on	APPR.apprlib_code = Z.apprlib_code
	and APPR.period_code = 'PA_FY2020'
	and APPR.company_code = 'mtindonesia'
	and APPR.reference_date = {ts '2021-04-05 00:00:00' }
left join TPMDPERIODAPPRAISAL PA on	PA.period_code = APPR.period_code
	and PA.company_code = APPR.company_code
	and PA.reference_date = APPR.reference_date
	and PA.position_id = 681
	and PA.apprlib_code = APPR.apprlib_code
order by
	Z.order_no,
	Z.depth,
	Z.apprlib_code,
	Z.appraisal_name;
	
select * from TPMDPERIODAPPRLIB;
select * from TPMDPERIODAPPRAISAL pa where PA.position_id = 681
and	PA.period_code = 'PA_FY2020'
	and PA.company_code = 'mtindonesia';

select
	*
from
	TPMDPERIODAPPRAISAL PA
where 1=1
-- 	PA.period_code = A.period_code
-- 	and PA.company_code = A.company_code
-- 	and PA.reference_date = A.reference_date
	and PA.position_id = 681
-- 	and PA.apprlib_code = A.apprlib_code
and	PA.period_code = 'PA_FY2020'
	and PA.company_code = 'mtindonesia'
	and PA.reference_date = {ts '2021-04-05 00:00:00' };
	
select
--             A.apprlib_code, A.parent_code, A.order_no, A.appraisal_name_en appraisal_name, A.appraisal_desc_en description, A.appraisal_depth depth, A.iscategory
pa.*
from
    TPMDPERIODAPPRLIB A
inner join TPMDPERIODAPPRAISAL PA on
    PA.period_code = A.period_code
    and PA.company_code = A.company_code
    and PA.reference_date = A.reference_date
    and PA.position_id = 681
    and PA.apprlib_code = A.apprlib_code
where
    PA.period_code = 'PA_FY2020'
    
select * from tpmmappraisal t where achievement_type like '%zero%';
select * from TPMDPERIODAPPRAISAL where achievement_type like '%zero%';

update TPMDPERFORMANCE_EVALD 
set achievement_type = 'QuestScore ' 
where achievement_type like '%zero%';