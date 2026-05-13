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
use "$data/kor_empl.dta" // COE 데이터만 미리 변수 만들어놓고 2005년도 이후 데이터로 컷해놓음 

merge m:1 year newindcode using "$data/sgp_empl.dta" // 둘다 2005~부터 있음 
drop _merge 

merge m:1 year newindcode using "$data/IFR_robot.dta" // 둘다 2005~부터 있음 
drop _merge 

*****************************************************
* emp_ j,고정연도 (singapore)
*****************************************************
foreach yr in 2005 2007 2010 2012 {
    preserve
    keep if year == `yr'
    collapse (mean) sgp_empl, by(newindcode)
    rename sgp_empl sgp_empj`yr'
    tempfile sgp_j`yr'
    save `sgp_j`yr''
    restore
    merge m:1 newindcode using `sgp_j`yr'', nogen
    label variable sgp_empj`yr' "Singapore employment in industry j, year `yr'"
}

drop sgp_empl
sort year regioncode  newindcode 

keep if  year==2007 | year ==2012 | year == 2017 | year == 2022 
*****************************************************
* delta_robot j (LD & SD)
* final_opstock_kr, final_opstock_sg 이미 머지되어있음
*****************************************************

* 기준연도 저장
foreach yr in 2007 2012 2017 2022 {
    preserve
    keep if year == `yr'
    collapse (mean) final_opstock_kr final_opstock_sg, by(newindcode)
    rename final_opstock_kr opstock_kr_`yr'
    rename final_opstock_sg opstock_sg_`yr'
    tempfile base`yr'
    save `base`yr''
    restore
    merge m:1 newindcode using `base`yr'', nogen
    label variable opstock_kr_`yr' "Korea: op_stock in `yr'"
    label variable opstock_sg_`yr' "Singapore: op_stock in `yr'"
}
*---------------------------------------------------------------------
* Long Difference ver1) 2007~2022
*---------------------------------------------------------------------
gen LD_opstock_kr_0722 = opstock_kr_2022 - opstock_kr_2007
gen LD_opstock_sg_0722 = opstock_sg_2022 - opstock_sg_2007
label variable LD_opstock_kr_0722 "Korea: LD Δop_stock (2007→2022)"
label variable LD_opstock_sg_0722 "Singapore: LD Δop_stock (2007→2022)"

*---------------------------------------------------------------------
* Long Difference ver2) 2007-2017 
*---------------------------------------------------------------------
gen LD_opstock_kr_0717 = opstock_kr_2017 - opstock_kr_2007  // ← 2012→2017을 2007→2017로 변경
gen LD_opstock_sg_0717 = opstock_sg_2017 - opstock_sg_2007  // ← 2012→2017을 2007→2017로 변경
label variable LD_opstock_kr_0717 "Korea: LD Δop_stock (2007→2017)"  // ← 라벨 변경
label variable LD_opstock_sg_0717 "Singapore: LD Δop_stock (2007→2017)"  // ← 라벨 변경

*---------------------------------------------------------------------
* Stacked Difference (t0 = year)
*---------------------------------------------------------------------
gen SD_opstock_kr = .
gen SD_opstock_sg = .

replace SD_opstock_kr = opstock_kr_2012 - opstock_kr_2007 if year == 2007
replace SD_opstock_sg = opstock_sg_2012 - opstock_sg_2007 if year == 2007

replace SD_opstock_kr = opstock_kr_2017 - opstock_kr_2012 if year == 2012
replace SD_opstock_sg = opstock_sg_2017 - opstock_sg_2012 if year == 2012

replace SD_opstock_kr = opstock_kr_2022 - opstock_kr_2017 if year == 2017
replace SD_opstock_sg = opstock_sg_2022 - opstock_sg_2017 if year == 2017

label variable SD_opstock_kr "Korea: SD Δop_stock (t0→t0+5)"
label variable SD_opstock_sg "Singapore: SD Δop_stock (t0→t0+5)"

* period 구분자
gen SDperiod = ""
replace SDperiod = "2007-2012" if year == 2007
replace SDperiod = "2012-2017" if year == 2012
replace SDperiod = "2017-2022" if year == 2017
label variable SDperiod "Stacked period identifier"

drop final_opstock_kr final_opstock_sg

sort year regioncode newindcode
compress
******************************************************************* 
* X 변수 및 IV 생성
* 데이터: year × regioncode × newindcode 패널
* X - share year 고정: 2005
* IV - share year: 1995 
* X, IV - shock denominator year: 2005 
********************************************************************
*---------------------------------------------------------------------
* Long Difference ver1) 2007~2022
*---------------------------------------------------------------------
* X: share05 × (LD_kr_0722 / emp_j2005)
gen X_ij_LD0722 = share05 * (LD_opstock_kr_0722 / emp_j2005)
bysort regioncode year: egen X_LD0722_all = total(X_ij_LD0722)
gen X_LD0722 = X_LD0722_all if year == 2007
label variable X_LD0722 "Bartik X: LD 2007-2022 (share05, emp_j2005)"
drop X_LD0722_all

* IV: share95 × (LD_sg_0722 / sgp_empj2005)
gen Z_ij_LD0722 = share95 * (LD_opstock_sg_0722 / sgp_empj2005)
bysort regioncode year: egen Z_LD0722_all = total(Z_ij_LD0722)
gen Z_LD0722 = Z_LD0722_all if year == 2007
label variable Z_LD0722 "Bartik IV: LD 2007-2022 (share95, sgp_empj2005)"
drop Z_LD0722_all

drop X_ij_LD0722 Z_ij_LD0722

*---------------------------------------------------------------------
* Long Difference ver2) 2007-2017
*---------------------------------------------------------------------
* X
gen X_ij_LD0717 = share05 * (LD_opstock_kr_0717 / emp_j2005)  // ← 변수명 변경
bysort regioncode year: egen X_LD0717_all = total(X_ij_LD0717)  // ← 변수명 변경
gen X_LD0717 = X_LD0717_all if year == 2007  // ← year == 2012를 2007로 변경
label variable X_LD0717 "Bartik X: LD 2007-2017 (share05, emp_j2005)"  // ← 라벨 변경
drop X_LD0717_all

* IV
gen Z_ij_LD0717 = share95 * (LD_opstock_sg_0717 / sgp_empj2005)  // ← 변수명 변경
bysort regioncode year: egen Z_LD0717_all = total(Z_ij_LD0717)  // ← 변수명 변경
gen Z_LD0717 = Z_LD0717_all if year == 2007  // ← year == 2012를 2007로 변경
label variable Z_LD0717 "Bartik IV: LD 2007-2017 (share95, sgp_empj2005)"  // ← 라벨 변경
drop Z_LD0717_all

drop X_ij_LD0717 Z_ij_LD0717  

*---------------------------------------------------------------------
* Stacked Difference
*---------------------------------------------------------------------
* X
gen X_ij_SD = share05 * (SD_opstock_kr / emp_j2005)
bysort regioncode year: egen X_SD_all = total(X_ij_SD)
gen X_SD = X_SD_all if inlist(year, 2007, 2012, 2017)
drop X_SD_all
label variable X_SD "Bartik X: SD (share05, emp_j2005)"

* IV
gen Z_ij_SD = share95 * (SD_opstock_sg / sgp_empj2005)
bysort regioncode year: egen Z_SD_all = total(Z_ij_SD)
gen Z_SD = Z_SD_all if inlist(year, 2007, 2012, 2017)
drop Z_SD_all
label variable Z_SD "Bartik IV: SD (share95, sgp_empj2005)"

*---------------------------------------------------------------------
* 검증
*---------------------------------------------------------------------
sum X_LD0722 if year == 2007   // 값 있어야 함 ✅
sum X_LD0722 if year == 2012   // missing이어야 함 ✅
sum X_LD0717 if year == 2007   // 값 있어야 함 ✅  ← 변경됨
sum X_LD0717 if year == 2012   // missing이어야 함 ✅  ← 변경됨
sum X_SD if year == 2022       // missing이어야 함 ✅
sort year regioncode newindcode
 
keep year regioncode sido_nm sigungu_nm SDperiod ///
     X_LD0722 Z_LD0722 X_LD0717 Z_LD0717 X_SD Z_SD  // 

duplicates drop year regioncode, force
isid year regioncode  // unique해야 함 

drop if sido_nm=="세종특별자치시" 
drop if sido_nm=="제주특별자치도" 

tab year 

save "$data/X_final.dta", replace
