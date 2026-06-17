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
**********************************************************************
* Industry(j)-level KR vs SG 비교: (1) 2005 employment share, (2) Δrobot stock
**********************************************************************
preserve
    use "$data/kor_empl.dta", clear
    keep newindcode newind emp_j2005
    duplicates drop
    isid newindcode

    merge 1:1 newindcode using "$data/sgp_empl.dta", keepusing(sgp_empj2005) nogen assert(3)
    merge 1:1 newindcode using "$data/IFR_robot.dta", nogen assert(3)

    **************************************************************
    * (1) 2005 employment share: KR vs SG
    **************************************************************
    egen kr_emp_total = total(emp_j2005)
    egen sg_emp_total = total(sgp_empj2005)
    gen kr_share2005 = emp_j2005 / kr_emp_total
    gen sg_share2005 = sgp_empj2005 / sg_emp_total

    graph hbar kr_share2005 sg_share2005, over(newind, sort(kr_share2005) descending) ///
        bar(1, fcolor(black) lcolor(black)) ///
        bar(2, fcolor(white) lcolor(black)) ///
        legend(order(1 "Korea" 2 "Singapore") position(5) ring(0)) ///
        ytitle("Employment Share in 2005") ///
        title("") ///
        name(emp_share_2005, replace)
    graph export "$output/figure/0607/emp_share_2005_korea_sg.pdf", replace name(emp_share_2005)

    pwcorr kr_share2005 sg_share2005, sig

    **************************************************************
    * (2) Change in robot stock (2007-2022): KR vs SG
    **************************************************************
    gen drobot_kr = rb_kr2022 - rb_kr2007
    gen drobot_sg = rb_sg2022 - rb_sg2007

    graph hbar drobot_kr drobot_sg, over(newind, sort(drobot_kr) descending) ///
        bar(1, fcolor(black) lcolor(black)) ///
        bar(2, fcolor(white) lcolor(black)) ///
        legend(order(1 "Korea" 2 "Singapore") position(5) ring(0)) ///
        ytitle("Change in Robot Stock") ///
        title("") ///
        name(drobot_0722, replace)
    graph export "$output/figure/0607/drobot_0722_korea_sg.pdf", replace name(drobot_0722)

    pwcorr drobot_kr drobot_sg, sig
restore


use "$data/X_final_beforeduplicates.dta", clear
keep if year==2007 | year==2012 | year==2017 | year==2022 

***************** 2005 employment share 


**************** change in the stock of robot : KR vs. SG 

collapse (mean) drobot_kr_SD drobot_sg_SD, by(newindcode year)
pwcorr drobot_kr drobot_sg, sig

xtset newindcode year 
corr drobot_kr drobot_sg
local r = r(rho)
local n = r(N)
local t = `r' * sqrt((`n'-2) / (1-`r'^2))
local p = 2*ttail(`n'-2, abs(`t'))

display "corr (rho)  = " %12.10f `r'
display "N           = " `n'
display "t-statistic = " %12.6f `t'
display "p-value     = " %12.10f `p'


preserve
    use "$data/X_final_beforeduplicates.dta", clear

    keep newindcode newind drobot_kr_0712 drobot_kr_1217 drobot_kr_1722 ///
                            drobot_sg_0712 drobot_sg_1217 drobot_sg_1722

    duplicates drop
    isid newindcode

    * wide -> long: newindcode x period(0712/1217/1722) 패널로 변환
    reshape long drobot_kr_ drobot_sg_, i(newindcode newind) j(year) string

    rename drobot_kr_ drobot_kr
    rename drobot_sg_ drobot_sg

    * newindcode x period (19 x 3 = 57) 패널에서 correlation
    pwcorr drobot_kr drobot_sg, sig

    * period별로 따로 보고싶으면
    pwcorr drobot_kr drobot_sg if year=="2007", sig
	pwcorr drobot_kr drobot_sg if year=="2012", sig
	pwcorr drobot_kr drobot_sg if year=="2017", sig
restore

// keep if country == "Rep. of Korea" 
// keep if newindcode >= 101 & newindcode <= 119   // all industries(100)/unspecified(200,300) 제외

keep year newindcode newind share2005 emp_j2005 sgp_empj2005 

collapse (mean) emp_j2005 sgp_empj2005 ,by(newindcode newind)

//keep if year==2007 
//drop year 

egen totalkr = total(emp_j2005)
egen totalsg = total(sgp_empj2005)
//drop year 

gen share_kr = emp_j2005/totalkr
gen share_sg = sgp_empj2005/ totalsg

graph hbar share_kr share_sg, over(newind, sort(share_kr) descending) ///
    bar(1, fcolor(black) lcolor(black)) ///
    bar(2, fcolor(white) lcolor(black)) ///
    legend(order(1 "Korea" 2 "Singapore") position(6)) ///
    ytitle("Share of Employment (2005)") ///
    title("Employment Share by Industry, 2005: Korea vs Singapore") ///
    name(emp_share_2005, replace)

graph export "emp_share_2005_korea_sg.pdf", replace name(emp_share_2005)

* 방법 2: corr로 rho, N 받아서 t-stat, p-value 직접 계산 (소수점 자유롭게)
corr share_kr share_sg
local r = r(rho)
local n = r(N)
local t = `r' * sqrt((`n'-2) / (1-`r'^2))
local p = 2*ttail(`n'-2, abs(`t'))

display "corr (rho)  = " %12.10f `r'
display "N           = " `n'
display "t-statistic = " %12.6f `t'
display "p-value     = " %12.10f `p'


cd "$output/figure/0607"
sort newindcode year



preserve 
keep if year==2005 


**********************************************************************
* Robot stock share by industry, 2005: Korea vs Singapore (Fig.7 스타일)
**********************************************************************
preserve
    keep if year == 2005
    keep if inrange(newindcode, 101, 119)   // 개별 산업 코드 (전체/미분류 제외, 확인 필요)
    keep if inlist(country, "Rep. of Korea", "Singapore")

    * 국가별 산업 코드명을 짧게 매핑 (reshape용)
    gen ctry = "korea" if country == "Rep. of Korea"
    replace ctry = "sg"   if country == "Singapore"

    * 국가별 총 robot_stock 대비 산업별 share
    bysort country: egen total_stock = total(robot_stock)
    gen share = robot_stock / total_stock

    keep newind newindcode ctry share
    reshape wide share, i(newind newindcode) j(ctry) string

    graph hbar sharekorea sharesg, over(newind, sort(sharekorea) descending) ///
        bar(1, fcolor(black) lcolor(black)) ///
        bar(2, fcolor(white) lcolor(black)) ///
        legend(order(1 "Korea" 2 "Singapore") position(6)) ///
        ytitle("Share of Robot Stock (2005)") ///
        title("Robot Stock Share by Industry, 2005: Korea vs Singapore") ///
        name(robot_share_2005, replace)
    graph export "robot_stock_share_2005_korea_sg.pdf", replace name(robot_share_2005)
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


**********************************************************************
* Table 8 준비: KR vs SG industry(j)-level employment 구조 비교
*  - kor_empl.dta: region(i) x industry(j) x year(t) 패널
*    -> emp_j2005 (= 전국 industry-j 2005년 총고용)는 newindcode별로
*       region/year에 관계없이 동일 값이 반복되므로 industry 단위로 축약
*  - sgp_empl.dta: industry(j) 단위(newindcode당 1행), sgp_empj2005 포함
**********************************************************************
preserve
    use "$data/kor_empl.dta", clear
    keep newindcode newind emp_j2005
    duplicates drop
    isid newindcode

    egen kr_emp_total2005 = total(emp_j2005)
    gen kr_share2005 = emp_j2005 / kr_emp_total2005
    rename emp_j2005 kr_empj2005
    drop kr_emp_total2005

    tempfile kr_emp
    save `kr_emp'

    use "$data/sgp_empl.dta", clear
    keep newindcode newind sgp_empj2005
    rename sgp_empj2005 sg_empj2005

    egen sg_emp_total2005 = total(sg_empj2005)
    gen sg_share2005 = sg_empj2005 / sg_emp_total2005
    drop sg_emp_total2005

    merge 1:1 newindcode using `kr_emp', nogen

    order newindcode newind kr_empj2005 sg_empj2005 kr_share2005 sg_share2005
    sort newindcode

    * Table 8: KR vs SG, industry(j)-level employment level & share (2005 baseline)
    list newindcode newind kr_empj2005 sg_empj2005 kr_share2005 sg_share2005, sep(0)
restore
