***** 2022년 대선 - 전국 합치기 
clear
cd "/Users/ihuila/Desktop/data/master thesis/raw/PresiE/2022"

// 파일 이름과 시도명 매칭 리스트
local files 2022busan 2022CHB 2022CHN 2022daegu 2022daejeon 2022GB 2022GN 2022GW 2022gwangju 2022gyeonggi 2022incheon 2022JB 2022JJ 2022JN 2022seoul 2022SJ 2022ulsan
local names 부산광역시 충청북도 충청남도 대구광역시 대전광역시 경상북도 경상남도 강원도 광주광역시 경기도 인천광역시 전라북도 제주특별자치도 전라남도 서울특별시 세종특별자치시 울산광역시

// 1단계: 엑셀 -> dta + sido_nm 생성
local i = 1
foreach f of local files {
    import excel "`f'.xlsx", firstrow clear

    // sido_nm 변수 생성
    local region : word `i' of `names'
    gen sido_nm = "`region'"
	drop in 1/3 
	drop in L 

    save "/Users/ihuila/Desktop/data/master thesis/afterpresi/2022/`f'.dta", replace
    local ++i
}

// 2단계: append로 하나로 합치기
clear
cd "/Users/ihuila/Desktop/data/master thesis/afterpresi/2022"

use 2022busan.dta, clear

foreach f of local files {
    if "`f'" != "2022busan" {
        append using `f'.dta
    }
}


// 결과 저장
save "/Users/ihuila/Desktop/data/master thesis/afterpresi/2022/2022premerge.dta", replace

** cleaning 
use 2022premerge.dta, clear 

ren B 선거인수
ren C 투표수 

ren D 더불어민주당 
ren E 국민의힘
ren F 정의당 
ren G 기본소득당 
ren H 국가혁명당 
ren I 노동당 
ren J 새누리당 
ren K 신자유민주연합 
ren L 우리공화당 
ren M 진보당 
ren N 통일한국당 
ren O 한류연합당 

ren P 유효투표수
ren Q 무효투표
ren R 기권 

ren 중앙선거관리위원회선거통계시스템 A 

drop S 

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
drop if A == "합계" | A == "구시군명" | A == "시도명"
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

destring 선거인수 투표수 더불어민주당 국민의힘 정의당 기본소득당 국가혁명당 노동당 새누리당 신자유민주연합 우리공화당 진보당 통일한국당 한류연합당 유효투표수 무효투표 기권, replace ignore(",")

************ STEP2: 변경된 시군구 -> 데이터 통합 혹은 변경 
****** 1) 인천광역시 남구 -> 미추홀구로 명칭변경  (명칭변경)
replace sigungu_nm = "미추홀구" if sido_nm=="인천광역시" & sigungu_nm == "남구"

****** 2) 연기군 -> 세종으로 통합되면서 연기군 폐지 (연기군 삭제, 세종특별자치시 삭제)
drop if sigungu_nm == "연기군"

***** 3)여주군 -> 여주시로 이름 변경 
replace sigungu_nm = "여주시" if sido_nm=="경기도" & sigungu_nm=="여주군" 
 
********************************************************************************
* 4) 나머지 구로 쪼개진 시들 → 시로 통합
********************************************************************************
local varlist 선거인수 투표수 더불어민주당 국민의힘 정의당 기본소득당 국가혁명당 노동당 새누리당 신자유민주연합 우리공화당 진보당 통일한국당 한류연합당 유효투표수 무효투표 기권

local cities  "수원시 성남시 안양시 안산시 고양시 용인시 전주시 포항시 천안시 창원시 청주시" /*부천시*/

// local 부천시_gu "부천시오정구 부천시원미구 부천시소사구"
local 수원시_gu "수원시장안구 수원시권선구 수원시팔달구 수원시영통구"
local 성남시_gu "성남시수정구 성남시중원구 성남시분당구"
local 안양시_gu "안양시만안구 안양시동안구"
local 안산시_gu "안산시상록구 안산시단원구"
local 고양시_gu "고양시덕양구 고양시일산동구 고양시일산서구"
local 용인시_gu "용인시처인구 용인시기흥구 용인시수지구"
local 전주시_gu "전주시완산구 전주시덕진구"
local 포항시_gu "포항시북구 포항시남구"
local 천안시_gu "천안시서북구 천안시동남구"
local 창원시_gu "창원시의창구 창원시성산구 창원시마산합포구 창원시마산회원구 창원시진해구"
local 청주시_gu "청주시상당구 청주시서원구 청주시흥덕구 청주시청원구"

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

gen year=2022 

// 세종1, 제주2, 나머지 226 -> 총obs 229 

keep sido_nm sigungu_nm 선거인수 투표수 유효투표수 무효투표 기권 year 더불어민주당 국민의힘

cd "/Users/ihuila/Desktop/data/master thesis/afterpresi/2022/"
save 2022premerge.dta, replace 
