*********************************************************************
*************2010~2011년도 9개도 
clear
set more off
cd "/Users/ihuila/Desktop/data/master thesis/raw/manufacturing"

import excel "20102011_9do.xlsx", sheet("데이터") clear

* 변수 이름 리스트
local varnames t_firm t_lab m_lab f_lab ma_firm ma_lab ma_mlab ma_flab

// t_firm 전체 사업체 수 
// t_lab 전체 종사자 수
// m_lab 남성 종사자 수 
// f_lab 여성 종사자 수 
// ma_firm 제조업 사업체 수
// ma_lab 제조업 종사자 수
// ma_mlab 제조업 남성 종사자 수
// ma_flab 제조업 여성 종사자 수 

// 마산시, 진해시 (2010~2011년도) 없음

* 반복할 연도 리스트
local years 2010 2011

foreach yr of local years {
    preserve

    * 연도별 열 범위 설정
    if `yr' == 2010 {
        keep A B C D E F G H I
        local collist B C D E F G H I
    }
    else if `yr' == 2011 {
        keep A J K L M N O P Q
        local collist J K L M N O P Q
    }

    * 변수명 변경
    local j = 1
    foreach col of local collist {
        local newvar : word `j' of `varnames'
        rename `col' `newvar'
        local ++j
    }

    gen year = `yr'
    drop in 1/4

    * 도 이름 설정
    gen sido_nm = "경기도" in 1/32
    replace sido_nm = "강원도" in 33/51
    replace sido_nm = "충청북도" in 52/64
    replace sido_nm = "충청남도" in 65/81
    replace sido_nm = "전라북도" in 82/96
    replace sido_nm = "전라남도" in 97/119
    replace sido_nm = "경상북도" in 120/143
    replace sido_nm = "경상남도" in 144/164
    replace sido_nm = "제주특별자치도" in 165/167

    * 시군구명 클리닝
    gen sigungu_nm = ustrregexra(A, "\p{Z}+", "")
    drop A

    order sido_nm sigungu_nm
    drop if sido_nm == sigungu_nm

	* 제주도 클리닝 
	drop if sigungu_nm=="제주도" 
	
    destring t_firm t_lab m_lab f_lab ma_firm ma_lab ma_mlab ma_flab, replace force

    save "/Users/ihuila/Desktop/data/master thesis/raw/afterclean/aftermanu/`yr'do.dta", replace

    restore
}
********************************************************************************
*******2010~2011년도 7개 시 
clear 
set more off
cd "/Users/ihuila/Desktop/data/master thesis/raw/manufacturing"

import excel "20102011_7si.xlsx", sheet("데이터") clear

* 변수 이름 리스트
local varnames t_firm t_lab m_lab f_lab ma_firm ma_lab ma_mlab ma_flab

* 반복할 연도 리스트
local years 2010 2011

foreach yr of local years {
    preserve

    * 연도별 열 범위 설정
    if `yr' == 2010 {
        keep A B C D E F G H I
        local collist B C D E F G H I
    }
    else if `yr' == 2011 {
        keep A J K L M N O P Q
        local collist J K L M N O P Q
    }

    * 변수명 변경
    local j = 1
    foreach col of local collist {
        local newvar : word `j' of `varnames'
        rename `col' `newvar'
        local ++j
    }

    gen year = `yr'
    drop in 1/4

    * 광역시 이름 설정
    gen sido_nm = "서울특별시" in 1/26
    replace sido_nm = "부산광역시" in 27/43
    replace sido_nm = "대구광역시" in 44/52
    replace sido_nm = "인천광역시" in 53/63
    replace sido_nm = "광주광역시" in 64/69
    replace sido_nm = "대전광역시" in 70/75
    replace sido_nm = "울산광역시" in 76/81

    * 시군구명 클리닝
    gen sigungu_nm = ustrregexra(A, "\p{Z}+", "")
    drop A

    order sido_nm sigungu_nm
    drop if sido_nm == sigungu_nm

    destring t_firm t_lab m_lab f_lab ma_firm ma_lab ma_mlab ma_flab, replace force

    save "/Users/ihuila/Desktop/data/master thesis/raw/afterclean/aftermanu/`yr'si.dta", replace

    restore
}

******************************************************************************
************************************ 2012~2016년도, 9개도 
clear
set more off
cd "/Users/ihuila/Desktop/data/master thesis/raw/manufacturing"

import excel "20122016_9do.xlsx", sheet("데이터") clear

// 마산시, 진해시(2012~2016) 없음 

* 연도별 열 알파벳 범위와 변수 이름 매핑
local years 2012 2013 2014 2015 2016

local cols2012 B C D E F G H I
local cols2013 J K L M N O P Q
local cols2014 R S T U V W X Y
local cols2015 Z AA AB AC AD AE AF AG
local cols2016 AH AI AJ AK AL AM AN AO

local varnames t_firm t_lab m_lab f_lab ma_firm ma_lab ma_mlab ma_flab

local i = 1
foreach yr of local years {
    
    preserve

    * 각 연도에 맞는 열 추출
    local colgroup : word `i' of cols2012 cols2013 cols2014 cols2015 cols2016

    * 명시적으로 매핑
    if `yr' == 2012 {
        keep A `cols2012'
        local collist `cols2012'
    }
    else if `yr' == 2013 {
        keep A `cols2013'
        local collist `cols2013'
    }
    else if `yr' == 2014 {
        keep A `cols2014'
        local collist `cols2014'
    }
    else if `yr' == 2015 {
        keep A `cols2015'
        local collist `cols2015'
    }
    else if `yr' == 2016 {
        keep A `cols2016'
        local collist `cols2016'
    }

    * rename 매핑
    local j = 1
    foreach col of local collist {
        local newvar : word `j' of `varnames'
        rename `col' `newvar'
        local ++j
    }

    gen year = `yr'
    drop in 1/4

    * 도 이름 설정
    gen sido_nm = "경기도" in 1/32
    replace sido_nm = "강원도" in 33/51
    replace sido_nm = "충청북도" in 52/64
    replace sido_nm = "충청남도" in 65/80
    replace sido_nm = "전라북도" in 81/95
    replace sido_nm = "전라남도" in 96/118
    replace sido_nm = "경상북도" in 119/142
    replace sido_nm = "경상남도" in 143/164
    replace sido_nm = "제주특별자치도" in 164/166

    gen sigungu_nm = ustrregexra(A, "\p{Z}+", "")
    drop A

    order sido_nm sigungu_nm
    drop if sido_nm == sigungu_nm

    destring t_firm t_lab m_lab f_lab ma_firm ma_lab ma_mlab ma_flab, replace force

    save "/Users/ihuila/Desktop/data/master thesis/raw/afterclean/aftermanu/`yr'do.dta", replace

    restore
    local ++i
}

*********************************************************************************
********************** 2012~2016년도, 8개시 
clear
set more off
cd "/Users/ihuila/Desktop/data/master thesis/raw/manufacturing"

import excel "20122016_8si.xlsx", sheet("데이터") clear

* 연도별 열 알파벳 범위와 변수 이름 매핑
local years 2012 2013 2014 2015 2016

local cols2012 B C D E F G H I
local cols2013 J K L M N O P Q
local cols2014 R S T U V W X Y
local cols2015 Z AA AB AC AD AE AF AG
local cols2016 AH AI AJ AK AL AM AN AO

local varnames t_firm t_lab m_lab f_lab ma_firm ma_lab ma_mlab ma_flab

local i = 1
foreach yr of local years {
    
    preserve

    * 열 매핑
    if `yr' == 2010 {
        keep A `cols2010'
        local collist `cols2010'
    }
    else if `yr' == 2011 {
        keep A `cols2011'
        local collist `cols2011'
    }
    else if `yr' == 2012 {
        keep A `cols2012'
        local collist `cols2012'
    }
    else if `yr' == 2013 {
        keep A `cols2013'
        local collist `cols2013'
    }
    else if `yr' == 2014 {
        keep A `cols2014'
        local collist `cols2014'
    }
    else if `yr' == 2015 {
        keep A `cols2015'
        local collist `cols2015'
    }
    else if `yr' == 2016 {
        keep A `cols2016'
        local collist `cols2016'
    }

    * rename 매핑
    local j = 1
    foreach col of local collist {
        local newvar : word `j' of `varnames'
        rename `col' `newvar'
        local ++j
    }

    gen year = `yr'
    drop in 1/4

    * 광역시 이름 설정
    gen sido_nm = "서울특별시" in 1/26
    replace sido_nm = "부산광역시" in 27/43
    replace sido_nm = "대구광역시" in 44/52
    replace sido_nm = "인천광역시" in 53/63
    replace sido_nm = "광주광역시" in 64/69 
    replace sido_nm = "대전광역시" in 70/75
    replace sido_nm = "울산광역시" in 76/81 
    replace sido_nm = "세종특별자치시" in 82/83

    * 시군구명 클리닝
    gen sigungu_nm = ustrregexra(A, "\p{Z}+", "")
    drop A

    order sido_nm sigungu_nm
    drop if sido_nm == sigungu_nm

    * 숫자형으로 변환
    destring t_firm t_lab m_lab f_lab ma_firm ma_lab ma_mlab ma_flab, replace force

    save "/Users/ihuila/Desktop/data/master thesis/raw/afterclean/aftermanu/`yr'si.dta", replace

    restore
    local ++i
}

********************************************************************************
******************** 2017~2023년도까지 9개도 
clear
set more off
cd "/Users/ihuila/Desktop/data/master thesis/raw/manufacturing"

import excel "20172023_9do.xlsx", sheet("데이터") clear

* 연도별 열 알파벳 범위와 변수 이름 매핑 (C부터 시작)
local years 2017 2018 2019 2020 2021 2022 2023

local cols2017 C D E F G H I J
local cols2018 K L M N O P Q R
local cols2019 S T U V W X Y Z
local cols2020 AA AB AC AD AE AF AG AH
local cols2021 AI AJ AK AL AM AN AO AP
local cols2022 AQ AR AS AT AU AV AW AX
local cols2023 AY AZ BA BB BC BD BE BF

local varnames t_firm t_lab m_lab f_lab ma_firm ma_lab ma_mlab ma_flab

local i = 1
foreach yr of local years {
    
    preserve

    * 열 매핑
    if `yr' == 2017 {
        keep A B `cols2017'
        local collist `cols2017'
    }
    else if `yr' == 2018 {
        keep A B `cols2018'
        local collist `cols2018'
    }
    else if `yr' == 2019 {
        keep A B `cols2019'
        local collist `cols2019'
    }
    else if `yr' == 2020 {
        keep A B `cols2020'
        local collist `cols2020'
    }
    else if `yr' == 2021 {
        keep A B `cols2021'
        local collist `cols2021'
    }
    else if `yr' == 2022 {
        keep A B `cols2022'
        local collist `cols2022'
    }
    else if `yr' == 2023 {
        keep A B `cols2023'
        local collist `cols2023'
    }

    * 변수명 매핑
    local j = 1
    foreach col of local collist {
        local newvar : word `j' of `varnames'
        rename `col' `newvar'
        local ++j
    }

    gen year = `yr'
    drop in 1/4  // 첫 행: 지역명 소개 등

	 * 도 이름 설정
    gen sido_nm = "경기도" in 1/32
    replace sido_nm = "강원도" in 33/51
    replace sido_nm = "충청북도" in 52/63
    replace sido_nm = "충청남도" in 64/79
    replace sido_nm = "전라북도" in 80/94
    replace sido_nm = "전라남도" in 95/117
    replace sido_nm = "경상북도" in 118/141
    replace sido_nm = "경상남도" in 142/160
    replace sido_nm = "제주특별자치도" in 161/163

	* 시군구명 클리닝
    gen sigungu_nm = ustrregexra(B, "\p{Z}+", "")
    drop B

	
    order sido_nm sigungu_nm
	drop if sigungu_nm=="소계" 
	drop A 

    destring t_firm t_lab m_lab f_lab ma_firm ma_lab ma_mlab ma_flab, replace force
	
    save "/Users/ihuila/Desktop/data/master thesis/raw/afterclean/aftermanu/`yr'do.dta", replace

    restore
    local ++i
}

*********************************************************************************
************ 2017~2023년도까지 8개의 시 
clear
set more off
cd "/Users/ihuila/Desktop/data/master thesis/raw/manufacturing"

import excel "20172023_8si.xlsx", sheet("데이터") clear

* 연도별 열 알파벳 범위와 변수 이름 매핑
local years 2017 2018 2019 2020 2021 2022 2023

local cols2017 C D E F G H I J
local cols2018 K L M N O P Q R
local cols2019 S T U V W X Y Z
local cols2020 AA AB AC AD AE AF AG AH
local cols2021 AI AJ AK AL AM AN AO AP
local cols2022 AQ AR AS AT AU AV AW AX
local cols2023 AY AZ BA BB BC BD BE BF

local varnames t_firm t_lab m_lab f_lab ma_firm ma_lab ma_mlab ma_flab

local i = 1
foreach yr of local years {
    
    preserve

    * 열 매핑
     * 열 매핑
    if `yr' == 2017 {
        keep A B `cols2017'
        local collist `cols2017'
    }
    else if `yr' == 2018 {
        keep A B `cols2018'
        local collist `cols2018'
    }
    else if `yr' == 2019 {
        keep A B `cols2019'
        local collist `cols2019'
    }
    else if `yr' == 2020 {
        keep A B `cols2020'
        local collist `cols2020'
    }
    else if `yr' == 2021 {
        keep A B `cols2021'
        local collist `cols2021'
    }
    else if `yr' == 2022 {
        keep A B `cols2022'
        local collist `cols2022'
    }
    else if `yr' == 2023 {
        keep A B `cols2023'
        local collist `cols2023'
    }
	
    * rename 매핑
    local j = 1
    foreach col of local collist {
        local newvar : word `j' of `varnames'
        rename `col' `newvar'
        local ++j
    }

    gen year = `yr'
    drop in 1/4

    * 광역시 이름 설정
    gen sido_nm = "서울특별시" in 1/26
    replace sido_nm = "부산광역시" in 27/43
    replace sido_nm = "대구광역시" in 44/53
    replace sido_nm = "인천광역시" in 54/64
    replace sido_nm = "광주광역시" in 65/70 
    replace sido_nm = "대전광역시" in 71/76
    replace sido_nm = "울산광역시" in 77/82 
    replace sido_nm = "세종특별자치시" in 83/84

    * 시군구명 클리닝
    gen sigungu_nm = ustrregexra(B, "\p{Z}+", "")
    drop B

	order sido_nm sigungu_nm
	drop if sigungu_nm=="소계" 
	drop A 
	
	
    * 숫자형으로 변환
    destring t_firm t_lab m_lab f_lab ma_firm ma_lab ma_mlab ma_flab, replace force

    save "/Users/ihuila/Desktop/data/master thesis/raw/afterclean/aftermanu/`yr'si.dta", replace

    restore
    local ++i
}
*****************************************************************************
***** longform 데이터로 만들기 (2010~2023년도까지)
clear
cd "/Users/ihuila/Desktop/data/master thesis/raw/afterclean/aftermanu"

* 가장 처음 파일부터 시작
use 2010do.dta, clear

* 나머지 27개 파일 append
foreach yr in 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 {
    foreach loc in do si {
        local fname = "`yr'`loc'.dta"
        if "`yr'`loc'" != "2010do" {
            append using "`fname'"
        }
    }
}

replace sigungu_nm = "세종특별자치시" if sido_nm == "세종특별자치시"

****************** 변수 만들기 
* 제조업 사업체 비율 (전체 사업체 중 제조업 비중)
gen p_mafirm = (ma_firm / t_firm) * 100

* 제조업 종사자 비율 (전체 종사자 중 제조업 종사자 비중)
gen p_malab = (ma_lab / t_lab) * 100

* 제조업 남성 종사자 비율 (제조업 종사자 중 남성 비중)
gen pm_malab = (ma_mlab / ma_lab) * 100

* 제조업 여성 종사자 비율 (제조업 종사자 중 여성 비중)
gen pf_malab = (ma_flab / ma_lab) * 100

**** 변수 라벨링 
label variable t_firm   "전체 사업체 수 (Total firms)"
label variable t_lab    "전체 종사자 수 (Total workers)"
label variable m_lab    "남성 종사자 수 (Male workers)"
label variable f_lab    "여성 종사자 수 (Female workers)"

label variable ma_firm  "제조업 사업체 수 (Manufacturing firms)"
label variable ma_lab   "제조업 종사자 수 (Manufacturing workers)"
label variable ma_mlab  "제조업 남성 종사자 수 (Male workers in manufacturing)"
label variable ma_flab  "제조업 여성 종사자 수 (Female workers in manufacturing)"

label variable p_mafirm  "Percent of manufacturing firms"
label variable p_malab   "Percent of manufacturing workers"
label variable pm_malab  "Percent male among manufacturing workers"
label variable pf_malab  "Percent female among manufacturing workers"

**** 바뀐 시군구명 수정 
replace sigungu_nm = "미추홀구" if sido_nm=="인천광역시" & sigungu_nm=="남구" 
replace sigungu_nm = "여주시" if sigungu_nm=="여주군" 
replace sigungu_nm = "당진시" if sigungu_nm=="당진군" 

** 없어진 곳 
drop if sigungu_nm=="연기군" & year !=2011 // 2011년도 연기군은 세종특별자치시 대체 데이터로 활용 
replace sigungu_nm="세종특별자치시" if year==2011 & sigungu_nm=="연기군" 
replace sido_nm="세종특별자치시" if year==2011 & sigungu_nm=="세종특별자치시"

drop if sigungu_nm=="청원군" 

** 통합된 곳 (원자료에서부터 마산/진해는 결측처리 되어있었음)
br if sigungu_nm=="마산시" | sigungu_nm=="진해시"

** 군위군 (2023년도 대구로 편입, 그 이전에 있던 경상북도 기준으로 시도명 수정)
br if sigungu_nm=="군위군" 
drop if year>=2017 & year <=2022 & sigungu_nm=="군위군" & sido_nm=="대구광역시" 
drop if year==2023 & sigungu_nm=="군위군" & sido_nm=="경상북도" 

replace sido_nm="경상북도" if year==2023 & sido_nm=="대구광역시" & sigungu_nm=="군위군" //2023년도에 대구광역시로 군위군이 편입되었지만 편의를 위해, 해당 데이터에서는 경상북도로 통일 


sort year sido_nm sigungu_nm 

* 저장
save 2010_2023.dta, replace
