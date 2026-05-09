**********************************************************************  
* Robot and automation
* Singapore Employment Statistics clean do-file
**********************************************************************
clear all

	global main "/Users/ihuila/Research/MASTER_thesis"
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
	* append service(DOS, 서로다른연도) + manufacutring (UNIDO, 다른산업)
********************************************************************************  
use "$interim/DOS/sgp_empl2_clean.dta"  // 2000~2007 

append using "$interim/DOS/sgp_empl3_clean.dta" // 2008~2025
append using "$interim/UNIDO/sgp_empl.dta" //. 2005~

tab year
keep if year>=2005 & year<=2022 // 연도 안맞는 것 삭제 

merge m:n newindcode using "$prof_raw/RobotInd.dta"

br if _merge==2 // 기존 산업코드에서 결측 or all industry or unclassified 
keep if newindcode >=101 & newindcode <= 119 

tab _merge // _merge==3 만 남음 

keep newindcode year sgp_empl newind

tab newindcode  // 19개의 산업 

label var sgp_empl "emp_sg j,t"

sort year newindcode  // 2005~2025

save "$data/sgp_empl.dta", replace 

/*
********************************************************************** 
* wood & furniture 통합
********************************************************************** 
replace newindcode = 118 if newindcode == 119
replace newind = "other manufacturing" if newindcode == 118

collapse (sum) sgp_empl , by(year newindcode newind)
*/

