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
use "$prof_raw/employmentCOE.dta" 

tab newindcode // 101~119 까지 사용, 118+119 aggregate 필요 

keep if newindcode >= 101 & newindcode <= 119 
drop if year < 1995 

/*
********************************************************************** 
* wood & furniture 통합 // 산업분류 통합 
********************************************************************** 
replace newindcode = 118 if newindcode == 119
replace newind = "other manufacturing" if newindcode == 118

collapse (sum) fullempl partempl allempl firm, by(year sido_nm sigungu_nm regioncode newindcode newind)

drop fullempl partempl firm 
*/

replace allempl = allempl/1000  // 1000명당으로 나누기 
replace fullempl = fullempl/1000
replace partempl = partempl/1000 

tab newindcode year 
********************************************************************** 
* 사업체가 아예 없어서 특정 연도, 지역, 산업에 해당하는 값이 아예 없는 경우 넣어줘야 함 
fillin year regioncode newindcode

foreach var of varlist allempl fullempl partempl firm {
    replace `var' = 0 if _fillin == 1
}

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

br
********************************************************************
* Employment 변수 생성 (allempl 버전만)
* Panel: year-region-industry
**********************************************************************
// 원본 변수명 정리
rename allempl emp_ijt
label variable emp_ijt "All employment in region i, industry j, year t"

**********************************************************************
* 지역-산업별 특정 연도 고용 (emp_i,j,특정연도)
**********************************************************************

foreach yr in 1995 2005 2010 2012 {
    bysort regioncode newindcode: egen emp_ij`yr' = total(emp_ijt * (year == `yr'))
    label variable emp_ij`yr' "Employment in region i, industry j, year `yr'"
}

sort year regioncode newindcode


**********************************************************************
* 지역별 연도별 총 고용 (emp_i,t)
**********************************************************************
bysort region year: egen emp_it = total(emp_ijt)
label variable emp_it "Total employment in region i, year t"

**********************************************************************
* 지역별 특정연도 총 고용 (emp_i,특정연도)
**********************************************************************
foreach yr in 1995 2005 2010 2012 {
    bysort regioncode: egen emp_i`yr' = total(emp_ijt * (year == `yr'))
    label variable emp_i`yr' "Total employment in region i, year `yr'"
}

**********************************************************************
* 산업별 연도별 총 고용 (emp_j,t)
**********************************************************************
bysort newindcode year: egen emp_jt = total(emp_ijt)
label variable emp_jt "Total employment in industry j, year t"
**********************************************************************
* 산업별 특정 연도 총 고용 (emp_j,t*) - 표준화용
**********************************************************************
foreach yr in 1995 2005 2010 2012 {
    bysort newindcode: egen emp_j`yr' = total(emp_ijt * (year == `yr'))
    label variable emp_j`yr' "Total employment in industry j, year `yr'"
}

sort year regioncode newindcode 

order year regioncode newindcode emp* 
**********************************************************************
* Employment Shares 계산
**********************************************************************
/*
gen share_emp = emp_ijt / emp_it
label variable share_emp "Employment share (current): emp_ijt / emp_it"
*/

gen share95 = emp_ij1995 / emp_i1995
label variable share95 "Employment share (1995 base): emp_ij1995 / emp_i1995"

gen share05 = emp_ij2005 / emp_i2005
label variable share05 "Employment share (2005 base): emp_ij2005 / emp_i2005"

gen share10 = emp_ij2010 / emp_i2010
label variable share10 "Employment share (2010 base): emp_ij2010 / emp_i2010"

gen share12 = emp_ij2012 / emp_i2012
label variable share12 "Employment share (2012 base): emp_ij2012 / emp_i2012"

drop _fillin fullempl partempl 
// keep if year >= 2010 & year <=2022 

// time period 1995~2022

save "$data/kor_empl.dta",replace 
