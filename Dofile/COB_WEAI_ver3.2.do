clear all 
set more off 
cd "/Users/ihuila/Desktop/data/2025ABS"
use cob_XYZ_final.dta 

sort LGAFINAL21 year 
xtset LGAFINAL21 year 
tsset LGAFINAL21 year, delta(5)

gen lag_share_college   = L1.share_college 
gen lag_share_popfifold = L1.share_popfifold 

global demo  lag_share_college
global demo2 lag_share_college lag_share_popfifold

*------------------------------------------------------------------------------
* English share dummy (1991 baseline)
*------------------------------------------------------------------------------
preserve
    keep if year == 1991
    gen high_eng91 = (share_eng >= share_noneng) ///
        if !missing(share_eng)
    label define lbl_eng91 0 "Low English share" 1 "High English share" 
    label values high_eng91 lbl_eng91
    keep LGAFINAL21 high_eng91 share_eng
    duplicates drop LGAFINAL21, force
    tempfile eng91_dummy
    save `eng91_dummy', replace
restore

merge m:1 LGAFINAL21 using `eng91_dummy', nogenerate

global hetero_higheng "high_eng91 == 1 & !missing(high_eng91)"
global hetero_loweng  "high_eng91 == 0 & !missing(high_eng91)"

gen sample = 1 if year >= 1996 & year <= 2021 

*------------------------------------------------------------------------------
* Common stats() macros
*------------------------------------------------------------------------------
global stat_ols ///
    stats(N r2, ///
          fmt(%9.0fc %8.3f) ///
          labels("Observations" "R-squared"))

global stat_feiv ///
    stats(fs_coef fs_se cdf widstat sy_cv10 sy_cv15 arf arfp N, ///
          fmt(%8.3f %8.3f %8.3f %8.2f %8.2f %8.3f %8.3f %9.0fc) ///
          labels("First stage: Immigration share" ///
                 "\ \ \ \ (SE)" ///
				 "C-D F-stat" ///
                 "KP F-statistic" ///
                 "Stock-Yogo CV (10\%)" ///
                 "Stock-Yogo CV (15\%)" ///
                 "AR F-statistic" ///
                 "AR p-value" ///
                 "Observations"))

cd "/Users/ihuila/Desktop/data/2025ABS/tables/3-2"

********************************************************************************
* TABLE 1: POLS + FE  —  Overall only
* Columns : (1) Unemployment (2) High skill (3) Mid skill (4) Low skill
* Panel A  : Overall POLS
* Panel B  : Overall FE
********************************************************************************

* ---------- Panel A: Overall — POLS ----------
est clear

xi: reg unempl_rate Xit2 i.year if sample==1, vce(cluster LGAFINAL21)
est store pA1

xi: reg share_highsk Xit2 i.year if sample==1, vce(cluster LGAFINAL21)
est store pA2

xi: reg share_midsk Xit2 i.year if sample==1, vce(cluster LGAFINAL21)
est store pA3

xi: reg share_lowsk Xit2 i.year if sample==1, vce(cluster LGAFINAL21)
est store pA4

esttab pA* using Table1.csv, ///
    nogap $stat_ols ///
    title("Panel A: Overall (POLS)") ///
    mtitles("Unemployment" "High skill" "Mid skill" "Low skill") ///
    b(%8.3f) se(%8.3f) ///
    label star(* 0.10 ** 0.05 *** 0.01) replace

* ---------- Panel B: Overall — FE ----------
est clear

xi: xtivreg2 unempl_rate Xit2 i.year if sample==1, fe cluster(LGAFINAL21)
est store pB1

xi: xtivreg2 share_highsk Xit2 i.year if sample==1, fe cluster(LGAFINAL21)
est store pB2

xi: xtivreg2 share_midsk Xit2 i.year if sample==1, fe cluster(LGAFINAL21)
est store pB3

xi: xtivreg2 share_lowsk Xit2 i.year if sample==1, fe cluster(LGAFINAL21)
est store pB4

esttab pB* using Table1.csv, ///
    nogap $stat_ols ///
    title("Panel B: Overall (FE)") ///
    b(%8.3f) se(%8.3f) ///
    label star(* 0.10 ** 0.05 *** 0.01) append

********************************************************************************
* TABLE 2: FE-IV  —  Overall only
* Columns : (1) Unemployment (2) High skill (3) Mid skill (4) Low skill
* Panel A  : Overall FE-IV
********************************************************************************

est clear

* --- Col (1): Unemployment ---
xi: xtivreg2 unempl_rate (Xit2 = Zit2) i.year $demo ///
    if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store mA1

* --- Col (2): High skill ---
xi: xtivreg2 share_highsk (Xit2 = Zit2) i.year $demo ///
    if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store mA2

* --- Col (3): Mid skill ---
xi: xtivreg2 share_midsk (Xit2 = Zit2) i.year $demo ///
    if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store mA3

* --- Col (4): Low skill ---
xi: xtivreg2 share_lowsk (Xit2 = Zit2) i.year $demo ///
    if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store mA4

esttab mA* , ///
    nogap $stat_feiv ///
    b(%8.3f) se(%8.3f) ///
    label star(* 0.10 ** 0.05 *** 0.01) replace

esttab mA* using Table2.csv, ///
    nogap $stat_feiv ///
    title("Panel A: Overall (FE-IV)") ///
    mtitles("Unemployment" "High skill" "Mid skill" "Low skill") ///
    b(%8.3f) se(%8.3f) ///
    label star(* 0.10 ** 0.05 *** 0.01) replace

********************************************************************************
* TABLE 3: FE-IV  —  Male + Female
* Columns : (1) Unemployment (2) High skill (3) Mid skill (4) Low skill
* Panel B  : Male FE-IV
* Panel C  : Female FE-IV
********************************************************************************

* ---------- Panel B: Male — FE-IV ----------
est clear

* --- Col (1): Male Unemployment ---
xi: xtivreg2 ma_unempl_rate (Xit2 = Zit2) i.year $demo ///
    if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store mB1

* --- Col (2): Male High skill ---
xi: xtivreg2 share_mhighsk (Xit2 = Zit2) i.year $demo ///
    if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store mB2

* --- Col (3): Male Mid skill ---
xi: xtivreg2 share_mmidsk (Xit2 = Zit2) i.year $demo ///
    if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store mB3

* --- Col (4): Male Low skill ---
xi: xtivreg2 share_mlowsk (Xit2 = Zit2) i.year $demo ///
    if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store mB4

esttab mB* , ///
    nogap $stat_feiv ///
    b(%8.3f) se(%8.3f) ///
    label star(* 0.10 ** 0.05 *** 0.01) replace
	
esttab mB* using Table3.csv, ///
    nogap $stat_feiv ///
    title("Panel B: Male (FE-IV)") ///
    mtitles("Unemployment" "High skill" "Mid skill" "Low skill") ///
    b(%8.3f) se(%8.3f) ///
    label star(* 0.10 ** 0.05 *** 0.01) replace

* ---------- Panel C: Female — FE-IV ----------
est clear

* --- Col (1): Female Unemployment ---
xi: xtivreg2 fe_unempl_rate (Xit2 = Zit2) i.year $demo ///
    if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store mC1

* --- Col (2): Female High skill ---
xi: xtivreg2 share_fhighsk (Xit2 = Zit2) i.year $demo ///
    if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store mC2

* --- Col (3): Female Mid skill ---
xi: xtivreg2 share_fmidsk (Xit2 = Zit2) i.year $demo ///
    if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store mC3

* --- Col (4): Female Low skill ---
xi: xtivreg2 share_flowsk (Xit2 = Zit2) i.year $demo ///
    if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store mC4

esttab mC* , ///
    nogap $stat_feiv ///
    b(%8.3f) se(%8.3f) ///
    label star(* 0.10 ** 0.05 *** 0.01) 
	
esttab mC* using Table3.csv, ///
    nogap $stat_feiv ///
    title("Panel C: Female (FE-IV)") ///
    b(%8.3f) se(%8.3f) ///
    label star(* 0.10 ** 0.05 *** 0.01) append

********************************************************************************
* TABLE 4: Marriage Share  —  POLS + FE + FE-IV
* Columns : (1) Overall  (2) Male  (3) Female
* Panel A  : POLS
* Panel B  : FE
* Panel C  : FE-IV
********************************************************************************

* ---------- Panel A: POLS ----------
est clear

xi: reg share_mar Xit2 i.year if sample==1, vce(cluster LGAFINAL21)
est store tA1

xi: reg share_marmale Xit2 i.year if sample==1, vce(cluster LGAFINAL21)
est store tA2

xi: reg share_marfemale Xit2 i.year if sample==1, vce(cluster LGAFINAL21)
est store tA3

esttab tA* using Table4.csv, ///
    nogap $stat_ols ///
    title("Panel A: POLS") ///
    mtitles("Overall" "Male" "Female") ///
    b(%8.3f) se(%8.3f) ///
    label star(* 0.10 ** 0.05 *** 0.01) replace

* ---------- Panel B: FE ----------
est clear

xi: xtivreg2 share_mar Xit2 i.year if sample==1, fe cluster(LGAFINAL21)
est store tB1

xi: xtivreg2 share_marmale Xit2 i.year if sample==1, fe cluster(LGAFINAL21)
est store tB2

xi: xtivreg2 share_marfemale Xit2 i.year if sample==1, fe cluster(LGAFINAL21)
est store tB3

esttab tB* using Table4.csv, ///
    nogap $stat_ols ///
    title("Panel B: FE") ///
    b(%8.3f) se(%8.3f) ///
    label star(* 0.10 ** 0.05 *** 0.01) append

* ---------- Panel C: FE-IV ----------
est clear

* --- Col (1): Overall Marriage ---
xi: xtivreg2 share_mar (Xit2 = Zit2) i.year $demo ///
    if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store tC1

* --- Col (2): Male Marriage ---
xi: xtivreg2 share_marmale (Xit2 = Zit2) i.year $demo ///
    if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store tC2

* --- Col (3): Female Marriage ---
xi: xtivreg2 share_marfemale (Xit2 = Zit2) i.year $demo ///
    if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store tC3


esttab tC*, ///
    nogap $stat_feiv ///
    b(%8.3f) se(%8.3f) ///
    label star(* 0.10 ** 0.05 *** 0.01) 
	
	
esttab tC* using Table4.csv, ///
    nogap $stat_feiv ///
    title("Panel C: FE-IV") ///
    b(%8.3f) se(%8.3f) ///
    label star(* 0.10 ** 0.05 *** 0.01) append

********************************************************************************
* TABLE 5: HETEROGENEITY  —  High vs Low English share
* Columns : High English (Overall/Male/Female) | Low English (Overall/Male/Female)
********************************************************************************

* ---------- Hetero: Unemployment ----------
est clear

* --- High English: Overall ---
xi: xtivreg2 unempl_rate (Xit2 = Zit2) i.year $demo ///
    if sample==1 & $hetero_higheng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store h_high_unempl

* --- High English: Male ---
xi: xtivreg2 ma_unempl_rate (Xit2 = Zit2) i.year $demo ///
    if sample==1 & $hetero_higheng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store h_high_ma_unempl

* --- High English: Female ---
xi: xtivreg2 fe_unempl_rate (Xit2 = Zit2) i.year $demo ///
    if sample==1 & $hetero_higheng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store h_high_fe_unempl

* --- Low English: Overall ---
xi: xtivreg2 unempl_rate (Xit2 = Zit2) i.year $demo ///
    if sample==1 & $hetero_loweng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store h_low_unempl

* --- Low English: Male ---
xi: xtivreg2 ma_unempl_rate (Xit2 = Zit2) i.year $demo ///
    if sample==1 & $hetero_loweng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store h_low_ma_unempl

* --- Low English: Female ---
xi: xtivreg2 fe_unempl_rate (Xit2 = Zit2) i.year $demo ///
    if sample==1 & $hetero_loweng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store h_low_fe_unempl

esttab h_high_unempl h_high_ma_unempl h_high_fe_unempl ///
       h_low_unempl  h_low_ma_unempl  h_low_fe_unempl  ///
    using Table5.csv, ///
    nogap $stat_feiv ///
    title("Hetero: Unemployment") ///
    mtitles("H-All" "H-Male" "H-Female" "L-All" "L-Male" "L-Female") ///
    b(%8.3f) se(%8.3f) ///
    label star(* 0.10 ** 0.05 *** 0.01) replace

* ---------- Hetero: Skill level ----------
est clear

* --- High English: High skill ---
xi: xtivreg2 share_highsk (Xit2 = Zit2) i.year $demo ///
    if sample==1 & $hetero_higheng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store h_high_highsk

* --- High English: Mid skill ---
xi: xtivreg2 share_midsk (Xit2 = Zit2) i.year $demo ///
    if sample==1 & $hetero_higheng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store h_high_midsk

* --- High English: Low skill ---
xi: xtivreg2 share_lowsk (Xit2 = Zit2) i.year $demo ///
    if sample==1 & $hetero_higheng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store h_high_lowsk

* --- Low English: High skill ---
xi: xtivreg2 share_highsk (Xit2 = Zit2) i.year $demo ///
    if sample==1 & $hetero_loweng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store h_low_highsk

* --- Low English: Mid skill ---
xi: xtivreg2 share_midsk (Xit2 = Zit2) i.year $demo ///
    if sample==1 & $hetero_loweng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store h_low_midsk

* --- Low English: Low skill ---
xi: xtivreg2 share_lowsk (Xit2 = Zit2) i.year $demo ///
    if sample==1 & $hetero_loweng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store h_low_lowsk

esttab h_high_highsk h_high_midsk h_high_lowsk ///
       h_low_highsk  h_low_midsk  h_low_lowsk  ///
    using Table5.csv, ///
    nogap $stat_feiv ///
    title("Hetero: Skill level") ///
    mtitles("H-High" "H-Mid" "H-Low" "L-High" "L-Mid" "L-Low") ///
    b(%8.3f) se(%8.3f) ///
    label star(* 0.10 ** 0.05 *** 0.01) append

* ---------- Hetero: Marriage share ----------
est clear

* --- High English: Overall Marriage ---
xi: xtivreg2 share_mar (Xit2 = Zit2) i.year $demo ///
    if sample==1 & $hetero_higheng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store h_high_mar

* --- High English: Male Marriage ---
xi: xtivreg2 share_marmale (Xit2 = Zit2) i.year $demo ///
    if sample==1 & $hetero_higheng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store h_high_mar_male

* --- High English: Female Marriage ---
xi: xtivreg2 share_marfemale (Xit2 = Zit2) i.year $demo ///
    if sample==1 & $hetero_higheng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store h_high_mar_fem

* --- Low English: Overall Marriage ---
xi: xtivreg2 share_mar (Xit2 = Zit2) i.year $demo ///
    if sample==1 & $hetero_loweng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store h_low_mar

* --- Low English: Male Marriage ---
xi: xtivreg2 share_marmale (Xit2 = Zit2) i.year $demo ///
    if sample==1 & $hetero_loweng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store h_low_mar_male

* --- Low English: Female Marriage ---
xi: xtivreg2 share_marfemale (Xit2 = Zit2) i.year $demo ///
    if sample==1 & $hetero_loweng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store h_low_mar_fem

esttab h_high_mar h_high_mar_male h_high_mar_fem ///
       h_low_mar  h_low_mar_male  h_low_mar_fem,  ///
    nogap $stat_feiv ///
    b(%8.3f) se(%8.3f) ///
    label star(* 0.10 ** 0.05 *** 0.01) 
	
esttab h_high_mar h_high_mar_male h_high_mar_fem ///
       h_low_mar  h_low_mar_male  h_low_mar_fem  ///
    using Table5.csv, ///
    nogap $stat_feiv ///
    title("Hetero: Marriage share") ///
    mtitles("H-All" "H-Male" "H-Female" "L-All" "L-Male" "L-Female") ///
    b(%8.3f) se(%8.3f) ///
    label star(* 0.10 ** 0.05 *** 0.01) append

* ---------- Hetero2: Marriage share (Metropolitan vs. non-metro) ----------
est clear

* --- High English: Overall Marriage ---
xi: xtivreg2 share_mar (Xit2 = Zit2) i.year $demo ///
    if sample==1 & metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store h_high_mar

* --- High English: Male Marriage ---
xi: xtivreg2 share_marmale (Xit2 = Zit2) i.year $demo ///
    if sample==1 & metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store h_high_mar_male

* --- High English: Female Marriage ---
xi: xtivreg2 share_marfemale (Xit2 = Zit2) i.year $demo ///
    if sample==1 & metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store h_high_mar_fem

* --- Low English: Overall Marriage ---
xi: xtivreg2 share_mar (Xit2 = Zit2) i.year $demo ///
    if sample==1 & metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store h_low_mar

* --- Low English: Male Marriage ---
xi: xtivreg2 share_marmale (Xit2 = Zit2) i.year $demo ///
    if sample==1 & metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store h_low_mar_male

* --- Low English: Female Marriage ---
xi: xtivreg2 share_marfemale (Xit2 = Zit2) i.year $demo ///
    if sample==1 & metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store h_low_mar_fem

esttab h_high_mar h_high_mar_male h_high_mar_fem ///
       h_low_mar  h_low_mar_male  h_low_mar_fem,  ///
    nogap $stat_feiv ///
    b(%8.3f) se(%8.3f) ///
    label star(* 0.10 ** 0.05 *** 0.01) 
********************************************************************************
* SUMMARY STATISTICS
********************************************************************************
tabstat Xit2 ///
        unempl_rate share_highsk share_midsk share_lowsk ///
		ma_unempl_rate fe_unempl_rate ///
		share_mhighsk share_fhighsk ///
		share_mmidsk share_fmidsk /// 
		share_mlowsk share_flowsk ///
        share_mar share_marmale share_marfemale ///
        if sample==1, ///
        stat(mean sd min max N) col(stat)
		
