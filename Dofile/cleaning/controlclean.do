****************************************************************************
********************* 65+ , college share 관련 통제변수 
clear 
set more off 

use "/Users/ihuila/Desktop/data/master thesis/raw/Prof_raw/sigungu1.dta" 

tab year // 제주도 없고, 세종특별자치시 있음 

// 변수명 변경 
ren region sigungu_nm 
tab sigungu_nm 

drop college1 college2 college0 

// 시도 이름 변경해주기 
replace sido_nm="강원도" if sido_nm=="강원특별자치도" 
replace sido_nm="전라북도" if sido_nm== "전북특별자치도"

replace sido_nm="경상북도" if sigungu_nm=="군위군" & sido_nm== "대구광역시" // 2022년 이후에 군위군이 대구광역시로 편입되었는데, 일단은 편입 이전의 경계를 기준으로 함 

tab sido_nm 
tab year 

merge m:n sido_nm sigungu_nm using "/Users/ihuila/Desktop/data/master thesis/after/sigungu_code.dta" // 시군구코드 머지 

br if _merge==2  // 제주도 
keep if _merge==3 
drop _merge 

tab year  // 제주도 제외 227개 시군구 
drop sigungu_id
 
save "/Users/ihuila/Desktop/data/master thesis/after/sigungucontrol.dta", replace 
