clear 
use "/Users/ihuila/Desktop/data/master thesis/raw/afterclean/afterdata/spendingrobot.dta"

gen sigungu_cd = regioncode * 10 

save "/Users/ihuila/Desktop/data/master thesis/raw/afterclean/afterdata/spendingrobotmap.dta",replace 
******** 지도데이터 불러오고 스테이타 식으로 변환 
clear 
cd "/Users/ihuila/Desktop/data/master thesis/map"

* 2. shp2dta 설치 (처음이면)
*ssc install shp2dta

* 3. 변환
shp2dta using "bnd_sigungu_00_2022_4Q", database(korea_map) coordinates(korea_coord) genid(id) replace

*********** 
use korea_map, clear
describe  // id 변수 있는지 확인
destring SIGUNGU_CD, replace 

ds
foreach var in `r(varlist)' {
    local lowername = lower("`var'")
    rename `var' `lowername'
}

save korea_map, replace 

use korea_coord, clear
describe  // id 변수 있는지 확인

ds
foreach var in `r(varlist)' {
    local lowername = lower("`var'")
    rename `var' `lowername'
}
ren _id id 
save korea_coord, replace 
*************
use korea_map, clear

merge m:n id using korea_coord
drop _merge

* 데이터에 시도별 지표가 있어야 함 (merge 필요)
merge m:n sigungu_cd using "/Users/ihuila/Desktop/data/master thesis/raw/afterclean/afterdata/spendingrobotmap.dta"

des 
des id 

save "/Users/ihuila/Desktop/data/master thesis/raw/afterclean/afterdata/spendingrobotmaptemp.dta"

* STEP 1: 1차 merge (id1 기준)
use master.dta, clear
merge 1:1 id1 using using1.dta

* STEP 2: 머지 실패한 관측치 분리 저장
preserve

    * master-only (_merge == 1)
    keep if _merge == 1
    drop _merge
    gen source = 1
    tempfile master_only
    save `master_only'

restore

keep if _merge == 2
drop _merge
gen source = 2
tempfile using_only
save `using_only'

* STEP 3: 머지 실패 관측치 append
use `master_only', clear
append using `using_only'
save master.dta, replace 

* 이제 이 데이터가 "머지 실패한 모든 관측치"임
* STEP 4: 복원한 master 원본 불러오기
use master.dta, clear

* STEP 5: 다른 키 (id2)로 다시 merge
merge 1:1 sigungu_nm using "/Users/ihuila/Desktop/data/master thesis/raw/afterclean/afterdata/spendingrobotmaptemp.dta"




//ssc install spmap, replace

spmap logwelfare using "/Users/ihuila/Desktop/data/master thesis/map/korea_coord.dta", id(_ID) fcolor(Blues) clmethod(quantile) ///
    title("1인당 복지 지출 (천원)") legend(pos(3) size(small))
