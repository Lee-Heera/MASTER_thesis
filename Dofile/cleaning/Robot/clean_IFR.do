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
use "$prof_raw/IFR2023_industry.dta" 

merge m:1 industry using "$prof_raw/RobotInd.dta"

drop _merge 

//save "$interim/IFR/IFR2003_indcode.dta" ,replace 

//
compress 
destring newindcode, replace 
drop delivered // operatinoal stock만 사용 

// 필터링 
keep if year >=1995 
keep if country == "Singapore" | country == "Rep. of Korea"

tab newindcode, m  // 100=all industries, 200 = metal, unspecified, 300 = unspecified 

drop if newindcode==100 | newindcode == 200 
drop if newindcode==. 

bysort year country: egen tot_opstock = total(op_stock)

/*
********************************************************************** 
* wood & furniture 통합
********************************************************************** 
replace newindcode = 118 if newindcode == 119
replace newind = "other manufacturing" if newindcode == 118

collapse (sum) op_stock delivered, by(year country newindcode newind)
*/

tab newindcode // 각산업별로 동일 관측치 개수인지 확인하기 
tab year 
tab year country // unspecified 포함 20개씩 
********************************************************************** 
* STEP 3: total unclassified (300번만)
********************************************************************** 
gen is_unclas = (newindcode == 300)

* unclassified 총합 (year-country 단위)
bysort year country: egen unclas_opstock = total(op_stock * is_unclas)
label variable unclas_opstock "Total unclassified op_stock (300번)"
********************************************************************** 
* STEP 4: total classified (unclassified 제외한 나머지)
********************************************************************** 
bysort year country: egen classified_opstock = total(op_stock * (is_unclas == 0))
label variable classified_opstock "Total classified op_stock (300번 제외)"

**********************************************************************
* STEP 5: 300번 행 제거
**********************************************************************
drop if is_unclas == 1

**********************************************************************
* STEP 6: 산업비중 계산 (in classified data)
**********************************************************************
gen ind_share_opstock = op_stock / classified_opstock
label variable ind_share_opstock "산업비중: op_stock_j / classified_opstock"

sort country year newindcode 
**********************************************************************
* STEP 7: unclassified 배분 → 최종값
**********************************************************************
gen final_opstock = op_stock + (unclas_opstock * ind_share_opstock)
label variable final_opstock "배분후 최종 op_stock (adjusted)"

* 검증: year-country별 final 합계 = 원래 total과 일치해야 함
bysort year country: egen check_final = total(final_opstock)
gen diff = abs(check_final - tot_opstock)
count if diff > 0
* → 0이어야 함 ✅
drop check_final diff

drop is_unclas
********************************************************************** 
* STEP 7: Reshape 
* country-year-industry → year-industry (국가별 변수 분리)
**********************************************************************
drop country industrycode industry op_stock tot_opstock unclas_opstock classified_opstock ind_share_opstock
		   
// Reshape: long → wide
reshape wide final_opstock, i(year newindcode newind) j(countrycode) string

rename final_opstockKR final_opstock_kr 
rename final_opstockSG final_opstock_sg

keep if year>=2005 

save "$data/IFR_robot.dta", replace 
