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
tab _merge // all matched 
drop _merge 

compress 
destring newindcode, replace 
drop delivered // operatinoal stock만 사용 

// 필터링 
keep if country == "Singapore" | country == "Rep. of Korea"
keep if year>=2005

tab newindcode, m  // 100=all industries, 200 = metal, unspecified, 300 = unspecified 

drop if newindcode==100 | newindcode == 200 
drop if newindcode==. 

bysort year country: egen tot_opstock = total(op_stock) // unspeicified, classified 포함 total stock 

sort country year newindcode 
tab newindcode // 각산업별로 동일 관측치 개수인지 확인하기 
tab year 
tab year country // unspecified 포함 20개씩 
********************************************************************** 
* STEP 3: total unclassified (300번만)
********************************************************************** 
gen is_unclas = (newindcode == 300)

* unclassified 총합 (year-country 단위)
bysort year country: egen tot_unclas = total(op_stock * is_unclas)
label variable tot_unclas "Total unclassified op_stock (300번)"
********************************************************************** 
* STEP 4: total classified (unclassified 제외한 나머지)
********************************************************************** 
bysort year country: egen classified_opstock = total(op_stock * (is_unclas == 0))
label variable classified_opstock "Total classified op_stock (300번 제외)"

**********************************************************************
* STEP 5: 300번 행 제거
**********************************************************************
sort country year newindcode 
order year country industrycode industry newind newindcode countrycode op_stock tot_opstock is_unclas tot_unclas classified_opstock

// drop if is_unclas == 1

**********************************************************************
* STEP 6: 산업비중 계산 (in classified data)
**********************************************************************
gen ind_share_opstock = op_stock / classified_opstock if newindcode !=300 
label variable ind_share_opstock "산업비중: op_stock_j / classified_opstock"

sort country year newindcode 
**********************************************************************
* STEP 7: unclassified 배분 → 최종값
**********************************************************************
gen final_opstock = op_stock + (tot_unclas * ind_share_opstock) if newindcode !=300 
label variable final_opstock "배분후 최종 op_stock (adjusted)"

sort year country newindcode 

drop if newindcode ==300 

/*
* 검증 
bys year country: egen final_sum = total(final_opstock)
count if final_sum != tot_opstock
br if final_sum != tot_opstock 
*/

********************************************************************** 
* STEP 8: Reshape 
* country-year-industry → year-industry (국가별 변수 분리) 
* -> industry 단위 데이터로 
**********************************************************************
drop country industrycode industry op_stock tot_opstock tot_unclas classified_opstock ind_share_opstock is_unclas 
		   
// Reshape: long → wide
reshape wide final_opstock, i(year newindcode newind) j(countrycode) string

save "$interim/IFR/IFR_long.dta",replace 

rename final_opstockKR rb_kr 
rename final_opstockSG rb_sg

reshape wide rb_kr rb_sg, i(newindcode newind) j(year) 
save "$interim/IFR/IFR_wide.dta",replace
save "$data/IFR_robot.dta", replace

**********************************************************************
* 제조업만 포함 버전 (newindcode 107~119)
* unclassified(300번) 배분도 제조업 산업끼리만 다시 계산
**********************************************************************
preserve
    use "$prof_raw/IFR2023_industry.dta", clear
    merge m:1 industry using "$prof_raw/RobotInd.dta"
    drop _merge
    compress
    destring newindcode, replace
    drop delivered

    keep if country == "Singapore" | country == "Rep. of Korea"
    keep if year>=2005

    drop if newindcode==100 | newindcode == 200
    drop if newindcode==.

    * 제조업(107~119) + unclassified(300)만 남겨서 그 안에서 배분
    keep if (newindcode>=107 & newindcode<=119) | newindcode==300

    bysort year country: egen tot_opstock_manu = total(op_stock)

    gen is_unclas_manu = (newindcode == 300)
    bysort year country: egen tot_unclas_manu = total(op_stock * is_unclas_manu)
    label variable tot_unclas_manu "Total unclassified op_stock (300번, 제조업 기준)"

    bysort year country: egen classified_opstock_manu = total(op_stock * (is_unclas_manu == 0))
    label variable classified_opstock_manu "Total classified op_stock (제조업, 300번 제외)"

    gen ind_share_opstock_manu = op_stock / classified_opstock_manu if newindcode !=300
    label variable ind_share_opstock_manu "산업비중: op_stock_j / classified_opstock (제조업 내)"

    gen final_opstock_manu = op_stock + (tot_unclas_manu * ind_share_opstock_manu) if newindcode !=300
    label variable final_opstock_manu "배분후 최종 op_stock (제조업 내 배분, adjusted)"

    drop if newindcode ==300

    drop country industrycode industry op_stock tot_opstock_manu tot_unclas_manu classified_opstock_manu ind_share_opstock_manu is_unclas_manu

    reshape wide final_opstock_manu, i(year newindcode newind) j(countrycode) string
    save "$interim/IFR/IFR_long_mfg.dta",replace

    rename final_opstock_manuKR rb_kr_manu
    rename final_opstock_manuSG rb_sg_manu

    reshape wide rb_kr_manu rb_sg_manu, i(newindcode newind) j(year)
    save "$interim/IFR/IFR_wide_mfg.dta",replace
    save "$data/IFR_robot_mfg.dta", replace
restore
**********************************************************************
