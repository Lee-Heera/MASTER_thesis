clear 
set more off

cd "/Users/ihuila/Desktop/data/master thesis"
use raw/Prof_raw/KOREA_immigration.dta 

** 도 이름 수정 
** 강원특별자치도 -> 강원도, 전북특별자치도 -> 전라북도 
ren region sigungu_nm 
replace sido_nm="강원도" if sido_nm=="강원특별자치도" 
replace sido_nm = "전라북도" if sido_nm=="전북특별자치도" 

tab sido_nm

** 해당데이터는 제주도 없음 
tab year // 227 

save after/KOREA_immigration_clean.dta, replace 
