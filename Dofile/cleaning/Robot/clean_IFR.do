*********************************************************************
* Robot and automation project 
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

********************************************************************** 
use "$prof_raw/IFR2023_industry.dta" 

merge m:1 industry using "$prof_raw/RobotInd.dta"

drop _merge 

save "$interim/IFR2003_indcode.dta" ,replace 

compress 

// 필터링 
keep if year > =1995 
keep if country == "Singapore" | country == "Rep. of Korea"
drop if newindcode==100 
keep if newindcode!=. 

********************************************************************** 
* wood & furniture 통합
********************************************************************** 
replace newindcode = 118 if newindcode == 119
replace newind = "other manufacturing" if newindcode == 118

collapse (sum) op_stock delivered, by(year country newindcode newind)
********************************************************************** 
* STEP 1: 산업1 (원래값)
********************************************************************** 
gen opdeli = op_stock + delivered

rename op_stock industry_opstock
rename delivered industry_delivered
rename opdeli industry_opdeli 

label variable industry_opstock "original op_stock"
label variable industry_delivered "original delivered"
label variable industry_opdeli  "original op_stock + delivered"

********************************************************************** 
* STEP 2: Total (산업1 + unclassified)
********************************************************************** 
bysort year country: egen total_opstock = total(industry_opstock)
bysort year country: egen total_delivered = total(industry_delivered)
bysort year country: egen total_opdeli = total(industry_opdeli)

label variable total_opstock "Total: classified + unclassified (전체 합)"
label variable total_delivered "Total: classified + unclassified (전체 합)"
label variable total_opdeli "Total: classified + unclassified (전체 합)"

********************************************************************** 
* STEP 3: unclassified (200, 300번만)
********************************************************************** 
gen is_unclassified = inlist(newindcode, 200, 300)

bysort year country: egen unclassified_opstock = total(industry_opstock) if is_unclassified == 1
bysort year country: egen unclassified_delivered = total(industry_delivered) if is_unclassified == 1
bysort year country: egen unclassified_opdeli = total(industry_opdeli) if is_unclassified == 1

// missing 채우기 (같은 year-country 그룹 내 모든 행에 동일값)
bysort year country (is_unclassified): replace unclassified_opstock = unclassified_opstock[_N]
bysort year country (is_unclassified): replace unclassified_delivered = unclassified_delivered[_N]
bysort year country (is_unclassified): replace unclassified_opdeli = unclassified_opdeli[_N]

label variable unclassified_opstock "Unclassified: 200,300번 총합"
label variable unclassified_delivered "Unclassified: 200,300번 총합"
label variable unclassified_opdeli "Unclassified: 200,300번 총합"

********************************************************************** 
* STEP 4: classified (unclassified 제외한 나머지)
********************************************************************** 
bysort year country: egen classified_opstock = total(industry_opstock) if is_unclassified == 0
bysort year country: egen classified_delivered = total(industry_delivered) if is_unclassified == 0
bysort year country: egen classified_opdeli = total(industry_opdeli) if is_unclassified == 0

// missing 채우기
bysort year country (is_unclassified): replace classified_opstock = classified_opstock[1]
bysort year country (is_unclassified): replace classified_delivered = classified_delivered[1]
bysort year country (is_unclassified): replace classified_opdeli = classified_opdeli[1]

label variable classified_opstock "Classified: unclassified 제외 총합"
label variable classified_delivered "Classified: unclassified 제외 총합"
label variable classified_opdeli "Classified: unclassified 제외 총합"

********************************************************************** 
* STEP 3→4 전환: unclassified 행 삭제
********************************************************************** 
drop if is_unclassified == 1

tab newind
********************************************************************** 
* STEP 5: 산업비중 (classified 중에서)
********************************************************************** 
gen industry_share_opstock = industry_opstock / classified_opstock
gen industry_share_delivered = industry_delivered / classified_delivered
gen industry_share_opdeli = industry_opdeli / classified_opdeli

label variable industry_share_opstock "산업비중: 산업1 / classified (op_stock)"
label variable industry_share_delivered "산업비중: 산업1 / classified (delivered)"
label variable industry_share_opdeli "산업비중: 산업1 / classified (opdeli)"

********************************************************************** 
* STEP 6: 배분후 (최종값 = 산업1 + unclassified × 산업비중)
********************************************************************** 
gen final_opstock = industry_opstock + (unclassified_opstock * industry_share_opstock)
gen final_delivered = industry_delivered + (unclassified_delivered * industry_share_delivered)
gen final_opdeli = industry_opdeli + (unclassified_opdeli * industry_share_opdeli)

label variable final_opstock "배분후 (최종): op_stock adjusted"
label variable final_delivered "배분후 (최종): delivered adjusted"
label variable final_opdeli "배분후 (최종): opdeli adjusted"
	  
// 중간 변수 제거
drop is_unclassified
********************************************************************** 
* STEP 7: Reshape 
* country-year-industry → year-industry (국가별 변수 분리)
**********************************************************************
// country 변수를 짧게 변환 (reshape에 사용)
gen ctry = ""
replace ctry = "KR" if country == "Rep. of Korea"
replace ctry = "SG" if country == "Singapore"
tab ctry 
drop country 

label variable ctry "Country code: KR=Korea, SG=Singapore"

// Reshape할 변수 리스트 정의
local vars_to_reshape "industry_opstock industry_delivered industry_opdeli total_opstock total_delivered total_opdeli unclassified_opstock unclassified_delivered unclassified_opdeli classified_opstock classified_delivered classified_opdeli industry_share_opstock industry_share_delivered industry_share_opdeli final_opstock final_delivered final_opdeli"
					   
// Reshape: long → wide
reshape wide `vars_to_reshape', i(year newindcode newind) j(ctry) string

// 변수명 정리 (더 명확하게)
foreach var in `vars_to_reshape' {
    rename `var'KR `var'_kr
    rename `var'SG `var'_sg
    
    label variable `var'_kr "`var' (Korea)"
    label variable `var'_sg "`var' (Singapore)"
}

********************************************************************
* delta_robot j,t (kr)
* 1) long difference 
* 2) first difference 
*********************************************************************
* delta_robot j,t (sgp)
* 1) long difference 
* 2) first difference 
*********************************************************************
* 2012년 데이터 저장
preserve
keep if year == 2012
keep newindcode final_opstock_kr final_opstock_sg
rename final_opstock_kr opstock_kr_2012
rename final_opstock_sg opstock_sg_2012
tempfile base2012
save `base2012'
restore

* 2017년 데이터 저장
preserve
keep if year == 2017
keep newindcode final_opstock_kr final_opstock_sg
rename final_opstock_kr opstock_kr_2017
rename final_opstock_sg opstock_sg_2017
tempfile base2017
save `base2017'
restore

* 원본에 merge
merge m:1 newindcode using `base2012', nogen
merge m:1 newindcode using `base2017', nogen

label variable opstock_kr_2012 "Korea: op_stock in 2012"
label variable opstock_sg_2012 "Singapore: op_stock in 2012"
label variable opstock_kr_2017 "Korea: op_stock in 2017"
label variable opstock_sg_2017 "Singapore: op_stock in 2017"
********************************************************************** Long Difference (2012 기준)
********************************************************************** 
* Korea
gen LD_opstock_kr = .
replace LD_opstock_kr = final_opstock_kr - opstock_kr_2012 if year == 2017
replace LD_opstock_kr = final_opstock_kr - opstock_kr_2012 if year == 2022

* Singapore
gen LD_opstock_sg = .
replace LD_opstock_sg = final_opstock_sg - opstock_sg_2012 if year == 2017
replace LD_opstock_sg = final_opstock_sg - opstock_sg_2012 if year == 2022

label variable LD_opstock_kr "Korea: Long Diff Δop_stock (2012 base)"
label variable LD_opstock_sg "Singapore: Long Diff Δop_stock (2012 base)"

sort year newindcode
order year newindcode final_opstock_sg opstock_sg_2012 opstock_sg_2017 LD_opstock_sg final_opstock_kr opstock_kr_2012 opstock_kr_2017 LD_opstock_kr

br if year==2012 | year==2017 | year==2022

*********************************************************************
* First Difference (연속 기간)
********************************************************************** 
* Korea
gen FD_opstock_kr = .
replace FD_opstock_kr = final_opstock_kr - opstock_kr_2012 if year == 2017
replace FD_opstock_kr = final_opstock_kr - opstock_kr_2017 if year == 2022

* Singapore
gen FD_opstock_sg = .
replace FD_opstock_sg = final_opstock_sg - opstock_sg_2012 if year == 2017
replace FD_opstock_sg = final_opstock_sg - opstock_sg_2017 if year == 2022

label variable FD_opstock_kr "Korea: First Diff Δop_stock (2012-17, 17-22)"
label variable FD_opstock_sg "Singapore: First Diff Δop_stock (2012-17, 17-22)"

order year newindcode final_opstock_sg opstock_sg_2012 opstock_sg_2017 LD_opstock_sg FD_opstock_sg final_opstock_kr opstock_kr_2012 opstock_kr_2017 LD_opstock_kr FD_opstock_kr

br if year==2012 | year==2017 | year==2022

compress
save "$data/Robot_IFR_clean.dta", replace 

/*
******************************************************************** 
* 검증: 배분 후 총합 확인
********************************************************************** 
di _newline(2) "=" * 70
di "VERIFICATION: 배분 후 총합이 원래 total과 일치하는지 확인"
di "=" * 70

bysort year country: egen check_sum_opstock = total(final_opstock)
bysort year country: egen check_sum_delivered = total(final_delivered)

gen diff_opstock = abs(check_sum_opstock - total_opstock)
gen diff_delivered = abs(check_sum_delivered - total_delivered)

// 예시 출력: 2010년 한국
preserve
keep if year == 2010 & country == "Rep. of Korea"
list newindcode newind ///
     industry_opstock industry_share_opstock final_opstock ///
     unclassified_opstock classified_opstock, ///
     separator(0) abbreviate(10)
restore

// 전체 검증
quietly count if diff_opstock > 0.01 | diff_delivered > 0.01
if r(N) == 0 {
    di _newline(1) "✓ SUCCESS: 모든 year-country에서 총합 일치!"
}
else {
    di _newline(1) "✗ WARNING: 일부 year-country에서 오차 발견"
    list year country diff_opstock diff_delivered if diff_opstock > 0.01 | diff_delivered > 0.01
}

di "=" * 70 _newline(1)

drop check_* diff_*
*/  



// IFR 데이터 -> 한국 로봇수, 싱가폴 로봇 수 

// COE 데이터 -> employment (number), employment share 둘다 구해야함 


/* 김혜진 교수님 논문에서 사용하는 산업 분류 18개
//6  
agriculture, 101 
mining, 102 
utilities, 103 
construction, 104 
research, 105 
and services. 106 

// 12 
food and beverages, 107 
textiles, 108
paper and printing, 109
plastics and chemicals, 110
minerals, 111 
basic metals, 112 
metal products, 113
metal and machinery, 
electronics, 115
automotive, 116
other vehicles (for example, shipbuilding and aerospace), 117
and other manufacturing (including wood and furniture). 118, 119 
*/ 
