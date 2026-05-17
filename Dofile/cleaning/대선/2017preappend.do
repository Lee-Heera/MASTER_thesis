**********************************************************************
* 대선 정치
* 2017 대통령선거 (19대) 개표결과 정리
**********************************************************************
clear all

global main   "/Users/ihuila/Research/MASTER_thesis"
global data   "${main}/Data cleaned"
global interim "${main}/Data interim"

local yr   2017
local elec 19
local in   "$main/Data raw/대선_개표/`yr'"
local out  "$interim/대선_개표/`yr'"

**********************************************************************
* STEP 1: 시도별 Excel → dta 저장
**********************************************************************
local files `" "강원도" "경기도" "경상남도" "경상북도" "광주광역시" "대구광역시" "대전광역시" "부산광역시" "서울특별시" "울산광역시" "인천광역시" "전라남도" "전라북도" "제주특별자치도" "충청남도" "충청북도" "세종특별자치시" "'

foreach region of local files {
    import excel "`in'/개표현황[제`elec'대][대통령선거][`region'].xlsx", firstrow clear
    gen sido_nm = "`region'"
    drop in 1/3
    drop in L
    save "`out'/`region'.dta", replace
}

**********************************************************************
* STEP 2: append
**********************************************************************
use "`out'/강원도.dta", clear
foreach region of local files {
    if "`region'" != "강원도" append using "`out'/`region'.dta", force
}
save "`out'/preappend.dta", replace

**********************************************************************
* STEP 3: 열 정리 및 변수명 부여
**********************************************************************
use "`out'/preappend.dta", clear

ren 중앙선거관리위원회선거통계시스템 sigungu_nm
ren B 선거인수
ren C 투표수
ren D 더불어민주당
ren E 자유한국당
ren F 국민의당
ren G 바른정당
ren H 정의당
ren I 새누리당
ren J 경제애국당
ren K 국민대통합당
ren L 늘푸른한국당
ren M 민중연합당
ren N 한국국민당
ren O 홍익당
ren P 무소속김민찬
ren Q 유효투표수
ren R 무효투표
ren S 기권
drop T

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

local varlist 선거인수 투표수 더불어민주당 자유한국당 국민의당 바른정당 정의당 새누리당 경제애국당 국민대통합당 늘푸른한국당 민중연합당 한국국민당 홍익당 무소속김민찬 유효투표수 무효투표 기권
destring `varlist', replace ignore(",")

**********************************************************************
* STEP 4: 시군구명 정규화
**********************************************************************
gen is_metro = regexm(sido_nm, "광역시|특별시|특별자치시")

replace sigungu_nm = ustrregexra(sigungu_nm, "([가-힣]+시)[가-힣]+구$", "$1") ///
    if !is_metro & regexm(sigungu_nm, "[가-힣]+시[가-힣]+구$")
replace sigungu_nm = ustrregexra(sigungu_nm, "([가-힣]+구)[가-힣]+시$", "$1") ///
    if is_metro & regexm(sigungu_nm, "[가-힣]+구[가-힣]+시$")
replace sigungu_nm = ustrregexra(sigungu_nm, "([가-힣]+군)[가-힣]+시$", "$1") ///
    if regexm(sigungu_nm, "[가-힣]+군[가-힣]+시$")
drop is_metro

**********************************************************************
* STEP 5: 1차 collapse → 시군구 단위
**********************************************************************
collapse (sum) `varlist', by(sido_nm sigungu_nm)

**********************************************************************
* STEP 6: 행정구역 변경 처리
**********************************************************************
* ── 공통 ─────────────────────────────────────────────────────────────
replace sigungu_nm = "미추홀구" if sido_nm=="인천광역시" & sigungu_nm=="남구"
drop if sigungu_nm == "연기군"
replace sigungu_nm = "여주시"   if sido_nm=="경기도" & sigungu_nm=="여주군"

* ── 창원시 통합: 마산시 + 진해시 → 창원시
replace sigungu_nm = "창원시" if inlist(sigungu_nm, "마산시", "진해시")

* ── 청주시 통합: 청원군 → 청주시
replace sigungu_nm = "청주시" if sigungu_nm == "청원군"

* ── 군 → 시 명칭 변경
replace sigungu_nm = "당진시" if sigungu_nm == "당진군"

**********************************************************************
* STEP 7: 2차 collapse (통합 후)
**********************************************************************
collapse (sum) `varlist', by(sido_nm sigungu_nm)

**********************************************************************
* STEP 8: 저장
**********************************************************************
gen year = `yr'
tab year  // 세종1, 제주2, 나머지 226 → 229

keep year sido_nm sigungu_nm `varlist'
isid sido_nm sigungu_nm
sort sido_nm sigungu_nm
save "$data/`yr'president_clean.dta", replace
