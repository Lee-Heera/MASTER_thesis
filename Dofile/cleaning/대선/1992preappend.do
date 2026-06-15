**********************************************************************
* 대선 정치
* 1992 대통령선거 (14대) 개표결과 정리
**********************************************************************
clear all

global main   "/Users/ihuila/Research/MASTER_thesis"
global data   "${main}/Data cleaned"
global interim "${main}/Data interim"

local yr   1992 
local elec 14
local in   "$main/Data raw/대선_개표/`yr'"
local out  "$interim/대선_개표/`yr'"

**********************************************************************
* STEP 1: 시도별 Excel → dta 저장
**********************************************************************
local files    `" "강원" "경기" "경남" "경북" "광주" "대구" "대전" "부산" "서울" "인천" "전남" "전북" "제주" "충남" "충북" "'
local sidonames `" "강원도" "경기도" "경상남도" "경상북도" "광주광역시" "대구광역시" "대전광역시" "부산광역시" "서울특별시" "인천광역시" "전라남도" "전라북도" "제주특별자치도" "충청남도" "충청북도" "'

local n = wordcount(`"`files'"')
forvalues i = 1/`n' {
    local region : word `i' of `files'
    local sidonm : word `i' of `sidonames'
    import excel "`in'/개표현황[제`elec'대][대통령선거][`region'].xlsx", firstrow clear
    gen sido_nm = "`sidonm'"
    drop in 1/3
    drop in L
    save "`out'/`region'.dta", replace
}

**********************************************************************
* STEP 2: append
**********************************************************************
use "`out'/강원.dta", clear
foreach region of local files {
    if "`region'" != "강원" append using "`out'/`region'.dta", force
}
save "`out'/preappend.dta", replace

**********************************************************************
* STEP 3: 열 정리 및 변수명 부여
**********************************************************************
use "`out'/preappend.dta", clear

ren 중앙선거관리위원회선거통계시스템 sigungu_nm
ren B 선거인수
ren C 투표수
ren D 민주자유당 
ren E 민주당 
ren F 통일국민당 
ren G 신정당 
ren H 대한정의당 
ren I 무소속김옥선 
ren J 무소속백기완 
ren K 유효투표수
ren L 무효투표
ren M 기권
drop N

order sido_nm sigungu_nm

* 문자열 앞뒤 공백 제거
ds, has(type string)
foreach var of varlist `r(varlist)' {
    replace `var' = ustrtrim(`var') if !missing(`var')
}

* 헤더/푸터 행 제거
drop if sigungu_nm == "" | inlist(sigungu_nm, "합계", "구시군명", "시도명")

* 깨진 문자 처리
gen _clean = ustrregexra(sigungu_nm, "[^가-힣a-zA-Z0-9]", "")
replace sigungu_nm = _clean + "시" if sigungu_nm != _clean
drop _clean

* 갑/을/병/정 제거 (선거구 분할 표기)
replace sigungu_nm = ustrregexra(sigungu_nm, "[갑을병정]$", "") ///
    if regexm(sigungu_nm, "[갑을병정]$")

local varlist 선거인수 투표수 민주자유당 민주당 통일국민당 신정당 대한정의당 무소속김옥선 무소속백기완 유효투표수 무효투표 기권
destring `varlist', replace ignore(",")

**********************************************************************
* STEP 4: 시군구명 정규화
**********************************************************************
* 울산시 -> 울산광역시  
replace sido_nm = "울산광역시" if sido_nm=="경상남도" & sigungu_nm=="울산시중구"
replace sido_nm = "울산광역시" if sido_nm=="경상남도" & sigungu_nm=="울산시남구"
replace sido_nm = "울산광역시" if sido_nm=="경상남도" & sigungu_nm=="울산시동구"

gen is_metro = regexm(sido_nm, "광역시|특별시|특별자치시")

* 일반도 시+구 → 시 (예: 부천시원미구 → 부천시)
replace sigungu_nm = ustrregexra(sigungu_nm, "([가-힣]+시)[가-힣]+구$", "$1") ///
    if !is_metro & regexm(sigungu_nm, "[가-힣]+시[가-힣]+구$")

* 광역시 구+시 → 구
replace sigungu_nm = ustrregexra(sigungu_nm, "([가-힣]+구)[가-힣]+시$", "$1") ///
    if is_metro & regexm(sigungu_nm, "[가-힣]+구[가-힣]+시$")

* 군+시 → 군
replace sigungu_nm = ustrregexra(sigungu_nm, "([가-힣]+군)[가-힣]+시$", "$1") ///
    if regexm(sigungu_nm, "[가-힣]+군[가-힣]+시$")

drop is_metro

* 수동 보정
// replace sigungu_nm = "중구" if sido_nm=="서울특별시" & sigungu_nm=="중구서울시"

**********************************************************************
* STEP 5: 1차 collapse → 시군구 단위
**********************************************************************
collapse (sum) `varlist', by(sido_nm sigungu_nm)

**********************************************************************
* STEP 6: 행정구역 변경 처리
**********************************************************************
* ── 공통 ─────────────────────────────────────────────────────────────
replace sigungu_nm = "미추홀구" if sido_nm=="인천광역시" & sigungu_nm=="남구"

replace sigungu_nm = "세종특별자치시" if sigungu_nm == "연기군"
replace sido_nm = "세종특별자치시" if sigungu_nm=="세종특별자치시"

replace sigungu_nm = "여주시"   if sido_nm=="경기도" & sigungu_nm=="여주군"

* ── 창원시 통합: 마산시 + 진해시 + 창원군 → 창원시
replace sigungu_nm = "창원시" if inlist(sigungu_nm, "마산시", "진해시", "창원군")

* ── 청주시 통합: 청원군 → 청주시
replace sigungu_nm = "청주시" if sigungu_nm == "청원군"

* ── 여수시 통합: 여천군 + 여천시 → 여수시
replace sigungu_nm = "여수시" if inlist(sigungu_nm, "여천군", "여천시")

* ── 평택시 통합: 평택군 + 송탄시 → 평택시
replace sigungu_nm = "평택시" if inlist(sigungu_nm, "평택군", "송탄시")

* ── 제주: 남제주군 → 서귀포시, 북제주군 → 제주시
replace sigungu_nm = "서귀포시" if sigungu_nm == "남제주군"
replace sigungu_nm = "제주시"   if sigungu_nm == "북제주군"

* 동광양시, 광양군 -> 광양시
replace sigungu_nm="광양시" if sigungu_nm=="동광양시"
replace sigungu_nm="광양시" if sigungu_nm=="광양군"

* ── 군 → 시 명칭 변경 (동일 명칭의 기존 시가 없는 경우)
foreach pair in "당진군:당진시" "김포군:김포시" "화성군:화성시" "안성군:안성시" ///
                "광주군:광주시" "양주군:양주시" "포천군:포천시" ///
                "남양주군:남양주시" "용인군:용인시" "이천군:이천시" "파주군:파주시" ///
                "양산군:양산시" "논산군:논산시" {
    local old = substr("`pair'", 1, strpos("`pair'", ":")-1)
    local new = substr("`pair'", strpos("`pair'", ":")+1, .)
    replace sigungu_nm = "`new'" if sigungu_nm == "`old'"
}

* 미금시 → 남양주시 (남양주군과 통합되어 남양주시로 신설)
replace sigungu_nm = "남양주시" if sigungu_nm == "미금시"

* ── 1995년 행정구역 통합: 군 → 동일 명칭의 기존 시로 흡수
foreach pair in "명주군:강릉시" "삼척군:삼척시" "원주군:원주시" "춘천군:춘천시" ///
                "김해군:김해시" "밀양군:밀양시" "진양군:진주시" ///
                "경산군:경산시" "경주군:경주시" "금릉군:김천시" "상주군:상주시" ///
                "선산군:구미시" "안동군:안동시" "영일군:포항시" "영천군:영천시" ///
                "영풍군:영주시" "김제군:김제시" "남원군:남원시" "옥구군:군산시" ///
                "나주군:나주시" "승주군:순천시" "공주군:공주시" "서산군:서산시" ///
                "천안군:천안시" "제천군:제천시" "중원군:충주시" {
    local old = substr("`pair'", 1, strpos("`pair'", ":")-1)
    local new = substr("`pair'", strpos("`pair'", ":")+1, .)
    replace sigungu_nm = "`new'" if sigungu_nm == "`old'"
}

* ── 1995년 행정구역 통합: 두 단위가 합쳐져 새 시로 신설
replace sigungu_nm = "거제시" if inlist(sigungu_nm, "거제군", "장승포시")
replace sigungu_nm = "사천시" if inlist(sigungu_nm, "사천군", "삼천포시")
replace sigungu_nm = "통영시" if inlist(sigungu_nm, "충무시", "통영군")
replace sigungu_nm = "문경시" if inlist(sigungu_nm, "문경군", "점촌시")
replace sigungu_nm = "익산시" if inlist(sigungu_nm, "이리시", "익산군")
replace sigungu_nm = "정읍시" if inlist(sigungu_nm, "정읍군", "정주시")
replace sigungu_nm = "보령시" if inlist(sigungu_nm, "대천시", "보령군")
replace sigungu_nm = "아산시" if inlist(sigungu_nm, "아산군", "온양시")

* ── 1995년 시도 변경: 경기도 → 인천광역시 편입
replace sido_nm = "인천광역시" if sido_nm=="경기도" & sigungu_nm=="강화군"
replace sido_nm = "인천광역시" if sido_nm=="경기도" & sigungu_nm=="옹진군"

* ── 1995년 시도 변경: 경상북도 달성군 → 대구광역시 편입
replace sido_nm = "대구광역시" if sido_nm=="경상북도" & sigungu_nm=="달성군"

* ── 1997년 울산광역시 승격: 경상남도 울산군 → 울산광역시 울주군
replace sigungu_nm = "울주군"    if sido_nm=="경상남도" & sigungu_nm=="울산군"
replace sido_nm    = "울산광역시" if sido_nm=="경상남도" & sigungu_nm=="울주군"

* ── 울산시중구/남구/동구 → 울산광역시 중구/남구/동구 (구명 정리)
replace sigungu_nm = "남구" if sido_nm=="울산광역시" & sigungu_nm=="울산시남구"
replace sigungu_nm = "동구" if sido_nm=="울산광역시" & sigungu_nm=="울산시동구"
replace sigungu_nm = "중구" if sido_nm=="울산광역시" & sigungu_nm=="울산시중구"

**********************************************************************
* STEP 7: 2차 collapse (통합 후)
**********************************************************************
collapse (sum) `varlist', by(sido_nm sigungu_nm)

**********************************************************************
* STEP 8: 시군구 분리 (1995~97년 신설 구·군 처리, 1/2 균등 분리 가정)
**********************************************************************
* 인천 북구 → 부평구 + 계양구 (북구는 소멸)
foreach var of local varlist {
    replace `var' = `var' / 2 if sido_nm=="인천광역시" & sigungu_nm=="북구"
}
expand 2 if sido_nm=="인천광역시" & sigungu_nm=="북구"
bysort sido_nm sigungu_nm: gen _seq = _n if sido_nm=="인천광역시" & sigungu_nm=="북구"
replace sigungu_nm = "부평구" if _seq==1 & sido_nm=="인천광역시" & sigungu_nm=="북구"
replace sigungu_nm = "계양구" if _seq==2 & sido_nm=="인천광역시" & sigungu_nm=="북구"
drop _seq

* spec 형식: "기존시도:기존시군구:신설시도:신설시군구" (기존 단위를 1/2씩 분리하여 신설)
foreach spec in ///
    "충청북도:괴산군:충청북도:증평군" ///
    "충청남도:논산시:충청남도:계룡시" ///
    "광주광역시:서구:광주광역시:남구" ///
    "경상남도:양산시:부산광역시:기장군" ///
    "부산광역시:북구:부산광역시:사상구" ///
    "부산광역시:남구:부산광역시:수영구" ///
    "부산광역시:동래구:부산광역시:연제구" ///
    "서울특별시:도봉구:서울특별시:강북구" ///
    "서울특별시:성동구:서울특별시:광진구" ///
    "서울특별시:구로구:서울특별시:금천구" ///
    "울산광역시:동구:울산광역시:북구" ///
    "인천광역시:미추홀구:인천광역시:연수구" {

    local s = subinstr("`spec'", ":", " ", .)
    local old_sido    : word 1 of `s'
    local old_sigungu : word 2 of `s'
    local new_sido    : word 3 of `s'
    local new_sigungu : word 4 of `s'

    foreach var of local varlist {
        replace `var' = `var' / 2 if sido_nm=="`old_sido'" & sigungu_nm=="`old_sigungu'"
    }
    expand 2 if sido_nm=="`old_sido'" & sigungu_nm=="`old_sigungu'"
    bysort sido_nm sigungu_nm: gen _seq = _n if sido_nm=="`old_sido'" & sigungu_nm=="`old_sigungu'"
    replace sigungu_nm = "`new_sigungu'" if _seq==2 & sido_nm=="`old_sido'" & sigungu_nm=="`old_sigungu'"
    replace sido_nm    = "`new_sido'"    if _seq==2 & sido_nm=="`old_sido'" & sigungu_nm=="`new_sigungu'"
    drop _seq
}

**********************************************************************
* STEP 9: 저장
**********************************************************************
gen year = `yr'
tab year  

keep year sido_nm sigungu_nm `varlist'

isid sido_nm sigungu_nm
sort sido_nm sigungu_nm
save "$data/`yr'president_clean.dta", replace
