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
poli_raw <- readRDS("/Users/ihuila/Research/MASTER_thesis/Data raw/국회_본회의표결/국회의원 정보 통합.rds")
#################### STEP 0: roll + poli 데이터 머지, 클리닝 ######################
# poli_raw 클리닝 (대수별 분리)
poli_clean <- poli_raw %>%
  select(NAAS_CD, NAAS_NM, PLPT_NM, ELECD_NM, ELECD_DIV_NM, 
         GTELT_ERACO, RLCT_DIV_NM) %>%
  separate_rows(GTELT_ERACO, sep = ", ") %>%
  mutate(AGE = as.integer(str_extract(GTELT_ERACO, "\\d+"))) %>%
  filter(AGE %in% c(20, 21, 22)) %>%
  rename(MONA_CD = NAAS_CD)
cat(sprintf("poli_clean: %d명 (중복 포함)\n", nrow(poli_clean)))
cat(sprintf("20대: %d명\n", sum(poli_clean$AGE == 20))) #320 
cat(sprintf("21대: %d명\n", sum(poli_clean$AGE == 21))) #322
cat(sprintf("22대: %d명\n", sum(poli_clean$AGE == 22))) #306

# 국회홈페이지 기준, 20대 의원 320명 / 21대 322명 일치 
# https://www.assembly.go.kr/portal/cnts/cntsCont/dataB.do?cntsDivCd=NAAS&menuNo=601032

# 22대 국회의원은 의원직 상실 및 승계가 몇번씩 이루어져 수가 안맞음 
# 위성락 -> 손솔 
# 강유정 -> 최혁진 
# 임광현 -> 이주희 
# 인요한 -> 이소희 (26.01. 기준)
# 조국 -> 백선희 (24.12.12)
# 신영대, 이병진 의원직 상실 (26.01.) 
##########################  roll_raw 정당분류
# 정당분류 변수 
# 일단 잘못분류된 의원 있는지 확인 
# 무소속의원들 잘못분류됨 

roll_raw <- roll_raw %>%
  mutate(
    POLY_NM = case_when(
      # 곽상도
      MONA_CD == "MHK9919B" & AGE == 20 ~ "새누리당",
      MONA_CD == "MHK9919B" & AGE == 21 ~ "미래통합당",
      
      # 김경진 - 국민의당
      MONA_CD == "YVN3115U" & AGE == 20 ~ "국민의당",
      
      # 김관영 - 국민의당
      MONA_CD == "W168182V" & AGE == 20 ~ "국민의당",
      
      # 김광수 - 국민의당
      MONA_CD == "3NM5411H" & AGE == 20 ~ "국민의당",
      
      # 김병기 - 더불어민주당
      MONA_CD == "8Q88373R" & AGE %in% c(20, 21, 22) ~ "더불어민주당",
      
      # 우원식 - 더불어민주당
      MONA_CD == "XBT9550Q" & AGE %in% c(20, 21, 22) ~ "더불어민주당",
      
      # 김성식 - 국민의당
      MONA_CD == "RCF90176" & AGE == 20 ~ "국민의당",
      
      # 김종민
      MONA_CD == "M2Q9024I" & AGE == 20 ~ "더불어민주당",
      MONA_CD == "M2Q9024I" & AGE == 21 ~ "더불어민주당",
      MONA_CD == "M2Q9024I" & AGE == 22 ~ "새로운미래",
      
      # 김종회 - 국민의당
      MONA_CD == "HTK5293K" & AGE == 20 ~ "국민의당",
      
      # 김진표 - 더불어민주당
      MONA_CD == "Q9H5708M" & AGE %in% c(20, 21) ~ "더불어민주당",
      
      # 문희상 - 더불어민주당
      MONA_CD == "IYD4143Y" & AGE == 20 ~ "더불어민주당",
      
      # 민병두 - 더불어민주당
      MONA_CD == "39P2522W" & AGE == 20 ~ "더불어민주당",
      
      # 박완주 - 더불어민주당
      MONA_CD == "A3H7195R" & AGE %in% c(20, 21) ~ "더불어민주당",
      
      # 윤관석 - 더불어민주당
      MONA_CD == "JMY9959W" & AGE %in% c(20, 21) ~ "더불어민주당",
      
      # 이상헌 - 더불어민주당
      MONA_CD == "WVU2479T" & AGE == 21 ~ "더불어민주당",
      
      # 이용주 - 국민의당
      MONA_CD == "X9Y63914" & AGE == 20 ~ "국민의당",
      
      # 이은재 - 새누리당
      MONA_CD == "IQN7588X" & AGE == 20 ~ "새누리당",
      
      # 이정현 - 새누리당
      MONA_CD == "7AN97172" & AGE == 20 ~ "새누리당",
      
      # 이춘석 - 더불어민주당
      MONA_CD == "V2R7430Z" & AGE %in% c(20, 22) ~ "더불어민주당",
      
      # 이현재 - 새누리당
      MONA_CD == "MBS2896E" & AGE == 20 ~ "새누리당",
      
      # 전혜숙 - 더불어민주당
      MONA_CD == "N9X9673B" & AGE %in% c(20, 21) ~ "더불어민주당",
      
      # 정인화 - 국민의당
      MONA_CD == "DKB8522X" & AGE == 20 ~ "국민의당",
      
      # 정태옥 - 새누리당
      MONA_CD == "06571503" & AGE == 20 ~ "새누리당",
      
      # 강선우 - 더불어민주당
      MONA_CD == "MNZ4401T" & AGE %in% c(21, 22) ~ "더불어민주당",
      
      # 윤미향 - 더불어민주당 (더불어시민당은 위성정당)
      MONA_CD == "KNM3215T" & AGE == 21 ~ "더불어민주당",
      
      # 이상직 - 더불어민주당
      MONA_CD == "CFE3998F" & AGE == 21 ~ "더불어민주당",
      
      # 이성만 - 더불어민주당
      MONA_CD == "8KF7223D" & AGE == 21 ~ "더불어민주당",
      
      # 이수진 - 더불어민주당
      MONA_CD == "D4L60530" & AGE %in% c(21, 22) ~ "더불어민주당",
      
      # 장경태 - 더불어민주당
      MONA_CD == "RPN2293B" & AGE %in% c(21, 22) ~ "더불어민주당",
      
      # 하영제 - 미래통합당
      MONA_CD == "FGI27280" & AGE == 21 ~ "미래통합당",
      
      # 최혁진 - 더불어민주당 (더불어민주연합)
      MONA_CD == "CC78321E" & AGE == 22 ~ "더불어민주당",
      
      # 기본값: 원래 값 유지
      TRUE ~ POLY_NM
    )
  )

# 정당분포 확인 
roll_raw %>%
  count(POLY_NM, sort = TRUE) %>%
  print()

# roll_raw와 머지
roll_poli_merged <- roll_raw %>%
  left_join(
    poli_clean %>% select(MONA_CD, AGE, PLPT_NM, ELECD_NM, ELECD_DIV_NM, RLCT_DIV_NM),
    by = c("MONA_CD", "AGE")
  ) #2,382,958

# roll_poli_merged 정당 분류 확인 
roll_poli_merged %>% distinct(POLY_NM) # 23개의 정당 

# 정당분류 변수 2개 추가 
# Ver1) 거대양당(위성정당포함) / 무소속 / 군소정당 그대로 
roll_poli_merged <- roll_poli_merged %>%
  mutate(
    PARTY_MAJOR = case_when(
      # 국민의힘 계열
      POLY_NM %in% c("국민의힘", "미래통합당", "미래한국당", "새누리당", "자유한국당") ~ "국민의힘",
      
      # 더불어민주당 계열
      POLY_NM %in% c("더불어민주당", "열린민주당") ~ "더불어민주당",
      
      # 무소속
      POLY_NM == "무소속" ~ "무소속",
      
      # 나머지는 당명 그대로 (제3지대 군소정당)
      TRUE ~ POLY_NM
    )
  )

roll_poli_merged %>%
  count(PARTY_MAJOR, sort = TRUE) %>%
  print()

# Ver2) 거대양당(위성정당, 군소정당 이념 포함) / 무소속 / 제3지대 
roll_poli_merged <- roll_poli_merged %>%
  mutate(
    PARTY_IDEOLOGY = case_when(
      # Conservative
      POLY_NM %in% c("개혁신당", "국민의힘", "미래통합당", "미래한국당", 
                     "새누리당", "우리공화당", "자유통일당", "자유한국당", 
                     "친박신당") ~ "Conservative",
      
      # Liberal
      POLY_NM %in% c("기본소득당", "더불어민주당", "민중당", "사회민주당",
                     "열린민주당", "정의당", "조국혁신당", "진보당") ~ "Liberal",
      
      # 제3지대 (중도 또는 분류 애매한 정당)
      POLY_NM %in% c("국민의당", "민생당", "민주평화당", "바른미래당", "새로운미래") ~ "제3지대",
      
      # 무소속
      POLY_NM == "무소속" ~ "무소속",
      
      # 기타
      TRUE ~ "기타"
    )
  )

# 결과 확인
cat("=== PARTY_MAJOR 분포 ===\n")
roll_poli_merged %>%
  count(PARTY_IDEOLOGY, sort = TRUE) %>%
  print()

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

#################### Step 3: W-nominate score 
#################### Step 4: Rollcall 객체 생성 (필터링 없이) ######################
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
    distinct(MONA_CD, HG_NM, PARTY_MAJOR, PARTY_IDEOLOGY) %>%
    arrange(MONA_CD) %>%
    filter(MONA_CD %in% rownames(roll_wide)) %>%
    mutate(
      party = case_when(
        PARTY_IDEOLOGY == "Conservative" ~ 100,
        PARTY_IDEOLOGY == "Liberal" ~ 200,
        PARTY_IDEOLOGY == "제3지대" ~ 300,
        PARTY_IDEOLOGY == "무소속" ~ 900,
        TRUE ~ 999
      ),
      # 한글 라벨 추가
      party_label = PARTY_IDEOLOGY
    )
  
  # Rollcall 객체
  rc_list[[as.character(age)]] <- rollcall(
    data = as.matrix(roll_wide),
    yea = 1,
    nay = 0,
    missing = NA,
    legis.names = rownames(roll_wide),
    vote.names = colnames(roll_wide),
    legis.data = legis_data
  ) 
  cat(sprintf("제%d대: 의원 %d명, 의안 %d개\n", 
              age, nrow(roll_wide), ncol(roll_wide)))
}
  
#################### Analysis: 20대 국회 w-nominate #############
# 한글 폰트 설정
library(showtext)
font_add("AppleGothic", 
         regular = "/System/Library/Fonts/Supplemental/AppleGothic.ttf")

# 20대 국회 1차원 polarity 설정 - 나경원 
roll_recoded %>%
  filter(AGE == 20, HG_NM == "나경원") %>%
  distinct(MONA_CD) %>%
  pull(MONA_CD)

# 20대 국회 - 1차원 
cat("제20대 실행 중...\n")
result_20_1d <- wnominate(
  rc_list[["20"]],
  dims = 1,
  polarity = "SLW27496",
  minvotes = 25,
  lop = 0.025,
  trials = 3,
  verbose = FALSE
)
cat("=== 제20대 결과 ===\n")
print(summary(result_20_1d))

# 포함된 의안 254 (-3181)
# 포함된 의원 316명 (-4)
plot(result_20_1d, main.title = "제20대 국회 W-NOMINATE (1차원)")

# 1차원 결과 확인
coords_20_1d <- result_20_1d$legislators

#################### Analysis: 21대 국회 w-nominate  #########
# 21대 국회 1차원 polarity 설정 - 주호영 의원 
roll_recoded %>%
  filter(AGE == 21, HG_NM == "주호영") %>%
  distinct(MONA_CD) %>%
  pull(MONA_CD)

result_21_1d <- wnominate(
  rc_list[["21"]],
  dims = 1,
  polarity = "8SV6917G", #주호영
  minvotes = 25,
  lop = 0.025,
  trials = 3,
  verbose = FALSE
)

print(summary(result_21_1d))

plot(result_21_1d, main.title = "제21대 국회 W-NOMINATE (1차원)")

coords_21_1d <- result_21_1d$legislators

#################### Analysis: 22대 국회 w-nominate  #########
## 22대 국회 1차원 Polarity 설정 - 권성동 
roll_recoded %>%
  filter(AGE == 22, HG_NM == "권성동") %>%
  distinct(MONA_CD) %>%
  pull(MONA_CD)

# 22대 국회 - 1차원 
cat("제22대 실행 중...\n")
result_22_1d <- wnominate(
  rc_list[["22"]],
  dims = 1,
  polarity = "GDG1847Z", #권성동 의원 
  minvotes = 25,
  lop = 0.025,
  trials = 3,
  verbose = FALSE
)

print(summary(result_22_1d))

plot(result_22_1d, main.title = "제22대 국회 W-NOMINATE (1차원)")

# 1차원 결과 확인
coords_22_1d <- result_22_1d$legislators
#################### 전체 결과 저장 ######################
# saveRDS (coords_20_1d, "20대국회_wnominate_1차원")
# saveRDS (coords_21_1d, "21대국회_wnominate_1차원")
# saveRDS (coords_22_1d, "22대국회_wnominate_1차원")
############################## 결과 데이터 정리#######################################
# 선거구 머지.roll_raw 데이터에 있는 (ORIG_CD, ORIG_NM) / 정당코드 (POLY_CD) 를 각 coords_20_1d, coords_21_1d, coords_22_1d 에 있는 데이터에 붙이기 
# 20대 국회 - ORIG_NM 추가
coords_20_1d <- coords_20_1d %>%
  left_join(
    roll_raw %>%
      filter(AGE == 20) %>%
      distinct(MONA_CD, ORIG_NM, ORIG_CD, POLY_CD),
    by = "MONA_CD"
  )

# 21대 국회 - ORIG_NM 추가
coords_21_1d <- coords_21_1d %>%
  left_join(
    roll_raw %>%
      filter(AGE == 21) %>%
      distinct(MONA_CD, ORIG_NM, ORIG_CD, POLY_CD),
    by = "MONA_CD"
  )

# 22대 국회 - ORIG_NM 추가
coords_22_1d <- coords_22_1d %>%
  left_join(
    roll_raw %>%
      filter(AGE == 22) %>%
      distinct(MONA_CD, ORIG_NM, ORIG_CD, POLY_CD),
    by = "MONA_CD"
  )



#################### 공백 기준으로 시도/선거구 분리 ######################

# coords_20_1d
coords_20_1d <- coords_20_1d %>%
  mutate(
    # 공백이 있으면 분리, 없으면 전체를 SIDO_NM에
    SIDO_NM = if_else(
      str_detect(ORIG_NM, "\\s"),                    # 공백 있는지 확인
      str_extract(ORIG_NM, "^[^\\s]+"),              # 공백 앞부분
      ORIG_NM                                       # 공백 없으면 전체
    ),
    
    SIGUNGU_NM = if_else(
      str_detect(ORIG_NM, "\\s"),                    # 공백 있는지 확인
      str_extract(ORIG_NM, "(?<=\\s).+"),            # 공백 뒷부분
      NA_character_                                    # 공백 없으면 NA
    )
  )

coords_20_1d <- coords_20_1d %>%
  mutate(
    # 1. 갑/을/병/정 추출
    DISTRICT_TYPE = str_extract(SIGUNGU_NM, "(갑|을|병|정)$"),
    
    # 2. 복합도농 여부 (시/군/구가 2개 이상, 단 "~시~구" 패턴은 제외)
    IS_COMPLEX = str_detect(SIGUNGU_NM, "(시|군|구).+(시|군|구)") & 
      !str_detect(SIGUNGU_NM, "시.+구(갑|을|병|정)?$"),
    
    # 3. SIGUNGU_NM2 생성
    SIGUNGU_NM2 = case_when(
      # 복합도농이면 그대로
      IS_COMPLEX == TRUE ~ SIGUNGU_NM,
      
      # 갑/을/병/정이 있으면 제거
      # "성남시분당구갑" → "성남시분당구"
      # "해운대구갑" → "해운대구"
      !is.na(DISTRICT_TYPE) ~ str_remove(SIGUNGU_NM, "(갑|을|병|정)$"),
      
      # 나머지는 그대로
      TRUE ~ SIGUNGU_NM
    ),
    
    # 4. 더미 변수들
    DUM_COMPLEX = if_else(IS_COMPLEX, 1, 0, missing = 0),           # 복합도농 더미
    DUM_GAP = if_else(DISTRICT_TYPE == "갑", 1, 0, missing = 0),     # 갑 더미
    DUM_EUL = if_else(DISTRICT_TYPE == "을", 1, 0, missing = 0),     # 을 더미
    DUM_BYEONG = if_else(DISTRICT_TYPE == "병", 1, 0, missing = 0),  # 병 더미
    DUM_JEONG = if_else(DISTRICT_TYPE == "정", 1, 0, missing = 0),   # 정 더미
    DUM_DISTRICT = if_else(!is.na(DISTRICT_TYPE), 1, 0, missing = 0) # 분구 여부
  )


# coords_21_1d
coords_21_1d <- coords_21_1d %>%
  mutate(
    SIDO_NM = if_else(
      str_detect(ORIG_NM, "\\s"),
      str_extract(ORIG_NM, "^[^\\s]+"),
      ORIG_NM
    ),
    SIGUNGU_NM = if_else(
      str_detect(ORIG_NM, "\\s"),
      str_extract(ORIG_NM, "(?<=\\s).+"),
      NA_character_
    )
  )


coords_21_1d <- coords_21_1d %>%
  mutate(
    # 1. 갑/을/병/정 추출
    DISTRICT_TYPE = str_extract(SIGUNGU_NM, "(갑|을|병|정)$"),
    
    # 2. 복합도농 여부 (시/군/구가 2개 이상, 단 "~시~구" 패턴은 제외)
    IS_COMPLEX = str_detect(SIGUNGU_NM, "(시|군|구).+(시|군|구)") & 
      !str_detect(SIGUNGU_NM, "시.+구(갑|을|병|정)?$"),
    
    # 3. SIGUNGU_NM2 생성
    SIGUNGU_NM2 = case_when(
      # 복합도농이면 그대로
      IS_COMPLEX == TRUE ~ SIGUNGU_NM,
      
      # 갑/을/병/정이 있으면 제거
      # "성남시분당구갑" → "성남시분당구"
      # "해운대구갑" → "해운대구"
      !is.na(DISTRICT_TYPE) ~ str_remove(SIGUNGU_NM, "(갑|을|병|정)$"),
      
      # 나머지는 그대로
      TRUE ~ SIGUNGU_NM
    ),
    
    # 4. 더미 변수들
    DUM_COMPLEX = if_else(IS_COMPLEX, 1, 0, missing = 0),           # 복합도농 더미
    DUM_GAP = if_else(DISTRICT_TYPE == "갑", 1, 0, missing = 0),     # 갑 더미
    DUM_EUL = if_else(DISTRICT_TYPE == "을", 1, 0, missing = 0),     # 을 더미
    DUM_BYEONG = if_else(DISTRICT_TYPE == "병", 1, 0, missing = 0),  # 병 더미
    DUM_JEONG = if_else(DISTRICT_TYPE == "정", 1, 0, missing = 0),   # 정 더미
    DUM_DISTRICT = if_else(!is.na(DISTRICT_TYPE), 1, 0, missing = 0) # 분구 여부
  )

# coords_22_1d
coords_22_1d <- coords_22_1d %>%
  mutate(
    SIDO_NM = if_else(
      str_detect(ORIG_NM, "\\s"),
      str_extract(ORIG_NM, "^[^\\s]+"),
      ORIG_NM
    ),
    SIGUNGU_NM = if_else(
      str_detect(ORIG_NM, "\\s"),
      str_extract(ORIG_NM, "(?<=\\s).+"),
      NA_character_
    )
  )
# coords_22_1d
coords_22_1d <- coords_22_1d %>%
  mutate(
    DISTRICT_TYPE = str_extract(SIGUNGU_NM, "(갑|을|병|정)$"),
    IS_COMPLEX = str_detect(SIGUNGU_NM, "(시|군|구).+(시|군|구)") & 
      !str_detect(SIGUNGU_NM, "시.+구(갑|을|병|정)?$"),
    SIGUNGU_NM2 = case_when(
      IS_COMPLEX == TRUE ~ SIGUNGU_NM,
      !is.na(DISTRICT_TYPE) ~ str_remove(SIGUNGU_NM, "(갑|을|병|정)$"),
      TRUE ~ SIGUNGU_NM
    ),
    DUM_COMPLEX = if_else(IS_COMPLEX, 1, 0, missing = 0),
    DUM_GAP = if_else(DISTRICT_TYPE == "갑", 1, 0, missing = 0),
    DUM_EUL = if_else(DISTRICT_TYPE == "을", 1, 0, missing = 0),
    DUM_BYEONG = if_else(DISTRICT_TYPE == "병", 1, 0, missing = 0),
    DUM_JEONG = if_else(DISTRICT_TYPE == "정", 1, 0, missing = 0),
    DUM_DISTRICT = if_else(!is.na(DISTRICT_TYPE), 1, 0, missing = 0)
  )

coords_all <- bind_rows(coords_20_1d, coords_21_1d, coords_22_1d)

saveRDS (coords_20_1d, "20대국회_wnominate_1차원")
saveRDS (coords_21_1d, "21대국회_wnominate_1차원")
saveRDS (coords_22_1d, "22대국회_wnominate_1차원")
saveRDS (coords_all, "20-22대국회_wnominate_1차원")


library(haven)
write_dta(coords_20_1d, "20대국회_wnominate_1차원.dta")
write_dta(coords_21_1d, "21대국회_wnominate_1차원.dta")
write_dta(coords_22_1d, "22대국회_wnominate_1차원.dta")
write_dta (coords_all, "20-22대국회_wnominate_1차원.dta")


