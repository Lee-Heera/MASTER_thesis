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
	global raw "${main}/Data raw"	
	/*
	global ifr "${main}/Data raw/IFR"
	global kepco  "${main}/Data raw/KEPCO"
	global oarlr "${main}/Data raw/OARLR"
	global singapore "${main}/Data raw/Singapore"
	*/
	
********************************************************************** 
use "${interim}/Klips_crosswalk.dta"

tab year 

keep if year==1998 

tab p_age 
tab p_sex 

// p_age p_sex p_edu p_region h0142


merge m:1 p_job "${interim}/Klips_crosswalk.dta"
keep p_jobfam2000 p_jobfam2007 p_jobfam2017 p_age p_sex p_edu p_region p_econstat p_employ_type p_firm_size p_hours p_married p_religion p_wage
tab p6601 

// p6602 p6603 p6604 p6615

tab p9211

// p9211 p9212 p9213 p9214 p9215 p9216 p9217 p9218 p9219 p9220 p9221 p9222 p9223


