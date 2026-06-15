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
**********************************************************************					
clear 
set more off 

use "$data/X_final.dta"

keep sido_nm sigungu_nm regioncode year 

duplicates drop
tab year // 1995~2022, 각 연도별 229개

* 1992년은 X_final.dta에 없으므로 2022년 지역 목록을 복사하여 1992년으로 추가
preserve
	keep if year == 2022
	replace year = 1992
	tempfile y1992
	save `y1992', replace
restore

append using `y1992'

preserve
	keep if year == 2022
	replace year = 1997
	tempfile y1997
	save `y1997', replace
restore

append using `y1997'

preserve
	keep if year == 2022
	replace year = 2002
	tempfile y2002
	save `y2002', replace
restore

append using `y2002'

isid sido_nm sigungu_nm year
sort year sido_nm sigungu_nm

save "$data/sigungu_code.dta", replace
