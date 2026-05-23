#################### W-NOMINATE Figure 생성 ####################
rm(list = ls())

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

# polarity_2d <- list(
#   "20" = c("SLW27496", "YBM9779M"), #20대: 나경원, 김한표 
#   "21" = c("8SV6917G", "LH97552Q"), #21대: 주호영, 김도읍 
#   "22" = c("GDG1847Z", "CNW5754J")  #22대: 권성동, 송석준
# )


# ── 경로 설정 ──────────────────────────────────────────────────
data_dir <- "/Users/ihuila/Research/MASTER_thesis/Data interim/국회_본회의표결"
fig_dir  <- "/Users/ihuila/Research/MASTER_thesis/Output/figure"
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

# ── 데이터 로드 ────────────────────────────────────────────────
coords_all    <- readRDS(file.path(data_dir, "20-22대국회_wnominate_1차원.rds"))
coords_all_2d <- readRDS(file.path(data_dir, "20-22대국회_wnominate_2차원.rds"))

# ── 폰트 ───────────────────────────────────────────────────────
font_add("AppleGothic",
         regular = "/System/Library/Fonts/Supplemental/AppleGothic.ttf")
showtext_auto()

# ── 공통 설정 ──────────────────────────────────────────────────
age_labels <- c("20" = "20th Assembly", "21" = "21th Assembly", "22" = "22th Assembly")

group_colors <- c(
  "Democratic Party of Korea (Progressive major party)" = "#1A6FC4",
  "People Power Party (Conservative major party)"       = "#D42828",
  "Conservative minor parties"                          = "#7D3C98",
  "Progressive minor parties"                           = "#D4AC0D",
  "Independent"                                         = "#7F8C8D",
  "The third party"                                     = "#2ECC71"
)

# 거대양당만 필터링한 데이터
major_groups <- c(
  "Democratic Party of Korea (Progressive major party)",
  "People Power Party (Conservative major party)"
)
d1_major <- coords_all    %>% filter(PARTY_GROUP %in% major_groups)
d2_major <- coords_all_2d %>% filter(PARTY_GROUP %in% major_groups)

# 전체 정당 (NA 제외)
d1_all <- coords_all    %>% filter(!is.na(PARTY_GROUP))
d2_all <- coords_all_2d %>% filter(!is.na(PARTY_GROUP))

###############################################################################
# Fig 1. 1D Density — 거대양당
###############################################################################
d1_density <- d1_major %>%
  mutate(AGE_chr = factor(AGE_chr, labels = age_labels))

p <- ggplot(d1_density, aes(x = coord1D, fill = PARTY_GROUP, color = PARTY_GROUP)) +
  geom_density(alpha = 0.35, linewidth = 0.7) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray40", linewidth = 0.4) +
  facet_wrap(~AGE_chr, ncol = 1) +
  scale_fill_manual(values  = group_colors) +
  scale_color_manual(values = group_colors) +
  scale_x_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
  labs(x = "W-NOMINATE Score  ← Progressive · Conservative →",
       y = "Density", fill = NULL, color = NULL,
       title = "Ideal Point Distribution (1st Dimension)") +
  theme_bw(base_size = 12) +
  theme(strip.background = element_rect(fill = "gray95"),
        legend.position  = "bottom")
ggsave(file.path(fig_dir, "fig1_1d_density.pdf"), p, width = 7, height = 7)

###############################################################################
# Fig 2. 1D Strip — 거대양당
###############################################################################
set.seed(42)
d1_strip <- d1_major %>%
  mutate(AGE_chr = factor(AGE_chr, levels = c("20","21","22"), labels = age_labels))

p <- ggplot(d1_strip, aes(x = coord1D, y = 0, color = PARTY_GROUP)) +
  geom_jitter(height = 0.4, size = 1.5, alpha = 0.7, width = 0) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray40", linewidth = 0.4) +
  facet_wrap(~AGE_chr, ncol = 1) +
  scale_color_manual(values = group_colors) +
  scale_x_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
  labs(x = "W-NOMINATE Score  ← Progressive · Conservative →",
       y = NULL, color = NULL,
       title = "Ideal Point Distribution (1st Dimension, Strip)") +
  theme_bw(base_size = 12) +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(),
        panel.grid.major.y = element_blank(),
        strip.background   = element_rect(fill = "gray95"),
        legend.position    = "bottom") +
  guides(color = guide_legend(nrow = 1, override.aes = list(size = 3)))
ggsave(file.path(fig_dir, "fig2_1d_strip.pdf"), p, width = 8, height = 6)

###############################################################################
# Fig 3. 1D Density — 전체 정당 (무소속 제외)
###############################################################################
d1_all_nd <- d1_all %>%
  filter(PARTY_GROUP != "Independent") %>%
  mutate(AGE_chr = factor(AGE_chr, labels = age_labels))

p <- ggplot(d1_all_nd, aes(x = coord1D, fill = PARTY_GROUP, color = PARTY_GROUP)) +
  geom_density(alpha = 0.35, linewidth = 0.7) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray40", linewidth = 0.4) +
  facet_wrap(~AGE_chr, ncol = 1) +
  scale_fill_manual(values  = group_colors) +
  scale_color_manual(values = group_colors) +
  scale_x_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
  labs(x = "W-NOMINATE Score  ← Progressive · Conservative →",
       y = "Density", fill = NULL, color = NULL,
       title = "Ideal Point Distribution — All Parties (1st Dimension)") +
  theme_bw(base_size = 12) +
  theme(strip.background = element_rect(fill = "gray95"),
        legend.position  = "bottom")
ggsave(file.path(fig_dir, "fig3_1d_density_all.pdf"), p, width = 7, height = 7)

###############################################################################
# Fig 4. 2D Scatter — 대수별 개별 (거대양당)
###############################################################################

# 20대
d2_20 <- d2_major %>% filter(AGE_chr == "20")
ext_20 <- d2_20 %>% mutate(dist = sqrt(coord1D^2 + coord2D^2)) %>% slice_max(dist, n = 15)

p <- ggplot(d2_20, aes(x = coord1D, y = coord2D, color = PARTY_GROUP)) +
  geom_point(size = 2, alpha = 0.7) +
  geom_label_repel(data = ext_20, aes(label = HG_NM),
                   size = 2.5, max.overlaps = 20, fill = "white", label.padding = 0.15) +
  geom_hline(yintercept = 0, color = "gray60", linewidth = 0.3, linetype = "dashed") +
  geom_vline(xintercept = 0, color = "gray60", linewidth = 0.3, linetype = "dashed") +
  scale_color_manual(values = group_colors) +
  scale_x_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
  scale_y_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
  labs(x = "1st Dimension", y = "2nd Dimension", color = NULL,
       title = "20th National Assembly — W-NOMINATE (2D)",
       subtitle = "Top 15 legislators by distance from origin labeled") +
  theme_bw(base_size = 13) +
  theme(legend.position = "bottom", aspect.ratio = 1)
ggsave(file.path(fig_dir, "fig4a_2d_20대.pdf"), p, width = 7, height = 7)

# 21대
d2_21 <- d2_major %>% filter(AGE_chr == "21")
ext_21 <- d2_21 %>% mutate(dist = sqrt(coord1D^2 + coord2D^2)) %>% slice_max(dist, n = 15)

p <- ggplot(d2_21, aes(x = coord1D, y = coord2D, color = PARTY_GROUP)) +
  geom_point(size = 2, alpha = 0.7) +
  geom_label_repel(data = ext_21, aes(label = HG_NM),
                   size = 2.5, max.overlaps = 20, fill = "white", label.padding = 0.15) +
  geom_hline(yintercept = 0, color = "gray60", linewidth = 0.3, linetype = "dashed") +
  geom_vline(xintercept = 0, color = "gray60", linewidth = 0.3, linetype = "dashed") +
  scale_color_manual(values = group_colors) +
  scale_x_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
  scale_y_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
  labs(x = "1st Dimension", y = "2nd Dimension", color = NULL,
       title = "21st National Assembly — W-NOMINATE (2D)",
       subtitle = "Top 15 legislators by distance from origin labeled") +
  theme_bw(base_size = 13) +
  theme(legend.position = "bottom", aspect.ratio = 1)
ggsave(file.path(fig_dir, "fig4b_2d_21대.pdf"), p, width = 7, height = 7)

# 22대
d2_22 <- d2_major %>% filter(AGE_chr == "22")
ext_22 <- d2_22 %>% mutate(dist = sqrt(coord1D^2 + coord2D^2)) %>% slice_max(dist, n = 15)

p <- ggplot(d2_22, aes(x = coord1D, y = coord2D, color = PARTY_GROUP)) +
  geom_point(size = 2, alpha = 0.7) +
  geom_label_repel(data = ext_22, aes(label = HG_NM),
                   size = 2.5, max.overlaps = 20, fill = "white", label.padding = 0.15) +
  geom_hline(yintercept = 0, color = "gray60", linewidth = 0.3, linetype = "dashed") +
  geom_vline(xintercept = 0, color = "gray60", linewidth = 0.3, linetype = "dashed") +
  scale_color_manual(values = group_colors) +
  scale_x_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
  scale_y_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
  labs(x = "1st Dimension", y = "2nd Dimension", color = NULL,
       title = "22nd National Assembly — W-NOMINATE (2D)",
       subtitle = "Top 15 legislators by distance from origin labeled") +
  theme_bw(base_size = 13) +
  theme(legend.position = "bottom", aspect.ratio = 1)
ggsave(file.path(fig_dir, "fig4c_2d_22대.pdf"), p, width = 7, height = 7)

###############################################################################
# Fig 5. 2D Facet — 3개 대수 한 장 (거대양당)
###############################################################################
d2_f <- d2_major %>%
  mutate(AGE_chr = factor(AGE_chr, levels = c("20","21","22"), labels = age_labels))

p <- ggplot(d2_f, aes(x = coord1D, y = coord2D, color = PARTY_GROUP)) +
  geom_point(size = 1.8, alpha = 0.75) +
  geom_hline(yintercept = 0, color = "gray70", linewidth = 0.3) +
  geom_vline(xintercept = 0, color = "gray70", linewidth = 0.3) +
  facet_wrap(~AGE_chr, ncol = 3) +
  scale_color_manual(values = group_colors) +
  scale_x_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
  scale_y_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
  labs(x = "1st Dimension", y = "2nd Dimension", color = NULL,
       title = "W-NOMINATE Ideal Points (2nd Dimension)") +
  theme_bw(base_size = 12) +
  theme(strip.background = element_rect(fill = "gray95"),
        legend.position  = "bottom", aspect.ratio = 1)
ggsave(file.path(fig_dir, "fig5_2d_facet.pdf"), p, width = 15, height = 6)

cat("Figure 저장 완료:", fig_dir, "\n")
