import pandas as pd
import re

BASE      = "/Users/ihuila/Research/MASTER_thesis"
PATH_CODE = f"{BASE}/Data raw/센서스 공간정보 지역 코드.xlsx"
PATH_ELEC = f"{BASE}/Data raw/총선_개표/제20대 국회의원선거 개표결과.xlsx"
PATH_OUT  = f"{BASE}/Data raw/총선_개표/20대_지역구_읍면동별_시군구매핑.xlsx"

# ── 1. 코드 테이블 ────────────────────────────────────────────────────────────
df_code = pd.read_excel(PATH_CODE, sheet_name="2016년", header=1)
df_code.columns = ["시도코드","시도명칭","시군구코드","시군구명칭","읍면동코드","읍면동명칭"]
df_code = df_code.dropna(subset=["읍면동명칭"]).reset_index(drop=True)

# lookup: (시도, 원본읍면동) → 시군구 목록
# 코드 테이블은 원본 그대로 유지 (norm은 선거 데이터에만 적용)
lookup = (
    df_code.groupby(["시도명칭", "읍면동명칭"])["시군구명칭"]
    .apply(list)
    .to_dict()
)

# ── 2. 선거 데이터 (소계 행만) ────────────────────────────────────────────────
df_raw = pd.read_excel(PATH_ELEC, sheet_name="지역구", header=None)

df_emd = df_raw[df_raw[3] == "소계"].copy()
df_emd["시도"] = df_raw[0].replace("", pd.NA).ffill()
df_emd = (
    df_emd.rename(columns={1:"선거구", 2:"읍면동", 4:"선거인수", 5:"투표수"})
          [["시도","선거구","읍면동","선거인수","투표수"]]
          .reset_index(drop=True)
)

for col in ["선거인수", "투표수"]:
    df_emd[col] = pd.to_numeric(
        df_emd[col].astype(str).str.replace(",", ""), errors="coerce"
    )

# 선거 데이터 읍면동 정규화: 제N동 → N동
def norm_emd(name):
    return re.sub(r"제(\d)", r"\1", str(name).strip())

df_emd["읍면동_norm"] = df_emd["읍면동"].apply(norm_emd)

# ── 3. 수동 매핑 4개 ──────────────────────────────────────────────────────────
manual_map = {
    "마전동": "거제시",  # 코드 테이블 미수록
    "벌용동": "사천시",  # 코드 테이블은 '벌룡동' (한자 차이)
    "수주면": "영월군",  # 코드 테이블 미수록
    "청북면": "평택시",  # 코드 테이블은 '청북읍' (읍 승격)
}

# ── 4. 시군구 결정 ────────────────────────────────────────────────────────────
def get_sigungu(row):
    sido     = row["시도"]
    emd_orig = row["읍면동"]
    emd_norm = row["읍면동_norm"]
    # 선거구명 정규화: 갑을병정무 제거, 공백 제거
    선거구_norm = re.sub(r"[갑을병정무]$", "", str(row["선거구"])).replace(" ", "")

    # 수동 처리
    if emd_orig in manual_map:
        return manual_map[emd_orig]

    # Pass 1: 원본 읍면동명으로 조회
    candidates = lookup.get((sido, emd_orig), [])
    # Pass 2: 정규화 읍면동명으로 조회
    if not candidates:
        candidates = lookup.get((sido, emd_norm), [])
    if not candidates:
        return None
    if len(candidates) == 1:
        return candidates[0]

    # 중복 → 선거구명에 포함된 시군구 선택
    for sgg in candidates:
        sgg_norm = sgg.replace(" ", "")
        if sgg_norm in 선거구_norm or 선거구_norm in sgg_norm:
            return sgg
    return "|".join(candidates)  # 미해결 시 전부 반환 (디버깅용)

df_emd["시군구"] = df_emd.apply(get_sigungu, axis=1)

# ── 5. 검증 ──────────────────────────────────────────────────────────────────
print(f"총 읍면동 행 수: {len(df_emd)}")
print(f"시군구 NA: {df_emd['시군구'].isna().sum()}")
print(f"시군구 중복미해결(|): {df_emd['시군구'].str.contains('|', regex=False, na=False).sum()}")

# ── 6. 저장 ──────────────────────────────────────────────────────────────────
df_final = df_emd[["시도","시군구","선거구","읍면동","선거인수","투표수"]].copy()
df_sgg   = df_final.groupby(["시도","시군구"])[["선거인수","투표수"]].sum().reset_index()

with pd.ExcelWriter(PATH_OUT, engine="openpyxl") as writer:
    df_final.to_excel(writer, sheet_name="읍면동별",  index=False)
    df_sgg.to_excel(  writer, sheet_name="시군구집계", index=False)

print(f"저장 완료: {PATH_OUT}")
