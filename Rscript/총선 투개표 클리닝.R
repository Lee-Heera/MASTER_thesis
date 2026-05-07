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
library(tidyverse)

getwd()
setwd("/Users/ihuila/Desktop/data/master thesis/aftercongwin")
#############################원자료 불러오기#################################
congturn_raw <- readRDS("/Users/ihuila/Desktop/data/master thesis/raw/CongWin/총선 투표 결과.rds") # 시군구 단위 
congwin_raw <- readRDS("/Users/ihuila/Desktop/data/master thesis/raw/CongWin/총선 개표 결과.rds") # 선거구 단위 
eledis_raw <- readRDS("/Users/ihuila/Desktop/data/master thesis/raw/CongWin/총선 선거구별 선거인수 정보.rds") # 선거구 단위 
emd_raw <- readRDS("/Users/ihuila/Desktop/data/master thesis/raw/CongWin/총선 읍면동별 선거인수 정보.rds") # 읍면동 단위 
############################# 원자료 클리닝  ######################
# 데이터 보기 
View(congturn_raw) # 1992년도부터 선거부터 있음 
View(congwin_raw) # 1992~
View(eledis_raw) # 2008~
View(emd_raw) # 2008~ 

# 1) 선거연도 통일 
# 2) 숫자인 변수들은 numeric으로 형태 변환 
# 3) 쓸모없는 변수 제거

# 1. 투표 결과
# sgID, sgTypecode, sdName, wiwName, totSunsu, psSunsu, psEtcSunsu, totTusu, psTusu, psEtcTusu, turnout, vroder 
congturn_raw <- congturn_raw %>% 
  filter(sgId >= "20080409") %>%
  mutate(across(c(totSunsu, psSunsu, psEtcSunsu, totTusu, psTusu, psEtcTusu), as.numeric))


# 2. 개표 결과
# 주요 변수: sgID, sgTypecode, sggName, sdName, wiwName, sunsu, tuu, yutusu, gigwonsu 
congwin_raw <- congwin_raw %>%
  filter(sgId >= "20080409") %>%
  mutate(across(c(sunsu, tusu, yutusu, mutusu, gigwonsu, starts_with("dugsu")), as.numeric))


# 3. 선거구별 선거인수
# sgId, sdName, sggName, wiwName, emdCount, tpgCount(투표구 수)
# ppltCnt (인구수, 선거인명부 작성일기준 현재)
# cfmtnElcnt (확정선거인수 합계)
# cfmtnManElcnt(확정선거인수 남성)
# cfmtnFmlElcnt	(확정선거인수 여성)
eledis_raw <- eledis_raw %>%
  filter(sgId >= "20080409") %>%
  mutate(across(c(ppltCnt, cfmtnElcnt, cfmtnManElcnt, cfmtnFmlElcnt), as.numeric))

eledis_raw <- eledis_raw %>% select(sgId, sdName, wiwName, sggName, emdCount, tpgCount, ppltCnt, cfmtnElcnt, cfmtnManElcnt, cfmtnFmlElcnt)

# 4. 읍면동별 선거인수
# sgId, sdName, wiwName, emdCount, tpgCount(투표구 수) // 읍면동 자료에는 sggName 이 없음 
# 추가: emdName 
# ppltCnt (인구수, 선거인명부 작성일기준 현재)
# cfmtnElcnt (확정선거인수 합계)
# cfmtnManElcnt(확정선거인수 남성)
# cfmtnFmlElcnt	(확정선거인수 여성)
emd_raw <- emd_raw %>%
  filter(sgId >= "20080409") %>%
  mutate(across(c(ppltCnt, cfmtnElcnt, cfmtnManElcnt, cfmtnFmlElcnt), as.numeric))

emd_raw <- emd_raw %>% select(sgId, sdName, wiwName, emdName,tpgCount, ppltCnt, cfmtnElcnt, cfmtnManElcnt, cfmtnFmlElcnt)

saveRDS(congturn_raw, "총선 투표 결과_2008.rds")
saveRDS(congwin_raw, "총선 개표 결과_2008.rds")
saveRDS(eledis_raw, "선거구별 선거인수_2008.rds")
saveRDS(emd_raw, "읍면동별 선거인수_2008.rds")
