**********************************************************************  
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
use "$data/Emp_COE_clean.dta"

merge m:1 year newindcode using "$data/Robot_IFR_clean.dta"
drop _merge 

merge m:1 year newindcode using "$data/sgp_emp.dta"
tab year if _merge==1 // 1995~2009년도 데이터 때문, 싱가포르 고용데이터에서는 1995~2009년도 x 
drop _merge 

****** 대선연도에 맞추기 
keep if year ==2012 | year == 2017 | year == 2022 

*******************************************************************
* FD Robot j,t = FD_opstock_kr 
* FD Robot j,t(sgp) = FD_opstock_sg

* LD Robot j,t = LD_opstock_kr 
* LD Robot j,t(sgp) = LD_opstock_sg 

* Emp j,2012 
* Emp j,2012(sgp)

* Emp i,j,t = emp_ijt 
* Emp i,t = emp_it 

* Emp i,j,1995 = emp_ij1995 
* Emp i,1995 = emp_i1995 
******************************************************************* 
* X 변수 및 IV 생성
* 데이터: year × regioncode × newindcode 패널
********************************************************************
* STEP 1: 고용 비중 계산 
* emp i,j,t/emp i,t
* emp i,j,1995 / emp i,1995 
*******************************************************************
* 지역-산업별 고용 비중
gen share_ij1995 = emp_ij1995 / emp_i1995 
label var share_ij1995 "Employment share: Emp_i,j,1995 / Emp_i,1995"

gen share_ijt = emp_ijt / emp_it
label var share_ijt "Employment share: Emp_i,j,1995 / Emp_i,1995"
*******************************************************************
* STEP 2: 로봇 밀도 계산 (산업별)
*******************************************************************
* Long Difference
gen robot_density_LD_kr = LD_opstock_kr / emp_j2012 
gen robot_density_LD_sg = LD_opstock_sg / sgp_empl_j2012

label var robot_density_LD_kr "Korea: ΔRobot_j(LD) / Emp_j,2012"
label var robot_density_LD_sg "Singapore: ΔRobot_j(LD) / Emp_j,2012"

* First Difference
gen robot_density_FD_kr = FD_opstock_kr / emp_j2012 
gen robot_density_FD_sg = FD_opstock_sg /sgp_empl_j2012

label var robot_density_FD_kr "Korea: ΔRobot_j(FD) / Emp_j,2012"
label var robot_density_FD_sg "Singapore: ΔRobot_j(FD) / Emp_j,2012"
*******************************************************************
* STEP 3: X 변수 (지역별 로봇 노출도) - Long Difference
*******************************************************************
* X_i,t = Σ_j (Emp_i,j,t / Emp_i,t) × (ΔRobot_j,t / Emp_j,2012)

* 지역-연도별로 합산
sort regioncode year newindcode

* Long Difference
by regioncode year: egen X_robot_LD = total(share_ijt * robot_density_LD_kr) if inlist(year, 2017, 2022)
label var X_robot_LD "Robot Exposure (LD): Korea robot × 1995 shares"

* First Difference  
by regioncode year: egen X_robot_FD = total(share_ijt * robot_density_FD_kr) if inlist(year, 2017, 2022)
label var X_robot_FD "Robot Exposure (FD): Korea robot × 1995 shares"

*******************************************************************
* STEP 4: IV (도구변수) - Singapore robot
*******************************************************************
* IV_i,t = Σ_j (Emp_i,j,1995 / Emp_i,1995) × (ΔRobot_j,SG,t / Emp_j,SG,2012)

* Long Difference
by regioncode year: egen IV_robot_LD = total(share_ij1995 * robot_density_LD_sg) if inlist(year, 2017, 2022)
label var IV_robot_LD "Robot IV (LD): Singapore robot × KR 1995 shares"

* First Difference
by regioncode year: egen IV_robot_FD = total(share_ij1995 * robot_density_FD_sg) if inlist(year, 2017, 2022)
label var IV_robot_FD "Robot IV (FD): Singapore robot × KR 1995 shares"


collapse (mean) X_robot_LD X_robot_FD IV_robot_LD IV_robot_FD ///
         (first) sido_nm sigungu_nm, ///
         by(regioncode year)

save "$data/Robot_COE_merged.dta", replace
*******************************************************************
* STEP 8: 회귀분석 예시
*******************************************************************
/*
* Long Difference - 2017년
reghdfe outcome X_robot_LD controls if year == 2017, ///
    absorb(regioncode) cluster(regioncode)

* Long Difference - 2017년 (IV)
ivreghdfe outcome controls (X_robot_LD = IV_robot_LD) if year == 2017, ///
    absorb(regioncode) cluster(regioncode) first

* First Difference - Pooled (2017 + 2022)
reghdfe outcome X_robot_FD controls if inlist(year, 2017, 2022), ///
    absorb(regioncode year) cluster(regioncode)

* First Difference - Pooled (IV)
ivreghdfe outcome controls (X_robot_FD = IV_robot_FD) if inlist(year, 2017, 2022), ///
    absorb(regioncode year) cluster(regioncode) first
*/
