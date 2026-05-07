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
use "$prof_raw/employmentCOE.dta" 

tab newindcode // 101~119 까지 사용, 118+119 aggregate 필요 

keep if newindcode >= 101 & newindcode <= 119 
drop if year < 1995 

********************************************************************** 
* wood & furniture 통합 // 산업분류 통합 
********************************************************************** 
replace newindcode = 118 if newindcode == 119
replace newind = "other manufacturing" if newindcode == 118

collapse (sum) fullempl partempl allempl firm, by(year sido_nm sigungu_nm regioncode newindcode newind)

drop fullempl partempl firm 

replace allempl = allempl/1000  //// 1000명당으로 나누기 

tab newindcode year 
********************************************************************** 
* 사업체가 아예 없어서 특정 연도, 지역, 산업에 해당하는 값이 아예 없는 경우 넣어줘야 함 
fillin year regioncode newindcode

replace allempl = 0 if _fillin == 1 
br if _fillin == 1

bysort newindcode: egen temp_newind = mode(newind), maxmode
replace newind = temp_newind if missing(newind)
drop temp_newind

bysort regioncode: egen temp_sido = mode(sido_nm), maxmode
replace sido_nm = temp_sido if missing(sido_nm)
drop temp_sido

bysort regioncode: egen temp_sigungu = mode(sigungu_nm), maxmode
replace sigungu_nm = temp_sigungu if missing(sigungu_nm)
drop temp_sigungu
********************************************************************
* Employment 변수 생성 (allempl 버전만)
* Panel: year-region-industry
**********************************************************************
// 원본 변수명 정리
rename allempl emp_ijt
label variable emp_ijt "All employment in region i, industry j, year t"

**********************************************************************
* 1995년 고용 데이터 (emp_i,j,1995)
**********************************************************************
preserve
keep if year == 1995
keep regioncode newindcode emp_ijt
rename emp_ijt emp_ij1995
tempfile emp1995
save `emp1995'
restore

merge m:1 regioncode newindcode using `emp1995', nogen
label variable emp_ij1995 "Employment in region i, industry j, year 1995"

sort year regioncode newindcode 
**********************************************************************
* 지역별 연도별 총 고용 (emp_i,t)
**********************************************************************
bysort region year: egen emp_it = total(emp_ijt)
label variable emp_it "Total employment in region i, year t"
**********************************************************************
* 지역별 1995년 총 고용 (emp_i,1995)
**********************************************************************
preserve
keep if year == 1995
collapse (sum) emp_ijt, by(regioncode)
rename emp_ijt emp_i1995
tempfile region1995
save `region1995'
restore

merge m:1 regioncode using `region1995', nogen
label variable emp_i1995 "Total employment in region i, year 1995"

**********************************************************************
* 산업별 2002년 총 고용 (emp_j,2012) - 표준화용
**********************************************************************
preserve
keep if year == 2012
collapse (sum) emp_ijt, by(newindcode)
rename emp_ijt emp_j2012
tempfile ind2012
save `ind2012'
restore

merge m:1 newindcode using `ind2012', nogen
label variable emp_j2012 "Total employment in industry j, year 2002"

**********************************************************************
* 산업별 1995년 총 고용 (emp_j,1995) - 대안 표준화용
**********************************************************************
preserve
keep if year == 1995
collapse (sum) emp_ijt, by(newindcode)
rename emp_ijt emp_j1995
tempfile ind1995
save `ind1995'
restore

merge m:1 newindcode using `ind1995', nogen
label variable emp_j1995 "Total employment in industry j, year 1995"
**********************************************************************
* Employment Shares 계산
**********************************************************************
gen share_current = emp_ijt / emp_it
label variable share_current "Employment share (current): emp_ijt / emp_it"

gen share_1995 = emp_ij1995 / emp_i1995
label variable share_1995 "Employment share (1995 base): emp_ij1995 / emp_i1995"

// keep if year >= 2010 & year <=2022 

save "$data/Emp_COE_clean.dta",replace 
