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
*******************************************************************************
* 1) change in the stock of robot 
* 2) stock of robot in 2007 
**********************************************************************
use "$prof_raw/IFR2023_industry.dta" 

merge m:1 industry using "$prof_raw/RobotInd.dta"
tab _merge // all matched 
drop _merge 

**********************************************************************
* 1) Korea / Singapore만 남기기
**********************************************************************
tab country   // 실제 국가명 표기 확인 (예: "Korea, Rep." / "Republic of Korea" 등) 후 아래 replace 조건 수정

gen ctr = ""
replace ctr = "kr" if countrycode=="KR"     // 실제 값에 맞게 수정
replace ctr = "sg" if countrycode == "SG"  // 실제 값에 맞게 수정
keep if inlist(ctr, "kr", "sg")

keep if newindcode >=101 & newindcode<=119
**********************************************************************
* industry_label (Table 8 라벨링)
**********************************************************************
     gen industry_label = newind

    replace industry_label = "Agriculture"                 if newindcode == 101  // agriculture, forestry, and fishing
    replace industry_label = "Mining"                      if newindcode == 102  // mining
    replace industry_label = "Utilities"                   if newindcode == 103  // utility
    replace industry_label = "Construction"                if newindcode == 104  // construction
    replace industry_label = "Education and research"      if newindcode == 105  // education, research, and development
    replace industry_label = "Services"                    if newindcode == 106  // services
    replace industry_label = "Food and beverages"          if newindcode == 107  // food and beverages
    replace industry_label = "Textiles"                    if newindcode == 108  // textiles (including apparel)
    replace industry_label = "Paper and printing"          if newindcode == 109  // paper and printing
    replace industry_label = "Plastics and chemicals"      if newindcode == 110  // plastics and chemicals
    replace industry_label = "Minerals"                    if newindcode == 111  // minerals
    replace industry_label = "Basic metals"                if newindcode == 112  // basic metals
    replace industry_label = "Metal products"              if newindcode == 113  // metal products
    replace industry_label = "Industrial machinery"         if newindcode == 114  // industrial machinery
    replace industry_label = "Electronics"                 if newindcode == 115  // electronics
    replace industry_label = "Automotive"                  if newindcode == 116  // automotive
    replace industry_label = "Shipbuilding and aerospace"  if newindcode == 117  // other vehicles (shipbuilding and aerospace)
    replace industry_label = "Other manufacturing"  if newindcode == 118  // other manufacturing
    replace industry_label = "Wood and furniture"  if newindcode == 119  // wood and furniture

keep newindcode industry_label ctr year op_stock
tempfile base
save `base'

**********************************************************************
* 2) 2007년 기준 Robot stock 비교: Korea vs Singapore (Table만)
**********************************************************************
preserve
    keep if year == 2007
    keep newindcode industry_label ctr op_stock

    reshape wide op_stock, i(newindcode industry_label) j(ctr) string
    rename op_stockkr kr_stock
    rename op_stocksg sg_stock

    quietly corr kr_stock sg_stock
    local r = r(rho)
    local n = r(N)
    local t = `r' * sqrt((`n'-2)/(1-`r'^2))
    local p = 2*ttail(`n'-2, abs(`t'))

    tostring kr_stock sg_stock, replace force format(%9.2f)
    local nobs = _N + 1
    set obs `nobs'
    replace industry_label = "Correlation coefficient" in `nobs'
    replace kr_stock = string(`r', "%9.4f") in `nobs'
    replace sg_stock = "(p value = " + string(`p', "%9.4f") + ")" in `nobs'

    export excel industry_label kr_stock sg_stock ///
        using "robot_stock_2007_table.xlsx", ///
        replace firstrow(variables) sheet("robot_stock_2007")
restore

**********************************************************************
* 3) Robot stock 변화량 (Short Difference): newindcode x period 패널로 직접 생성
**********************************************************************
use `base', clear
keep if inlist(year, 2007, 2012, 2017, 2022)

* newindcode + ctr 묶어서 패널 단위(unit) 생성
egen unit = group(newindcode ctr)
sort unit year

* 2007->2012->2017->2022, 모두 5년 간격이므로 delta(5)로 tsset
tsset unit year, delta(5)

* 직전 기간 대비 차분 (2012행=07-12, 2017행=12-17, 2022행=17-22)
gen drobot = D.op_stock

* 기간 라벨 생성
gen period = ""
replace period = "0712" if year == 2012
replace period = "1217" if year == 2017
replace period = "1722" if year == 2022

drop if missing(drobot)   // 2007행(직전 값 없어 차분 불가)은 제거

keep newindcode industry_label ctr period drobot

* ctr -> wide (kr/sg 분리) : newindcode x period 패널 완성
reshape wide drobot, i(newindcode industry_label period) j(ctr) string
rename drobotkr drobot_kr
rename drobotsg drobot_sg

tempfile delta
save `delta'

**********************************************************************
* 기간별로 Table만 생성 (Figure 없음)
**********************************************************************
foreach sp in 0712 1217 1722 {
    use `delta', clear
    keep if period == "`sp'"
    keep newindcode industry_label drobot_kr drobot_sg

    quietly corr drobot_kr drobot_sg
    local r = r(rho)
    local n = r(N)
    local t = `r' * sqrt((`n'-2)/(1-`r'^2))
    local p = 2*ttail(`n'-2, abs(`t'))

    tostring drobot_kr drobot_sg, replace force format(%9.2f)
    local nobs = _N + 1
    set obs `nobs'
    replace industry_label = "Correlation coefficient" in `nobs'
    replace drobot_kr = string(`r', "%9.4f") in `nobs'
    replace drobot_sg = "(p value = " + string(`p', "%9.4f") + ")" in `nobs'

    export excel industry_label drobot_kr drobot_sg ///
        using "drobot_`sp'_table.xlsx", ///
        replace firstrow(variables) sheet("drobot_`sp'")
}

********************************************************************* 
* Figure 
**********************************************************************
* 공통 준비: share 계산 + Top5 산업 정의 (KR+SG 합산, 2007년 기준)
**********************************************************************
use `base', clear
bysort ctr year: egen total_stock = total(op_stock)
gen share = op_stock / total_stock

preserve
    keep if year == 2007
    collapse (sum) share, by(newindcode industry_label)
    gsort -share
    keep if _n <= 5
    levelsof newindcode, local(top5)
restore

gen is_top5 = 0
foreach ind of local top5 {
    replace is_top5 = 1 if newindcode == `ind'
}
gen group_label = industry_label
replace group_label = "Other" if is_top5 == 0

tempfile share_data
save `share_data'

**********************************************************************
* 1) Slope chart: 2007 vs 2022 (전산업, op_stock 기준, log scale, KR/SG 각각 패널)
*    -> op_stock+1에 로그 스케일을 적용해 0->양수 전환 산업도 표현
*    -> 범례 대신 2022쪽 끝점에 산업명 라벨 표시 (겹치는 산업은 좌/우 번갈아 배치)
**********************************************************************
use `share_data', clear
keep if inlist(year, 2007, 2022)

gen plot_stock = op_stock + 1
gen xpos = (year == 2022)

* 짝수번째 산업: 2007 시작점 왼쪽에 라벨 / 홀수번째 산업: 2022 끝점 오른쪽에 라벨
gen grp = mod(newindcode - 100, 2)
gen vallabel = industry_label if (grp == 1 & year == 2022) | (grp == 0 & year == 2007)

levelsof newindcode, local(inds)

foreach c in kr sg {
    local cname Korea
    if "`c'" == "sg" local cname Singapore

    local plotcmd ""
    local i = 0
    foreach ind of local inds {
        local i = `i' + 1
        local mlabpos = 3
        if mod(`i', 2) == 0 local mlabpos = 9
        local plotcmd `"`plotcmd' (connected plot_stock xpos if newindcode==`ind' & ctr=="`c'", msymbol(none) lwidth(medthin) mlabel(vallabel) mlabposition(`mlabpos') mlabsize(tiny) mlabgap(*1))"'
    }

    twoway `plotcmd', ///
        xlabel(0 "2007" 1 "2022") xscale(range(-0.6 1.8)) ///
        yscale(log) ylabel(1 10 100 1000 10000 100000, format(%9.0fc) angle(0)) ///
        ytitle("Robot Stock (log scale)") xtitle("") ///
        legend(off) ///
        title("`cname'") ///
        ysize(6) xsize(8) ///
        name(slope_`c', replace)
    graph export "robot_stock_slope_2007_2022_`c'.pdf", replace name(slope_`c')
}
graph combine slope_kr slope_sg, rows(1) name(slope_combined, replace)
graph export "robot_stock_slope_2007_2022.pdf", replace name(slope_combined)

**********************************************************************
* 2) Heatmap: 산업 x 연도, op_stock 기준 (KR 위 / SG 아래, 전산업)
*    -> heatplot 패키지 필요: ssc install heatplot (최초 1회만)
**********************************************************************
use `share_data', clear
keep if year >= 2007 & year <= 2022
encode industry_label, gen(ind_num)

* Electronics가 압도적으로 커서 선형 스케일에서는 다른 산업이 모두 흐리게 보임 -> log 스케일 사용
gen log_stock = log(op_stock + 1)

foreach c in kr sg {
    local cname Korea
    if "`c'" == "sg" local cname Singapore

    preserve
        keep if ctr == "`c'"
        heatplot log_stock i.year i.ind_num, ///
            color(blues) ///
            xlabel(, angle(45) labsize(small)) ///
            ylabel(, labsize(vsmall) angle(0)) ///
            title("`cname'") ///
            legend(off) ///
            name(heat_`c', replace)
        graph export "robot_stock_heatmap_`c'.pdf", replace name(heat_`c')
    restore
}
graph combine heat_kr heat_sg, cols(1) ysize(10) xsize(6) name(heat_combined, replace)
graph export "robot_stock_heatmap_combined.pdf", replace name(heat_combined)

