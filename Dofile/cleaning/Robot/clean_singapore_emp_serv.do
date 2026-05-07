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
**********************************************************************	
use "$prof_raw/interim/sgp_empl3.dta"

compress 

ren SSIC2020 Indnm 
ren Industry SSIC2020 


// 산업분류 
gen newindcode = 106 if inlist(Indnm, "G46-47", "H49-53", "I55-56", "J58-63")
replace newindcode = 106 if inlist(Indnm, "L68", "N77-82", "O84", "Q86-88") 
replace newindcode = 106 if inlist(Indnm, "R90-93", "S, T, U")
replace  newindcode = 106 if inlist(Indnm, "M69-70 ", "M71 ", "K64-66 ")

replace newindcode = 104 if Indnm == "F41-43"
replace newindcode = 105 if Indnm == "O85"

keep if Indnm == "A, B, D, E" | newindcode !=. 

// aggregated variable -> split (101, 102, 103)
expand 3 if Indnm == "A, B, D, E"

foreach var of varlist sgp_empl2008-sgp_empl2025 {
    replace `var' = `var' / 3 if Indnm == "A, B, D, E"
}

replace newindcode = 101 in 16
replace newindcode = 102 in 17 
replace newindcode = 103 in 18 

replace SSIC2020 = "Agriculture, forestry, fishing" if newindcode == 101
replace SSIC2020 = "Mining and quarrying" if newindcode == 102
replace SSIC2020 = "Electricity, gas, water supply" if newindcode == 103

collapse (sum) sgp_empl2008-sgp_empl2025, by(newindcode)

reshape long  sgp_empl, i(newindcode) j(year)

// 단위: 천단위 (원자료에서 이미 1000명단위)
// 6개 산업 

keep if year >= 2010 & year <= 2022 

save "$interim/sgp_emp_service.dta", replace 
