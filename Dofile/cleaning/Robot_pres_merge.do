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
	
******************************************************
// 1. 로봇데이터 (수정전)
use "$data/Robot_COE_merged.dta"
*************************
// 2. 종속변수 
merge m:1 regioncode year using "$data/pres_panel.dta"

tab year if _merge==2 // 대선 데이터에 있는 2007년도 값 때문에 
tab year if _merge==1 // 대선 데이터에 없는 연도 때문에 

keep if _merge==3 
drop _merge 

tab year // 2012, 2017, 2022 (229 * 3개연도)

*************************
// 3. 통제변수 
merge m:1 sido_nm sigungu_nm year using "$interim/sigungucontrol.dta"

br if _merge==1  // 통제변수 데이터에는 제주도 없음 
drop if _merge==1 

tab year if _merge==2  // 227개씩, 대선연도가 아닌 관측치 
br if _merge==2 

// lagged control variable 쓸거라서 2007년도 데이터 포함 
keep if _merge==3 

tab year // 2012,2017,2022년도 

sort sido_nm sigungu_nm

drop _merge 
*************************
//5. immigrant 데이터 추가머지하기 
merge m:1 sido_nm sigungu_nm year using "$interim/KOREA_immigration_clean.dta"

tab year if _merge==2  // 대선 없는 연도 

keep if _merge==3 
drop _merge

tab year 

save "$final/Robot_pres_merge.dta", replace 
