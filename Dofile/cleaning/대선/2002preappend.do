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
local in "$main/Data raw/대선_개표/2002"
local out "$interim/대선_개표/2002"

* 파일명 리스트
local files `" "강원" "경기" "경남" "경북" "광주" "대구" "대전" "부산" "서울" "울산" "인천" "전남" "전북" "제주" "충남" "충북" "'

* 시도명 리스트 (파일명과 순서 동일하게)
local sidonames `" "강원도" "경기도" "경상남도" "경상북도" "광주광역시" "대구광역시" "대전광역시" "부산광역시" "서울특별시" "울산광역시" "인천광역시" "전라남도" "전라북도" "제주특별자치도" "충청남도" "충청북도" "'

local n = wordcount(`"`files'"')

forvalues i = 1/`n' {
    local region : word `i' of `files'
    local sidonm : word `i' of `sidonames'
    
    local fname "개표현황[제16대][대통령선거][`region'].xlsx"
    
    import excel "`in'/`fname'", firstrow clear
    
    gen sido_nm = "`sidonm'"
    
    drop in 1/3
    drop in L
    
    save "`out'/`region'.dta", replace
    
    di "완료: `region' → `sidonm'"
}

// 2단계: append로 하나로 합치기
use "$interim/대선_개표/2002/강원.dta", clear

cd "$interim/대선_개표/2002"
local files  `" "강원" "경기" "경남" "경북" "광주" "대구" "대전" "부산" "서울" "울산" "인천" "전남" "전북" "제주" "충남" "충북" "'

foreach region of local files {
    if "`region'" != "강원" {
        append using "`region'.dta", force
    }
}

save "$interim/대선_개표/2002/preappend.dta", replace
****************************************************************************
** cleaning 
use "$interim/대선_개표/2002/preappend.dta"
//drop B C F G H I K L M 
ren B 선거인수 
ren C 투표수 

ren D 한나라당 
ren E 새천년민주당
ren F 하나로국민연합
ren G 민주노동당
ren H 사회당 
ren I 호국당

ren J 유효투표수 
ren K 무효투표 
ren L 기권 

ren 중앙선거관리위원회선거통계시스템 A 

drop M 

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

destring 선거인수 투표수 한나라당 새천년민주당 하나로국민연합 민주노동당 사회당 호국당 유효투표수 무효투표 기권, replace ignore(",")
*************************************** 시군구명 정리 
gen sigungu_nm_new = sigungu_nm

gen is_metro = regexm(sido_nm, "광역시|특별시|특별자치시")

replace sigungu_nm_new = ustrregexra(sigungu_nm, "([가-힣]+시)[가-힣]+구$", "$1") ///
    if is_metro == 0 & regexm(sigungu_nm, "[가-힣]+시[가-힣]+구$")


replace sigungu_nm_new = ustrregexra(sigungu_nm, "([가-힣]+구)[가-힣]+시$", "$1") ///
    if is_metro == 1 & regexm(sigungu_nm, "[가-힣]+구[가-힣]+시$")


replace sigungu_nm_new = ustrregexra(sigungu_nm, "([가-힣]+군)[가-힣]+시$", "$1") ///
    if regexm(sigungu_nm, "[가-힣]+군[가-힣]+시$")


list sido_nm sigungu_nm sigungu_nm_new if sigungu_nm != sigungu_nm_new

drop is_metro

collapse (sum) 선거인수 투표수 한나라당 새천년민주당 하나로국민연합 민주노동당 사회당 호국당 유효투표수 무효투표 기권, by(sido_nm sigungu_nm_new)

ren sigungu_nm_new sigungu_nm 

************ STEP2: 변경된 시군구 -> 데이터 통합 혹은 변경 
****** 1) 인천광역시 남구 -> 미추홀구로 명칭변경  (명칭변경)
replace sigungu_nm = "미추홀구" if sido_nm=="인천광역시" & sigungu_nm == "남구"

****** 2) 연기군 -> 세종으로 통합되면서 연기군 폐지 (연기군 삭제, 세종특별자치시 삭제)
drop if sigungu_nm == "연기군"

***** 3)여주군 -> 여주시로 이름 변경 
replace sigungu_nm = "여주시" if sido_nm=="경기도" & sigungu_nm=="여주군" 
******************************************************************************
* 4) 창원시 통합: 마산시 + 진해시 + 창원시 → 창원시
******************************************************************************
gen sigungu_nm_new = sigungu_nm 
replace  sigungu_nm_new ="창원시" if sigungu_nm=="마산시" 
replace sigungu_nm_new = "창원시"  if sigungu_nm=="진해시" 

*******************************************************************************
* 5) 청주시 통합: 청주시 + 청원군 
*******************************************************************************
replace  sigungu_nm_new ="청주시" if sigungu_nm=="청원군" 

collapse (sum) 선거인수 투표수 한나라당 새천년민주당 하나로국민연합 민주노동당 사회당 호국당 유효투표수 무효투표 기권, by(sido_nm sigungu_nm_new)
ren sigungu_nm_new sigungu_nm 
******************************************************************************
* 5) 증평군 생성: 괴산군 1/2 분리 (2003년 이전 데이터 처리)
********************************************************************************
local varlist 선거인수 투표수 한나라당 새천년민주당 하나로국민연합 민주노동당 사회당 호국당 유효투표수 무효투표 기권

* 괴산군 값 절반으로
foreach var of local varlist {
    replace `var' = `var' / 2 if sigungu_nm == "괴산군" & sido_nm == "충청북도"
}

* 증평군 행 복사 (괴산군 절반값 그대로)
expand 2 if sigungu_nm == "괴산군" & sido_nm == "충청북도"
bysort sido_nm sigungu_nm: gen _seq = _n if sigungu_nm == "괴산군"
replace sigungu_nm = "증평군" if _seq == 2
drop _seq

* 확인
list sido_nm sigungu_nm `varlist' if inlist(sigungu_nm, "괴산군", "증평군")

*******************************************************************************
* 6) 계룡시 생성: 논산시 1/2 분리 (2003년 이전 데이터 처리)
* 주의: 실제 분리 비율 불명 → 균등 1/2 가정
********************************************************************************
* 논산시 값 절반으로
foreach var of local varlist {
    replace `var' = `var' / 2 if sigungu_nm == "논산시" & sido_nm == "충청남도"
}

* 계룡시 행 복사
expand 2 if sigungu_nm == "논산시" & sido_nm == "충청남도"
bysort sido_nm sigungu_nm: gen _seq = _n if sigungu_nm == "논산시"
replace sigungu_nm = "계룡시" if _seq == 2
drop _seq

* 확인
list sido_nm sigungu_nm `varlist' if inlist(sigungu_nm, "논산시", "계룡시")

* 제주 분석에서 제외 
drop if sido_nm == "제주특별자치도"
******************************************************
sort sido_nm sigungu_nm 

replace sigungu_nm="당진시" if sigungu_nm=="당진군"
replace sigungu_nm="양주시" if sigungu_nm=="양주군"
replace sigungu_nm="포천시" if sigungu_nm=="포천군"

gen year=2002 
tab year 

keep year sido_nm sigungu_nm 선거인수 투표수 한나라당 새천년민주당 하나로국민연합 민주노동당 사회당 호국당 유효투표수 무효투표 기권

isid sido_nm sigungu_nm 

save "$data/2002president_clean.dta", replace 
