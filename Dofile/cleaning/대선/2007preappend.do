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
// 파일 이름과 시도명 매칭 리스트
local in "$main/Data raw/대선_개표/2007"
local out "$interim/대선_개표/2007"
local files  `" "강원도" "경기도" "경상남도" "경상북도" "광주광역시" "대구광역시" "대전광역시" "부산광역시" "서울특별시" "울산광역시" "인천광역시" "전라남도" "전라북도" "제주특별자치도" "충청남도" "충청북도" "'

foreach region of local files {
    
    local fname "개표현황[제17대][대통령선거][`region'].xlsx"
    
    import excel "`in'/`fname'", firstrow clear
    
    gen sido_nm = "`region'"
    
    drop in 1/3
    drop in L
    
    save "`out'/`region'.dta", replace
    
    di "완료: `region'"
}

// 2단계: append로 하나로 합치기
use "$interim/대선_개표/2007/강원도.dta", clear

cd "$interim/대선_개표/2007"
local files  `" "강원도" "경기도" "경상남도" "경상북도" "광주광역시" "대구광역시" "대전광역시" "부산광역시" "서울특별시" "울산광역시" "인천광역시" "전라남도" "전라북도" "제주특별자치도" "충청남도" "충청북도" "'

foreach region of local files {
    if "`region'" != "강원도" {
        append using "`region'.dta", force
    }
}

save "$interim/대선_개표/2007/preappend.dta", replace
**********************************************************************************
** cleaning 
use "$interim/대선_개표/2007/preappend.dta", clear 

//drop B C F G H I K L M 
ren B 선거인수 
ren C 투표수 

ren D 대통합민주신당 
ren E 한나라당
ren F 민주노동당 
ren G 민주당
ren H 창조한국당 
ren I 참주인연합
ren J 경제공화당 
ren K 새시대참사람연합 
ren L 한국사회당 
ren M 무소속이회창 

ren N 유효투표수 
ren O 무효투표 
ren P 기권 

ren 중앙선거관리위원회선거통계시스템 A 

drop Q 

order sido_nm A 
drop in 1/3

******************** STEP 1 
* 문자열인 변수 - 문자열 앞뒤공백 제거 
ds, has(type string)
foreach var of varlist `r(varlist)' {
    replace `var' = ustrtrim(`var') if !missing(`var')
}

//득표율 말고, 투표수 기준으로 다시 계산(추후 패널데이터 통합, 시군구 구획 변경때문에)
drop if A == "" // 짝수행 제거 
drop if A == "합계" | A == "구시군명"

tab A 

* 1. 깨진 문자 패턴 설정 (한글, 영문, 숫자 외 문자 제거)
gen A_clean = ustrregexra(A, "[^\uAC00-\uD7A3a-zA-Z0-9]", "")

* 2. 원래 값과 비교해서 '깨짐이 있었던 경우'만 처리
replace A_clean = A_clean + "시" if A != A_clean

* 3. A 변수 덮어쓰기 (선택사항)
replace A = A_clean if A != A_clean

* 4. 정리
drop A_clean

ren A sigungu_nm 

destring 선거인수 투표수 대통합민주신당 한나라당 민주노동당 민주당 창조한국당 참주인연합 경제공화당 새시대참사람연합 한국사회당 무소속이회창 유효투표수 무효투표 기권, replace ignore(",")

************ STEP2: 변경된 시군구 -> 데이터 통합 혹은 변경 
****** 1) 인천광역시 남구 -> 미추홀구로 명칭변경  (명칭변경)
replace sigungu_nm = "미추홀구" if sido_nm=="인천광역시" & sigungu_nm == "남구"

****** 2) 연기군 -> 세종으로 통합되면서 연기군 폐지 (연기군 삭제, 세종특별자치시 삭제)
drop if sigungu_nm == "연기군"


***** 3)여주군 -> 여주시로 이름 변경 
replace sigungu_nm = "여주시" if sido_nm=="경기도" & sigungu_nm=="여주군" 
 
********************************************************************************
* 4) 창원시 통합: 마산시 + 진해시 + 창원시 → 창원시
********************************************************************************
local varlist 선거인수 투표수 대통합민주신당 한나라당 민주노동당 민주당 창조한국당 참주인연합 경제공화당 새시대참사람연합 한국사회당 무소속이회창 유효투표수 무효투표 기권

local target   "창원시"
local src_list "마산시 진해시"

* src 조건 생성
local src_cond ""
foreach src of local src_list {
    if "`src_cond'" == "" local src_cond `"sigungu_nm == "`src'""'
    else                   local src_cond `"`src_cond' | sigungu_nm == "`src'""'
}

* Step 1: 합산값 스칼라로 저장
foreach var of local varlist {
    quietly summarize `var' if sigungu_nm == "`target'"
    local base_`var' = r(sum)
    foreach src of local src_list {
        quietly summarize `var' if sigungu_nm == "`src'"
        local base_`var' = `base_`var'' + r(sum)
    }
}

* Step 2: _new 변수 생성 (target 행에만 합산값 입력)
foreach var of local varlist {
    gen `var'_new = `var'
    replace `var'_new = `base_`var'' if sigungu_nm == "`target'"
}

* Step 3: 검증
local all_ok 1
foreach var of local varlist {
    quietly summarize `var'_new if sigungu_nm == "`target'"
    local diff = abs(r(mean) - `base_`var'')
    if `diff' > 0.01 {
        di "  ❌ `var' 불일치: 예상=`base_`var'', _new=`r(mean)'"
        local all_ok 0
    }
}
if `all_ok' == 1 di "  ✅ 창원시 모든 변수 일치"

* Step 4: 처리
if `all_ok' == 1 {
    drop if `src_cond'                          // 마산시, 진해시 행 삭제
    foreach var of local varlist {
        drop `var'
        rename `var'_new `var'
    }
    di "  ✅ 창원시 통합 완료"
}
else {
    foreach var of local varlist {
        drop `var'_new
    }
    di "  ⚠️ 검증 실패 — 창원시 통합 중단"
}


********************************************************************************
* 5) 청주시 통합: 청원군 + 청주시상당구 + 청주시흥덕구 → 청주시
********************************************************************************
local target   "청주시"
local src_list "청원군 청주시상당구 청주시흥덕구"

* src 조건 생성
local src_cond ""
foreach src of local src_list {
    if "`src_cond'" == "" {
        local src_cond `"sigungu_nm == "`src'""'
    }
    else {
        local src_cond `"`src_cond' | sigungu_nm == "`src'""'
    }
}

* ★ 청주시 행 없으면 새로 삽입
count if sigungu_nm == "`target'"
if r(N) == 0 {
    insobs 1
    replace sigungu_nm = "`target'" if sigungu_nm == ""
    replace sido_nm    = "충청북도"  if sigungu_nm == "`target'"
    di "  ✅ 청주시 행 생성 완료"
}


* Step 1: 합산값 스칼라로 저장
foreach var of local varlist {
    quietly summarize `var' if sigungu_nm == "`target'"
    local base_`var' = r(sum)          // 청주시 행은 이제 존재하지만 missing이므로 0
    foreach src of local src_list {
        quietly summarize `var' if sigungu_nm == "`src'"
        local base_`var' = `base_`var'' + r(sum)
    }
}

* Step 2: 청주시 행에 합산값 채우기
foreach var of local varlist {
    replace `var' = `base_`var'' if sigungu_nm == "`target'"
}

* Step 3: 검증
local all_ok 1
foreach var of local varlist {
    quietly summarize `var' if sigungu_nm == "`target'"
    local diff = abs(r(mean) - `base_`var'')
    if `diff' > 0.01 {
        di "  ❌ `var' 불일치: 예상=`base_`var'', 실제=`r(mean)'"
        local all_ok 0
    }
}
if `all_ok' == 1 {
    di "  ✅ 청주시 모든 변수 일치"
}

* Step 4: 처리
if `all_ok' == 1 {
    drop if `src_cond'
    di "  ✅ 청주시 통합 완료"
}
else {
    * 실패 시 삽입했던 청주시 행도 제거
    drop if sigungu_nm == "`target'"
    di "  ⚠️ 검증 실패 — 청주시 통합 중단"
}

********************************************************************************
* 6) 나머지 구로 쪼개진 시들 → 시로 통합
********************************************************************************
local cities  "부천시 수원시 성남시 안양시 안산시 고양시 용인시 전주시 포항시"

local 부천시_gu "부천시오정구 부천시원미구 부천시소사구"
local 수원시_gu "수원시장안구 수원시권선구 수원시팔달구 수원시영통구"
local 성남시_gu "성남시수정구 성남시중원구 성남시분당구"
local 안양시_gu "안양시만안구 안양시동안구"
local 안산시_gu "안산시상록구 안산시단원구"
local 고양시_gu "고양시덕양구 고양시일산동구 고양시일산서구"
local 용인시_gu "용인시처인구 용인시기흥구 용인시수지구"
local 전주시_gu "전주시완산구 전주시덕진구"
local 포항시_gu "포항시북구 포항시남구"

foreach city of local cities {

    local gu_list "``city'_gu'"

    * keep 조건 생성
    local keep_cond ""
    foreach gu of local gu_list {
        if "`keep_cond'" == "" local keep_cond `"sigungu_nm == "`gu'""'
        else                    local keep_cond `"`keep_cond' | sigungu_nm == "`gu'""'
    }

    di "==============================="
    di "통합: `city'"
    di "==============================="

    * Step 1: 합산값 스칼라로 저장
    foreach var of local varlist {
        local base_`var' = 0
        foreach gu of local gu_list {
            quietly summarize `var' if sigungu_nm == "`gu'"
            local base_`var' = `base_`var'' + r(sum)
        }
    }

    * Step 2: 통합행 생성 후 append
    preserve
    keep if `keep_cond'
    collapse (sum) `varlist', by(sido_nm)
    gen sigungu_nm = "`city'"
    tempfile merged_`city'
    save `merged_`city''
    restore

    drop if `keep_cond'
    append using `merged_`city''

    * Step 3: 검증
    local all_ok 1
    foreach var of local varlist {
        quietly summarize `var' if sigungu_nm == "`city'"
        local diff = abs(r(mean) - `base_`var'')
        if `diff' > 0.01 {
            di "  ❌ `var' 불일치: 예상=`base_`var'', 실제=`r(mean)'"
            local all_ok 0
        }
    }
    if `all_ok' == 1 di "  ✅ 모든 변수 일치 — `city' 통합 완료"
    else             di "  ⚠️ 검증 실패 — `city' 확인 필요"
}

******************************************************
sort sido_nm sigungu_nm 

replace sigungu_nm="당진시" if sigungu_nm=="당진군"
gen year=2007 

// 제주2, 세종0, 나머지 226 -> 총 obs 228 

keep sido_nm sigungu_nm 선거인수 투표수 유효투표수 무효투표 기권 year 대통합민주신당 한나라당 창조한국당 무소속이회창 

save "$data/2007president_clean.dta", replace 
