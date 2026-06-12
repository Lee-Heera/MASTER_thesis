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
import excel "$main/Data raw/순이동인구.xlsx", sheet("데이터")

ren A sido_nm 
ren B sigungu_nm 
drop C 

ren (D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC) ///
    (y2000 y2001 y2002 y2003 y2004 y2005 y2006 y2007 y2008 y2009 ///
     y2010 y2011 y2012 y2013 y2014 y2015 y2016 y2017 y2018 y2019 ///
     y2020 y2021 y2022 y2023 y2024 y2025)

drop in 1/2 

destring y2000-y2025, replace force 

replace sido_nm = sido_nm[_n-1] if sido_nm == ""
drop if sigungu_nm=="소계" 

*******************************************************************************
* 시군구명 정리 
gen sigungu_nm2 = sigungu_nm 

* 대구광역시 군위군 -> 경상북도 군위군 (2024년 이전기준) 
replace sido_nm="경상북도" if sido_nm=="대구광역시" & sigungu_nm=="군위군" 

* 인천광역시 남구 -> 인천광역시 미추홀구 
replace sigungu_nm="미추홀구" if sido_nm=="인천광역시" & sigungu_nm=="남  구"

* 연기군 -> 세종특별자치시로 
replace sigungu_nm="세종특별자치시" if sigungu_nm=="연기군"
replace sido_nm="세종특별자치시" if sigungu_nm=="세종특별자치시"

* 여주군 -> 여주시 
replace sigungu_nm="여주시" if sigungu_nm=="여주군"
 
* 화성군 -> 화성시 
replace sigungu_nm="화성시" if sigungu_nm=="화성군" 

* 광주군 -> 광주시 
replace sigungu_nm="광주시" if sigungu_nm=="광주군" 

* 파주군 -> 파주시 
replace sigungu_nm="파주시" if sigungu_nm=="파주군"
 
* 이천군 -> 이천시 
replace sigungu_nm="이천시" if sigungu_nm=="이천군"

* 용인군 -> 용인시 
replace sigungu_nm="용인시" if sigungu_nm=="용인군"

* 안성군 -> 안성시 
replace sigungu_nm="안성시" if sigungu_nm=="안성군"

* 김포군 -> 김포시 
replace sigungu_nm="김포시" if sigungu_nm=="김포군"

* 당진군 -> 당진시 
replace sigungu_nm="당진시" if sigungu_nm=="당진군"

* 양주군 -> 양주시 
replace sigungu_nm="양주시" if sigungu_nm=="양주군"

* 양주군 -> 양주시 
replace sigungu_nm="양주시" if sigungu_nm=="양주군"

* 포천군 -> 포천시 
replace sigungu_nm="포천시" if sigungu_nm=="포천군"

* 마산, 창원, 진해 -> 창원시 
replace sigungu_nm="창원시" if sigungu_nm=="마산시"
replace sigungu_nm="창원시" if sigungu_nm=="진해시"

* 북제주군 -> 제주시 
replace sigungu_nm="제주시" if sigungu_nm=="북제주군"

* 남제주군 -> 서귀포시 
replace sigungu_nm="서귀포시" if sigungu_nm=="남제주군"

* 청원군 -> 청주시 
replace sigungu_nm="청주시" if sigungu_nm=="청원군"

drop if sigungu_nm=="양산군" 
drop if sigungu_nm=="울산시" 
drop if sigungu_nm=="여천군" 
drop if sigungu_nm=="여천시" 
drop if sigungu_nm=="논산군" 

collapse (sum) y* , by (sido_nm sigungu_nm) 

order sido_nm sigungu_nm 
replace sigungu_nm = subinstr(sigungu_nm, " ", "", .)
*******************************************************************************
reshape long y, i(sido_nm sigungu_nm) j(year)

replace sido_nm="전라북도" if sido_nm=="전북특별자치도" 
replace sido_nm="강원도" if sido_nm=="강원특별자치도"
*******************************************************************************
merge m:1 year sido_nm sigungu_nm using "$data/sigungu_code.dta"

tab year if _merge==1 // 2023, 2024, 2025년도 
tab year if _merge==2 // 1995-1999년도 

keep if _merge==3 
drop _merge

ren y pop_migra

save "$data/migration_control.dta", replace 

