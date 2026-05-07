################# 학위논문 api 로 데이터 수집 
rm(list=ls())
library(httr)
library(rvest)
library(xml2)
library(stringr)
library(lubridate)
library(httr)
library(rvest)
library(xml2)
library(stringr)
library(lubridate)
library(jsonlite)
library(readr)
library(readxl)
library(readr)
##################################################################
##### Frame 1  '/Users/ihuila/Desktop/data/master thesis/raw/CongRoll'
# 데이터1: 의안정보통합 api -> 의안번호 호출받기 (api)
# -> save: 의안20대_22대.rds 

# 데이터2: 데이터1에서 있는 의안중에 유의미한 것(본회의표결까지 올라간 의안)을 요청인자로 넣어서 본회의표결정보 불러오기 (api)
# -> save: rollcall_최종.rds / failed_bills_최종.rds 

# 데이터3: 국회의원 정보통합 api 를 통해 국회의원 데이터 불러오기 
# -> save: 국회의원 정보통합.rds 
#####################################################################
# 데이터1: 의안정보 통합 api -> 의안번호 호출받기 
setwd("/Users/ihuila/Desktop/data/master thesis/raw/CongRoll")

api <- "3f9b24a1babb41769610795d153598e2"
base_url <- "https://open.assembly.go.kr/portal/openapi/ALLBILLV2"

# 시험삼아 
url <- paste0(
  base_url, 
  "?KEY=", api,
  "&Type=json",
  "&pIndex=1",
  "&pSize=100",
  "&ERACO=", URLencode("제20대", repeated = TRUE)
)

res <- fromJSON(url)
View(res)

# res$ALLBILLV2$row[[2]]
#### 20~22대 반복문 시행 
rollcall_all <- NULL

for (age in 20:22) {
  stack <- NULL
  eraco <- URLencode(paste0("제", age, "대"), repeated = TRUE)
  
  # 첫 페이지로 전체 건수 확인
  url <- paste0(
    base_url,
    "?KEY=", api,
    "&Type=json",
    "&pIndex=1",
    "&pSize=100",
    "&ERACO=", eraco
  )
  
  res <- fromJSON(url)
  total <- res$ALLBILLV2$head[[1]]$list_total_count
  total_pages <- ceiling(total / 100)
  
  cat("=============================\n")
  cat("▶ 대수:", age, "시작\n")
  cat("  전체건수:", total, "| 전체페이지:", total_pages, "\n")
  cat("=============================\n")
  
  for (page in 1:total_pages) {
    url <- paste0(
      base_url,
      "?KEY=", api,
      "&Type=json",
      "&pIndex=", page,
      "&pSize=100",
      "&ERACO=", eraco
    )
    
    res <- fromJSON(url)
    tab <- res$ALLBILLV2$row[[2]]
    stack <- rbind(stack, tab)
    
    cat(sprintf("  [%d대] 페이지 %d / %d 완료 (누적 %d건)\n", 
                age, page, total_pages, nrow(stack)))
    
    Sys.sleep(0.5)
  }
  
  stack$대수 <- age
  rollcall_all <- rbind(rollcall_all, stack)
  cat(sprintf("✔ %d대 완료 | 전체 누적: %d행\n\n", age, nrow(rollcall_all)))
} # 70,311행 

# 대수 일치 여부. 
rollcall_all %>%
  mutate(ERACO_대수 = as.numeric(gsub("제|대", "", ERACO))) %>%
  count(ERACO, 대수, ERACO_대수) %>%
  mutate(일치여부 = 대수 == ERACO_대수) # 대수모두 일치 

# 불러온 정보로 대수변수 새로 만들기 
rollcall_all <- rollcall_all %>% select(-대수)
rollcall_all <- rollcall_all %>%
  mutate(대수 = as.numeric(gsub("제|대", "", ERACO))) 

#readr::write_csv(rollcall_all, "의안20대_22대.csv") #필터링 전에 전체 의안 불러오기 
saveRDS(rollcall_all, "/Users/ihuila/Desktop/data/master thesis/raw/CongRoll/의안20대_22대.rds")

######################### 의안데이터 클리닝 
rollcall_all %>% count(ERACO)
rollcall_all %>% distinct(PROC_STAGE_CD)

rollcall_all %>%
  filter(PROC_STAGE_CD %in% c(
    "본회의의결",
    "본회의부의안건",
    "공포",
    "정부이송",
    "재의요구",
    "재의(부결)",
    "재의(가결)"
  )) %>%
  count(ERACO)

rollcall_all %>%
  group_by(ERACO) %>%
  summarise(
    전체 = n(),
    PROC_STAGE_CD_NA = sum(is.na(PROC_STAGE_CD)),
    본회의의결 = sum(PROC_STAGE_CD == "본회의의결", na.rm = TRUE)
  )

rollcall_all %>%
  filter(ERACO == "제20대") %>%
  summarise(across(everything(), ~sum(!is.na(.)))) %>%
  glimpse()

rollcall_all %>%
  filter(ERACO == "제20대") %>%
  distinct(RGS_CONF_RSLT)  # 본회의심의결과 변수, 원안가결/임기만료폐기/수정가결/폐기/철회/부결/수정안반영폐기/심사대상제외 

# 본회의까지 올라간 의안만 
agenda <- rollcall_all %>%
  filter(RGS_CONF_RSLT %in% c(
    "원안가결",
    "수정가결",
    "부결"
  )) 

# 제안일자 NA 확인 
agenda %>% summarise(PPSL_DT_NA = sum(is.na(PPSL_DT))) # 제안일자 NA 없음 

names(agenda)

# 필요없는 변수삭제 
agenda <- agenda %>% select(-HWP_URL1, -HWP_URL2, -LINK_URL)

# 의안 중복된 것 없는지 
agenda %>%
  count(BILL_ID) %>%
  filter(n > 1) #중복 의안 1건 있음 

agenda %>%
  filter(BILL_ID == "PRC_S2M5U0W9H2I4J1G2K3U5L5J1J5X2J0") # 두건 완전 동일값 -> 중복 1건 삭제 (before obs: 8939)

agenda <- agenda %>% distinct() # after obs=8938  

agenda %>%
  summarise(across(everything(), ~n_distinct(.))) %>%
  glimpse() #의안ID랑 의안번호랑 개수가 다른데, 의안ID 기준으로 하기

agenda20 <- agenda  %>% filter(ERACO == "제20대")
agenda21 <- agenda %>% filter(ERACO == "제21대")
agenda22 <- agenda %>% filter(ERACO == "제22대")

saveRDS(agenda, "본회의의안20대_22대.rds")
saveRDS(agenda20, "본회의의안20대.rds")
saveRDS(agenda21, "본회의의안21대.rds")
saveRDS(agenda22, "본회의의안22대.rds")

##############################위에서 수집한 의안데이터를 통해 본회의표결 호출 
api <- "3f9b24a1babb41769610795d153598e2"
base_url <- "https://open.assembly.go.kr/portal/openapi/nojepdqqaweusdfbi"

#테스트용 코드. 
url <- paste0(
  base_url,
  "?KEY=", api,
  "&Type=json",
  "&pIndex=1",
  "&pSize=100",
  "&AGE=22",
  "&BILL_ID=PRC_A2S5H1A2H1P6H1F7Q1T0L0F4E9E5Y3"
)

res <- fromJSON(url)

res$nojepdqqaweusdfbi$row[[2]] # 결과저장 

total <- res$nojepdqqaweusdfbi$head[[1]]$list_total_count[[1]]
########### 반복문 (20~22대 국회)
rollcall <- NULL
failed_bills <- NULL  # 오류 누적
bill_info <- agenda %>% select(BILL_ID, 대수)
total_bills <- nrow(bill_info)
cat("전체 의안 수:", total_bills, "\n")

for (i in 1:total_bills) {
  bill_id <- bill_info$BILL_ID[i]
  age <- bill_info$대수[i]
  
  tryCatch({
    url <- paste0(
      base_url,
      "?KEY=", api,
      "&Type=json",
      "&pIndex=1",
      "&pSize=100",
      "&AGE=", age,
      "&BILL_ID=", bill_id
    )
    
    res <- fromJSON(url)
    total <- res$nojepdqqaweusdfbi$head[[1]]$list_total_count[[1]]
    
    if (is.na(total) || total == 0) {
      cat(sprintf("[%d/%d] BILL_ID: %s | 표결 없음 skip\n", i, total_bills, bill_id))
      next
    }
    
    total_pages <- ceiling(total / 100)
    temp <- NULL
    
    for (page in 1:total_pages) {
      url <- paste0(
        base_url,
        "?KEY=", api,
        "&Type=json",
        "&pIndex=", page,
        "&pSize=100",
        "&AGE=", age,
        "&BILL_ID=", bill_id
      )
      
      res <- fromJSON(url)
      tab <- res$nojepdqqaweusdfbi$row[[2]]
      if (!is.null(tab)) {
        temp <- rbind(temp, tab)
      }
      
      Sys.sleep(0.3)
    }
    
    rollcall <- rbind(rollcall, temp)
    cat(sprintf("[%d/%d] %d대 BILL_ID: %s | %d건 수집 | 누적: %d행\n",
                i, total_bills, age, bill_id, total, nrow(rollcall)))
    
  }, error = function(e) {
    cat(sprintf("[%d/%d] BILL_ID: %s | 오류: %s\n", i, total_bills, bill_id, e$message))
    failed_bills <<- rbind(failed_bills, data.frame(  # <<- 로 전역변수 저장
      index = i,
      BILL_ID = bill_id,
      대수 = age,
      오류메세지 = e$message
    ))
  })
  
  Sys.sleep(0.3)
}

# 여기부터 
# 현재 진행상황 저장
saveRDS(rollcall, "/Users/ihuila/Desktop/data/master thesis/raw/CongRoll/rollcall_중간저장.rds")
saveRDS(failed_bills, "/Users/ihuila/Desktop/data/master thesis/raw/CongRoll/failed_bills_중간저장.rds")

View(rollcall)
##################### 수집 실패한 의안번호 기준으로 다시 본회의표결 데이터 수집 
# 첫 번째 실패 의안 확인
failed_bills[1, ]

# 테스트
bill_id <- failed_bills$BILL_ID[1]
age <- failed_bills$대수[1]

url <- paste0(
  base_url,
  "?KEY=", api,
  "&Type=json",
  "&pIndex=1",
  "&pSize=100",
  "&AGE=", age,
  "&BILL_ID=", bill_id
)

res <- fromJSON(url)
str(res, max.level = 3)

# 실패한 의안만 재시도
failed_bills_retry <- NULL  # 재시도 후에도 실패한 것
total_retry <- nrow(failed_bills)
cat("재시도 의안 수:", total_retry, "\n")

for (i in 1:total_retry) {
  bill_id <- failed_bills$BILL_ID[i]
  age <- failed_bills$대수[i]
  
  tryCatch({
    url <- paste0(
      base_url,
      "?KEY=", api,
      "&Type=json",
      "&pIndex=1",
      "&pSize=100",
      "&AGE=", age,
      "&BILL_ID=", bill_id
    )
    
    res <- fromJSON(url)
    total <- res$nojepdqqaweusdfbi$head[[1]]$list_total_count[[1]]
    
    if (is.na(total) || total == 0) {
      cat(sprintf("[%d/%d] BILL_ID: %s | 표결 없음 skip\n", i, total_retry, bill_id))
      next
    }
    
    total_pages <- ceiling(total / 100)
    temp <- NULL
    
    for (page in 1:total_pages) {
      url <- paste0(
        base_url,
        "?KEY=", api,
        "&Type=json",
        "&pIndex=", page,
        "&pSize=100",
        "&AGE=", age,
        "&BILL_ID=", bill_id
      )
      
      res <- fromJSON(url)
      tab <- res$nojepdqqaweusdfbi$row[[2]]
      if (!is.null(tab)) {
        temp <- rbind(temp, tab)
      }
      
      Sys.sleep(0.3)
    }
    
    rollcall <- rbind(rollcall, temp)
    cat(sprintf("[%d/%d] %d대 BILL_ID: %s | %d건 수집 | 누적: %d행\n",
                i, total_retry, age, bill_id, total, nrow(rollcall)))
    
  }, error = function(e) {
    cat(sprintf("[%d/%d] BILL_ID: %s | 재시도 오류: %s\n", i, total_retry, bill_id, e$message))
    failed_bills_retry <<- rbind(failed_bills_retry, data.frame(
      index = failed_bills$index[i],
      BILL_ID = bill_id,
      대수 = age,
      오류메세지 = e$message
    ))
  })
  
  Sys.sleep(0.3)
}

cat("재시도 완료!\n")
cat("최종 누적행수:", nrow(rollcall), "\n")
cat("재시도 후에도 실패:", nrow(failed_bills_retry), "건\n")

# 최종 저장
saveRDS(rollcall, "/Users/ihuila/Desktop/data/master thesis/raw/CongRoll/rollcall_최종.rds")
saveRDS(failed_bills_retry, "/Users/ihuila/Desktop/data/master thesis/raw/CongRoll/failed_bills_최종.rds")
  
# 1차시도: 성공  2,303,588 / 실패 의안수 1198 
# 2차 시도: 성공 후 2,382,958 / 실패의안수 933건 


# #### 여기부터
# # 2차 재시도
# failed_bills_retry2 <- NULL
# total_retry2 <- nrow(failed_bills_retry)
# cat("2차 재시도 의안 수:", total_retry2, "\n")
# 
# for (i in 1:total_retry2) {
#   bill_id <- failed_bills_retry$BILL_ID[i]
#   age <- failed_bills_retry$대수[i]
#   
#   tryCatch({
#     url <- paste0(
#       base_url,
#       "?KEY=", api,
#       "&Type=json",
#       "&pIndex=1",
#       "&pSize=100",
#       "&AGE=", age,
#       "&BILL_ID=", bill_id
#     )
#     
#     res <- fromJSON(url)
#     total <- res$nojepdqqaweusdfbi$head[[1]]$list_total_count[[1]]
#     
#     if (is.na(total) || total == 0) {
#       cat(sprintf("[%d/%d] BILL_ID: %s | 표결 없음 skip\n", i, total_retry2, bill_id))
#       next
#     }
#     
#     total_pages <- ceiling(total / 100)
#     temp <- NULL
#     
#     for (page in 1:total_pages) {
#       url <- paste0(
#         base_url,
#         "?KEY=", api,
#         "&Type=json",
#         "&pIndex=", page,
#         "&pSize=100",
#         "&AGE=", age,
#         "&BILL_ID=", bill_id
#       )
#       
#       res <- fromJSON(url)
#       tab <- res$nojepdqqaweusdfbi$row[[2]]
#       if (!is.null(tab)) {
#         temp <- rbind(temp, tab)
#       }
#       
#       Sys.sleep(0.5)  # 좀 더 여유있게
#     }
#     
#     rollcall <- rbind(rollcall, temp)
#     cat(sprintf("[%d/%d] %d대 BILL_ID: %s | %d건 수집 | 누적: %d행\n",
#                 i, total_retry2, age, bill_id, total, nrow(rollcall)))
#     
#   }, error = function(e) {
#     cat(sprintf("[%d/%d] BILL_ID: %s | 2차 오류: %s\n", i, total_retry2, bill_id, e$message))
#     failed_bills_retry2 <<- rbind(failed_bills_retry2, data.frame(
#       index = failed_bills_retry$index[i],
#       BILL_ID = bill_id,
#       대수 = age,
#       오류메세지 = e$message
#     ))
#   })
#   
#   Sys.sleep(0.5)
# }
# 
# cat("2차 재시도 완료!\n")
# cat("최종 누적행수:", nrow(rollcall), "\n")
# cat("2차 재시도 후에도 실패:", nrow(failed_bills_retry2), "건\n")
# 
# # v3로 저장
# saveRDS(rollcall, "/Users/ihuila/Desktop/data/master thesis/raw/CongRoll/rollcall_v3.rds")
# saveRDS(failed_bills_retry2, "/Users/ihuila/Desktop/data/master thesis/raw/CongRoll/failed_bills_v3.rds")

###############################################################
#### 데이터 3: 국회의원 정보통합 api 
setwd("/Users/ihuila/Desktop/data/master thesis/raw/CongRoll")

api <- "3f9b24a1babb41769610795d153598e2"
base_url <- "https://open.assembly.go.kr/portal/openapi/ALLNAMEMBER" # 국회의원 

####### 테스트용 코드 
url <- paste0(
  base_url,
  "?KEY=", api,
  "&Type=json",
  "&pIndex=1",
  "&pSize=100"
)

res <- fromJSON(url)
str(res, max.level = 3)

# 전체 건수 확인
total <- res$ALLNAMEMBER$head[[1]]$list_total_count[[1]]
total_pages <- ceiling(total / 100)
cat("전체 의원 수:", total, "| 전체 페이지:", total_pages, "\n")

####### 전체대수 불러오기, 국회의원 코드 
member_all <- NULL

for (page in 1:total_pages) {
  url <- paste0(
    base_url,
    "?KEY=", api,
    "&Type=json",
    "&pIndex=", page,
    "&pSize=100"
  )
  
  res <- fromJSON(url)
  tab <- res$ALLNAMEMBER$row[[2]]
  
  if (!is.null(tab)) {
    member_all <- rbind(member_all, tab)
  }
  
  cat(sprintf("페이지 %d / %d 완료 (누적 %d명)\n", page, total_pages, nrow(member_all)))
  Sys.sleep(0.3)
}

cat("완료! 총:", nrow(member_all), "명\n")

# GTELT_ERACO 기준으로 대수 확인
member_all %>% count(GTELT_ERACO)
View(member_all)
saveRDS(member_all, "국회의원 정보 통합.rds")

# ##########################################################################
# ##### Frame 2 '/Users/ihuila/Desktop/data/master thesis/raw/CongWin'
# # 셋업용 0: 선거정보 (전체 -> 총선 -> 총선 선거구)
# # -> save: 선거코드.rds, 총선 선거코드.rds, 총선 선거구코드.rds 
# 
# # 데이터 1:  선거인수 정보 
# # 1.1. 선거구별 선거인수 정보 
# # -> save: 총선 선거구별 선거인수 정보.rds 
# # 1.2. 읍면동별 선거인수 정보 
# # -> save: 총선 읍면동별 선거인수 정보.rds 
# 
# # 데이터 2: 총선 투/개표현황 정보 (지역구, 비례 모두 포함해서 수집)
# # 2.1. 총선 투표 결과 
# # -> save: 총선 투표 결과.rds 
# # 2.2. 총선 개표 결과 (정당별 득표수 포함)
# # -> save: 총선 개표 결과.rds 
# ###########################################################################
# rm(list=ls())
# 
# setwd("/Users/ihuila/Desktop/data/master thesis/raw/CongWin")
# 
# library(httr)
# library(rvest)
# library(xml2)
# library(stringr)
# library(lubridate)
# library(jsonlite)
# library(readr)
# library(readxl)
# library(readr)
# library(pscl)
# library(tidyverse)
# library(wnominate)
# library(ggmap)
# library(maps)
# # library(kormaps2014)
# library(showtext)
# library(writexl)
# library(dplyr)
# library(haven)
# ############################# # 0.1. 셋업용: 선거코드 정보 api로 불러오기 
# api <- "galcUP%2F2CbobQbIrDH9M9GLSJORs6PdpNQyGKdu%2BOECt%2FzZzQ1d2eqm2lX0KvHoAfoaD98LG8F2zm4DG5dm5Bw%3D%3D"
# base_url <- "http://apis.data.go.kr/9760000/CommonCodeService/getCommonSgCodeList" 
# 
# url <- paste0(base_url,
#               "?ServiceKey=", api)
# res <- GET(url)
# 
# res_xml <- content(res, "text", encoding = "UTF-8")
# parsed <- read_xml(res_xml)
# total <- xml_text(xml_find_first(parsed, "//totalCount"))
# cat("전체 선거 수:", total, "\n") # 총 192번의 선거.  
# 
# # 전체 선거코드 정보 불러오기 
# url_all <- paste0(base_url, "?ServiceKey=", api, "&numOfRows=100&pageNo=1")
# res_all <- GET(url_all)
# parsed_all <- read_xml(content(res_all, "text", encoding = "UTF-8"))
# items_all <- xml_find_all(parsed_all, "//item")
# 
# df1 <- do.call(rbind, lapply(items_all, function(item) {
#   data.frame(
#     sgId       = xml_text(xml_find_first(item, "sgId")),
#     sgName     = xml_text(xml_find_first(item, "sgName")),
#     sgTypecode = xml_text(xml_find_first(item, "sgTypecode")),
#     sgVotedate = xml_text(xml_find_first(item, "sgVotedate")),
#     stringsAsFactors = FALSE
#   )
# }))
# 
# # 2페이지
# url_all2 <- paste0(base_url, "?ServiceKey=", api, "&numOfRows=100&pageNo=2")
# res_all2 <- GET(url_all2)
# parsed_all2 <- read_xml(content(res_all2, "text", encoding = "UTF-8"))
# items_all2 <- xml_find_all(parsed_all2, "//item")
# 
# df2 <- do.call(rbind, lapply(items_all2, function(item) {
#   data.frame(
#     sgId       = xml_text(xml_find_first(item, "sgId")),
#     sgName     = xml_text(xml_find_first(item, "sgName")),
#     sgTypecode = xml_text(xml_find_first(item, "sgTypecode")),
#     sgVotedate = xml_text(xml_find_first(item, "sgVotedate")),
#     stringsAsFactors = FALSE
#   )
# }))
# 
# df_all <- rbind(df1, df2)
# 
# 
# df_all <- df_all %>% filter(sgId >= "20080409")
# 
# saveRDS(df_all, "선거 코드_2008.rds")
# 
# df_all %>% filter(grepl("국회의원", sgName)) %>% select(sgId, sgName, sgTypecode, sgVotedate)
# 
# df_all %>% distinct(sgTypecode)
# 
# # 국회의원선거만
# congress <- df_all %>% 
#   filter(grepl("국회의원", sgName)) %>%
#   filter(sgTypecode %in% c("0", "2", "7")) %>%
#   select(sgId, sgName, sgTypecode, sgVotedate)
# saveRDS(congress, "총선 선거 코드.rds")
# 
# congress %>% distinct(sgId) %>% pull(sgId)
# 
# 
# ####### 0.2. 셋업용: 선거구 코드 
# api <- "galcUP%2F2CbobQbIrDH9M9GLSJORs6PdpNQyGKdu%2BOECt%2FzZzQ1d2eqm2lX0KvHoAfoaD98LG8F2zm4DG5dm5Bw%3D%3D"
# base_url <- "http://apis.data.go.kr/9760000/CommonCodeService/getCommonSggCodeList" 
# 
# # 테스트용 
# url <- paste0(base_url,
#                    "?ServiceKey=", api,
#                    "&sgId=20240410",
#                    "&sgTypecode=2",
#                    "&numOfRows=100",
#                    "&pageNo=1")
# 
# res_test <- GET(url)
# cat("상태코드:", status_code(res_test), "\n")
# parsed_test <- read_xml(content(res_test, "text", encoding = "UTF-8"))
# xml_text(xml_find_first(parsed_test, "//totalCount"))  # 총 254개 
# 
# 
# # XML 파싱 함수
# parse_sgg <- function(parsed) {
#   items <- xml_find_all(parsed, "//item")
#   if (length(items) == 0) return(NULL)
#   
#   do.call(rbind, lapply(items, function(item) {
#     data.frame(
#       sgId       = xml_text(xml_find_first(item, "sgId")),
#       sgTypecode = xml_text(xml_find_first(item, "sgTypecode")),
#       sggName    = xml_text(xml_find_first(item, "sggName")),
#       sdName     = xml_text(xml_find_first(item, "sdName")),
#       stringsAsFactors = FALSE
#     )
#   }))
# }
# 
# # 반복문
# sgg_all <- NULL
# 
# for (i in 1:nrow(congress)) {
#   sgid <- congress$sgId[i]
#   sgtc <- congress$sgTypecode[i]
#   
#   # 첫 페이지로 전체 건수 확인
#   url <- paste0(base_url,
#                 "?ServiceKey=", api,
#                 "&sgId=", sgid,
#                 "&sgTypecode=", sgtc,
#                 "&numOfRows=100&pageNo=1")
#   
#   res <- GET(url)
#   parsed <- read_xml(content(res, "text", encoding = "UTF-8"))
#   total <- as.numeric(xml_text(xml_find_first(parsed, "//totalCount")))
#   
#   if (is.na(total) || total == 0) {
#     cat(sprintf("[%d/%d] sgId=%s sgTypecode=%s | 데이터 없음\n", i, nrow(congress), sgid, sgtc))
#     next
#   }
#   
#   total_pages <- ceiling(total / 100)
#   temp <- parse_sgg(parsed)
#   
#   if (total_pages > 1) {
#     for (page in 2:total_pages) {
#       url_p <- paste0(base_url,
#                       "?ServiceKey=", api,
#                       "&sgId=", sgid,
#                       "&sgTypecode=", sgtc,
#                       "&numOfRows=100&pageNo=", page)
#       res_p <- GET(url_p)
#       parsed_p <- read_xml(content(res_p, "text", encoding = "UTF-8"))
#       temp <- rbind(temp, parse_sgg(parsed_p))
#       Sys.sleep(0.3)
#     }
#   }
#   
#   sgg_all <- rbind(sgg_all, temp)
#   cat(sprintf("[%d/%d] sgId=%s sgTypecode=%s | %d건 | 누적: %d행\n",
#               i, nrow(congress), sgid, sgtc, total, nrow(sgg_all)))
#   Sys.sleep(0.3)
# }
# 
# cat("완료! 총:", nrow(sgg_all), "행\n")
# 
# sgg_all <- sgg_all %>% filter(sgId >= "20080409")
# saveRDS(sgg_all, "총선 선거구 코드_2008.rds")
# write_dta(sgg_all,"총선 선거구 코드_2008.dta" )
# #######################################################################
# ##### 데이터 1: 선거인수 정보 (총선)
# # 1.1. 선거구별 선거인수 정보 (총선) (셋업에서 얻은 정보를 가지고 요청인자 넣기)
# # 1.2. 읍면동별 선거인수 정보 (총선) (1.1에서 얻은 정보를 가지고 요청인자 넣기)
# ######################################################################
# # 1.1. 선거구별 선거인수 정보
# api <- "galcUP%2F2CbobQbIrDH9M9GLSJORs6PdpNQyGKdu%2BOECt%2FzZzQ1d2eqm2lX0KvHoAfoaD98LG8F2zm4DG5dm5Bw%3D%3D"
# base_url <- "http://apis.data.go.kr/9760000/ElcntInfoInqireService/getElpcElcntInfoInqire"
# 
# # 파싱 함수
# parse_elcnt <- function(res) {
#   df <- res$response$body$items[[1]]
#   if (is.null(df) || nrow(df) == 0) return(NULL)
#   return(df)
# }
# 
# # 2008, 2016, 2020, 2024년 총선만 필터링
# congress <- congress %>%
#   filter(sgId %in% c("20080409", "20120411", "20160413", "20200415", "20240410"))
# 
# # congress에서 sgTypecode 0,2,7 각각에 대해 반복
# elcnt_all <- NULL
# 
# for (i in 1:nrow(congress)) {
#   sgid <- congress$sgId[i]
#   sgtc <- congress$sgTypecode[i]
#   
#   # sgTypecode 0은 지원 안 됨 (2,3,4,5,6,10,11만 가능)
#   if (!(sgtc %in% c("0", "2", "7"))) next
#   
#   # 첫 페이지로 전체 건수 확인
#   url <- paste0(base_url,
#                 "?serviceKey=", api,
#                 "&sgId=", sgid,
#                 "&sgTypecode=", sgtc,
#                 "&numOfRows=100&pageNo=1",
#                 "&resultType=json")
#   
#   tryCatch({
#     res <- fromJSON(url)
#     total <- res$response$body$totalCount
#     
#     if (is.null(total) || total == 0) {
#       cat(sprintf("[%d/%d] sgId=%s sgTypecode=%s | 데이터 없음\n", i, nrow(congress), sgid, sgtc))
#       next
#     }
#     
#     total_pages <- ceiling(total / 100)
#     temp <- parse_elcnt(res)
#     
#     if (total_pages > 1) {
#       for (page in 2:total_pages) {
#         url_p <- paste0(base_url,
#                         "?serviceKey=", api,
#                         "&sgId=", sgid,
#                         "&sgTypecode=", sgtc,
#                         "&numOfRows=100&pageNo=", page,
#                         "&resultType=json")
#         res_p <- fromJSON(url_p)
#         temp <- rbind(temp, parse_elcnt(res_p))
#         Sys.sleep(0.3)
#       }
#     }
#     
#     elcnt_all <- rbind(elcnt_all, temp)
#     cat(sprintf("[%d/%d] sgId=%s sgTypecode=%s | %d건 | 누적: %d행\n",
#                 i, nrow(congress), sgid, sgtc, total, nrow(elcnt_all)))
#     
#   }, error = function(e) {
#     cat(sprintf("[%d/%d] sgId=%s sgTypecode=%s | 오류: %s\n", i, nrow(congress), sgid, sgtc, e$message))
#   })
#   
#   Sys.sleep(0.3)
# }
# 
# cat("완료! 총:", nrow(elcnt_all), "행\n")
# 
# elcnt_all %>% 
#   filter(sgId == "20160413", sdName == "경상남도") %>% 
#   distinct(sggName)
# 
# elcnt_all <- elcnt_all  %>% filter(sgId >= "20080409")
# saveRDS(elcnt_all, "총선 선거구별 선거인수 정보_2008.rds") # 2008년 총선부터밖에 없음 참고
# write_dta(elcnt_all, "총선 선거구별 선거인수 정보_2008.dta") 
# # 2016년 경상남도 통영시고성군 선거구는 정보 없음 (무투표 당선됨)
# # 읍면동 데이터에는 있음 
# 
# # 선거구별 선거인수
# # sgId, sdName, sggName, wiwName, emdCount, tpgCount(투표구 수)
# # ppltCnt (인구수, 선거인명부 작성일기준 현재)
# # cfmtnElcnt (확정선거인수 합계)
# # cfmtnManElcnt(확정선거인수 남성)
# # cfmtnFmlElcnt	(확정선거인수 여성)
# ######################################################################
# # 1.2. 읍면동별 선거인수 정보
# api <- "galcUP%2F2CbobQbIrDH9M9GLSJORs6PdpNQyGKdu%2BOECt%2FzZzQ1d2eqm2lX0KvHoAfoaD98LG8F2zm4DG5dm5Bw%3D%3D"
# base_url <- "http://apis.data.go.kr/9760000/ElcntInfoInqireService/getEmdElcntInfoInqire"
# 
# 
# # 테스트용 코드 
# url <- paste0(base_url,
#               "?serviceKey=", api,
#               "&sgId=20240410",
#               "&sgTypecode=2", 
#               "&resultType=json") 
# 
# res <- fromJSON(url)
# res
# str(res, max.level = 3) # $totalCount: 602
# res$response$body$items[[1]]
# 
# 
# # sgid 별로 - 각 시도명, 시군명 조합대로 요청인자에 넣어야 함 
# # sdName + wiwName 조합 확인
# elcnt_all %>% 
#   distinct(sgId, sdName, wiwName) %>% 
#   head(20)
# 
# combo <- elcnt_all %>%
#   distinct(sgId, sdName, wiwName)
# 
# # 총선만 
# combo <- combo %>%
#   filter(sgId %in% c("20080409", "20120411", "20160413", "20200415", "20240410"))
# 
# # ★ 2016년 경상남도 통영시고성군 선거구 수동 추가 (무투표 당선으로 누락됨) 선관위 xlsx 에서도 선거구기준 데이터에는 없음 
# 
# missing_tongyeong <- data.frame(
#   sgId = c("20160413", "20160413"),
#   sdName = c("경상남도", "경상남도"),
#   wiwName = c("통영시", "고성군"),
#   stringsAsFactors = FALSE
# )
# 
# emd_all <- NULL
# 
# for (i in 1:nrow(combo)) {
#   sgid    <- combo$sgId[i]
#   sdname  <- combo$sdName[i]
#   wiwname <- combo$wiwName[i]
#   
#   tryCatch({
#     url <- paste0(base_url,
#                   "?serviceKey=", api,
#                   "&sgId=", sgid,
#                   "&sdName=", URLencode(sdname, repeated=TRUE),
#                   "&wiwName=", URLencode(wiwname, repeated=TRUE),
#                   "&numOfRows=100&pageNo=1",
#                   "&resultType=json")
#     
#     res <- fromJSON(url)
#     total <- res$response$body$totalCount
#     
#     if (is.null(total) || total == 0) {
#       cat(sprintf("[%d/%d] sgId=%s %s %s | 데이터 없음\n", i, nrow(combo), sgid, sdname, wiwname))
#       next
#     }
#     
#     total_pages <- ceiling(total / 100)
#     temp <- res$response$body$items[[1]]
#     
#     if (total_pages > 1) {
#       for (page in 2:total_pages) {
#         url_p <- paste0(base_url,
#                         "?serviceKey=", api,
#                         "&sgId=", sgid,
#                         "&sdName=", URLencode(sdname, repeated=TRUE),
#                         "&wiwName=", URLencode(wiwname, repeated=TRUE),
#                         "&numOfRows=100&pageNo=", page,
#                         "&resultType=json")
#         res_p <- fromJSON(url_p)
#         temp <- rbind(temp, res_p$response$body$items[[1]])
#         Sys.sleep(0.3)
#       }
#     }
#     
#     emd_all <- rbind(emd_all, temp)
#     cat(sprintf("[%d/%d] sgId=%s %s %s | %d건 | 누적: %d행\n",
#                 i, nrow(combo), sgid, sdname, wiwname, total, nrow(emd_all)))
#     
#   }, error = function(e) {
#     cat(sprintf("[%d/%d] sgId=%s %s %s | 오류: %s\n", 
#                 i, nrow(combo), sgid, sdname, wiwname, e$message))
#   })
#   
#   Sys.sleep(0.3)
# }
# 
# # 여기부터 
# getwd()
# setwd("/Users/ihuila/Desktop/data/master thesis/raw/CongWin")
# saveRDS(emd_all, "총선 읍면동별 선거인수 정보_2008.rds")
# write_dta(emd_all, "총선 읍면동별 선거인수 정보_2008.dta")
# #######################################################################
# ##### 데이터 2: 총선 투/개표 결과 
# # 2.1. 총선 투표 결과 
# # 2.2. 총선 개표 결과 (정당별 득표수 포함)
# ######################################################################
# ########## 2.0. 총선 투표 결과 불러오기 전에 셋업 
# 
# names(congress)
# names(elcnt_all)
# 
# congress %>% distinct(sgTypecode) # 0, 2, 7 
# 
# # congress 에 있는 sgId, sgTypecde 이용 
# 
# # 2.1. 총선 투표 결과 
# api <- "galcUP%2F2CbobQbIrDH9M9GLSJORs6PdpNQyGKdu%2BOECt%2FzZzQ1d2eqm2lX0KvHoAfoaD98LG8F2zm4DG5dm5Bw%3D%3D" 
# base_url <- "http://apis.data.go.kr/9760000/VoteXmntckInfoInqireService2/getVoteSttusInfoInqire"
# 
# ### 총선 투표결과 api만 sgTypecode=7로 국회의원 선거 고정 
# # sgType=0 안됨, sgType=2 안됨 
# # sgType=7인 경우 총선 
# 
# vote_all <- NULL
# failed_vote <- NULL
# cnt <- 0
# 
# sgId_list <- congress %>% 
#   filter(sgId %in% c("20080409", "20120411", "20160413", "20200415", "20240410")) %>%
#   distinct(sgId) %>% 
#   pull(sgId)
# 
# total_combo <- length(sgId_list) * 3
# 
# for (sgid in sgId_list) {
#   for (sgtc in c("0", "2", "7")) {
#     cnt <- cnt + 1
#     
#     tryCatch({
#       url <- paste0(base_url,
#                     "?ServiceKey=", api,
#                     "&sgId=", sgid,
#                     "&sgTypecode=", sgtc,
#                     "&numOfRows=100&pageNo=1",
#                     "&resultType=json")
#       
#       res <- fromJSON(url)
#       
#       if (res$response$header$resultCode != "INFO-00") {
#         cat(sprintf("[%d/%d] sgId=%s sgTypecode=%s | 오류: %s\n",
#                     cnt, total_combo, sgid, sgtc, res$response$header$resultMsg))
#         next
#       }
#       
#       total <- res$response$body$totalCount
#       
#       if (is.null(total) || total == 0) {
#         cat(sprintf("[%d/%d] sgId=%s sgTypecode=%s | 데이터 없음\n",
#                     cnt, total_combo, sgid, sgtc))
#         next
#       }
#       
#       total_pages <- ceiling(total / 100)
#       temp <- res$response$body$items[[1]]
#       
#       if (total_pages > 1) {
#         for (page in 2:total_pages) {
#           url_p <- paste0(base_url,
#                           "?ServiceKey=", api,
#                           "&sgId=", sgid,
#                           "&sgTypecode=", sgtc,
#                           "&numOfRows=100&pageNo=", page,
#                           "&resultType=json")
#           res_p <- fromJSON(url_p)
#           temp <- rbind(temp, res_p$response$body$items[[1]])
#           Sys.sleep(0.3)
#         }
#       }
#       
#       vote_all <- rbind(vote_all, temp)
#       cat(sprintf("[%d/%d] sgId=%s sgTypecode=%s | %d건 | 누적: %d행\n",
#                   cnt, total_combo, sgid, sgtc, total, nrow(vote_all)))
#       
#     }, error = function(e) {
#       cat(sprintf("[%d/%d] sgId=%s sgTypecode=%s | 오류: %s\n",
#                   cnt, total_combo, sgid, sgtc, e$message))
#       failed_vote <<- rbind(failed_vote, data.frame(
#         sgId = sgid, sgTypecode = sgtc, 오류 = e$message
#       ))
#     })
#     
#     Sys.sleep(0.3)
#   }
# }
# 
# saveRDS(vote_all, "총선 투표 결과_2008.rds") 
# write_dta(vote_all, "총선 투표 결과_2008.dta")
# ######################################################################
# # 2.2. 총선 개표 결과 
# api <- "galcUP%2F2CbobQbIrDH9M9GLSJORs6PdpNQyGKdu%2BOECt%2FzZzQ1d2eqm2lX0KvHoAfoaD98LG8F2zm4DG5dm5Bw%3D%3D" 
# base_url <- "http://apis.data.go.kr/9760000/VoteXmntckInfoInqireService2/getXmntckSttusInfoInqire"
# 
# # congress 에서 추출한 sgId 쓰고, 
# # sgTypecode는 0,2,7 각각 반복문에 넣어보면서 수집 
# 
# ## 총선 투표결과에서 sgTypecode 7로 고정 
# ## 총선 개표결과에서 sgTypecode 2,7로 고정 
# 
# result_all <- NULL
# failed_result <- NULL
# cnt <- 0
# 
# sgId_list <- congress %>% 
#   filter(sgId %in% c("20080409", "20120411", "20160413", "20200415", "20240410")) %>%
#   distinct(sgId) %>% 
#   pull(sgId)
# total_combo <- length(sgId_list) * 3
# 
# for (sgid in sgId_list) {
#   for (sgtc in c("0", "2", "7")) {
#     cnt <- cnt + 1
#     
#     tryCatch({
#       url <- paste0(base_url,
#                     "?ServiceKey=", api,
#                     "&sgId=", sgid,
#                     "&sgTypecode=", sgtc,
#                     "&numOfRows=100&pageNo=1",
#                     "&resultType=json")
#       
#       res <- fromJSON(url)
#       
#       if (res$response$header$resultCode != "INFO-00") {
#         cat(sprintf("[%d/%d] sgId=%s sgTypecode=%s | 오류: %s\n",
#                     cnt, total_combo, sgid, sgtc, res$response$header$resultMsg))
#         next
#       }
#       
#       total <- res$response$body$totalCount
#       
#       if (is.null(total) || total == 0) {
#         cat(sprintf("[%d/%d] sgId=%s sgTypecode=%s | 데이터 없음\n",
#                     cnt, total_combo, sgid, sgtc))
#         next
#       }
#       
#       total_pages <- ceiling(total / 100)
#       temp <- res$response$body$items[[1]]
#       
#       if (total_pages > 1) {
#         for (page in 2:total_pages) {
#           url_p <- paste0(base_url,
#                           "?ServiceKey=", api,
#                           "&sgId=", sgid,
#                           "&sgTypecode=", sgtc,
#                           "&numOfRows=100&pageNo=", page,
#                           "&resultType=json")
#           res_p <- fromJSON(url_p)
#           temp <- rbind(temp, res_p$response$body$items[[1]])
#           Sys.sleep(0.3)
#         }
#       }
#       
#       result_all <- rbind(result_all, temp)
#       cat(sprintf("[%d/%d] sgId=%s sgTypecode=%s | %d건 | 누적: %d행\n",
#                   cnt, total_combo, sgid, sgtc, total, nrow(result_all)))
#       
#     }, error = function(e) {
#       cat(sprintf("[%d/%d] sgId=%s sgTypecode=%s | 오류: %s\n",
#                   cnt, total_combo, sgid, sgtc, e$message))
#       failed_result <<- rbind(failed_result, data.frame(
#         sgId = sgid, sgTypecode = sgtc, 오류 = e$message
#       ))
#     })
#     
#     Sys.sleep(0.3)
#   }
# }
# 
# saveRDS(result_all, "총선 개표 결과_2008.rds") 
# write_dta(result_all, "총선 개표 결과_2008.dta")
###########################################################################
##### Frame 3 '/Users/ihuila/Desktop/data/master thesis/raw/Donor'
# source: openwatch 

# 데이터1: 정치인 후원금 총액 내역 (엑셀로 다운)
# https://openwatch.kr/api/political-contributions/totals

# 1.1. 국회의원 선거 
# 다운완료 
# 1.2. 대통령 선거 
# 지역정보 없어서, 유효하지 않음 

# 데이터2: 정치인 고액후원자 명단 (엑셀로 다운)
# https://openwatch.kr/api/political-contributions

# 2.1. 국회의원 선거
# 지금 데이터 막혀있음 

# 2.2. 대통령 선거 
# 다운완료 
##########################################################################