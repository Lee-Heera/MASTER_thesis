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
use "$data/2007president_clean.dta" 

append using "$data/2012president_clean.dta" 

append using "$data/2017president_clean.dta" 

append using "$data/2022president_clean.dta" 

append using "$data/2002president_clean.dta"

append using "$data/1997president_clean.dta"

/*
// pretrend check 용 
append using "$data/1997president_clean.dta" 

append using "$data/2002president_clean.dta" 
*/

tab year 

drop if sido_nm == "세종특별자치시"
drop if sido_nm == "제주특별자치도"
****************************** 지역코드 매치
merge m:1 sido_nm sigungu_nm year  using "$data/sigungu_code.dta"

tab year if _merge== 1 // 1997, 2002년도 데이터 

keep if _merge ==1 | _merge ==3 
******************************* 2007년도 지역코드 넣어주기 
* 1단계: 2012년 코드 따로 저장 (변수명 바꿔서 저장)
preserve
    keep if year == 2012
    keep sido_nm sigungu_nm regioncode
    rename regioncode regioncode_2012
    tempfile code_2012
    save `code_2012'
restore

* 2단계: 머지
merge m:1 sido_nm sigungu_nm using `code_2012', keep(master match) nogen

* 3단계: 2007년 관측치에만 코드 채워넣기
replace regioncode = regioncode_2012 if year == 2007 & missing(regioncode)
replace regioncode = regioncode_2012 if year == 2002 & missing(regioncode)
replace regioncode = regioncode_2012 if year == 1997 & missing(regioncode)

drop regioncode_2012

drop _merge 
sort sido_nm sigungu_nm 

save "$interim/대선_개표/president_append.dta", replace 
**********************************************************************
* 정당 매핑 (1997~2022)
**********************************************************************
// 1997 한나라당 새정치국민회의 국민신당 건설국민승리 공화당 바른정치연합 통일한국당 
// 2002 한나라당 새천년민주당 하나로국민연합 민주노동당 호국당 
// 2007 한나라당, 대통합민주신당, 창조한국당, 무소속이회창
// 2012 새누리당, 민주통합당 
// 2017 더불어민주당, 자유한국당, 국민의당, 바른정당, 정의당 
// 2022 더불어민주당, 국민의힘 

order sido_nm sigungu_nm year 선거인수 투표수 유효투표수 무효투표 기권 

*---------------------------------------------------------------------
* Version 1: 거대양당만
*---------------------------------------------------------------------
* 진보
gen liberal1_st = 0
replace liberal1_st = cond(missing(새정치국민회의), 0, 새정치국민회의) if year == 1997
replace liberal1_st = cond(missing(새천년민주당), 0, 새천년민주당) if year == 2002
replace liberal1_st = cond(missing(대통합민주신당), 0, 대통합민주신당) if year == 2007
replace liberal1_st = cond(missing(민주통합당), 0, 민주통합당) if year == 2012
replace liberal1_st = cond(missing(더불어민주당), 0, 더불어민주당) if inlist(year, 2017, 2022)

* 보수
gen conserv1_st = 0
replace conserv1_st = cond(missing(한나라당), 0, 한나라당) if inlist(year, 1997, 2002, 2007)
replace conserv1_st = cond(missing(새누리당), 0, 새누리당) if year == 2012
replace conserv1_st = cond(missing(자유한국당), 0, 자유한국당) if year == 2017
replace conserv1_st = cond(missing(국민의힘), 0, 국민의힘) if year == 2022
*---------------------------------------------------------------------
* 연도별 군소 정당 매핑
*---------------------------------------------------------------------
* 1997: 국민신당, 공화당, 바른정치연합 (보수), 건설국민승리 통일한국당(진보) 
* 2002: 하나로국민연합(보수), 민주노동당(진보) // 호국당은 제외 
* 2007: 무소속이회창(보수) // 창조한국당 제외 
* 2012: 
* 2017: 바른정당(보수), 정의당(진보) // 국민의당 제외 
* 2022: 
*---------------------------------------------------------------------
* Version 2: 군소정당/무소속 포함
*---------------------------------------------------------------------
// 군소정당 포함 (정의당/바른정당, 이회창)
gen liberal2_st = liberal1_st
gen conserv2_st = conserv1_st

* 진보 군소정당 추가
replace liberal2_st = liberal2_st + cond(missing(건설국민승리), 0, 건설국민승리) ///
                                  + cond(missing(통일한국당), 0, 통일한국당) if year == 1997
replace liberal2_st = liberal2_st + cond(missing(민주노동당), 0, 민주노동당) if year == 2002
replace liberal2_st = liberal2_st + cond(missing(정의당), 0, 정의당) if year == 2017

* 보수 군소정당 추가
replace conserv2_st = conserv2_st + cond(missing(국민신당), 0, 국민신당) ///
                                  + cond(missing(공화당), 0, 공화당) ///
                                  + cond(missing(바른정치연합), 0, 바른정치연합) if year == 1997
replace conserv2_st = conserv2_st + cond(missing(하나로국민연합), 0, 하나로국민연합) if year == 2002
replace conserv2_st = conserv2_st + cond(missing(무소속이회창), 0, 무소속이회창) if year == 2007
replace conserv2_st = conserv2_st + cond(missing(바른정당), 0, 바른정당) if year == 2017
*---------------------------------------------------------------------
* Vote Shares 계산
*---------------------------------------------------------------------
gen conserv1_p = conserv1_st / (conserv1_st + liberal1_st) 
gen conserv2_p = conserv2_st / (conserv2_st + liberal2_st) 
gen liberal1_p = liberal1_st / (conserv1_st + liberal1_st)
gen liberal2_p = liberal2_st / (conserv2_st + liberal2_st)

* Check
gen check = liberal1_p + conserv1_p
tab check 
assert abs(check - 1) < 0.0001 if !missing(check)

gen check2 = liberal2_p + conserv2_p
tab check2
assert abs(check2 - 1) < 0.0001 if !missing(check2)

drop check check2
************************************************************************
//// Turnout in percentage of registered votes 
gen turnout = 투표수 / 선거인수

//// Change in vote share & turnout
* 기준연도 값 저장
foreach yr in 2007 2012 2017 2022 {
    preserve
    keep if year == `yr'
    keep regioncode conserv1_p conserv2_p liberal1_p liberal2_p turnout
    foreach var in conserv1_p conserv2_p liberal1_p liberal2_p turnout {
        rename `var' `var'_`yr'
    }
    tempfile base`yr'
    save `base`yr''
    restore
    merge m:1 regioncode using `base`yr'', nogen
}	 
*---------------------------------------------------------------------
* Long Difference ver1) 2007→2022 (t0=2007 행에 저장)
*---------------------------------------------------------------------
gen LD_conserv1_p_0722 = conserv1_p_2022 - conserv1_p_2007 if year == 2007
gen LD_conserv2_p_0722 = conserv2_p_2022 - conserv2_p_2007 if year == 2007
gen LD_liberal1_p_0722 = liberal1_p_2022 - liberal1_p_2007 if year == 2007
gen LD_liberal2_p_0722 = liberal2_p_2022 - liberal2_p_2007 if year == 2007
gen LD_turnout_0722    = turnout_2022    - turnout_2007     if year == 2007

label variable LD_conserv1_p_0722 "LD conserv1_p (2007→2022), t0=2007"
label variable LD_conserv2_p_0722 "LD conserv2_p (2007→2022), t0=2007"
label variable LD_turnout_0722    "LD turnout (2007→2022), t0=2007"

*---------------------------------------------------------------------
* Long Difference ver2) 2007→2017 (t0=2007 행에 저장)  ← 변경됨
*---------------------------------------------------------------------
gen LD_conserv1_p_0717 = conserv1_p_2017 - conserv1_p_2007 if year == 2007  // ← 변경
gen LD_conserv2_p_0717 = conserv2_p_2017 - conserv2_p_2007 if year == 2007  // ← 변경
gen LD_liberal1_p_0717 = liberal1_p_2017 - liberal1_p_2007 if year == 2007  // ← 변경
gen LD_liberal2_p_0717 = liberal2_p_2017 - liberal2_p_2007 if year == 2007  // ← 변경
gen LD_turnout_0717    = turnout_2017    - turnout_2007     if year == 2007  // ← 변경

label variable LD_conserv1_p_0717 "LD conserv1_p (2007→2017), t0=2007"  // ← 변경
label variable LD_conserv2_p_0717 "LD conserv2_p (2007→2017), t0=2007"  // ← 변경
label variable LD_turnout_0717    "LD turnout (2007→2017), t0=2007"  // ← 변경

*---------------------------------------------------------------------
* Stacked Difference (t0 행에 저장)
*---------------------------------------------------------------------
gen SD_conserv1_p = .
gen SD_conserv2_p = .
gen SD_liberal1_p = .
gen SD_liberal2_p = .
gen SD_turnout    = .

* 2007→2012 (year==2007 행)
replace SD_conserv1_p = conserv1_p_2012 - conserv1_p_2007 if year == 2007
replace SD_conserv2_p = conserv2_p_2012 - conserv2_p_2007 if year == 2007
replace SD_liberal1_p = liberal1_p_2012 - liberal1_p_2007 if year == 2007
replace SD_liberal2_p = liberal2_p_2012 - liberal2_p_2007 if year == 2007
replace SD_turnout    = turnout_2012    - turnout_2007    if year == 2007

* 2012→2017 (year==2012 행)
replace SD_conserv1_p = conserv1_p_2017 - conserv1_p_2012 if year == 2012
replace SD_conserv2_p = conserv2_p_2017 - conserv2_p_2012 if year == 2012
replace SD_liberal1_p = liberal1_p_2017 - liberal1_p_2012 if year == 2012
replace SD_liberal2_p = liberal2_p_2017 - liberal2_p_2012 if year == 2012
replace SD_turnout    = turnout_2017    - turnout_2012    if year == 2012

* 2017→2022 (year==2017 행)
replace SD_conserv1_p = conserv1_p_2022 - conserv1_p_2017 if year == 2017
replace SD_conserv2_p = conserv2_p_2022 - conserv2_p_2017 if year == 2017
replace SD_liberal1_p = liberal1_p_2022 - liberal1_p_2017 if year == 2017
replace SD_liberal2_p = liberal2_p_2022 - liberal2_p_2017 if year == 2017
replace SD_turnout    = turnout_2022    - turnout_2017    if year == 2017

label variable SD_conserv1_p "SD conserv1_p (t0→t0+5)"
label variable SD_conserv2_p "SD conserv2_p (t0→t0+5)"
label variable SD_turnout    "SD turnout (t0→t0+5)"

sort year regioncode 
tab year 
********************************************************************
* 지역 내 특정 정당이 55% 초과 유지되는지 dummy, 
* solid liberal, solid conserva, competitive 지역 변수 만들기
******************************************************************** 
************************ version 1 ) 거대양당만 
* 각 연도별 liberal vote share > 55% 여부
gen lib1_over55 = (liberal1_p > 0.55) if !missing(liberal1_p)
* conservative vote share > 55% 여부  
gen con1_over55 = (conserv1_p > 0.55) if !missing(conserv1_p)

bysort regioncode: egen solid_lib1 = min(lib1_over55) 
bysort regioncode: egen solid_con1 = min(con1_over55) 

gen dum_solid_lib1 = (solid_lib1 == 1) 
gen dum_solid_con1 = (solid_con1 == 1) 
gen dum_competitive1 = (dum_solid_lib1 == 0 & dum_solid_con1 == 0)

* 확인, 아래의 해당하는 관측치 있으면 안됨 
count if dum_solid_lib1==1 & dum_solid_con1==1
************************** version 2 ) 군소정당, 무소속 포함 
* 각 연도별 liberal vote share > 55% 여부
gen lib2_over55 = (liberal2_p > 0.55) if !missing(liberal2_p)
* conservative vote share > 55% 여부  
gen con2_over55 = (conserv2_p > 0.55) if !missing(conserv2_p) 

bysort regioncode: egen solid_lib2 = min(lib2_over55) 
bysort regioncode: egen solid_con2 = min(con2_over55) 

gen dum_solid_lib2 = (solid_lib2 == 1)
gen dum_solid_con2 = (solid_con2 == 1) 
gen dum_competitive2 = (dum_solid_lib2 == 0 & dum_solid_con2 == 0) 

* 확인, 아래의 해당하는 관측치 있으면 안됨 
count if dum_solid_lib2==1 & dum_solid_con2==1
*---------------------------------------------------------------------
* 2002, 2007년 값 저장
*---------------------------------------------------------------------
foreach yr in 2002 2007 {
    preserve
    keep if year == `yr'
    keep regioncode conserv1_p conserv2_p turnout
    foreach var in conserv1_p conserv2_p turnout {
        rename `var' `var'_pre`yr'
    }
    tempfile basepre`yr'
    save `basepre`yr''
    restore
    merge m:1 regioncode using `basepre`yr'', nogen
}

*---------------------------------------------------------------------
* Pretrend -  Difference (2002→2007)
*---------------------------------------------------------------------
**** ! 주의: pretrend 변수만 baseline yaer 말고 2007년도에 저장 (merge 위해서)
gen D_conserv1_p_0207 = conserv1_p_pre2007 - conserv1_p_pre2002 if year == 2007
gen D_conserv2_p_0207 = conserv2_p_pre2007 - conserv2_p_pre2002 if year == 2007
gen D_turnout_0207    = turnout_pre2007    - turnout_pre2002    if year == 2007

label variable D_conserv1_p_0207 "ΔConservative (2002→2007, pretrend)"
label variable D_conserv2_p_0207 "ΔConservative v2 (2002→2007, pretrend)"
label variable D_turnout_0207    "ΔTurnout (2002→2007, pretrend)"

**********************************************************************
* 정리 & 저장
**********************************************************************
* 임시 변수 정리
drop conserv1_p_2007-turnout_2022 ///
     conserv1_p_pre2002-turnout_pre2007 ///
     lib1_over55 con1_over55 lib2_over55 con2_over55 ///
     solid_lib1 solid_con1 solid_lib2 solid_con2

* 원본 정당 변수 정리
drop 선거인수 투표수 유효투표수 무효투표 기권 ///
     한나라당 새정치국민회의 국민신당 건설국민승리 공화당 바른정치연합 통일한국당 ///
     새천년민주당 하나로국민연합 민주노동당 호국당 ///
     대통합민주신당 창조한국당 무소속이회창 ///
     새누리당 민주통합당 ///
     더불어민주당 자유한국당 국민의당 바른정당 정의당 국민의힘 ///
     liberal1_st liberal2_st conserv1_st conserv2_st ///
     liberal1_p liberal2_p conserv1_p conserv2_p turnout

compress
sort year regioncode

save "$data/Y_final.dta", replace 
