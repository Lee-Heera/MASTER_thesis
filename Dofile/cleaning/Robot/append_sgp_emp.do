**********************************************************************  
* Robot and automation
* Singapore Employment Statistics clean do-file
**********************************************************************
clear all

	global main "/Users/ihuila/Desktop/data/master thesis"
	global data "${main}/Data cleaned"
	global interim "${main}/Data interim"
	global final "${main}/Data final"
	global prof_raw "${main}/Data raw/professor_raw"	
	/*
	global ifr "${main}/Data raw/IFR"
	global kepco  "${main}/Data raw/KEPCO"
	global oarlr "${main}/Data raw/OARLR"
	global singapore "${main}/Data raw/Singapore"
	*/
	
	
********************************************************************************
	* append service + manufacutring (SGP)
********************************************************************************  
use "$interim/sgp_emp_service.dta" 

append using "$interim/sgp_emp_manu.dta"

tab year 

merge m:n newindcode using "$prof_raw/RobotInd.dta"

// br if _merge==2 // 기존 산업코드에서 결측 or all industry or unclassified 
keep if _merge==3 
keep newindcode year sgp_empl newind

********************************************************************** 
* wood & furniture 통합
********************************************************************** 
replace newindcode = 118 if newindcode == 119
replace newind = "other manufacturing" if newindcode == 118

collapse (sum) sgp_empl , by(year newindcode newind)

label var sgp_empl "emp_sg j,t"

*****************************************************
* emp_sg j,2012 만들기 
*****************************************************
preserve
keep if year == 2012
collapse (sum) sgp_empl, by(newindcode)
rename sgp_empl sgp_empl_j2012  // 수정: sgp_empl을 rename
tempfile ind2012
save `ind2012'
restore

merge m:1 newindcode using `ind2012', nogen
label variable sgp_empl_j2012 "Total employment in industry j, year 2012"  // 수정: 2002 → 2012

sort year newindcode 

save "$data/sgp_emp.dta", replace 
