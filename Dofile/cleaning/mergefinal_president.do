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
use "$data/X_final.dta"

merge m:1 regioncode year using "$data/Y_final.dta"
drop _merge 

merge m:1 regioncode year using "$data/demoshare_control.dta"
drop _merge 

merge m:1 regioncode year using "$data/immi_control.dta"
drop _merge 

merge m:1 regioncode year using "$data/manu_control.dta"
drop _merge 

save "$final/Final_president.dta", replace 
