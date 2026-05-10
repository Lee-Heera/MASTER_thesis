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
****************************************************************************
********************* 65+ , college share 관련 통제변수 
use "$prof_raw/sigungu1.dta"

tab year // 제주도 없고, 세종특별자치시 있음 

** 변수명 변경 
ren region sigungu_nm 
tab sigungu_nm 

drop college1 college2 college0 

** 시도 이름 변경해주기 
replace sido_nm="강원도" if sido_nm=="강원특별자치도" 
replace sido_nm="전라북도" if sido_nm== "전북특별자치도"
replace sido_nm="경상북도" if sigungu_nm=="군위군" & sido_nm== "대구광역시" // 2022년 이후에 군위군이 대구광역시로 편입되었는데, 일단은 편입 이전의 경계를 기준으로 함 

** 지역 필터링 -> 세종, 제주 제외 
drop if sido_nm=="세종특별자치시" 
drop if sido_nm=="제주특별자치도"

** 연도 필터링 
keep if year == 2007 | year==2012 | year==2017 | year==2022 
tab year 

** merge 
merge m:n sido_nm sigungu_nm using "$data/sigungu_code.dta" // 시군구코드 머지 

drop _merge // _merge!=3 인 경우 없음 

ren pop65 aged_share 
ren college_final college_share 

// 0~1 사이값 (share)으로 만들기 
replace aged_share = aged_share/100
replace college_share = college_share/100 

label var aged_share "share of population aged 65 and above"
label var college_share "share of college-educated"

*****************************************************
* 고정연도별 변수 생성 (2007, 2012)
* → 해당 연도 행에만 값, 나머지 missing
*****************************************************
foreach yr in 2007 2012 {
    gen aged_share_`yr'    = aged_share    if year == `yr'
    gen college_share_`yr' = college_share if year == `yr'
    
    label variable aged_share_`yr'    "Share aged 65+ (`yr' base)"
    label variable college_share_`yr' "Share college-educated (`yr' base)"
}

*****************************************************
* SD용 통제변수 (2022년 missing)
*****************************************************
gen aged_share_SD    = aged_share    if inlist(year, 2007, 2012, 2017)
gen college_share_SD = college_share if inlist(year, 2007, 2012, 2017)

label variable aged_share_SD    "Share aged 65+ (SD: t0=2007/2012/2017, 2022=missing)"
label variable college_share_SD "Share college-educated (SD: t0=2007/2012/2017, 2022=missing)"

*****************************************************
* 검증
*****************************************************
* 해당 연도에만 값 있어야 함
assert !missing(aged_share_2007) if year == 2007
assert  missing(aged_share_2007) if year != 2007
assert !missing(aged_share_2012) if year == 2012
assert  missing(aged_share_2012) if year != 2012

* SD: 2022년 missing
assert  missing(aged_share_SD) if year == 2022
assert !missing(aged_share_SD) if inlist(year, 2007, 2012, 2017)

* 범위 확인
assert aged_share_2007 >= 0 & aged_share_2007 <= 1 if !missing(aged_share_2007)
assert college_share_2007 >= 0 & college_share_2007 <= 1 if !missing(college_share_2007)

save "$data/demoshare_control.dta", replace 
