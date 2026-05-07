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
clear 

cd "$interim/대선_개표"

use 2007/2007premerge.dta 

append using 2012/2012premerge.dta 

append using 2017/2017premerge.dta 

append using 2022/2022premerge.dta 

tab year 
// 2007년도는 세종시 없어서 228개 

*****************************8* 지역코드 매치
merge m:1 sido_nm sigungu_nm year  using "$interim/crosswalk/sigungu_code.dta"

tab year if _merge== 1 // 대선데이터  - 2007년도 데이터 
tab year if _merge==2 // 대선이 없던 연도 

keep if _merge ==1 | _merge ==3 

**** 2007년도 지역코드 넣어주기 
* 1단계: 2012년 코드 따로 저장 (변수명 바꿔서 저장)
preserve
    keep if year == 2012
    keep sido_nm sigungu_nm countyid regioncode
    rename countyid countyid_2012
    rename regioncode regioncode_2012
    tempfile code_2012
    save `code_2012'
restore

* 2단계: 머지
merge m:1 sido_nm sigungu_nm using `code_2012', keep(master match) nogen

* 3단계: 2007년 관측치에만 코드 채워넣기
replace countyid = countyid_2012 if year == 2007 & missing(countyid)
replace regioncode = regioncode_2012 if year == 2007 & missing(regioncode)
drop countyid_2012 regioncode_2012

drop _merge 
sort sido_nm sigungu_nm 


////////////////////////////////////////////////////////////////////////////////
// 각 대수별 5% 미만 득표율인 후보 및 정당은 cut 
////////////////////////////////////////////////////////////////////////////////

// 2007 한나라당, 대통합민주신당, 창조한당, 무소속이회창
// 2012 새누리당, 민주통합당 
// 2017 더불어민주당, 자유한국당, 국민의당, 바른정당, 정의당 
// 2022 더불어민주당, 국민의힘 

order sido_nm sigungu_nm year 선거인수 투표수 유효투표수 무효투표 기권 

////// 투표수 
// 거대양당만 
gen liberal1_st = cond(missing(대통합민주신당), 0, 대통합민주신당) + cond(missing(민주통합당), 0, 민주통합당) + cond(missing(더불어민주당), 0, 더불어민주당) 
gen conserv1_st = cond(missing(한나라당), 0, 한나라당) + cond(missing(새누리당), 0, 새누리당) + cond(missing(자유한국당), 0, 자유한국당) +  cond(missing(국민의힘), 0, 국민의힘)

// 군소정당, 무소속 포함 
gen liberal2_st = cond(missing(대통합민주신당), 0, 대통합민주신당) + cond(missing(민주통합당), 0, 민주통합당) + cond(missing(더불어민주당), 0, 더불어민주당) + cond(missing(정의당), 0, 정의당) + cond(missing(창조한국당), 0, 창조한국당) + cond(missing(국민의당), 0, 국민의당)  

gen conserv2_st = cond(missing(한나라당), 0, 한나라당) + cond(missing(새누리당), 0, 새누리당) + cond(missing(자유한국당), 0, 자유한국당) +  cond(missing(국민의힘), 0, 국민의힘) +  cond(missing(무소속이회창), 0, 무소속이회창) +  cond(missing(바른정당), 0, 바른정당)

******************************************************
keep if year >=2012 
///// 전체 유효투표수로 나누는 것이 아님 
* Conservative two-party vote share 
* = 보수 득표수 / (보수 득표수 + 진보 득표수)
gen conserv1_p = conserv1_st / (conserv1_st + liberal1_st) 
gen conserv2_p = conserv2_st / (conserv2_st + liberal2_st) 


* Liberal two-party vote share
gen liberal1_p = liberal1_st / (conserv1_st + liberal1_st)
gen liberal2_p = liberal2_st / (conserv2_st + liberal2_st) 

// check 변수의 값이 모두 1이어야 함 
gen check = liberal1_p + conserv1_p
tab check 

gen check2 = liberal2_p + conserv2_p
tab check2 

drop check check2 

//// Turnout in percentage of registered votes 
gen turnout = 투표수 / 선거인수

//// Change in Republican two-party vote share
* 연도별 정렬 필수
sort regioncode year 

* year 기준 명시적 차분 (t - (t-1))
bysort regioncode (year): gen d_conserv1_p = conserv1_p - conserv1_p[_n-1] ///
    if year - year[_n-1] == 5

bysort regioncode (year): gen d_conserv2_p = conserv2_p - conserv2_p[_n-1] ///
    if year - year[_n-1] == 5

bysort regioncode (year): gen d_turnout = turnout - turnout[_n-1] ///
    if year - year[_n-1] == 5
	
****************************************************** 
***** 지역 내 특정 정당이 55% 초과 유지되는지 dummy, 
** solid liberal, solid conserva, competitive 지역 변수 만들기 

*********** version 1 ) 거대양당만 
* 각 연도별 liberal vote share > 55% 여부
gen lib1_over55 = (liberal1_p > 0.55) if !missing(liberal1_p)
* conservative vote share > 55% 여부  
gen con1_over55 = (conserv1_p > 0.55) if !missing(conserv1_p)

bysort regioncode: egen solid_lib1 = min(lib1_over55) 
bysort regioncode: egen solid_con1 = min(con1_over55) 

*** dummy 
* Solid Liberal 
gen dum_solid_lib1 = (solid_lib1 == 1) 
* Solid Conservative 
gen dum_solid_con1 = (solid_con1 == 1) 
* Competitive (나머지)
gen dum_competitive1 = (dum_solid_lib1 == 0 & dum_solid_con1 == 0)

*********** version 2 ) 군소정당, 무소속 포함 
* 각 연도별 liberal vote share > 55% 여부
gen lib2_over55 = (liberal2_p > 0.55) if !missing(liberal2_p)
* conservative vote share > 55% 여부  
gen con2_over55 = (conserv2_p > 0.55) if !missing(conserv2_p) 

bysort regioncode: egen solid_lib2 = min(lib2_over55) 
bysort regioncode: egen solid_con2 = min(con2_over55) 

*** dummy 
gen dum_solid_lib2 = (solid_lib2 == 1)
gen dum_solid_con2 = (solid_con2 == 1) 
gen dum_competitive2 = (dum_solid_lib2 == 0 & dum_solid_con2 == 0) 

***********************************************************
***************** 변수 Robustness check - version 1 
* 1. 기본 분포 확인
tab dum_solid_lib1 
tab dum_solid_con1 
tab dum_competitive1 

* 2. 세 더미가 mutually exclusive & exhaustive 한지 확인
* 세 개 합이 항상 1이어야 함
gen check_dum1 = dum_solid_lib1 + dum_solid_con1 + dum_competitive1
tab check_dum1 
* 1만 나와야 정상, 0이나 2 나오면 문제
// 모두 1 

* 3. lib과 con 동시에 1인 케이스 없는지 확인
tab dum_solid_lib1 dum_solid_con1 
* 1,1 케이스 없어야 정상 

* 4. 지역별로 연도 간 일관성 확인 (같은 regioncode면 모든 연도에서 동일해야 함)
bysort regioncode: egen check_lib1_consistency = sd(dum_solid_lib1) 
tab check_lib1_consistency 
* 0만 나와야 정상 (지역 내 연도별 변동 없어야 함)

bysort regioncode: egen check_con1_consistency = sd(dum_solid_con1) 
tab check_con1_consistency 

* 5. 몇 개 지역이 각 카테고리에 속하는지
preserve
    keep if year == 2012
    tab dum_solid_lib1
    tab dum_solid_con1
    tab dum_competitive1
restore

// solid conserv: 51 
// solid liberal: 41 
// competitive: 137 
***************** 변수 Robustness check - version 2 
* 1. 기본 분포 확인
tab dum_solid_lib2 
tab dum_solid_con2 
tab dum_competitive2 

* 2. mutually exclusive & exhaustive 확인
gen check_dum2 = dum_solid_lib2 + dum_solid_con2 + dum_competitive2
tab check_dum2 
* 1만 나와야 정상
// 1만 나옴 

* 3. lib과 con 동시에 1인 케이스 없는지 확인
tab dum_solid_lib2 dum_solid_con2 
* 1,1 케이스 없어야 정상 -> 해당케이스 없음 

* 4. 지역별 연도 간 일관성 확인
bysort regioncode: egen check_lib2_consistency = sd(dum_solid_lib2) 
tab check_lib2_consistency 
* 0만 나와야 정상 -> 0만 나옴 

bysort regioncode: egen check_con2_consistency = sd(dum_solid_con2) 
tab check_con2_consistency 
* 0만 나와야 정상 -> 0만 나옴 

* 5. 몇 개 지역이 각 카테고리에 속하는지
preserve
    keep if year == 2012
    tab dum_solid_lib2
    tab dum_solid_con2
    tab dum_competitive2
restore

// solid conserv: 34 
// solid liberal: 41 
// solid competitive: 154 

* 확인용 변수 삭제
drop check_dum1 check_dum2 check_lib1_consistency check_con1_consistency ///
     check_lib2_consistency check_con2_consistency
	 
*********** Long difference 변수 추가, 기준: 2012년 (solid/competitive dummy 기준연도와 통일)
preserve
    keep if year == 2012
    keep regioncode conserv1_p conserv2_p turnout
    rename conserv1_p conserv1_p_base2012
    rename conserv2_p conserv2_p_base2012
    rename turnout turnout_base2012
    tempfile base2012
    save `base2012'
restore

* 원본에 merge
merge m:1 regioncode using `base2012', nogen

* Long difference from 2012
gen ld_conserv1_p = conserv1_p - conserv1_p_base2012 if inlist(year, 2017, 2022)
gen ld_conserv2_p = conserv2_p - conserv2_p_base2012 if inlist(year, 2017, 2022)
gen ld_turnout = turnout - turnout_base2012 if inlist(year, 2017, 2022)

/*
bysort regioncode (year): gen base_conserv1_p_2007 = conserv1_p if year == 2007
bysort regioncode (year): egen conserv1_p_base2007 = max(base_conserv1_p_2007)

bysort regioncode (year): gen base_conserv2_p_2007 = conserv2_p if year == 2007
bysort regioncode (year): egen conserv2_p_base2007 = max(base_conserv2_p_2007)

bysort regioncode (year): gen base_turnout_2007 = turnout if year == 2007
bysort regioncode (year): egen turnout_base2007 = max(base_turnout_2007)

* Long difference from 2012
gen ld_conserv1_p_2007 = conserv1_p - conserv1_p_base2007 if year != 2007
gen ld_conserv2_p_2007 = conserv2_p - conserv2_p_base2007 if year != 2007
gen ld_turnout_2007    = turnout    - turnout_base2007      if year != 2007

drop base_conserv1_p_2007 base_conserv2_p_2007 base_turnout_2007 ///
     conserv1_p_base2007 conserv2_p_base2007 turnout_base2007
	 */
******************************************************
////// Labels
label variable liberal1_st "Liberal votes (major parties: 민주통합당, 더불어민주당)"
label variable conserv1_st "Conservative votes (major parties: 새누리당, 자유한국당, 국민의힘)"
label variable liberal2_st "Liberal votes (incl. 정의당, 국민의당)"
label variable conserv2_st "Conservative votes (incl. 바른정당)"
label variable conserv1_p "Conservative two-party vote share (major parties only)"
label variable conserv2_p "Conservative two-party vote share (incl. minor parties)"
label variable turnout "Turnout (투표수 / 선거인수)"
label variable d_conserv1_p "FD: Δconserv1_p (major parties, t - t-1)"
label variable d_conserv2_p "FD: Δconserv2_p (incl. minor parties, t - t-1)"
label variable d_turnout "FD: Δturnout (t - t-1)"

label variable dum_solid_lib1 "Solid Liberal: liberal1_p > 55% in all 3 elections"
label variable dum_solid_con1 "Solid Conservative: conserv1_p > 55% in all 3 elections"
label variable dum_competitive1 "Competitive district (major parties)"
label variable dum_solid_lib2 "Solid Liberal: liberal2_p > 55% in all 3 elections"
label variable dum_solid_con2 "Solid Conservative: conserv2_p > 55% in all 3 elections"
label variable dum_competitive2 "Competitive district (incl. minor parties)"

label variable ld_conserv1_p "LD: conserv1_p - 2012 base (major parties)"
label variable ld_conserv2_p "LD: conserv2_p - 2012 base (incl. minor)"
label variable ld_turnout "LD: turnout - 2012 base"
********************************************************* 
drop 선거인수 투표수 유효투표수 무효투표 기권 대통합민주신당 한나라당 창조한국당 무소속이회창 새누리당 민주통합당 더불어민주당 자유한국당 국민의당 바른정당 정의당 국민의힘

drop lib1_over55 con1_over55 lib2_over55 con2_over55 solid_lib1 solid_con1 solid_lib2 solid_con2

compress 

save "$data/pres_panel.dta", replace 
