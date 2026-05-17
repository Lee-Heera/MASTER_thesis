library(tidyverse)
library(readxl)
library(writexl)

BASE <- "/Users/ihuila/Research/MASTER_thesis"
PATH_CODE  <- file.path(BASE, "Data raw/센서스 공간정보 지역 코드.xlsx")
PATH_ELEC  <- file.path(BASE, "Data raw/총선_개표/제20대 국회의원선거 개표결과.xlsx")
PATH_OUT   <- file.path(BASE, "Data raw/총선_개표/20대_지역구_읍면동별_시군구매핑.xlsx")

# ── 1. 코드 테이블 ──────────────────────────────────────────────
code_tbl <- read_excel(PATH_CODE, sheet = "2016년", skip = 1,
                       col_names = c("시도코드","시도명칭","시군구코드",
                                     "시군구명칭","읍면동코드","읍면동명칭")) |>
  filter(!is.na(읍면동명칭)) |>
  select(시도명칭, 시군구명칭, 읍면동명칭)

# ── 2. 선거 데이터 (소계 행만) ──────────────────────────────────
raw <- read_excel(PATH_ELEC, sheet = "지역구", col_names = FALSE)

df_emd <- raw |>
  set_names(seq_len(ncol(raw))) |>
  rename(시도_raw = `1`, 선거구 = `2`, 읍면동 = `3`,
         투표구 = `4`, 선거인수 = `5`, 투표수 = `6`) |>
  fill(시도_raw) |>                          # 시도 forward fill
  filter(투표구 == "소계") |>
  transmute(
    시도     = 시도_raw,
    선거구,
    읍면동,
    선거인수 = parse_number(as.character(선거인수)),
    투표수   = parse_number(as.character(투표수)),
    읍면동_norm = str_replace(읍면동, "제(\\d)", "\\1")  # 제N동 → N동
  )

# ── 3. 수동 매핑 4개 ────────────────────────────────────────────
manual <- tribble(
  ~읍면동,   ~시군구,
  "마전동",  "거제시",
  "벌용동",  "사천시",
  "수주면",  "영월군",
  "청북면",  "평택시"
)

# ── 4. 시군구 매핑 (2-pass join + 선거구명 disambiguation) ──────
norm_emd <- function(x) str_replace(x, "제(\\d)", "\\1")

join_pass <- function(df, key_col) {
  df |>
    left_join(
      code_tbl |> rename(emd_key = 읍면동명칭),
      by = c("시도" = "시도명칭", !!key_col := "emd_key"),
      relationship = "many-to-many"
    )
}

# Pass 1: 원본 읍면동명칭으로 join
p1 <- join_pass(df_emd, "읍면동")
matched1   <- p1 |> filter(!is.na(시군구명칭))
unmatched1 <- p1 |> filter(is.na(시군구명칭)) |> select(-시군구명칭)

# Pass 2: 정규화 이름으로 join
p2 <- join_pass(unmatched1, "읍면동_norm")

df_joined <- bind_rows(matched1, p2)

# 중복 해소: (시도, 선거구, 읍면동) 당 여러 시군구 후보 → 선거구명으로 필터
선거구_norm_fn <- function(x) str_remove(str_remove_all(x, "\\s"), "[갑을병정무]$")

df_result <- df_joined |>
  mutate(
    선거구_norm  = 선거구_norm_fn(선거구),
    시군구_norm  = str_remove_all(시군구명칭, "\\s")
  ) |>
  group_by(시도, 선거구, 읍면동) |>
  filter(
    n() == 1 |
    str_detect(선거구_norm, 시군구_norm) |
    str_detect(시군구_norm, 선거구_norm)
  ) |>
  slice(1) |>
  ungroup()

# 수동 매핑 적용
df_result <- df_result |>
  left_join(manual, by = "읍면동") |>
  mutate(시군구 = coalesce(시군구명칭, 시군구)) |>
  select(시도, 시군구, 선거구, 읍면동, 선거인수, 투표수)

# ── 5. 검증 ────────────────────────────────────────────────────
cat("총 읍면동 행 수:", nrow(df_result), "\n")
cat("시군구 NA:", sum(is.na(df_result$시군구)), "\n")

df_sgg <- df_result |>
  group_by(시도, 시군구) |>
  summarise(선거인수 = sum(선거인수), 투표수 = sum(투표수), .groups = "drop")

cat("총 시군구 수:", nrow(df_sgg), "\n")

# ── 6. 저장 ────────────────────────────────────────────────────
write_xlsx(list(읍면동별 = df_result, 시군구집계 = df_sgg), PATH_OUT)
cat("저장 완료:", PATH_OUT, "\n")
