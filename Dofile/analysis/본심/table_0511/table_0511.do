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
*******************************************************************************
use "$final/Final_president.dta"

label var Z_SD ""
label var X_SD ""

label var Z_SD "SG_IV"
label var X_SD "KR_X"
. 
. label variable Z_SD ""

. label variable X_SD ""


tab year // 2007, 2012, 2017, 2022 

sort regioncode year 
xtset regioncode year // balanced panel 

order year regioncode sido_nm sigungu_nm 
global fixed i.year 
global LD2007 aged_share_2007 college_share_2007
global LD2012 aged_share_2012 college_share_2012
global SD aged_share_SD college_share_SD 

gen filter = 1 if year >=2007 & year <= 2017 
xi: xtivreg2 SD_conserv2_p  (X_SD = Z_SD),fe cluster(regioncode) robust first
gen sample=e(sample)

count if filter != sample & year>=2007 & year<=2017 

*******************************************************************************
********************** summary statistics 
* outcome variables 
tabstat SD_turnout if sample==1, stat(mean sd min max N)
tabstat SD_conserv1_p if sample==1, stat(mean sd min max N)
tabstat SD_conserv2_p if sample==1, stat(mean sd min max N)

* explanatory variables 
tabstat X_SD if sample==1, stat(mean sd min max N)
tabstat Z_SD if sample==1, stat(mean sd min max N)

* control variables 
tabstat aged_share_SD if sample==1, stat(mean sd min max N)
tabstat college_share_SD  if sample==1, stat(mean sd min max N)

/*
* Using estpost
ssc install estout

estpost tabstat SD_turnout SD_conserv1_p SD_conserv2_p ///
    X_SD Z_SD aged_share_SD college_share_SD ///
    if sample==1, ///
    statistics(mean sd min max count) ///
    columns(statistics)
*/
esttab , ///
    cells("mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3)) count(fmt(0))") ///
    nomtitle nonumber replace
	
*******************************************************************************
********************** first stage regression 
xtreg X_SD Z_SD if sample==1 , fe 
est store fir1 

xtreg X_SD Z_SD  $fixed if sample==1 , cluster(regioncode) fe 
est store fir2 

xtreg X_SD  Z_SD $fixed $SD if sample==1 , cluster(regioncode) fe 
est store fir3 

esttab fir* , nogap stats(N widstat arf arfp) r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) 

*******************************************************************************
********************** pretrend check (Exclusion criteria)
est clear 

reg D_turnout_0207 Z_SD  if year==2007
est store pre1
reg D_conserv1_p_0207 Z_SD if year==2007 
est store pre2
reg D_conserv2_p_0207 Z_SD if year==2007 
est store pre3

reg D_turnout_0207 Z_SD if year==2007, robust 
est store pre4
reg D_conserv1_p_0207 Z_SD if year==2007 , robust 
est store pre5
reg D_conserv2_p_0207 Z_SD if year==2007 , robust 
est store pre6

reg D_turnout_0207 Z_SD $SD if year==2007 , robust 
est store pre7
reg D_conserv1_p_0207 Z_SD $SD if year==2007, robust 
est store pre8
reg D_conserv2_p_0207 Z_SD $SD if year==2007 , robust 
est store pre9

cd "$main/Output/table/0511"
	
esttab pre* , nogap stats(N r2 F) r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) 
			
********************** (Stacked difference 2007-2022) ************************
*********** Main Table 1(Panel A) - OLS 
est clear 

xi: reg SD_turnout $fixed $SD X_SD if sample==1 , vce(cluster regioncode) 
est store m7

xi: reg  SD_conserv1_p $fixed $SD X_SD if sample==1, vce(cluster regioncode)
est store m8

xi: reg SD_conserv2_p $fixed $SD X_SD if sample==1, vce(cluster regioncode)
est store m9 

esttab m*, nogap stats(cdf widstat arf arfp N) r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) 

*********** Main Table 1(Panel B) - FE 
est clear 
xi: xtivreg2  SD_turnout $fixed $SD X_SD if sample==1, cluster(regioncode) robust first fe 
est store m7

xi: xtivreg2  SD_conserv1_p $fixed $SD X_SD if sample==1, cluster(regioncode) robust first fe 
est store m8

xi:  xtivreg2 SD_conserv2_p $fixed $SD X_SD if sample==1, cluster(regioncode) robust first fe 
est store m9

esttab m*, nogap stats(cdf widstat arf arfp N) r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) 

*********** Main Table 1 (Panel C) - FEIV 
est clear 

xi: xtivreg2  SD_turnout $fixed $SD (X_SD = Z_SD) if sample==1, ///
cluster(regioncode) robust first fe 
est store m7

xi: xtivreg2  SD_conserv1_p $fixed $SD (X_SD = Z_SD) if sample==1, ///
cluster(regioncode) robust first fe 
est store m8

xi: xtivreg2 SD_conserv2_p $fixed $SD (X_SD = Z_SD) if sample==1 , ///
cluster(regioncode) robust first fe 
est store m9 

esttab m*, nogap stats(cdf widstat arf arfp N) r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) 

***********************
***  fe 옵션 안넣은 버전 
est clear 
ivreg2  SD_turnout $fixed $SD (X_SD = Z_SD) if sample==1, cluster(regioncode) robust first 
est store m7

ivreg2 SD_conserv1_p $fixed $SD (X_SD = Z_SD) if sample==1, cluster(regioncode) robust first 
est store m8

ivreg2 SD_conserv2_p $fixed $SD (X_SD = Z_SD) if sample==1 , cluster(regioncode) robust first 
est store m9 

esttab m*, nogap stats(cdf widstat arf arfp N) r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) 
*******************************************************************
************ Main Table 2 - only competitive region 
est clear 
xi: xtivreg2  SD_turnout $fixed $SD (X_SD = Z_SD) if sample==1&dum_competitive1==1 , ///
cluster(regioncode) robust first fe 
est store m7

xi: xtivreg2  SD_conserv1_p $fixed $SD (X_SD = Z_SD) if sample==1&dum_competitive1==1, ///
cluster(regioncode) robust first fe 
est store m8

xi: xtivreg2  SD_conserv2_p $fixed $SD (X_SD = Z_SD) if sample==1&dum_competitive1==1, ///
cluster(regioncode) robust first fe 
est store m9

esttab m*, nogap stats(cdf widstat arf arfp N) r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) 


/*
********************** (Stacked difference 2012-2022) ************************
est clear 
xi: xtivreg2 SD_turnout $fixed $SD (X_SD = Z_SD) if year>=2012 & year<=2022,fe cluster(regioncode) robust first
est store m1

xi: xtivreg2 SD_conserv1_p $fixed $SD (X_SD = Z_SD)  if year>=2012 & year<=2022 ,fe cluster(regioncode) robust first
est store m2

xi: xtivreg2 SD_conserv2_p $fixed $SD  (X_SD = Z_SD)  if year>=2012 & year<=2022 ,fe cluster(regioncode) robust first
est store m3 
esttab m*, nogap stats(N widstat arf arfp) r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) 

xi: xtivreg2 SD_turnout   (X_SD = Z_SD)  if year>=2012 & year<=2022 ,fe cluster(regioncode) robust first
est store m4

xi: xtivreg2 SD_conserv1_p  (X_SD = Z_SD)  if year>=2012 & year<=2022 ,fe cluster(regioncode) robust first
est store m5

xi: xtivreg2 SD_conserv2_p  (X_SD = Z_SD)  if year>=2012 & year<=2022 ,fe cluster(regioncode) robust first
est store m6 

ivreg2  SD_turnout $fixed $SD immi_share_SD mfg_share_SD (X_SD = Z_SD)  if year>=2012 & year<=2022, cluster(regioncode) robust first
est store m7

ivreg2  SD_conserv1_p $fixed $SD immi_share_SD mfg_share_SD (X_SD = Z_SD)  if year>=2012 & year<=2022, cluster(regioncode) robust first
est store m8

ivreg2 SD_conserv2_p $fixed $SD immi_share_SD mfg_share_SD (X_SD = Z_SD)  if year>=2012 & year<=2022, cluster(regioncode) robust first
est store m9 

esttab m*, nogap stats(N widstat arf arfp) r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) 
*/

***************************** 이질성 분석 ****************************
* immigration 
est clear 
 
xi: xtivreg2 SD_turnout $fixed $SD (X_SD = Z_SD) if sample==1 & high_immi_2007==1, ///
cluster(regioncode) robust first fe
est store m1 

xi: xtivreg2 SD_conserv1_p $fixed $SD (X_SD = Z_SD) if sample==1&high_immi_2007==1, ///
cluster(regioncode) robust first fe 
est store m2 

xi: xtivreg2 SD_conserv2_p $fixed $SD (X_SD = Z_SD) if sample==1&high_immi_2007==1, ///
cluster(regioncode) robust first fe
est store m3 

xi: xtivreg2 SD_turnout $fixed $SD (X_SD = Z_SD) if sample==1&high_immi_2007==0, ///
cluster(regioncode) robust first fe 
est store m4 

xi: xtivreg2 SD_conserv1_p $fixed $SD (X_SD = Z_SD) if sample==1&high_immi_2007==0, /// 
cluster(regioncode) robust first fe
est store m5 

xi: xtivreg2 SD_conserv2_p $fixed $SD (X_SD = Z_SD) if sample==1&high_immi_2007==0, /// 
cluster(regioncode) robust first fe
est store m6 

esttab m*, nogap stats(N cdf widstat arf arfp) r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) 

* manufacturing share 
est clear 
 
xi: xtivreg2 SD_turnout $fixed $SD (X_SD = Z_SD) if sample==1&high_mfg_2007==1, ///
cluster(regioncode) robust first fe
est store m1 

xi: xtivreg2 SD_conserv1_p $fixed $SD (X_SD = Z_SD) if sample==1&high_mfg_2007==1, ///
cluster(regioncode) robust first fe
est store m2 

xi: xtivreg2 SD_conserv2_p $fixed $SD (X_SD = Z_SD) if sample==1& high_mfg_2007==1, ///
cluster(regioncode) robust first fe
est store m3 

xi: xtivreg2 SD_turnout $fixed $SD (X_SD = Z_SD) if sample==1& high_mfg_2007==0, ///
cluster(regioncode) robust first fe
est store m4 

xi: xtivreg2 SD_conserv1_p $fixed $SD (X_SD = Z_SD) if sample==1&high_mfg_2007==0, ///
cluster(regioncode) robust first fe
est store m5 

xi: xtivreg2 SD_conserv2_p $fixed $SD (X_SD = Z_SD) if sample==1&high_mfg_2007==0, ///
cluster(regioncode) robust first fe
est store m6 

esttab m*, nogap stats(N cdf widstat arf arfp) r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) 

*************************************************************************
******************** Robustness check - addtional control 
est clear 

xi: xtivreg2  SD_turnout $fixed $SD mfg_share_SD immi_share_SD (X_SD = Z_SD) if sample==1, ///
cluster(regioncode) robust first fe 
est store m7

xi: xtivreg2  SD_conserv1_p $fixed $SD mfg_share_SD immi_share_SD (X_SD = Z_SD) if sample==1, ///
cluster(regioncode) robust first fe 
est store m8

xi: xtivreg2 SD_conserv2_p $fixed $SD mfg_share_SD immi_share_SD  (X_SD = Z_SD) if sample==1 , ///
cluster(regioncode) robust first fe 
est store m9 

esttab m*, nogap stats(cdf widstat arf arfp N) r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) 










