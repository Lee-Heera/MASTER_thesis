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
//bysort regioncode year (regioncode): keep if _n == 1

tab year // 세종, 제주 제외 226개씩 

save "$data/sigungu_code.dta", replace 
