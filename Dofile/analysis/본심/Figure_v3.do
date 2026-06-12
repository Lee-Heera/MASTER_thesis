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
	global output "${main}/Output"
	/*
	global ifr "${main}/Data raw/IFR"
	global kepco  "${main}/Data raw/KEPCO"
	global oarlr "${main}/Data raw/OARLR"
	global singapore "${main}/Data raw/Singapore"
	*/
	
********************************************************************** 
use "$interim/IFR/IFR_long.dta", replace // unspecified industry -> distributed 

cd  "$output/figure/0607"
sort newindcode 

* --------------------------------------------------------
* 1. [방법 A] 최근 연도(최종 연도) opstock level 기준 Top-5
*    -> "현재(최근) 로봇 도입 수준이 가장 높은 산업"
* --------------------------------------------------------

quietly summarize year
local maxyear = r(max)

preserve
    keep if year == `maxyear'
    gsort -final_opstockKR
    keep newindcode newind final_opstockKR
    list newindcode newind final_opstockKR, sep(0)

    * 상위 5개 산업명(newind, string)을 매크로로 저장
    local top5_level ""
    forvalues r = 1/5 {
        local ind = newind[`r']
        local top5_level `"`top5_level' "`ind'""'
    }
    display `"Top-5 industries (final year `maxyear' level): `top5_level'"'
restore


* --------------------------------------------------------
* 2. [방법 B] 기간 내 opstock 증가량(level change) 기준 Top-5
*    -> "로봇 도입이 가장 급격히 늘어난 산업" (robot exposure 논리에 더 부합)
* --------------------------------------------------------

quietly summarize year
local minyear = r(min)
local maxyear = r(max)

preserve
    keep if year == `minyear' | year == `maxyear'
    keep newindcode newind year final_opstockKR
    * reshape 식별자는 newindcode (numeric), newind는 같이 끌고가기 위해 별도 보존
    reshape wide final_opstockKR, i(newindcode) j(year)

    gen delta_opstock = final_opstockKR`maxyear' - final_opstockKR`minyear'
    gsort -delta_opstock
    list newindcode newind delta_opstock, sep(0)

    local top5_delta ""
    forvalues r = 1/5 {
        local ind = newind[`r']
        local top5_delta `"`top5_delta' "`ind'""'
    }
    display `"Top-5 industries (largest increase, `minyear'-`maxyear'): `top5_delta'"'
restore

/*
  1. |      115                                   electronics    191959.5 |
  2. |      116                                    automotive     91276.2 |
  3. |      114                          industrial machinery    9413.242 |
  4. |      110                        plastics and chemicals    7368.086 |
  5. |      118                          other manufacturing     3802.415 

 */ 
  
* --------------------------------------------------------
* 3. 그래프: 선택한 Top-5 산업의 시계열
*    -> 위 1단계 또는 2단계 결과를 보고 아래 리스트를 채워넣기
*       (newind에 들어있는 실제 산업명 문자열과 정확히 일치해야 함)
* --------------------------------------------------------

* 예시 — 실제 newind 값으로 교체할 것 (공백 포함 가능, 큰따옴표로 각각 감싸기)
local top5_industries `" "electronics" "automotive" "industrial machinery" "plastics and chemicals" "other manufacturing" "'

preserve
    * 선택된 산업만 남기기 (newind, string 기준 매칭)
    gen byte _top5 = 0

    local n : word count `top5_industries'
    forvalues i = 1/`n' {
        local ind : word `i' of `top5_industries'
        replace _top5 = 1 if newind == `"`ind'"'
    }

    keep if _top5 == 1

    keep newind year final_opstockKR
	

    * reshape의 j(string) 변수는 공백을 허용하지 않으므로,
    * 공백/특수문자를 제거한 임시 변수를 만들어 사용
    gen ind_lbl = subinstr(newind, " ", "", .)
    drop newind

    reshape wide final_opstockKR, i(year) j(ind_lbl) string

    describe
	


    * --------------------------------------------------------
    * 라인 그래프
    * 주의: 아래 변수명(final_opstockKRAutomotive 등)은 예시이며,
    *       위 describe 결과에 맞게 직접 수정해야 함
    * --------------------------------------------------------
    twoway ///
        (line final_opstockKRAutomotive    year, lcolor(navy)         lwidth(medthick)) ///
        (line final_opstockKRElectronics   year, lcolor(maroon)       lwidth(medthick) lpattern(dash)) ///
        (line final_opstockKRMetalProducts year, lcolor(forest_green) lwidth(medthick) lpattern(shortdash)) ///
        (line final_opstockKRMachinery     year, lcolor(orange)       lwidth(medthick) lpattern(dash_dot)) ///
        (line final_opstockKRChemicals     year, lcolor(purple)       lwidth(medthick) lpattern(longdash)) ///
        , ///
        title("Robot Operational Stock by Industry (Korea)", size(medium)) ///
        ytitle("Operational Stock") ///
        xtitle("Year") ///
        legend(order(1 "Automotive" 2 "Electronics" 3 "Metal Products" ///
                      4 "Machinery" 5 "Chemicals") ///
               position(6) rows(1) size(small)) ///
        scheme(s1color)

    graph export "robot_stock_top5_KR.png", replace width(1600)
restore


* --------------------------------------------------------
* 4. (선택) 한국 vs 싱가포르 비교 — 전체(aggregate) 시계열
* --------------------------------------------------------

preserve
    collapse (sum) final_opstockKR final_opstockSG, by(year)

    twoway ///
        (line final_opstockKR year, lcolor(navy) lwidth(medthick)) ///
        (line final_opstockSG year, lcolor(maroon) lwidth(medthick) lpattern(dash)) ///
        , ///
        title("Aggregate Robot Operational Stock: Korea vs Singapore", size(medium)) ///
        ytitle("Operational Stock") ///
        xtitle("Year") ///
        legend(order(1 "Korea" 2 "Singapore") position(6) rows(1)) ///
        scheme(s1color)

    graph export "robot_stock_KR_vs_SG.png", replace width(1600)
restore

