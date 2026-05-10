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
use "$data/kor_empl.dta"  // COE 데이터에서 나온 고용비율 보고 -> 제조업 비율 산출하기 

keep year regioncode newindcode emp_ij2007 emp_ij2012 emp_ij2017 emp_i2007 emp_i2012  emp_i2017 sido_nm sigungu_nm newind firm

isid year regioncode newindcode // unique 

// 지역필터링
drop if sido_nm=="제주특별자치도" 
drop if sido_nm=="세종특별자치시"

tab year 

// 연도 필터링 
keep if year==2007 | year==2012 | year==2017 | year==2022

// 제조업 newindcode: 107~119
// 제조업 산업 더미 
gen is_mfg = 1 if newindcode>=107 & newindcode <=119 
replace is_mfg = 0 if newindcode <107 
tab is_mfg, m

foreach yr in 2007 2012 2017 {
    preserve
        keep if year == `yr'
        
        * newindcode 단위 합산 → regioncode 단위로
        bysort regioncode: egen mfg_emp = total(emp_ij`yr' * is_mfg)
        gen mfg_share_`yr' = mfg_emp / emp_i`yr'
        assert mfg_share_`yr' >= 0 & mfg_share_`yr' <= 1
        
        * regioncode 단위로 축소
        collapse (mean) mfg_share_`yr', by(regioncode)
        
        * 확인
        isid regioncode
        
        sum mfg_share_`yr', detail
        local median_`yr' = r(p50)
        
        tempfile mfg_`yr'
        save `mfg_`yr''
    restore

    merge m:1 regioncode using `mfg_`yr'', nogen
    replace mfg_share_`yr' = . if year != `yr'

    * 더미: 해당 연도 기준으로 만들고 모든 연도에 복사
    gen high_mfg_`yr'_temp = (mfg_share_`yr' >= `median_`yr'') if year == `yr'
    bysort regioncode: egen high_mfg_`yr' = max(high_mfg_`yr'_temp)
    drop high_mfg_`yr'_temp

    label variable mfg_share_`yr' "Manufacturing share (`yr' base)"
    label variable high_mfg_`yr'  "High mfg dummy (`yr', >= median)"
}

*****************************************************
* SD용 통제변수 (2022년 missing)
*****************************************************
gen mfg_share_SD = .
replace mfg_share_SD = mfg_share_2007 if year == 2007
replace mfg_share_SD = mfg_share_2012 if year == 2012
replace mfg_share_SD = mfg_share_2017 if year == 2017
label variable mfg_share_SD "Manufacturing share (SD: t0=2007/2012/2017, 2022=missing)"

*****************************************************
* 검증
*****************************************************
assert !missing(mfg_share_2007) if year == 2007
assert  missing(mfg_share_2007) if year != 2007
assert !missing(mfg_share_2012) if year == 2012
assert  missing(mfg_share_2012) if year != 2012
assert !missing(mfg_share_2017) if year == 2017
assert  missing(mfg_share_2017) if year != 2017
assert  missing(mfg_share_SD)   if year == 2022
assert !missing(mfg_share_SD)   if inlist(year, 2007, 2012, 2017)

keep year regioncode sido_nm sigungu_nm ///
     mfg_share_2007 mfg_share_2012 mfg_share_2017 mfg_share_SD ///
     high_mfg_2007 high_mfg_2012 high_mfg_2017

duplicates drop year regioncode, force
isid year regioncode
tab year

sort regioncode year 

save "$data/manu_control.dta",replace 
