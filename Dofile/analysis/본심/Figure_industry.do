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
* 산업별 figure /table 
**********************************************************************
use "$interim/COE_empl_control.dta", clear

collapse (mean) emp_jt, by(newindcode newind year)

merge m:1 year newindcode using "$data/sgp_empl_long.dta"
keep if _merge==3 
drop _merge 

bysort year: egen kr_emp_total = total(emp_jt)
bysort year: egen sg_emp_total = total(sgp_empl)
gen kr_share = emp_jt   / kr_emp_total
gen sg_share = sgp_empl / sg_emp_total

pwcorr kr_share sg_share, sig          // pooled (전체 연도 합산)
bysort year: pwcorr kr_share sg_share, sig   // 연도별

**********************************************************************
* 2005년 Employment Share: Korea vs Singapore (Figure + Table, Table 8 스타일)
**********************************************************************
preserve
    keep if year == 2005
    keep newind newindcode kr_share sg_share
    sort newindcode

    * 표/그림 공통 라벨 (newindcode 기준, list로 확인 후 맞춰서 조정)
    list newindcode newind, sep(0)

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

    **************************************************************
    * Figure (industry_label 기준, 숫자형일 때 먼저 그리기)
    **************************************************************
    graph hbar kr_share sg_share, over(industry_label, sort(kr_share) descending label(labsize(small))) ///
    bar(1, fcolor(black) lcolor(black)) ///
    bar(2, fcolor(white) lcolor(black)) ///
    legend(order(1 "Korea" 2 "Singapore") position(5) ring(0)) ///
    ytitle("Employment Share (2005)") ///
    title("") ///
    bargap(30) ///
    ysize(10) xsize(7) ///
    name(emp_share_2005, replace)
graph export "$output/figure/0607/emp_share_2005_korea_sg.pdf", replace name(emp_share_2005)


	*twoway (scatter kr_share sg_share) (lfit kr_share sg_share)
    **************************************************************
    * Table (correlation 행 추가, tostring으로 문자형 변환 후)
    **************************************************************
    quietly corr kr_share sg_share
    local r = r(rho)
    local n = r(N)
    local t = `r' * sqrt((`n'-2)/(1-`r'^2))
    local p = 2*ttail(`n'-2, abs(`t'))

    tostring kr_share sg_share, replace force format(%9.4f)

    local nobs = _N + 1
    set obs `nobs'
    replace industry_label = "Correlation coefficient" in `nobs'
    replace kr_share = string(`r', "%9.4f") in `nobs'
    replace sg_share = "(p value = " + string(`p', "%9.4f") + ")" in `nobs'

    export excel industry_label kr_share sg_share ///
        using "$output/figure/0607/emp_share_2005_table.xlsx", ///
        replace firstrow(variables) sheet("emp_share_2005")
restore
