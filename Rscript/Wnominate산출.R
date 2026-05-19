#################### Roll call vote -> DW-nominate score 산출 
rm(list=ls())

getwd()

library(httr)
library(rvest)
library(xml2)
library(stringr)
library(lubridate)
library(jsonlite)
library(readxl)
library(readr)
library(pscl)
library(tidyverse)
library(wnominate)
library(ggmap)
library(maps)
library(showtext)
library(writexl)
library(dplyr)

.libPaths()
setwd("/Users/ihuila/Research/MASTER_thesis/Data interim/국회_본회의표결") 

roll_raw <- readRDS("/Users/ihuila/Research/MASTER_thesis/Data raw/국회_본회의표결/rollcall_최종.rds")
poli_raw20 <- read_xlsx("/Users/ihuila/Research/MASTER_thesis/Data raw/국회_본회의표결/20대 국회의원.xlsx") %>% mutate(AGE = 20L)
poli_raw21 <- read_xlsx("/Users/ihuila/Research/MASTER_thesis/Data raw/국회_본회의표결/21대 국회의원.xlsx") %>% mutate(AGE = 21L)
poli_raw22 <- read_xlsx("/Users/ihuila/Research/MASTER_thesis/Data raw/국회_본회의표결/22대 국회의원.xlsx") %>% mutate(AGE = 22L)

poli_raw <- bind_rows(poli_raw20, poli_raw21, poli_raw22)

poli_totalraw <- readRDS("/Users/ihuila/Research/MASTER_thesis/Data raw/국회_본회의표결/국회의원 정보 통합.rds") # 국회의원 코드 이용하려고 

# 컬럼명 확인
cat("=== poli_raw 컬럼명 ===\n");   print(names(poli_raw))
cat("=== poli_totalraw 컬럼명 ===\n"); print(names(poli_totalraw))
#################### STEP 0: poli_raw 클리닝 ######################
# 국회의원 코드 붙이기 
# poli_totalraw에서 의원코드 룩업 (이름 + 대수 + 정당 포함 → 동명이인 대비)
code_lookup <- poli_totalraw %>%
  select(NAAS_CD, NAAS_NM, PLPT_NM, GTELT_ERACO, ELECD_NM) %>%
  distinct(NAAS_CD, .keep_all = TRUE) %>%
  mutate(
    ages_list  = str_split(GTELT_ERACO, ",\\s*"),
    party_list = str_split(PLPT_NM, "/")
  ) %>%
  mutate(rows = map2(ages_list, party_list, function(a, p) {
    n <- min(length(a), length(p))
    tibble(age_str = a[seq_len(n)], 정당_lookup = str_trim(p[seq_len(n)]))
  })) %>%
  select(NAAS_CD, NAAS_NM, ELECD_NM, rows) %>%
  unnest(rows) %>%
  mutate(AGE = as.integer(str_extract(age_str, "\\d+"))) %>%
  filter(AGE %in% c(20, 21, 22)) %>%
  select(NAAS_CD, NAAS_NM, AGE, ELECD_NM, 정당_lookup) %>%
  distinct(NAAS_CD, AGE, .keep_all = TRUE)

# 동명이인 4건 — code_lookup vs poli_raw 지역 형식 비교
dup_names <- c("김성태", "최경환", "김병욱", "이수진")

cat("=== code_lookup (ELECD_NM) ===\n")
code_lookup %>%
  filter(NAAS_NM %in% dup_names) %>%
  select(NAAS_CD, NAAS_NM, AGE, ELECD_NM, 정당_lookup) %>%
  arrange(NAAS_NM, AGE) %>%
  print()

cat("=== poli_raw (지역) ===\n")
poli_raw %>%
  filter(의원명 %in% dup_names) %>%
  select(의원명, AGE, 지역, 정당) %>%
  arrange(의원명, AGE) %>%
  print(n=70)


# 동명이인 제외한 1:1 룩업으로 m:1 조인
dup_names <- code_lookup %>% count(NAAS_NM, AGE) %>% filter(n > 1) %>% select(NAAS_NM, AGE)

code_lookup_unique <- code_lookup %>%
  anti_join(dup_names, by = c("NAAS_NM", "AGE"))

code_lookup_dup <- code_lookup %>%
  semi_join(dup_names, by = c("NAAS_NM", "AGE"))

# 이전 조인 잔여 컬럼 제거 (재실행 안전하게)
poli_raw <- poli_raw %>%
  select(-any_of(c("NAAS_CD", "NAAS_CD.x", "NAAS_CD.y")))

# 1단계: m:1 조인 (동명이인 제외) — NAAS_CD만 붙임
poli_raw <- poli_raw %>%
  left_join(code_lookup_unique %>% select(NAAS_CD, NAAS_NM, AGE),
            by = c("의원명" = "NAAS_NM", "AGE"))

# 미매칭 확인
cat(sprintf("코드 미매칭: %d명\n", sum(is.na(poli_raw$NAAS_CD))))
poli_raw %>% filter(is.na(NAAS_CD)) %>% distinct(의원명, AGE, 지역, 정당) %>% print(n = Inf)

# 2단계: 동명이인 처리 — 지역 ↔ ELECD_NM 포함 여부로 매칭, NAAS_CD만 붙임
dup_matched <- poli_raw %>%
  filter(is.na(NAAS_CD)) %>%
  select(-NAAS_CD) %>%
  left_join(code_lookup_dup %>% select(NAAS_CD, NAAS_NM, AGE, ELECD_NM),
            by = c("의원명" = "NAAS_NM", "AGE"),
            relationship = "many-to-many") %>%
  filter(str_detect(ELECD_NM, fixed(지역))) %>%
  select(-ELECD_NM)

# 1단계 매칭 결과에 병합
poli_raw <- poli_raw %>%
  filter(!is.na(NAAS_CD)) %>%
  bind_rows(dup_matched)

# 최종 확인
cat(sprintf("\n최종 미매칭: %d명\n", sum(is.na(poli_raw$NAAS_CD))))
cat(sprintf("총 행수: %d\n", nrow(poli_raw)))

# 정당명 분포 확인
cat("\n=== 대수별 정당 분포 (poli_raw) ===\n")
poli_raw %>%
  count(AGE, 정당) %>%
  arrange(AGE, desc(n)) %>%
  as.data.frame() %>%
  print()

##########################  roll_raw + poli_raw 머지 & 정당명 비교 ######################
roll_poli_merged <- roll_raw %>%
  left_join(
    poli_raw %>% select(NAAS_CD, AGE, 정당_poli = 정당, 지역, 성별, 당선횟수, 당선방법, 소속위원회),
    by = c("MONA_CD" = "NAAS_CD", "AGE")
  )

# roll_raw POLY_NM vs poli_raw 정당 불일치 확인
cat("=== POLY_NM(roll_raw) vs 정당(poli_raw) 불일치 ===\n")
roll_poli_merged %>%
  filter(!is.na(정당_poli), POLY_NM != 정당_poli) %>% distinct(MONA_CD, AGE, POLY_NM, 정당_poli) %>%
 arrange(AGE, 정당_poli)

# 정당명 클리닝: poli_raw의 정당(선거 당시)을 우선, 없으면 roll_raw POLY_NM 사용
roll_poli_merged <- roll_poli_merged %>%
  mutate(POLY_NM_CLEAN = coalesce(정당_poli, POLY_NM))

cat("\n=== 정당명 보정 현황 ===\n")
cat(sprintf("POLY_NM_CLEAN이 정당_poli로 교체된 건수: %d행 (의원-법안 단위)\n",
            sum(!is.na(roll_poli_merged$정당_poli) & roll_poli_merged$POLY_NM != roll_poli_merged$POLY_NM_CLEAN)))
cat(sprintf("poli_raw 미매칭(POLY_NM 그대로 유지): %d행\n",
            sum(is.na(roll_poli_merged$정당_poli))))

# 보정 후 잔존 정당명 목록 확인
cat("\n=== POLY_NM_CLEAN 정당 목록 ===\n")
roll_poli_merged %>%
  count(POLY_NM_CLEAN, sort = TRUE) 

# 정당분류 변수 2개 추가
# Ver1) 거대양당(위성정당포함) / 무소속 / 군소정당 그대로
roll_poli_merged <- roll_poli_merged %>%
  mutate(
    PARTY_MAJOR = case_when(
      # 국민의힘 계열 (위성정당 포함)
      POLY_NM_CLEAN %in% c("국민의힘", "미래통합당", "미래한국당", "새누리당", "자유한국당", "시대전환") ~ "국민의힘",

      # 더불어민주당 계열 (위성정당 포함)
      POLY_NM_CLEAN %in% c("더불어민주당", "열린민주당", "더불어시민당") ~ "더불어민주당",

      # 무소속
      POLY_NM_CLEAN == "무소속" ~ "무소속",

      # 나머지는 당명 그대로 (제3지대 군소정당)
      TRUE ~ POLY_NM_CLEAN
    )
  )

roll_poli_merged %>%  count(PARTY_MAJOR, sort = TRUE) 

roll_poli_merged <- roll_poli_merged %>%
  mutate(
    PARTY_EN = case_when(
      # 거대양당 계열
      POLY_NM_CLEAN %in% c("더불어민주당", "열린민주당", "더불어시민당")
      ~ "Democratic Party of Korea (DPK)",
      POLY_NM_CLEAN %in% c("국민의힘", "미래통합당", "미래한국당",
                     "새누리당", "자유한국당", "시대전환") ~ "People Power Party (PPP)",

      # 군소정당
      POLY_NM_CLEAN == "국민의당"    ~ "The People's Party",
      POLY_NM_CLEAN == "개혁신당"    ~ "Reform Party",
      POLY_NM_CLEAN == "기본소득당"  ~ "Basic Income Party",
      POLY_NM_CLEAN == "민생당"      ~ "Minsaeng Party",
      POLY_NM_CLEAN == "민주평화당"  ~ "Party for Democracy and Peace (PDP)",
      POLY_NM_CLEAN == "민중당"      ~ "The Minjung Party",
      POLY_NM_CLEAN == "바른미래당"  ~ "Bareunmirae Party",
      POLY_NM_CLEAN == "사회민주당"  ~ "Social Democratic Party (SDP)",
      POLY_NM_CLEAN == "새로운미래"  ~ "New Future Party",
      POLY_NM_CLEAN == "우리공화당"  ~ "Our Republican Party",
      POLY_NM_CLEAN == "자유통일당"  ~ "Liberty Unification Party",
      POLY_NM_CLEAN == "정의당"      ~ "Justice Party",
      POLY_NM_CLEAN == "조국혁신당"  ~ "Rebuilding Korea Party",
      POLY_NM_CLEAN == "진보당"      ~ "Progressive Party",
      POLY_NM_CLEAN == "친박신당"    ~ "Pro-Park New Party",

      # 무소속
      POLY_NM_CLEAN == "무소속"      ~ "Independent",

      # 나머지
      TRUE ~ POLY_NM_CLEAN
    )
  )


# Ver2) 이념 분류
roll_poli_merged <- roll_poli_merged %>%
  mutate(
    PARTY_IDEOLOGY = case_when(
      # Conservative
      POLY_NM_CLEAN %in% c("국민의힘", "미래통합당", "미래한국당",
                           "새누리당", "자유한국당", "시대전환", "개혁신당", "우리공화당", "자유통일당", "우리공화당", "친박신당", "바른미래당") ~ "Conservative",

      # Liberal
      POLY_NM_CLEAN %in% c("더불어민주당", "열린민주당", "더불어시민당","기본소득당", "민주평화당", "민중당", "사회민주당", "정의당", "진보당", "조국혁신당" ) ~ "Liberal",

      # 무소속
      POLY_NM_CLEAN == "무소속" ~ "Independent",

      # 기타
      TRUE ~ "Minor Party"
    )
  )


# Ver3) Figure용 그룹핑 변수 (거대양당 / 보수군소 / 진보군소 / 무소속)
roll_poli_merged <- roll_poli_merged %>%
  mutate(
    PARTY_GROUP = case_when(
      PARTY_MAJOR == "더불어민주당"            ~ "Democratic Party of Korea (Progressive major party)",
      PARTY_MAJOR == "국민의힘"                ~ "People Power Party (Conservative major party)",
      POLY_NM_CLEAN %in% c("개혁신당", "우리공화당", "자유통일당", "우리공화당", "친박신당", "바른미래당", "국민의당")         ~ "Conservative minor parties",
      POLY_NM_CLEAN %in% c("기본소득당", "민주평화당", "민중당", "사회민주당", "정의당", "진보당", "조국혁신당", "새로운미래", "민생당")             ~ "Progressive minor parties",
      POLY_NM_CLEAN == "무소속"                  ~ "Independent"
    )
  )

roll_poli_merged %>% count(POLY_NM_CLEAN, sort = TRUE)
roll_poli_merged %>% count(PARTY_MAJOR, sort = TRUE)
roll_poli_merged %>% count(PARTY_EN, sort = TRUE)
roll_poli_merged %>% count(PARTY_GROUP, sort = TRUE)
roll_poli_merged %>% count(PARTY_IDEOLOGY, sort = TRUE)

roll_poli_merged %>%
  distinct(POLY_NM_CLEAN, PARTY_MAJOR, PARTY_EN, PARTY_GROUP, PARTY_IDEOLOGY) %>%
  arrange(PARTY_GROUP, POLY_NM_CLEAN)
# ── 매핑 검증: POLY_NM_CLEAN × 생성변수 크로스탭 ──────────────────────
mapping_check <- roll_poli_merged %>%
  distinct(POLY_NM_CLEAN, PARTY_MAJOR, PARTY_IDEOLOGY, PARTY_EN) %>%
  arrange(PARTY_IDEOLOGY, POLY_NM_CLEAN)

cat("=== 정당 매핑 검증 (POLY_NM_CLEAN → 생성변수) ===\n")
print(mapping_check)

# NA 확인: 매핑 누락 정당 있으면 여기서 잡힘
cat("\n=== PARTY_EN 미매핑 정당 ===\n")
mapping_check %>% filter(is.na(PARTY_EN)) %>% print()

cat("\n=== PARTY_IDEOLOGY 분포 ===\n")
roll_poli_merged %>%
  count(PARTY_IDEOLOGY, sort = TRUE)

# 단축키 cmd+shift+c
saveRDS(roll_poli_merged, "본회의표결_국회의원통합_분석용최종.rds")

#################### Step 1: 데이터 탐색 ######################
# 각 대수별 의안 개수 
roll_poli_merged %>%
  group_by(AGE) %>%
  summarise(
    의안수 = n_distinct(BILL_ID),
    .groups = "drop"
  )
# 20대 3435, 21대 3228, 22대 1342 -> 총 8005개 

# 각 대수별 의원 수
roll_poli_merged %>%
  group_by(AGE) %>%
  summarise(
    의원수 = n_distinct(MONA_CD),
    .groups = "drop"
  )
# 20대: 320명, 21대:322명, 22대: 305명 
#################### Step 2: 쟁점법안 선정 (소수측 2.5% 미만 제거, 즉 찬성률 2.5%~97

# 남은 의안: 702개 (36.4%)
# 20대: 254개 
# 21대 308개 
# 22대: 140개 

#################### Step 3: Rollcall 객체 생성 (필터링 없이) ######################
# 투표 재코딩, 기권은 -> NA 처리
roll_recoded <- roll_poli_merged %>%
  mutate(vote = case_when(
    RESULT_VOTE_MOD == "찬성" ~ 1,
    RESULT_VOTE_MOD == "반대" ~ 0,
    RESULT_VOTE_MOD == "기권" ~ NA_real_,
    RESULT_VOTE_MOD == "불참" ~ NA_real_
  ))

library(pscl)

rc_list <- list()

for (age in c(20, 21, 22)) {
  
  # Wide-form 변환
  roll_wide <- roll_recoded %>%
    filter(AGE == age) %>%
    select(MONA_CD, BILL_ID, vote) %>%
    pivot_wider(
      names_from = BILL_ID,
      values_from = vote,
      values_fill = NA
    ) %>%
    column_to_rownames("MONA_CD")
  
  # 의원 정보
  legis_data <- roll_recoded %>%
    filter(AGE == age) %>%
    distinct(MONA_CD, HG_NM, PARTY_MAJOR, PARTY_IDEOLOGY, PARTY_EN, PARTY_GROUP) %>%
    arrange(MONA_CD) %>%
    filter(MONA_CD %in% rownames(roll_wide)) %>%
    mutate(
      party = case_when(
        PARTY_GROUP == "People Power Party (Conservative major party)" ~ 100,
        PARTY_GROUP == "Conservative minor parties"                    ~ 150,
        PARTY_GROUP == "Democratic Party of Korea (Progressive major party)" ~ 200,
        PARTY_GROUP == "Progressive minor parties"                     ~ 250,
        PARTY_GROUP == "Independent"                                   ~ 900,
        TRUE                                                           ~ 999
      ))
  
  # Rollcall 객체
  rc_list[[as.character(age)]] <- rollcall(
    data        = as.matrix(roll_wide),
    yea = 1, nay = 0, missing = NA,
    legis.names = rownames(roll_wide),
    vote.names  = colnames(roll_wide),
    legis.data  = legis_data
  )
  
  cat(sprintf("제%d대: 의원 %d명, 의안 %d개\n", 
              age, nrow(roll_wide), ncol(roll_wide)))
}
  

# # 기권률 높은 의원 확인 
# roll_recoded %>%
#   group_by(MONA_CD, HG_NM, PARTY_MAJOR) %>%
#    summarise(
#        총투표 = n(),
#        찬성 = sum(RESULT_VOTE_MOD == "찬성", na.rm = TRUE),
#        반대 = sum(RESULT_VOTE_MOD == "반대", na.rm = TRUE),
#        기권 = sum(RESULT_VOTE_MOD == "기권", na.rm = TRUE),
#         찬성률 = 찬성 / (찬성 + 반대),  # 기권 제외
#         기권률 = 기권 / 총투표,
#        .groups = "drop"
#     ) %>%
# arrange(desc(기권률))


###############################################################################
# ── 0. 사전 설정: 폰트 · Polarity ────────────────────────────────────────────
###############################################################################
library(showtext)
font_add("AppleGothic",
         regular = "/System/Library/Fonts/Supplemental/AppleGothic.ttf")

ages    <- c("20", "21", "22")   # 공통 대수 벡터 (이하 전체에서 재사용)
fig_dir <- "/Users/ihuila/Research/MASTER_thesis/Output/figure"
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

# 1D polarity: 각 대수별 기준 의원 (보수 방향 양수 고정)
# 20대: 나경원 / 21대: 주호영 / 22대: 권성동
polarity_1d <- list(
  "20" = "SLW27496",   # 나경원
  "21" = "8SV6917G",   # 주호영
  "22" = "GDG1847Z"    # 권성동
)

# 2D polarity: dim1은 1D와 동일한 의원으로 방향 고정, dim2는 같은 의원 반복
# → dim2 방향은 사실상 자유 (최소 제약으로 탐색)
polarity_2d <- list(
  "20" = c("SLW27496", "SNJ6318D"), #20대: 나경원, 김무성 
  "21" = c("8SV6917G", "NAL4555X"), #21대: 주호영, 홍준표 
  "22" = c("GDG1847Z", "CNW5754J") #22대: 권성동, 송석준 
)

###############################################################################
# ── 1. W-NOMINATE 추정 (1D · 2D 통합 루프) ────────────────────────────────────
###############################################################################
result_list    <- list()
result_list_2d <- list()

for (age in ages) {
  cat(sprintf("\n▶ 제%s대 W-NOMINATE 추정 중...\n", age))

  # 1D: 지정 의원으로 좌우 방향 고정
  result_list[[age]] <- wnominate(
    rc_list[[age]], dims = 1, polarity = polarity_1d[[age]],
    minvotes = 25, lop = 0.05, trials = 20, verbose = FALSE
  )
  print(summary(result_list[[age]]))
  png(file.path(fig_dir, sprintf("%s대국회_wnominate_1d.png", age)), width = 900, height = 700)
  plot(result_list[[age]], main.title = sprintf("제%s대 국회 W-NOMINATE (1차원)", age))
  dev.off()
  saveRDS(result_list[[age]], sprintf("%s대국회_wnominate_1d_원자료", age))

  # 2D: dim1 방향만 고정, dim2는 자유 탐색
  result_list_2d[[age]] <- wnominate(
    rc_list[[age]], dims = 2, polarity = polarity_2d[[age]],
    minvotes = 25, lop = 0.05, trials = 20, verbose = FALSE
  )
  print(summary(result_list_2d[[age]]))
  png(file.path(fig_dir, sprintf("%s대국회_wnominate_2d.png", age)), width = 900, height = 700)
  plot(result_list_2d[[age]], main.title = sprintf("제%s대 국회 W-NOMINATE (2차원)", age))
  dev.off()
  saveRDS(result_list_2d[[age]], sprintf("%s대국회_wnominate_2d_원자료", age))
}

# ###############################################################################
# # ── 2. 결과 처리 함수 정의 ────────────────────────────────────────────────────
# ###############################################################################

# (2-1) 선거구 변수 파생
add_district_vars <- function(df) {
  df %>%
    mutate(
      SIDO_NM    = if_else(str_detect(ORIG_NM, "\\s"),
                           str_extract(ORIG_NM, "^[^\\s]+"), ORIG_NM),
      SIGUNGU_NM = if_else(str_detect(ORIG_NM, "\\s"),
                           str_extract(ORIG_NM, "(?<=\\s).+"), NA_character_)
    ) %>%
    mutate(
      DISTRICT_TYPE = str_extract(SIGUNGU_NM, "(갑|을|병|정)$"),
      IS_COMPLEX    = str_detect(SIGUNGU_NM, "(시|군|구).+(시|군|구)") &
                      !str_detect(SIGUNGU_NM, "시.+구(갑|을|병|정)?$"),
      SIGUNGU_NM2   = case_when(
        IS_COMPLEX            ~ SIGUNGU_NM,
        !is.na(DISTRICT_TYPE) ~ str_remove(SIGUNGU_NM, "(갑|을|병|정)$"),
        TRUE                  ~ SIGUNGU_NM
      ),
      DUM_COMPLEX  = if_else(IS_COMPLEX,            1L, 0L, missing = 0L),
      DUM_GAP      = if_else(DISTRICT_TYPE == "갑", 1L, 0L, missing = 0L),
      DUM_EUL      = if_else(DISTRICT_TYPE == "을", 1L, 0L, missing = 0L),
      DUM_BYEONG   = if_else(DISTRICT_TYPE == "병", 1L, 0L, missing = 0L),
      DUM_JEONG    = if_else(DISTRICT_TYPE == "정", 1L, 0L, missing = 0L),
      DUM_DISTRICT = if_else(!is.na(DISTRICT_TYPE), 1L, 0L, missing = 0L)
    )
}

# (2-2) legislators → 선거구 메타 조인 (dplyr/haven 충돌 회피: 100% base R)
process_coords <- function(result_obj, age_num) {
  leg <- as.data.frame(result_obj$legislators, stringsAsFactors = FALSE)
  if (!"MONA_CD" %in% names(leg)) leg$MONA_CD <- rownames(leg)
  for (col in names(leg))
    if (inherits(leg[[col]], "haven_labelled")) leg[[col]] <- as.character(leg[[col]])

  sub  <- roll_raw[roll_raw$AGE == age_num, c("MONA_CD","ORIG_NM","ORIG_CD","POLY_CD")]
  meta <- data.frame(
    MONA_CD = as.character(sub$MONA_CD), ORIG_NM = as.character(sub$ORIG_NM),
    ORIG_CD = as.character(sub$ORIG_CD), POLY_CD = as.character(sub$POLY_CD),
    stringsAsFactors = FALSE
  )
  meta <- meta[!duplicated(meta$MONA_CD), ]

  idx         <- match(leg$MONA_CD, meta$MONA_CD)
  leg$ORIG_NM <- meta$ORIG_NM[idx]
  leg$ORIG_CD <- meta$ORIG_CD[idx]
  leg$POLY_CD <- meta$POLY_CD[idx]

  as_tibble(leg) %>% add_district_vars()
}

###############################################################################
# ── 3. 좌표 추출 및 저장 ──────────────────────────────────────────────────────
###############################################################################

# 1D
coords_list <- setNames(
  lapply(ages, function(age)
    process_coords(result_list[[age]], as.integer(age)) %>%
      rename_with(~ gsub("\\.", "_", .x))),
  ages
)
coords_all <- bind_rows(coords_list, .id = "AGE_chr") %>%
  mutate(AGE = as.integer(AGE_chr))

# 2D
coords_2d_list <- setNames(
  lapply(ages, function(age)
    process_coords(result_list_2d[[age]], as.integer(age)) %>%
      rename_with(~ gsub("\\.", "_", .x))),
  ages
)
coords_all_2d <- bind_rows(coords_2d_list, .id = "AGE_chr") %>%
  mutate(AGE = as.integer(AGE_chr))

# 정당 변수 직접 join (wnominate가 character 컬럼 보존을 보장하지 않으므로)
party_vars <- roll_poli_merged %>%
  distinct(MONA_CD, AGE, PARTY_GROUP, PARTY_MAJOR, PARTY_EN)

coords_all    <- coords_all    %>% select(-any_of(c("PARTY_GROUP","PARTY_MAJOR","PARTY_EN"))) %>%
  left_join(party_vars, by = c("MONA_CD", "AGE"))
coords_all_2d <- coords_all_2d %>% select(-any_of(c("PARTY_GROUP","PARTY_MAJOR","PARTY_EN"))) %>%
  left_join(party_vars, by = c("MONA_CD", "AGE"))

cat(sprintf("coords_all PARTY_GROUP NA: %d / %d\n",
            sum(is.na(coords_all$PARTY_GROUP)), nrow(coords_all)))

# 저장 (1D · 2D 동일 구조)
library(haven)
for (age in ages) {
  saveRDS(coords_list[[age]],    sprintf("%s대국회_wnominate_1차원",     age))
  write_dta(coords_list[[age]],  sprintf("%s대국회_wnominate_1차원.dta", age))
  saveRDS(coords_2d_list[[age]], sprintf("%s대국회_wnominate_2차원",     age))
  write_dta(coords_2d_list[[age]], sprintf("%s대국회_wnominate_2차원.dta", age))
}
saveRDS(coords_all,    "20-22대국회_wnominate_1차원")
write_dta(coords_all,  "20-22대국회_wnominate_1차원.dta")
saveRDS(coords_all_2d,   "20-22대국회_wnominate_2차원")
write_dta(coords_all_2d, "20-22대국회_wnominate_2차원.dta")

##############################Figure 그리기 ###############################여기부터 수정 
library(ggplot2)
library(ggrepel)
library(RColorBrewer)
library(ggforce)

fig_dir <- "/Users/ihuila/Research/MASTER_thesis/Output/figure"
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

# ── 색상 설정 (PARTY_GROUP 기준) ─────────────────────────────────
group_colors <- c(
  "Democratic Party of Korea (Progressive major party)" = "#1A6FC4",
  "People Power Party (Conservative major party)"       = "#D42828",
  "Conservative minor parties"                          = "#7D3C98",
  "Progressive minor parties"                           = "#D4AC0D",
  "Independent"                                         = "#7F8C8D"
)

# 한국어 레이블 (lang=="kr"일 때 사용; lang=="en"은 PARTY_GROUP명 그대로 — waiver())
lbl_kr <- c(
  "Democratic Party of Korea (Progressive major party)" = "더불어민주당",
  "People Power Party (Conservative major party)"       = "국민의힘",
  "Conservative minor parties"                          = "보수 군소정당",
  "Progressive minor parties"                           = "진보 군소정당",
  "Independent"                                         = "무소속"
)

age_labels <- c("20" = "20th Assembly", "21" = "21st Assembly", "22" = "22nd Assembly")

# ══════════════════════════════════════════════════════════════════
# Figure 저장 루프: scope × lang (inline)
# ══════════════════════════════════════════════════════════════════

for (scope in c("major", "all")) {

  major_groups <- c("Democratic Party of Korea (Progressive major party)",
                    "People Power Party (Conservative major party)")

  if (scope == "major") {
    d1 <- coords_all    %>% filter(PARTY_GROUP %in% major_groups)
    d2 <- coords_all_2d %>% filter(PARTY_GROUP %in% major_groups)
  } else {
    d1 <- coords_all    %>% filter(!is.na(PARTY_GROUP))
    d2 <- coords_all_2d %>% filter(!is.na(PARTY_GROUP))
  }

  for (lang in c("kr", "en")) {
    lbl <- if (lang == "kr") lbl_kr else waiver()
    sfx <- sprintf("%s_%s", scope, lang)

    # ── 1D strip ──────────────────────────────────────────────────
    set.seed(42)
    p <- ggplot(d1, aes(x = coord1D, y = 0, color = PARTY_GROUP)) +
      geom_jitter(height = 0.4, size = 1.5, alpha = 0.7, width = 0) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "gray40", linewidth = 0.4) +
      facet_wrap(~AGE_chr, ncol = 1, labeller = labeller(AGE_chr = age_labels)) +
      scale_color_manual(values = group_colors, labels = lbl) +
      scale_x_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
      labs(x = "W-NOMINATE Score  ← Liberal · Conservative →", y = NULL, color = "Party",
           title = "W-NOMINATE Ideal Point Distribution (1st Dimension)") +
      theme_bw(base_size = 12) +
      theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(),
            panel.grid.major.y = element_blank(),
            strip.background = element_rect(fill = "gray95"), legend.position = "bottom") +
      guides(color = guide_legend(nrow = 2, override.aes = list(size = 3)))
    ggsave(file.path(fig_dir, sprintf("1d_strip_%s.pdf", sfx)), p, width = 8, height = 6)

    # ── 1D density ────────────────────────────────────────────────
    d1_nd <- d1 %>%
      filter(PARTY_GROUP != "Independent") %>%
      mutate(AGE_chr = factor(AGE_chr, labels = age_labels))
    p <- ggplot(d1_nd, aes(x = coord1D, fill = PARTY_GROUP, color = PARTY_GROUP)) +
      geom_density(alpha = 0.35, linewidth = 0.7) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "gray40", linewidth = 0.4) +
      facet_wrap(~AGE_chr, ncol = 1) +
      scale_fill_manual(values = group_colors, labels = lbl) +
      scale_color_manual(values = group_colors, labels = lbl) +
      scale_x_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
      labs(x = "W-NOMINATE Score  ← Liberal · Conservative →",
           y = "Density", fill = "Party", color = "Party",
           title = "Density Distribution of Ideal Points (1st Dimension)") +
      theme_bw(base_size = 12) +
      theme(strip.background = element_rect(fill = "gray95"), legend.position = "bottom")
    ggsave(file.path(fig_dir, sprintf("1d_density_%s.pdf", sfx)), p, width = 7, height = 7)

    # ── 1D extremes ───────────────────────────────────────────────
    ext1 <- d1 %>%
      group_by(AGE_chr) %>%
      mutate(pct = percent_rank(coord1D)) %>%
      filter(pct <= 0.05 | pct >= 0.95) %>%
      ungroup() %>%
      mutate(AGE_chr = factor(AGE_chr, labels = age_labels))
    d1_f <- d1 %>% mutate(AGE_chr = factor(AGE_chr, labels = age_labels))
    p <- ggplot(d1_f, aes(x = coord1D, fill = PARTY_GROUP)) +
      geom_histogram(bins = 40, alpha = 0.5, position = "identity") +
      geom_label_repel(data = ext1, aes(x = coord1D, y = 8, label = HG_NM, color = PARTY_GROUP),
                       size = 2.5, max.overlaps = 15, fill = "white") +
      facet_wrap(~AGE_chr, ncol = 1) +
      scale_fill_manual(values = group_colors, labels = lbl) +
      scale_color_manual(values = group_colors, labels = lbl) +
      labs(x = "W-NOMINATE Score", y = "Number of Legislators", fill = "Party", color = "Party",
           title = "Extreme Legislators (Top/Bottom 5%)") +
      theme_bw(base_size = 12) +
      theme(strip.background = element_rect(fill = "gray95"), legend.position = "bottom")
    ggsave(file.path(fig_dir, sprintf("1d_extremes_%s.pdf", sfx)), p, width = 8, height = 8)

    # ── 2D facet ──────────────────────────────────────────────────
    d2_f <- d2 %>% mutate(AGE_chr = factor(AGE_chr, labels = age_labels))
    p <- ggplot(d2_f, aes(x = coord1D, y = coord2D, color = PARTY_GROUP)) +
      geom_point(size = 1.8, alpha = 0.75) +
      geom_hline(yintercept = 0, color = "gray70", linewidth = 0.3) +
      geom_vline(xintercept = 0, color = "gray70", linewidth = 0.3) +
      facet_wrap(~AGE_chr, ncol = 3) +
      scale_color_manual(values = group_colors, labels = lbl) +
      scale_x_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
      scale_y_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
      labs(x = "1st Dimension", y = "2nd Dimension", color = "Party",
           title = "W-NOMINATE Ideal Points (2nd Dimension)") +
      theme_bw(base_size = 12) +
      theme(strip.background = element_rect(fill = "gray95"), legend.position = "bottom", aspect.ratio = 1)
    ggsave(file.path(fig_dir, sprintf("2d_facet_%s.pdf", sfx)), p, width = 15, height = 8)

    # ── 2D convex hull ────────────────────────────────────────────
    p <- ggplot(d2_f, aes(x = coord1D, y = coord2D, color = PARTY_GROUP, fill = PARTY_GROUP)) +
      geom_mark_hull(aes(group = PARTY_GROUP), alpha = 0.08, expand = unit(3, "mm"), radius = unit(3, "mm")) +
      geom_point(size = 1.5, alpha = 0.6) +
      facet_wrap(~AGE_chr, ncol = 3) +
      scale_color_manual(values = group_colors, labels = lbl) +
      scale_fill_manual(values  = group_colors, labels = lbl) +
      scale_x_continuous(limits = c(-1.1, 1.1), breaks = seq(-1, 1, 0.5)) +
      scale_y_continuous(limits = c(-1.1, 1.1), breaks = seq(-1, 1, 0.5)) +
      labs(x = "1st Dimension", y = "2nd Dimension", color = "Party", fill = "Party",
           title = "Party Ideology Space — Convex Hull (2D W-NOMINATE)") +
      theme_bw(base_size = 12) +
      theme(strip.background = element_rect(fill = "gray95"), legend.position = "bottom", aspect.ratio = 1)
    ggsave(file.path(fig_dir, sprintf("2d_hull_%s.pdf", sfx)), p, width = 12, height = 5)

    # ── 2D per-assembly ───────────────────────────────────────────
    for (age in ages) {
      d2_a <- d2 %>% filter(AGE_chr == age)
      ext2  <- d2_a %>% mutate(dist = sqrt(coord1D^2 + coord2D^2)) %>% slice_max(dist, n = 15)
      p <- ggplot(d2_a, aes(x = coord1D, y = coord2D, color = PARTY_GROUP)) +
        geom_point(size = 2, alpha = 0.7) +
        geom_label_repel(data = ext2, aes(label = HG_NM),
                         size = 2.5, max.overlaps = 20, fill = "white", label.padding = 0.15) +
        geom_hline(yintercept = 0, color = "gray60", linewidth = 0.3, linetype = "dashed") +
        geom_vline(xintercept = 0, color = "gray60", linewidth = 0.3, linetype = "dashed") +
        scale_color_manual(values = group_colors, labels = lbl) +
        scale_x_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
        scale_y_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
        labs(x = "1st Dimension", y = "2nd Dimension", color = "Party",
             title = sprintf("%s National Assembly — W-NOMINATE (2D)", age_labels[age]),
             subtitle = "Top 15 legislators by distance from origin labeled") +
        theme_bw(base_size = 13) +
        theme(legend.position = "bottom", aspect.ratio = 1)
      ggsave(file.path(fig_dir, sprintf("2d_%s대_%s.pdf", age, sfx)), p, width = 7, height = 7)
    }
  }
}
