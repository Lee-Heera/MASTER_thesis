**********************************************************************
* Robot exposure & employment share panel (newindcode x year)
* - IFR robot stock(KR) + KLIPS 산업별 고용을 merge
* - Figure_v3.do의 robot/emp exposure, employment share 그래프용 입력 데이터 생성
**********************************************************************
clear all

	global main "/Users/ihuila/Research/MASTER_thesis"
	global data "${main}/Data cleaned"
	global interim "${main}/Data interim"

**********************************************************************
* 1. 산업별 고용 패널: kor_empl (region-industry, wide) -> newindcode x year, long
**********************************************************************
use "$interim/COE_empl_control.dta" 


// "$interim/IFR_figure.dta" // unspecified industry -> distributed 


* emp_j[year] = 산업 j의 전국 총고용(연도별), region 행마다 동일한 값이 반복되어 있음
keep newindcode emp_j*
collapse (mean) emp_j*, by(newindcode)

* emp_j1995, emp_j2005-emp_j2022 -> year를 행으로 reshape
reshape long emp_j, i(newindcode) j(year)

* 산업별 고용 비중 (employment share)
bysort year: egen total_emp = total(emp_j)
gen emp_share = emp_j / total_emp

tempfile emp_panel
save `emp_panel'

**********************************************************************
* 2. IFR robot stock과 merge -> robot exposure 계산
**********************************************************************
use "$interim/IFR/IFR_long.dta", clear // 이미 unspecified robot -> distributed 된 로봇 수 

* IFR: newindcode x year (2005-2022), emp_panel: newindcode x year (1995, 2005-2022)
* -> 겹치는 2005-2022만 사용
merge 1:1 newindcode year using `emp_panel', keep(match) nogen

* robot exposure: 노동자 1,000명당 로봇 수
gen robot_exposure = final_opstockKR / emp_j * 1000

order newindcode newind year final_opstockKR final_opstockSG emp_j emp_share robot_exposure
sort newindcode year

save "$interim/IFR/IFR_emp_merged.dta", replace
