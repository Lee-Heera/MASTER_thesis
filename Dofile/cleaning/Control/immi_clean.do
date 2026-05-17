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
use "$prof_raw/KOREA_immigration.dta"

tab year // 제주도 없음 

** 도 이름 수정 
** 강원특별자치도 -> 강원도, 전북특별자치도 -> 전라북도 
ren region sigungu_nm 
replace sido_nm="강원도" if sido_nm=="강원특별자치도" 
replace sido_nm = "전라북도" if sido_nm=="전북특별자치도" 

tab year // 226개씩 

merge m:1 year sido_nm sigungu_nm using "$data/sigungu_code.dta"
tab year if _merge!=3 
keep if _merge==3 
drop _merge 

** 변수 만들기 
keep year sigungu_id sido_nm sigungu_nm pop immi0 regioncode
sort year regioncode 

label var immi0 "외국인 주민 수(total = 국적취득자, 미취득자, 외국인주민 자녀)"

*****************************************************
* 이민자 비율 (immi_share) & 이질성 더미
* immi_share = immi0 / pop
*****************************************************
gen immi_share = immi0 / pop 
label variable immi_share "Foreign resident share (immi0/pop)"

assert immi_share >= 0 & immi_share <= 1 if !missing(immi_share)
sum immi_share

/*
*****************************************************
* 고정연도별 변수 생성 (2007, 2012)
* → 해당 연도 행에만 값, 나머지 missing
*****************************************************
foreach yr in 2007 2012 {
    gen immi_share_`yr' = immi_share if year == `yr'
    label variable immi_share_`yr' "Foreign resident share (`yr' base)"
}

*****************************************************
* SD용 통제변수 (2022년 missing)
*****************************************************
gen immi_share_SD = immi_share if inlist(year, 2007, 2012, 2017)
label variable immi_share_SD "Foreign resident share (SD: t0=2007/2012/2017, 2022=missing)"

*****************************************************
* 이질성 더미 (2007, 2012, 2017 기준)
*****************************************************
foreach yr in 2007 2012 2017 {
    qui sum immi_share if year == `yr', detail
    local med = r(p50)
    
    * 해당 연도 기준으로 더미 생성 후 모든 연도에 복사
    gen high_immi_`yr'_temp = (immi_share >= `med') if year == `yr'
    bysort regioncode: egen high_immi_`yr' = max(high_immi_`yr'_temp)
    drop high_immi_`yr'_temp
    
    label variable high_immi_`yr' "High immi dummy (`yr', >= median `=round(`med', 0.001)')"
    di "중위수 (immi_share_`yr'): `med'"
}

*****************************************************
* 검증
*****************************************************
assert !missing(immi_share_2007) if year == 2007
assert  missing(immi_share_2007) if year != 2007
assert !missing(immi_share_2012) if year == 2012
assert  missing(immi_share_2012) if year != 2012
assert  missing(immi_share_SD)   if year == 2022
assert !missing(immi_share_SD)   if inlist(year, 2007, 2012, 2017)
*/

drop pop immi0
tab year 

save "$data/immi_control.dta", replace 
