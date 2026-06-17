**********************************************************************
* Robot exposure & employment share panel (newindcode x year)
* - IFR_figure.dta (KR, unspecified 배분 전 raw op_stock) + COE_empl_control.dta(KLIPS 고용) merge
* - Figure_v3.do의 robot/emp exposure, employment share 그래프용 입력 데이터 생성
**********************************************************************
clear all

	global main "/Users/ihuila/Research/MASTER_thesis"
	global data "${main}/Data cleaned"
	global interim "${main}/Data interim"
	global output "${main}/Output"

**********************************************************************
use "$interim/IFR_figure.dta", clear

// keep if country == "Rep. of Korea" 
// keep if newindcode >= 101 & newindcode <= 119   // all industries(100)/unspecified(200,300) 제외

keep year newindcode newind op_stock countrycode country 
rename op_stock robot_stock_raw

* 스케일링: 만 단위(10,000대)로 표시
gen robot_stock = robot_stock_raw

cd "$output/figure/0607"
sort newindcode year

**********************************************************************
* 1) trend in robot stock by national level - All industries
**********************************************************************
preserve
    keep if newindcode == 100   // All industries 총계 (확인 필요)
    keep if inlist(country, "Rep. of Korea", "United States", "Germany", "Singapore", "WORLD")

    twoway (connected robot_stock year if country=="Rep. of Korea", lcolor(navy)   mcolor(navy)   lpattern(solid)) ///
           (connected robot_stock year if country=="United States", lcolor(red)    mcolor(red)    lpattern(dash)) ///
           (connected robot_stock year if country=="Germany",       lcolor(green)  mcolor(green)  lpattern(shortdash)) ///
           (connected robot_stock year if country=="Singapore",     lcolor(orange) mcolor(orange) lpattern(dash_dot)), ///
        ytitle("Robot Stock (10,000 units)") xtitle("Year") ///
        legend(order(1 "Korea" 2 "US" 3 "Germany" 4 "Singapore") position(11) ring(0)) ///
        title("Robot Stock Trend: Korea vs. Major Countries (All Industries)") ///
        name(robot_stock_trend_all, replace)
    graph export "robot_stock_trend_all_industries.pdf", replace name(robot_stock_trend_all)
restore

**********************************************************************
* 2) trend in robot stock by national level - Manufacturing only
**********************************************************************
preserve
    keep if inrange(newindcode, 107, 119)
    keep if inlist(country, "Rep. of Korea", "United States", "Germany", "Singapore")

    collapse (sum) robot_stock, by(year country)

    twoway (connected robot_stock year if country=="Rep. of Korea", lcolor(navy)   mcolor(navy)   lpattern(solid)) ///
           (connected robot_stock year if country=="United States", lcolor(red)    mcolor(red)    lpattern(dash)) ///
           (connected robot_stock year if country=="Germany",       lcolor(green)  mcolor(green)  lpattern(shortdash)) ///
           (connected robot_stock year if country=="Singapore",     lcolor(orange) mcolor(orange) lpattern(dash_dot)), ///
        ytitle("Robot Stock (10,000 units)") xtitle("Year") ///
        legend(order(1 "Korea" 2 "US" 3 "Germany" 4 "Singapore") position(11) ring(0)) ///
        title("Robot Stock Trend: Korea vs. Major Countries (Manufacturing)") ///
        name(robot_stock_trend_mfg, replace)
    graph export "robot_stock_trend_manufacturing.pdf", replace name(robot_stock_trend_mfg)
restore


**********************************************************************
* (A) Base-year = 100 indexed trend (Manufacturing, newindcode 107-119)
**********************************************************************
preserve
    keep if inrange(newindcode, 107, 119)
    keep if inlist(country, "Rep. of Korea", "United States", "Germany", "Singapore")

    collapse (sum) robot_stock, by(year country)
	drop if year<2005
    * 국가별 최초 연도 값을 100으로 indexing
    bysort country (year): gen base = robot_stock[1]
    gen robot_index = robot_stock / base * 100
    drop base

    twoway (connected robot_index year if country=="Rep. of Korea", lcolor(navy)   mcolor(navy)   lpattern(solid)) ///
           (connected robot_index year if country=="United States", lcolor(red)    mcolor(red)    lpattern(dash)) ///
           (connected robot_index year if country=="Germany",       lcolor(green)  mcolor(green)  lpattern(shortdash)) ///
           (connected robot_index year if country=="Singapore",     lcolor(orange) mcolor(orange) lpattern(dash_dot)), ///
        ytitle("Robot Stock Index (Base year = 100)") xtitle("Year") ///
        legend(order(1 "Korea" 2 "US" 3 "Germany" 4 "Singapore") position(11) ring(0)) ///
        title("Robot Stock Trend (Indexed): Korea vs. Major Countries (Manufacturing)") ///
        name(robot_stock_trend_mfg_idx, replace)
    graph export "robot_stock_trend_manufacturing_indexed.pdf", replace name(robot_stock_trend_mfg_idx)
restore

**********************************************************************
* (B) Log scale trend (Manufacturing, newindcode 107-119)
**********************************************************************
preserve
    keep if inrange(newindcode, 107, 119)
    keep if inlist(country, "Rep. of Korea", "United States", "Germany", "Singapore")

    collapse (sum) robot_stock, by(year country)

    twoway (connected robot_stock year if country=="Rep. of Korea", lcolor(navy)   mcolor(navy)   lpattern(solid)) ///
           (connected robot_stock year if country=="United States", lcolor(red)    mcolor(red)    lpattern(dash)) ///
           (connected robot_stock year if country=="Germany",       lcolor(green)  mcolor(green)  lpattern(shortdash)) ///
           (connected robot_stock year if country=="Singapore",     lcolor(orange) mcolor(orange) lpattern(dash_dot)), ///
        yscale(log) ///
        ytitle("Robot Stock (10,000 units, log scale)") xtitle("Year") ///
        legend(order(1 "Korea" 2 "US" 3 "Germany" 4 "Singapore") position(11) ring(0)) ///
        title("Robot Stock Trend (Log Scale): Korea vs. Major Countries (Manufacturing)") ///
        name(robot_stock_trend_mfg_log, replace)
    graph export "robot_stock_trend_manufacturing_log.pdf", replace name(robot_stock_trend_mfg_log)
restore


* 색상/패턴 팔레트 (산업 개수만큼 순서대로 사용)
local colors   navy maroon forest_green orange purple teal
local patterns solid dash shortdash dash_dot longdash

* --------------------------------------------------------
* Top-5 / Bottom-3 산업 선정: robot_stock_raw 증가량(최초연도 -> 최종연도) 기준
* --------------------------------------------------------
quietly summarize year
local minyear = r(min)
local maxyear = r(max)

preserve
    keep newindcode newind year robot_stock_raw emp_share
    reshape wide robot_stock_raw emp_share, i(newindcode newind) j(year)

    gen delta_robot = robot_stock_raw`maxyear' - robot_stock_raw`minyear'
    gen delta_share = emp_share`maxyear'      - emp_share`minyear'

    gsort -delta_robot
    list newindcode newind delta_robot, sep(0)

    local top5 ""
    forvalues r = 1/5 {
        local ind = newind[`r']
        local top5 `"`top5' "`ind'""'
    }
    display `"Top-5 industries (robot stock increase, `minyear'-`maxyear'): `top5'"'

    * robot stock 증가량 최하위 3개 산업 (Bottom-3)
    local N = _N
    local bottom3 ""
    forvalues r = 0/2 {
        local ind = newind[`N' - `r']
        local bottom3 `"`bottom3' "`ind'""'
    }
    display `"Bottom-3 industries (robot stock increase, `minyear'-`maxyear'): `bottom3'"'
restore

* --------------------------------------------------------
* top5 산업에 rank(1..k) 부여 + plot/legend 명령 동적 생성
* --------------------------------------------------------
local n : word count `top5'

gen byte rank = .
local k = 0
local matched ""
forvalues i = 1/`n' {
    local ind : word `i' of `top5'
    quietly count if newind == `"`ind'"'
    if r(N) > 0 {
        local ++k
        replace rank = `k' if newind == `"`ind'"'
        local matched `"`matched' "`ind'""'
    }
    else {
        display as error `"Warning: "`ind'" not found in newind -- skipped"'
    }
}


* --------------------------------------------------------
* Top3(rank 1-3) robot stock level plot/legend 생성 (색상 + 선모양으로 구분)
* --------------------------------------------------------
local plot_robot_hl ""
local legendcmd_robot_hl ""
forvalues i = 1/3 {
    local ind     : word `i' of `matched'
    local ind     = strtrim("`ind'")
    local color   : word `i' of `colors'
    local pattern : word `i' of `patterns'
    local plot_robot_hl `"`plot_robot_hl' (line robot_stock_raw`i' year, lcolor(`color') lwidth(medthick) lpattern(`pattern'))"'
    local legendcmd_robot_hl `"`legendcmd_robot_hl' `i' "`ind'""'
}


* --------------------------------------------------------
* 그래프 1: robot stock 증가량(1995->2022 long difference) 기준 Top3 산업의 robot stock(level) 트렌드
* --------------------------------------------------------
preserve
    keep if rank <= 3
    keep year rank robot_stock_raw
    reshape wide robot_stock_raw, i(year) j(rank)

    * y축 라벨 길이로 인한 ytitle 겹침 방지: 천 단위로 스케일
    forvalues i = 1/3 {
        replace robot_stock_raw`i' = robot_stock_raw`i' / 1000
    }

    twoway `plot_robot_hl', ///
        title("", size(medium)) ///
        ytitle("Robot Stock (thousands)", size(small) margin(r+3)) ///
        xtitle("Year", size(small)) ///
        legend(order(`legendcmd_robot_hl') position(6) rows(1) size(small) region(lcolor(none))) ///
        graphregion(color(white)) plotregion(color(white)) ///
        scheme(s2color)
    graph export "robot_stock_top3.png", replace width(2000) height(1400)
restore
// Robot Stock by Industry: Top3 by {&Delta}Robot Stock, 1995-2022 (KR)

* --------------------------------------------------------
* 그래프 2: 산업별 Δrobot stock vs Δemployment share (1995 -> 2022, 19개 산업)
* -> "로봇이 많이 늘어난 산업일수록 고용비중이 더 많이 줄었는가" 상관관계
* --------------------------------------------------------
preserve
    keep newindcode newind year robot_stock_raw emp_share rank
    reshape wide robot_stock_raw emp_share, i(newindcode newind rank) j(year)

    gen delta_robot = (robot_stock_raw`maxyear' - robot_stock_raw`minyear') / 1000
    gen delta_share = emp_share`maxyear' - emp_share`minyear'

    replace newind = strtrim(newind)

    * Top-5 (robot stock 증가량 기준) 산업만 라벨링
    gen lbl = newind if rank <= 5

    * 상관관계 및 유의성 (단순회귀, n=19)
    reg delta_share delta_robot
    local b  : display %6.4f _b[delta_robot]
    local df = e(df_r)
    local t  = _b[delta_robot] / _se[delta_robot]
    local p  : display %5.3f 2*ttail(`df', abs(`t'))

    quietly sum delta_share
    local ytxt = r(max) - (r(max)-r(min))*0.05
    quietly sum delta_robot
    local xtxt = r(max) - (r(max)-r(min))*0.05

    twoway (scatter delta_share delta_robot, mlabel(lbl) mlabposition(3) mlabsize(small) msize(small) mcolor(navy)) ///
           (lfit delta_share delta_robot, lcolor(maroon) lwidth(medthick)), ///
        title("", size(medium)) ///
        ytitle("{&Delta} Employment Share", size(small) margin(r+3)) ///
        xtitle("{&Delta} Robot Stock (thousands)", size(small)) ///
        xscale(range(0 230)) ///
        text(`ytxt' `xtxt' "coeff=`b'" "p-value=`p'", size(small) place(sw)) ///
        legend(off) ///
        graphregion(color(white)) plotregion(color(white)) ///
        scheme(s2color)

    graph export "scatter_robotstock_empshare.png", replace width(2000) height(1400)
restore
// {&Delta} Robot Stock vs. {&Delta} Employment Share" "(1995-2022, by industry, KR)
