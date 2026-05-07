**********************************************************************  
* Robot and automation
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
	
	
/*******************************************************************************
	import excel
*******************************************************************************/
import excel "$prof_raw/mrsd_65_annl_emp_lvl_by_ind_singapore.xlsx", sheet("SSIC1996") cellrange(A3) firstrow clear
//drop SSIC1996
forvalues i = 1990(1)2000 {
	rename Dec`i' sgp_empl`i'

	destring sgp_empl`i', force replace
}
drop if Industry == ""
drop N O P
save "$prof_raw/interim/sgp_empl1.dta", replace


import excel "$prof_raw/mrsd_65_annl_emp_lvl_by_ind_singapore.xlsx", sheet("SSIC2005") cellrange(A3) firstrow clear
//drop SSIC2005
	rename C sgp_empl2001
	rename D sgp_empl2002
	rename E sgp_empl2003
	rename F sgp_empl2004
	rename G sgp_empl2005
	rename H sgp_empl2006
	rename I sgp_empl2007
forvalues i = 2001(1)2007 {
	destring sgp_empl`i', force replace
}
drop if Industry == ""
drop J - O
save "$prof_raw/interim/sgp_empl2.dta", replace

import excel "$prof_raw/mrsd_65_annl_emp_lvl_by_ind_singapore.xlsx", sheet("SSIC2020") cellrange(A3) firstrow clear
//drop SSIC2020
	rename C sgp_empl2008
	rename D sgp_empl2009
	rename E sgp_empl2010
	rename F sgp_empl2011
	rename G sgp_empl2012
	rename H sgp_empl2013
	rename I sgp_empl2014
	rename J sgp_empl2015
	rename K sgp_empl2016
	rename L sgp_empl2017
	rename M sgp_empl2018
	rename N sgp_empl2019
	rename O sgp_empl2020
	rename P sgp_empl2021
	rename Q sgp_empl2022
	rename R sgp_empl2023
	rename S sgp_empl2024
	rename T sgp_empl2025
forvalues i = 2008(1)2025 {
	destring sgp_empl`i', force replace
}
drop if Industry == ""
drop U - W
save "$prof_raw/interim/sgp_empl3.dta", replace

