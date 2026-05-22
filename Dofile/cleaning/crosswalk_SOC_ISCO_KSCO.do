**********************************************************************
* crosswalk_SOC_ISCO_KSCO.do
* ─────────────────────────────────────────────────────────────────
* 목적: SOC(2010) → ISCO-08 → KSCO 8차 → 7차 → 6차 → 5차(소분류)
*       자동화 확률(Frey-Osborne 2013)을 KLIPS 직업·산업 코드에 부착
*
* 연계 체인:
*   automation_prob.csv  (SOC 2010, 702개)
*     → isco_soc_crosswalk.xls         (SOC → ISCO-08)
*     → KSCO8-ISCO 연계표.xlsx         (ISCO-08 → KSCO 8차, 4자리 세분류)
*     → KSCO 연계표(8-7-6-5).xls      (KSCO 버전 연계, 4자리 세분류)
*     → KSCO 5차 소분류(3자리) 수준 자동화 확률
*
* 최종 산출물:
*   Data interim/crosswalk_master.dta     (마스터 크로스워크: SOC–ISCO–KSCO7–KSCO6–KSCO5–auto_prob)
*   Data interim/auto_prob_ksco5.dta      (KSCO5 소분류 수준 평균, KLIPS merge용)
*   Data interim/auto_prob_ind2000.dta    (산업×연도 수준, 1998-2000 기준)
*   Data interim/Klips_crosswalk.dta      (KLIPS 개인 패널 + 자동화 확률)
*
* Excel 셀 참조 기준 (import excel cellrange):
*   isco_soc_crosswalk.xls  → A8:D1132  (행 8부터 데이터)
*   KSCO8-ISCO 연계표.xlsx  → A7:D712   (행 7부터 데이터)
*   8차-7차 연계             → A3:C2035  (행 3부터 데이터)
*   7차-6차 연계             → A3:C2094
*   6차-5차 연계             → A4:C2812  (행 4부터 데이터)
*
* 참고: KLIPS p_jobfam2000은 KSCO 5차 소분류 코드(정수, 앞자리 0 없음)
*       예) KSCO5 "011" → KLIPS 11,  "111" → KLIPS 111
**********************************************************************

clear all
set more off

global main    "/Users/ihuila/Research/MASTER_thesis"
global raw     "${main}/Data raw"
global interim "${main}/Data interim"

* ── 파일명 전역 변수 ──────────────────────────────────────────────
global f_auto  "${raw}/automation_prob.csv"
global f_si    "${raw}/isco_soc_crosswalk.xls"
global f_ki    "${raw}/한국표준직업분류(KSCO 8차)-국제표준직업분류(ISCO-08) 연계표_20251103085955.xlsx"
global f_ver   "${raw}/한국표준직업분류 연계표(8-7 7-6 6-5 5-4 4-3)_250604_20250604045215.xls"

**********************************************************************
* PART A. Crosswalk 구축 (순수 Stata)
**********************************************************************

* ──────────────────────────────────────────────────────────────────
* A1. 자동화 확률 (SOC 2010 기준)
*     automation_prob.csv: SOC, Occupation, Probability, ...
* ──────────────────────────────────────────────────────────────────
import delimited "${f_auto}", encoding(latin1) varnames(1) clear
keep soc probability
rename soc        soc_code
rename probability auto_prob

* SOC 코드 하이픈 제거: "11-1011" → "111011"
replace soc_code = subinstr(soc_code, "-", "", .)
replace soc_code = strtrim(soc_code)
drop if missing(soc_code) | missing(auto_prob)

di "[A1] 자동화 확률 로드: " _N " SOC 코드"
tempfile f1_auto
save `f1_auto'

* ──────────────────────────────────────────────────────────────────
* A2. SOC 2010 → ISCO-08 연계표
*     Sheet: "2010 SOC to ISCO-08"
*     행 8부터 데이터 (행 7: 컬럼 헤더 "2010 SOC Code", ...)
*     Col A=SOC code, B=SOC title, C=part, D=ISCO-08 code
* ──────────────────────────────────────────────────────────────────
import excel "${f_si}", sheet("2010 SOC to ISCO-08") ///
    cellrange(A8:D1132) allstring clear

rename A soc_code
rename D isco08
drop C

drop if soc_code == "" | isco08 == ""

* SOC 코드 정리
replace soc_code = strtrim(subinstr(soc_code, "-", "", .))

* ISCO 코드 정리: 별표 제거, 앞자리 0 보완하여 4자리로
replace isco08 = strtrim(subinstr(isco08, "*", "", .))
replace isco08 = "0" + isco08 if length(isco08) == 3

* 4자리 숫자 코드만 유지
keep if regexm(isco08, "^[0-9]{4}$")
keep soc_code isco08
duplicates drop

di "[A2] SOC→ISCO 연계: " _N " 매핑 쌍"
tempfile f2_si
save `f2_si'

* ──────────────────────────────────────────────────────────────────
* A3. ISCO-08 → KSCO 8차 연계표
*     Sheet: "3-2. (연계표) ISCO(08)-KSCO(8차)"
*     행 7부터 데이터 (행 6: "세분류" 컬럼 헤더)
*     Col A=ISCO (ffill 필요), B=한국명, C=영문명, D=KSCO8
* ──────────────────────────────────────────────────────────────────
import excel "${f_ki}", ///
    sheet("3-2. (연계표) ISCO(08)-KSCO(8차)") ///
    allstring clear

drop in 1/6 

rename A isco08
rename D ksco8
drop B C

replace isco08 = strtrim(subinstr(isco08, "*", "", .))
replace ksco8  = strtrim(subinstr(ksco8,  "*", "", .))

* ISCO 코드 Forward Fill (Excel 병합 셀 → 빈 셀)
gen long _obs = _n
gen long _grp = sum(isco08 != "")
bysort _grp (_obs): replace isco08 = isco08[1]
drop _grp _obs

drop if isco08 == "" | ksco8 == ""

* 양쪽 모두 4자리 숫자 코드만 유지 (군인 A코드 등 제외)
keep if regexm(isco08, "^[0-9]{4}$") & regexm(ksco8, "^[0-9]{4}$")
keep isco08 ksco8
duplicates drop

di "[A3] ISCO→KSCO8 연계: " _N " 매핑 쌍"
tempfile f3_ki
save `f3_ki'

* ──────────────────────────────────────────────────────────────────
* A4. KSCO 버전 연계표 (공통 파싱 로직)
*
* 구조: 신부호(A, ffill 필요) | 신항목명(B) | 구부호(C)
*       행 3부터 데이터 (8차-7차, 7차-6차)
*       행 4부터 데이터 (6차-5차)
*
* 처리: ① 공백·별표 제거 → ② ffill → ③ 4자리 신부호 필터
*        → ④ 구부호 앞 4자리 추출
* ──────────────────────────────────────────────────────────────────

* ── A4a. KSCO 8차 → 7차 ─────────────────────────────────────────
import excel "${f_ver}", sheet("8차-7차 연계") ///
    allstring clear
drop in 1/2 

rename A ksco8
rename C ksco7
drop B

replace ksco8 = strtrim(subinstr(ksco8, "*", "", .))
replace ksco7 = strtrim(subinstr(ksco7, "*", "", .))

* Forward fill 신부호 (1:N 매핑 처리)
gen long _obs = _n
gen long _grp = sum(ksco8 != "")
bysort _grp (_obs): replace ksco8 = ksco8[1]
drop _grp _obs

drop if ksco8 == "" | ksco7 == ""

* 신부호(KSCO8) 4자리만, 구부호(KSCO7) 앞 4자리
keep if regexm(ksco8, "^[0-9]{4}$")
replace ksco7 = substr(ksco7, 1, 4)
keep if regexm(ksco7, "^[0-9]{4}$")
keep ksco8 ksco7
duplicates drop

di "[A4a] KSCO8→KSCO7: " _N " 매핑 쌍"
tempfile f4_v87
save `f4_v87'

* ── A4b. KSCO 7차 → 6차 ─────────────────────────────────────────
import excel "${f_ver}", sheet("7차-6차 연계") ///
     allstring clear
	 
drop in 1/2 

rename A ksco7
rename C ksco6
drop B

replace ksco7 = strtrim(subinstr(ksco7, "*", "", .))
replace ksco6 = strtrim(subinstr(ksco6, "*", "", .))

gen long _obs = _n
gen long _grp = sum(ksco7 != "")
bysort _grp (_obs): replace ksco7 = ksco7[1]
drop _grp _obs

drop if ksco7 == "" | ksco6 == ""
keep if regexm(ksco7, "^[0-9]{4}$")
replace ksco6 = substr(ksco6, 1, 4)
keep if regexm(ksco6, "^[0-9]{4}$")
keep ksco7 ksco6
duplicates drop

di "[A4b] KSCO7→KSCO6: " _N " 매핑 쌍"
tempfile f5_v76
save `f5_v76'

* ── A4c. KSCO 6차 → 5차 (소분류 3자리 추출) ─────────────────────
*     행 4부터 데이터: Col A=KSCO6, B=항목명, C=KSCO5
import excel "${f_ver}", sheet("6차-5차 연계") ///
     allstring clear

drop in 1/3 

rename A ksco6
rename C ksco5
drop B

replace ksco6 = strtrim(subinstr(ksco6, "*", "", .))
replace ksco5 = strtrim(subinstr(ksco5, "*", "", .))

gen long _obs = _n
gen long _grp = sum(ksco6 != "")
bysort _grp (_obs): replace ksco6 = ksco6[1]
drop _grp _obs

drop if ksco6 == "" | ksco5 == ""

* 신부호(KSCO6) 4자리만
keep if regexm(ksco6, "^[0-9]{4}$")

* 구부호(KSCO5) 앞 4자리 확보 후 소분류(앞 3자리) 추출
replace ksco5 = substr(ksco5, 1, 4)
keep if regexm(ksco5, "^[0-9]{3,4}$")   // 3~4자리 (앞자리 0 포함)
gen ksco5_3d = substr(ksco5, 1, 3)       // 소분류 코드 (3자리 문자열)

keep ksco6 ksco5_3d
duplicates drop

di "[A4c] KSCO6→KSCO5: " _N " 매핑 쌍"
tempfile f6_v65
save `f6_v65'

* ──────────────────────────────────────────────────────────────────
* A5. 전체 연계 체인 병합 (many-to-many joins)
*     자동화 확률 → SOC→ISCO→KSCO8→KSCO7→KSCO6→KSCO5
* ──────────────────────────────────────────────────────────────────
use `f1_auto', clear

joinby soc_code using `f2_si'    // SOC → ISCO-08
joinby isco08   using `f3_ki'    // ISCO-08 → KSCO 8차
joinby ksco8    using `f4_v87'   // KSCO 8차 → 7차
joinby ksco7    using `f5_v76'   // KSCO 7차 → 6차
joinby ksco6    using `f6_v65'   // KSCO 6차 → 5차 소분류

di "[A5] 체인 병합 완료: " _N " rows"

compress

* ──────────────────────────────────────────────────────────────────
* A6. 마스터 크로스워크 테이블
*     SOC(2010) – ISCO-08 – KSCO7차 – KSCO6차 – KSCO5차(소분류, 3자리)
*     KSCO8차는 연계 경유 코드 → 최종 산출물에서 제외
*     기준 연도: 1998 (KLIPS 1998-2000 사용 분류 = KSCO 5차)
* ──────────────────────────────────────────────────────────────────
drop ksco8
gen p_jobfam2000 = real(ksco5_3d)

bysort soc_code isco08 ksco7 ksco6 ksco5_3d: keep if _n == 1

label var soc_code     "SOC 2010 코드 (하이픈 제거)"
label var isco08       "ISCO-08 세분류 코드 (4자리)"
label var ksco7        "KSCO 7차 세분류 코드 (4자리)"
label var ksco6        "KSCO 6차 세분류 코드 (4자리)"
label var ksco5_3d     "KSCO 5차 소분류 코드 (3자리 문자열, 기준 1998년)"
label var p_jobfam2000 "KSCO 5차 소분류 코드 정수 (KLIPS p_jobfam2000)"
label var auto_prob    "자동화 확률 (Frey-Osborne 2013, SOC 수준)"

order soc_code isco08 ksco7 ksco6 ksco5_3d p_jobfam2000 auto_prob
sort p_jobfam2000 soc_code
save "${interim}/crosswalk_master.dta", replace
di "[A6] 마스터 크로스워크 저장: " _N " 행 → ${interim}/crosswalk_master.dta"

* ──────────────────────────────────────────────────────────────────
* A7. KSCO5 소분류 수준 집계 (KLIPS merge용)
*     SOC×KSCO5 deduplicate 후 KSCO5 평균
* ──────────────────────────────────────────────────────────────────
bysort soc_code ksco5_3d: keep if _n == 1
collapse (mean) auto_prob (count) n_soc = auto_prob, by(ksco5_3d p_jobfam2000)

label var auto_prob    "자동화 확률 (KSCO5 소분류 평균, Frey-Osborne 2013)"
label var n_soc        "매핑 SOC 코드 수"
label var ksco5_3d     "KSCO 5차 소분류 코드 (3자리 문자열)"
label var p_jobfam2000 "KSCO 5차 소분류 코드 정수 (KLIPS p_jobfam2000)"

sort p_jobfam2000
save "${interim}/auto_prob_ksco5.dta", replace
di "[A7] KSCO5 수준 자동화 확률 저장: " _N " 소분류 코드 → ${interim}/auto_prob_ksco5.dta"

**********************************************************************
* PART B. KLIPS 데이터에 자동화 확률 부착
**********************************************************************

use "${raw}/Klips27/Klips_long_260522.dta", clear

* ── B0. 원자료 직업 코드 커버리지 기록 ──────────────────────────
qui tab p_jobfam2000 if !missing(p_jobfam2000)
local n_occ_raw = r(r)
di "[B0] 원자료 고유 직업 코드(p_jobfam2000) 수: " `n_occ_raw'

* ── B1. 취업자 필터 (KSCO 5차 직업 코드 유효한 관측치) ───────────
*   p_jobfam2000: KSCO 5차 소분류 코드 (결측 = 미취업 또는 정보 없음)
//keep if !missing(p_jobfam2000)

* ── B2. 소분류 수준 자동화 확률 병합 (3자리 소분류만) ────────────
merge m:1 p_jobfam2000 using "${interim}/auto_prob_ksco5.dta", ///
    keep(1 3) nogen keepusing(auto_prob ksco5_3d n_soc)

rename auto_prob auto_prob_occ

count if missing(auto_prob_occ)
di "[B2] 소분류 미매핑 관측치: " r(N) " (직업 코드 있으나 crosswalk 미매핑)"

label var auto_prob_occ "자동화 확률 (직업 수준, KSCO5 소분류 기준)"

order pid ksco5_3d p_jobfam2007 p_jobfam2017
save "${interim}/Klips_crosswalk.dta", replace 
**********************************************************************
* PART C. 산업 수준 자동화 확률 (p_ind2000 × 연도)
*
* 방법: 취업자 가중 평균
*   auto_prob_ind_jt = Σ_occ (N_occ,j,t / N_j,t) × auto_prob_occ
*                    = 개인 수준 데이터의 산업-연도 평균
*                      (각 취업자가 동일 가중치를 가짐)
*
* 참고: p_ind2000은 KSIC 2000(한국표준산업분류 9차) 3자리 코드
**********************************************************************

use "${interim}/Klips_crosswalk.dta", clear

* 기준 연도 1998-2000 + 자동화 확률·산업 코드 모두 유효한 취업자
keep if inlist(year, 1998, 1999, 2000) & !missing(auto_prob_occ) & !missing(p_ind2000)

* 산업-연도 수준으로 collapse (고용 가중 평균)
collapse (mean)  auto_prob_ind  = auto_prob_occ  ///
         (count) n_workers_ind  = auto_prob_occ, ///
         by(p_ind2000 year)

label var auto_prob_ind  "산업 수준 자동화 확률 (고용 가중 평균)"
label var p_ind2000      "KSIC 2000 산업 코드 (3자리, KLIPS p_ind2000 기준)"
label var n_workers_ind  "산업-연도별 KLIPS 취업자 수 (자동화 확률 유효 표본)"
label var year           "조사 연도"

sort p_ind2000 year
order p_ind2000 year auto_prob_ind n_workers_ind

save "${interim}/auto_prob_ind2000.dta", replace
di "[C] 산업 수준 자동화 확률 저장: ${interim}/auto_prob_ind2000.dta"

**********************************************************************
* PART D. 요약 통계 및 커버리지 검증
**********************************************************************

di ""
di "=== 직업 수준 자동화 확률 요약 (KSCO 5차 소분류) ==="
use "${interim}/auto_prob_ksco5.dta", clear
sum auto_prob, detail
di "커버 소분류 코드 수: " _N

di ""
di "=== 산업 수준 자동화 확률 요약 ==="
use "${interim}/auto_prob_ind2000.dta", clear
sum auto_prob_ind, detail
di "커버 산업-연도 관측치 수: " _N

di "--- 연도별 산업 수준 자동화 확률 평균 ---"
tabstat auto_prob_ind, by(year) stat(mean sd n)

di ""
di "=== 직업 코드 커버리지 비교 ==="
use "${interim}/auto_prob_ksco5.dta", clear
local n_occ_cross = _N
di "원자료 고유 직업 코드(p_jobfam2000):         " `n_occ_raw'
di "최종 crosswalk 고유 직업 코드(p_jobfam2000): " `n_occ_cross'
if `n_occ_cross' == `n_occ_raw' {
    di "=> 직업 코드 완전 커버 (100%)"
}
else {
    local n_miss_occ = `n_occ_raw' - `n_occ_cross'
    di "=> 미커버 직업: `n_miss_occ' 개 (" ///
        string(`n_occ_cross'/`n_occ_raw'*100, "%5.1f") "% 커버)"
}

di ""
di "=== 미매핑 직업 코드 진단 ==="
use "${raw}/Klips27/Klips_long_260522.dta", clear
keep if !missing(p_jobfam2000)
duplicates drop p_jobfam2000, force
keep p_jobfam2000

merge 1:1 p_jobfam2000 using "${interim}/auto_prob_ksco5.dta", ///
    keepusing(auto_prob)
list p_jobfam2000 if _merge == 1, noobs sep(0)

di ""
di "=== crosswalk_SOC_ISCO_KSCO.do 완료 ==="
di "산출 파일:"
di "  ${interim}/auto_prob_ksco5.dta       (직업 수준)"
di "  ${interim}/auto_prob_ind2000.dta     (산업 수준)"
di "  ${interim}/Klips_crosswalk.dta       (KLIPS 개인 패널 + 자동화 확률)"

