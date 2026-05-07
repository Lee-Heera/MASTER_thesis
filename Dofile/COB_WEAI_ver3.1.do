clear all 
set more off 
cd "/Users/ihuila/Desktop/data/2025ABS"
use cob_XYZ_final.dta 

tab year 

sort LGAFINAL21 year 
xtset LGAFINAL21 year 
***********************************************************************
order LGAFINAL21 year

sort LGAFINAL21 year 
tsset LGAFINAL21 year, delta(5)

gen lag_year = L1.year
gen lag_share_college = L1.share_college 
gen lag_share_popfifold = L1.share_popfifold 

global demo lag_share_college
global demo2 lag_share_college lag_share_popfifold

preserve
    keep if year == 1991
	
	/*
	* 중위값 추출
    quietly sum share_eng, d
    local median_eng91 = r(p50)
    display "Median English immigrant share (1991) = `median_eng91'"
*/
    * 더미 생성
    gen high_eng91 = (share_eng >= share_noneng) ///
        if !missing(share_eng)

    label define lbl_eng91 ///
        0 "Low English share" ///
        1 "High English share" 
    label values high_eng91 lbl_eng91

    * 확인
    tab high_eng91
    tabstat share_eng, ///
        by(high_eng91) stats(n mean sd min max)

    keep LGAFINAL21 high_eng91 share_eng
    duplicates drop LGAFINAL21, force

    tempfile eng91_dummy
    save `eng91_dummy', replace
restore

merge m:1 LGAFINAL21 using `eng91_dummy', nogenerate

* Global 정의
global hetero_higheng "high_eng91 == 1 & !missing(high_eng91)"
global hetero_loweng  "high_eng91 == 0 & !missing(high_eng91)"

* 최종 확인
tab high_eng91 year

/*
* 이질성분석 기준변수 만들기 (female college share)
preserve
    keep if year == 1991
    gen sexratio91 = male20 / female20 

    keep LGAFINAL21 sexratio91 
    duplicates drop LGAFINAL21, force       

    sum sexratio91, d             
    tempfile sr1991
    save `sr1991'
restore

merge m:1 LGAFINAL21 using `sr1991', nogenerate

sum sexratio91, d // 
codebook sexratio91 // missing 없음 
*/

gen sample = 1 if year >= 1996 & year <= 2021 
************************* 1. 전체 main table ******************
cd "/Users/ihuila/Desktop/data/2025ABS/tables/3-1"
*********************** Table 1 - about unemployment rate 
// Table1 (Panel A)
est clear 

xi: reg unempl_rate Xit i.year if sample==1, vce(cluster LGAFINAL21)
est store reg1 

xi: reg ma_unempl_rate Xit i.year  if sample==1, vce(cluster LGAFINAL21)
est store reg2

xi: reg fe_unempl_rate Xit i.year if sample==1, vce(cluster LGAFINAL21)
est store reg3 

esttab reg* using Table1.csv, nogap stats(N r2) title("Table 1A: POLS")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace  


// Table 1 (Panel B) : FE
est clear
xi: xtivreg2 unempl_rate Xit i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m1

xi: xtivreg2 ma_unempl_rate Xit i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m2 

xi: xtivreg2 fe_unempl_rate Xit i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m3 

esttab m* using Table1.csv, nogap stats(N r2) title("Table 1B: FE")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append


// Table 1 (Panel C): FE-IV estimation 
est clear 
xi: xtivreg2 unempl_rate (Xit = Zit) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 ma_unempl_rate (Xit = Zit) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 fe_unempl_rate (Xit = Zit) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m3 

esttab m* using Table1.csv, nogap stats(N widstat arf arfp) title("Table 1C: FEIV")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append

esttab m* , nogap stats(N widstat arf arfp)  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01)

*********************** Table 2  - about jobs employment by skill level 
// Table 2 (Panel A): POLS 
est clear 

xi: reg share_highsk Xit i.year if sample==1, vce(cluster LGAFINAL21)
est store reg1 

xi: reg share_midsk Xit i.year  if sample==1, vce(cluster LGAFINAL21)
est store reg2

xi: reg share_lowsk Xit i.year if sample==1, vce(cluster LGAFINAL21)
est store reg3 

esttab reg* using Table2.csv, nogap stats(N r2) title("Table 2A: POLS")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace  


// Table 2 (Panel B) : FE
est clear
xi: xtivreg2 share_highsk Xit i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m1

xi: xtivreg2 share_midsk Xit i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m2 

xi: xtivreg2 share_lowsk Xit i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m3 

esttab m* using Table2.csv, nogap stats(N r2) title("Table 2B: FE")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append


// Table 2 (Panel C): FE-IV estimation 
est clear 
xi: xtivreg2 share_highsk (Xit = Zit) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 share_midsk (Xit = Zit) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 share_lowsk (Xit = Zit) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m3 

esttab m* , nogap stats(N widstat arf arfp)  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01)

esttab m* using Table2.csv, nogap stats(N widstat arf arfp) title("Table 2C: FEIV")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append

*********************** Table 3 - about marriage rate 
// Table 3 (Panel A)
est clear 

xi: reg share_mar Xit i.year if sample==1, vce(cluster LGAFINAL21)
est store reg1 

xi: reg share_marmale Xit i.year  if sample==1, vce(cluster LGAFINAL21)
est store reg2

xi: reg share_marfemale Xit i.year if sample==1, vce(cluster LGAFINAL21)
est store reg3 

esttab reg* using Table3.csv, nogap stats(N r2) title("Table 3A: POLS")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace  


// Table 3 (Panel B) : FE
est clear
xi: xtivreg2 share_mar Xit i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m1

xi: xtivreg2 share_marmale Xit i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m2 

xi: xtivreg2 share_marfemale Xit i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m3 

esttab m* using Table3.csv, nogap stats(N r2) title("Table 3B: FE")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append


// Table 3 (Panel C): FE-IV estimation 
est clear 
xi: xtivreg2 share_mar (Xit = Zit) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 share_marmale (Xit = Zit) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 share_marfemale (Xit = Zit) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m3 

esttab m* using Table3.csv, nogap stats(N widstat arf arfp) title("Table 3C: FEIV")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append
*********************** Table 4 - about STEM 
// Table 4 (Panel A)
est clear 

xi: reg share_stem Xit i.year if sample==1, vce(cluster LGAFINAL21)
est store reg1 

xi: reg share_stemm Xit i.year  if sample==1, vce(cluster LGAFINAL21)
est store reg2

xi: reg share_stemf Xit i.year if sample==1, vce(cluster LGAFINAL21)
est store reg3 

esttab reg* using Table4.csv, nogap stats(N r2) title("Table 4A: POLS")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace  


// Table 4 (Panel B) : FE
est clear
xi: xtivreg2 share_stem Xit i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m1

xi: xtivreg2 share_stemm Xit i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m2 

xi: xtivreg2 share_stemf Xit i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m3 

esttab m* using Table4.csv, nogap stats(N r2) title("Table 4B: FE")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append


// Table 4 (Panel C): FE-IV estimation 
est clear 
xi: xtivreg2 share_stem (Xit = Zit) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 share_stemm (Xit = Zit) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 share_stemf (Xit = Zit) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m3 

esttab m* using Table4.csv, nogap stats(N widstat arf arfp) title("Table 4C: FEIV")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append

*************************************pilot study**************************

est clear 
xi: xtivreg2 share_highsk (Xit = Zit) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 share_mhighsk (Xit = Zit) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 
xi: xtivreg2 share_fhighsk (Xit = Zit) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m3 

xi: xtivreg2 share_midsk (Xit = Zit) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m4 

xi: xtivreg2 share_mmidsk (Xit = Zit) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m5 
xi: xtivreg2 share_fmidsk (Xit = Zit) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m6 

xi: xtivreg2 share_lowsk (Xit = Zit) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m7 

xi: xtivreg2 share_mlowsk (Xit = Zit) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m8
xi: xtivreg2 share_flowsk (Xit = Zit) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m9 

esttab m*, nogap stats(N widstat arf arfp)  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01)
************************Summary statistics**************
tabstat unempl_rate if year>=1996 & year<=2021 , stat (mean sd min max N)
br unempl_rate if sample==1 

tabstat Xit if sample==1,  stat (mean sd min max N)

tabstat unempl_rate if sample==1,  stat (mean sd min max N)
tabstat ma_unempl_rate if sample==1,  stat (mean sd min max N)
tabstat fe_unempl_rate if sample==1,  stat (mean sd min max N)

tabstat share_highsk if sample==1,  stat (mean sd min max N)
tabstat share_midsk if sample==1,  stat (mean sd min max N)
tabstat share_lowsk if sample==1,  stat (mean sd min max N)

tabstat share_mar if sample==1,  stat (mean sd min max N)
tabstat share_marmale if sample==1,  stat (mean sd min max N)
tabstat share_marfemale if sample==1,  stat (mean sd min max N)

tabstat share_stem if sample==1,  stat (mean sd min max N)
tabstat share_stemm if sample==1,  stat (mean sd min max N)
tabstat share_mar if sample==1,  stat (mean sd min max N)

*********************heterogeneity analysis 
// table 1 
est clear 
xi: xtivreg2 unempl_rate (Xit = Zit) i.year $demo  if sample==1& $hetero_higheng , fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 ma_unempl_rate (Xit = Zit) i.year $demo  if sample==1& $hetero_higheng , fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 fe_unempl_rate (Xit = Zit) i.year $demo  if sample==1&  $hetero_higheng , fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m3 

xi: xtivreg2 unempl_rate (Xit = Zit) i.year $demo  if sample==1& $hetero_loweng , fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m4

xi: xtivreg2 ma_unempl_rate (Xit = Zit) i.year $demo  if sample==1& $hetero_loweng, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m5 

xi: xtivreg2 fe_unempl_rate (Xit = Zit) i.year $demo  if sample==1& $hetero_loweng , fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m6  

esttab m* , nogap stats(N widstat arf arfp)  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) 

esttab m* using Table5.csv, nogap stats(N widstat arf arfp) title("Table 5: Hetero")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace 



// table 2 
est clear 
xi: xtivreg2 share_highsk (Xit = Zit) i.year $demo  if sample==1 & $hetero_higheng , fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 share_midsk (Xit = Zit) i.year $demo  if sample==1 & $hetero_higheng, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 share_lowsk (Xit = Zit) i.year $demo  if sample==1& $hetero_higheng , fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m3 

xi: xtivreg2 share_highsk (Xit = Zit) i.year $demo  if sample==1 & $hetero_loweng , fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m4

xi: xtivreg2 share_midsk (Xit = Zit) i.year $demo  if sample==1& $hetero_loweng , fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m5 

xi: xtivreg2 share_lowsk (Xit = Zit) i.year $demo  if sample==1& $hetero_loweng , fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m6  

esttab m* , nogap stats(N widstat arf arfp)  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) 

esttab m* using Table5.csv, nogap stats(N widstat arf arfp) title("Table 5: Hetero")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append

// Table 3 (Panel C): FE-IV estimation 
est clear 
xi: xtivreg2 share_mar (Xit = Zit) i.year $demo  if sample==1& $hetero_higheng , fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 share_marmale (Xit = Zit) i.year $demo  if sample==1& $hetero_higheng , fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 share_marfemale (Xit = Zit) i.year $demo  if sample==1& $hetero_higheng , fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m3 

xi: xtivreg2 share_mar (Xit = Zit) i.year $demo  if sample==1& $hetero_loweng , fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m4 

xi: xtivreg2 share_marmale (Xit = Zit) i.year $demo  if sample==1& $hetero_loweng , fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m5 

xi: xtivreg2 share_marfemale (Xit = Zit) i.year $demo  if sample==1& $hetero_loweng , fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m6 

esttab m* , nogap stats(N widstat arf arfp)  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) 

esttab m* using Table5.csv, nogap stats(N widstat arf arfp) title("Table 5: Hetero")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append

// table 4 
est clear 
xi: xtivreg2 share_stem (Xit = Zit) i.year $demo  if sample==1 & $hetero_higheng , fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 share_stemm (Xit = Zit) i.year $demo  if sample==1 & $hetero_higheng , fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 share_stemf (Xit = Zit) i.year $demo  if sample==1& $hetero_higheng , fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m3 

xi: xtivreg2 share_stem (Xit = Zit) i.year $demo  if sample==1& $hetero_loweng , fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m4 

xi: xtivreg2 share_stemm (Xit = Zit) i.year $demo  if sample==1& $hetero_loweng , fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m5  

xi: xtivreg2 share_stemf (Xit = Zit) i.year $demo  if sample==1& $hetero_loweng , fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m6  

esttab m* using Table5.csv, nogap stats(N widstat arf arfp) title("Table 5: Hetero")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append
