"""
crosswalk_prep.py
-----------------
SOC (2010) -> ISCO-08 -> KSCO 8차 -> 7차 -> 6차 -> 5차 (소분류, 3-digit)

입력 파일:
  - Data raw/automation_prob.csv
  - Data raw/isco_soc_crosswalk.xls
  - Data raw/한국표준직업분류(KSCO 8차)-국제표준직업분류(ISCO-08) 연계표_*.xlsx
  - Data raw/한국표준직업분류 연계표(8-7 7-6 6-5 5-4 4-3)_*.xls

출력 파일:
  - Data interim/auto_prob_ksco5.csv
      p_jobfam2000  : KSCO 5차 소분류 코드 (정수, KLIPS p_jobfam2000 변수와 일치)
      ksco5_3d      : 3자리 문자열 (앞자리 0 포함)
      auto_prob     : Frey-Osborne 자동화 확률 (단순 평균, 모든 매핑 경로 포함)
      n_soc         : 해당 코드에 매핑된 SOC 코드 수
"""

import sys
import os
import re
import pandas as pd
import numpy as np
import warnings
warnings.filterwarnings("ignore")

# ─────────────────────────────────────────────
# 경로 설정
# ─────────────────────────────────────────────
MAIN = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
RAW  = os.path.join(MAIN, "Data raw")
OUT  = os.path.join(MAIN, "Data interim")
os.makedirs(OUT, exist_ok=True)

# ─────────────────────────────────────────────
# Helper: KSCO 버전 연계표 파싱
# ─────────────────────────────────────────────
XLS_VER = os.path.join(RAW, "한국표준직업분류 연계표(8-7 7-6 6-5 5-4 4-3)_250604_20250604045215.xls")

def _clean_code(x):
    """공백·별표 제거 후 첫 번째 영숫자 토큰 반환."""
    if pd.isna(x):
        return np.nan
    m = re.match(r'^([A-Za-z0-9]+)', str(x).strip().replace("*", "").strip())
    return m.group(1) if m else np.nan

def parse_ver_xwalk(sheet, ncol=0, ocol=2):
    """
    신부호(ncol) → 구부호(ocol) 연계표를 파싱.
    - 신부호 열을 ffill하여 1:N 매핑 포착
    - 순수 숫자 코드만 유지 (군인 A 코드 제외)
    """
    df = pd.read_excel(XLS_VER, sheet_name=sheet, header=None)[[ncol, ocol]].copy()
    df.columns = ["new", "old"]
    df["new"] = df["new"].apply(_clean_code)
    df["old"] = df["old"].apply(_clean_code)
    df["new"] = df["new"].ffill()          # 1:N 매핑 처리
    df = df.dropna(subset=["old"])
    df = df[df["new"].str.match(r"^\d+$", na=False) &
            df["old"].str.match(r"^\d+$", na=False)]
    return df.drop_duplicates()

# ─────────────────────────────────────────────
# STEP 1: 자동화 확률 (SOC 2010 기준)
# ─────────────────────────────────────────────
print("[1/5] 자동화 확률 데이터 로드 중...")
auto = pd.read_csv(os.path.join(RAW, "automation_prob.csv"), encoding="latin1")
auto["soc_code"] = auto["SOC"].str.replace("-", "", regex=False).str.strip()
auto = (auto[["soc_code", "Probability"]]
        .rename(columns={"Probability": "auto_prob"})
        .dropna())
print(f"    SOC 코드 수: {len(auto)}")

# ─────────────────────────────────────────────
# STEP 2: SOC 2010 → ISCO-08
# ─────────────────────────────────────────────
print("[2/5] SOC → ISCO-08 연계표 로드 중...")
xls_soc = pd.ExcelFile(os.path.join(RAW, "isco_soc_crosswalk.xls"))
si = pd.read_excel(xls_soc, sheet_name="2010 SOC to ISCO-08",
                   header=None, skiprows=6)[[0, 3]].copy()
si.columns = ["soc_code", "isco08"]
si = si.dropna(subset=["soc_code", "isco08"])
si["soc_code"] = si["soc_code"].astype(str).str.replace("-", "", regex=False).str.strip()
si["isco08"]   = (si["isco08"].astype(str).str.strip()
                  .str.replace("*", "", regex=False)
                  .str.zfill(4))
si = si[si["isco08"].str.match(r"^\d{4}$")]
print(f"    SOC-ISCO 매핑 수: {len(si)} ({si['soc_code'].nunique()} SOC → {si['isco08'].nunique()} ISCO)")

# ─────────────────────────────────────────────
# STEP 3: ISCO-08 → KSCO 8차 (4자리 세분류)
# ─────────────────────────────────────────────
print("[3/5] ISCO-08 → KSCO 8차 연계표 로드 중...")
import glob
ksco8_files = glob.glob(os.path.join(RAW, "한국표준직업분류(KSCO 8차)-국제표준직업분류(ISCO-08) 연계표*.xlsx"))
xls_ksco8 = pd.ExcelFile(ksco8_files[0])
ik = pd.read_excel(xls_ksco8,
                   sheet_name="3-2. (연계표) ISCO(08)-KSCO(8차)",
                   header=None, skiprows=5)[[0, 3]].copy()
ik.columns = ["isco08", "ksco8"]
ik["isco08"] = ik["isco08"].ffill()           # ISCO 코드 ffill (병합 셀 처리)
ik = ik.dropna(subset=["ksco8"])
ik["isco08"] = (ik["isco08"].astype(str).str.strip()
                .str.replace("*", "", regex=False)
                .str.zfill(4))
ik["ksco8"] = ik["ksco8"].astype(str).str.strip().str.replace("*", "", regex=False)
# 4자리 숫자 코드만 (세분류)
ik = ik[ik["isco08"].str.match(r"^\d{4}$") &
        ik["ksco8"].str.match(r"^\d{4}$")].drop_duplicates()
print(f"    ISCO-KSCO8 매핑 수: {len(ik)} ({ik['isco08'].nunique()} ISCO → {ik['ksco8'].nunique()} KSCO8)")

# ─────────────────────────────────────────────
# STEP 4: KSCO 버전 연계 (8차→7차→6차→5차)
# ─────────────────────────────────────────────
print("[4/5] KSCO 버전 연계표 처리 중 (8차→7차→6차→5차)...")

# 4자리 KSCO8 → (최대 4자리) KSCO7
v87 = parse_ver_xwalk("8차-7차 연계")
v87 = v87[v87["new"].str.len() == 4].copy()
v87.columns = ["ksco8", "ksco7"]
v87["ksco7"] = v87["ksco7"].str[:4]
v87 = v87.drop_duplicates()
print(f"    KSCO8→7: {len(v87)} pairs")

# 4자리 KSCO7 → (최대 4자리) KSCO6
v76 = parse_ver_xwalk("7차-6차 연계")
v76 = v76[v76["new"].str.len() == 4].copy()
v76.columns = ["ksco7", "ksco6"]
v76["ksco6"] = v76["ksco6"].str[:4]
v76 = v76.drop_duplicates()
print(f"    KSCO7→6: {len(v76)} pairs")

# 4자리 KSCO6 → KSCO5 4자리 → 앞 3자리 = 소분류
v65 = parse_ver_xwalk("6차-5차 연계")
v65 = v65[v65["new"].str.len() == 4].copy()
v65.columns = ["ksco6", "ksco5_4d"]
v65["ksco5_4d"] = v65["ksco5_4d"].str[:4]
v65["ksco5_3d"] = v65["ksco5_4d"].str[:3]     # 소분류 (앞 3자리)
v65 = v65[["ksco6", "ksco5_3d"]].drop_duplicates()
print(f"    KSCO6→5: {len(v65)} pairs → {v65['ksco5_3d'].nunique()} 소분류 코드")

# ─────────────────────────────────────────────
# STEP 5: 연계 체인 병합 & 소분류 수준 집계
# ─────────────────────────────────────────────
print("[5/5] 전체 연계 체인 병합 및 집계 중...")

merged = (auto
          .merge(si,   on="soc_code", how="left")
          .merge(ik,   on="isco08",   how="left")
          .merge(v87,  on="ksco8",    how="left")
          .merge(v76,  on="ksco7",    how="left")
          .merge(v65,  on="ksco6",    how="left"))

matched = merged.dropna(subset=["ksco5_3d"])
print(f"    매칭 성공: {matched['soc_code'].nunique()} SOC / {len(auto)} SOC ({matched['soc_code'].nunique()/len(auto)*100:.1f}%)")
print(f"    커버 소분류 수: {matched['ksco5_3d'].nunique()}")

# 각 SOC별로 KSCO5 소분류 집계 (여러 경로 평균)
# - 먼저 SOC × ksco5_3d 로 deduplicate (중복 경로 제거)
# - 그 후 ksco5_3d 수준으로 자동화 확률 평균
soc_ksco = (matched[["soc_code", "ksco5_3d", "auto_prob"]]
            .drop_duplicates(subset=["soc_code", "ksco5_3d"]))  # 경로 중복 제거

result = (soc_ksco
          .groupby("ksco5_3d")
          .agg(auto_prob=("auto_prob", "mean"),
               n_soc=("soc_code", "nunique"))
          .reset_index())

result["p_jobfam2000"] = result["ksco5_3d"].astype(int)  # KLIPS 코드 (앞자리 0 없음)
result = result.sort_values("p_jobfam2000").reset_index(drop=True)

# ─────────────────────────────────────────────
# 2차 보완: 미매핑 코드를 중분류(2자리) 평균으로 대체
# ─────────────────────────────────────────────
result["ksco5_2d"] = result["ksco5_3d"].str[:2]
group2 = result.groupby("ksco5_2d")["auto_prob"].mean().rename("auto_prob_2d")
result = result.merge(group2, on="ksco5_2d", how="left")

out_cols = ["p_jobfam2000", "ksco5_3d", "auto_prob", "n_soc"]
out = result[out_cols].copy()

# ─────────────────────────────────────────────
# 저장
# ─────────────────────────────────────────────
out_path = os.path.join(OUT, "auto_prob_ksco5.csv")
out.to_csv(out_path, index=False, encoding="utf-8-sig")
print(f"\n[완료] {out_path} 저장 ({len(out)} 소분류 코드)")
print(out.to_string(index=False))

# ─────────────────────────────────────────────
# 부록: 2자리 중분류 평균 테이블 (Stata에서 보완 매핑 용)
# ─────────────────────────────────────────────
sup2 = result.groupby("ksco5_2d").agg(
    auto_prob_2d=("auto_prob", "mean"),
    n_soc_2d=("n_soc", "sum")
).reset_index()
sup2["p_jobfam2000_2d"] = sup2["ksco5_2d"].astype(int)
sup2_path = os.path.join(OUT, "auto_prob_ksco5_2digit.csv")
sup2.to_csv(sup2_path, index=False, encoding="utf-8-sig")
print(f"[완료] {sup2_path} 저장 (중분류 보완용, {len(sup2)} 코드)")
