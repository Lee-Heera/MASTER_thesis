// 시군구명과 시군구 숫자 일치시키고 - 시군구명 + 시군구코드 표 데이터 분리해서 저장 
clear 
set more off 
pwd

cd "/Users/ihuila/Desktop/data/master thesis/raw/Prof_raw"
use Robot1.dta, clear 

keep sido_nm sigungu_nm regioncode year countyid 
//bysort regioncode year (regioncode): keep if _n == 1

save "/Users/ihuila/Desktop/data/master thesis/after/sigungu_code.dta", replace 
export excel using "/Users/ihuila/Desktop/data/master thesis/after/시군구매치.xlsx", replace 
