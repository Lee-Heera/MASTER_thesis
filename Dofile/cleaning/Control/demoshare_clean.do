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
****************************************************************************
********************* 65+ , college share 관련 통제변수 
use "$prof_raw/sigungu1.dta"

tab year // 제주도 없고, 세종특별자치시 있음 

** 변수명 변경 
ren region sigungu_nm 
tab sigungu_nm 

drop college1 college2 college0 

** 시도 이름 변경해주기 
replace sido_nm="강원도" if sido_nm=="강원특별자치도" 
replace sido_nm="전라북도" if sido_nm== "전북특별자치도"
replace sido_nm="경상북도" if sigungu_nm=="군위군" & sido_nm== "대구광역시" // 2022년 이후에 군위군이 대구광역시로 편입되었는데, 일단은 편입 이전의 경계를 기준으로 함 

** merge 
merge m:1 year sido_nm sigungu_nm using "$data/sigungu_code.dta" // 시군구코드 머지 
tab year if _merge!=3 
keep if _merge==3 
drop _merge // _merge!=3 인 경우 없음 

ren pop65 aged_share 
ren college_final college_share 

// 0~1 사이값 (share)으로 만들기 
replace aged_share = aged_share/100
replace college_share = college_share/100 

label var aged_share "share of population aged 65 and above"
label var college_share "share of college-educated"

tab year 

save "$data/demoshare_control.dta", replace 
