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
library(ggplot2)
library(showtext)
library(haven)

# ── 경로 설정 ──────────────────────────────────────────────────
data_dir <- "/Users/ihuila/Research/MASTER_thesis/Data interim/국회_본회의표결"
fig_dir  <- "/Users/ihuila/Research/MASTER_thesis/Output/figure"
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

# ── 데이터 로드 ────────────────────────────────────────────────
coords_all    <- readRDS(file.path(data_dir, "20-22대국회_wnominate_1차원.rds"))
coords_all_2d <- readRDS(file.path(data_dir, "20-22대국회_wnominate_2차원.rds"))

# ── W-NOMINATE 객체 로드 (기본 plot용) ─────────────────────────
# 1D 결과
wnominate_20_1d <- readRDS(file.path(data_dir, "20대국회_wnominate_1d_원자료.rds"))
wnominate_21_1d <- readRDS(file.path(data_dir, "21대국회_wnominate_1d_원자료.rds"))
wnominate_22_1d <- readRDS(file.path(data_dir, "22대국회_wnominate_1d_원자료.rds"))

# 2D 결과
wnominate_20_2d <- readRDS(file.path(data_dir, "20대국회_wnominate_2d_원자료.rds"))
wnominate_21_2d <- readRDS(file.path(data_dir, "21대국회_wnominate_2d_원자료.rds"))
wnominate_22_2d <- readRDS(file.path(data_dir, "22대국회_wnominate_2d_원자료.rds"))

# ── 폰트 ───────────────────────────────────────────────────────
font_add("AppleGothic", regular = "/System/Library/Fonts/Supplemental/AppleGothic.ttf")
showtext_auto()

# ── 공통 매핑 ──────────────────────────────────────────────────
age_lv  <- c("20", "21", "22")
age_lab <- c("20th Assembly", "21st Assembly", "22nd Assembly")
to_fct  <- function(x) factor(x, levels = age_lv, labels = age_lab)

group_colors <- c(
  "Democratic Party of Korea (Progressive major party)" = "#1A6FC4",
  "People Power Party (Conservative major party)"       = "#D42828",
  "Conservative minor parties"                          = "#7D3C98",
  "Progressive minor parties"                           = "#D4AC0D",
  "Independent"                                         = "#7F8C8D",
  "The third party"                                     = "#2ECC71"
)

linetype_map <- c(
  "Democratic Party of Korea (Progressive major party)" = "solid",
  "People Power Party (Conservative major party)"       = "dashed",
  "Conservative minor parties"                          = "dotted",
  "Progressive minor parties"                           = "dotdash",
  "Independent"                                         = "longdash",
  "The third party"                                     = "twodash"
)

shape_map <- c(
  "Democratic Party of Korea (Progressive major party)" = 16,
  "People Power Party (Conservative major party)"       = 17,
  "Conservative minor parties"                          = 15,
  "Progressive minor parties"                           = 18,
  "Independent"                                         = 8,
  "The third party"                                     = 3
)

# ── 데이터 준비 ────────────────────────────────────────────────
major_groups <- c(
  "Democratic Party of Korea (Progressive major party)",
  "People Power Party (Conservative major party)"
)

# 정당 순서 (범례용)
party_order <- c(
  "Democratic Party of Korea (Progressive major party)",
  "People Power Party (Conservative major party)",
  "Progressive minor parties",
  "Conservative minor parties",
  "The third party",
  "Independent"
)

d1_major <- coords_all    %>% filter(PARTY_GROUP %in% major_groups) %>% mutate(AGE_f = to_fct(AGE_chr))
d2_major <- coords_all_2d %>% filter(PARTY_GROUP %in% major_groups) %>% mutate(AGE_f = to_fct(AGE_chr))
d1_all   <- coords_all    %>% filter(!is.na(PARTY_GROUP))            %>% mutate(AGE_f = to_fct(AGE_chr))
d2_all   <- coords_all_2d %>% filter(!is.na(PARTY_GROUP))            %>% mutate(AGE_f = to_fct(AGE_chr))

# ── 공통 theme ──────────────────────────────────────────────────
th <- theme_bw(base_size = 12) +
  theme(
    strip.background  = element_rect(fill = "gray95"),
    legend.position   = "bottom",
    legend.margin     = margin(t = 4, unit = "pt"),
    legend.text       = element_text(size = 9),
    plot.margin       = margin(5, 8, 20, 8, "pt")
  )

x_lab_1d <- "W-NOMINATE Score\n← Progressive · Conservative →"


###############################################################################
# Fig 0. W-NOMINATE 기본 plot() - 타이틀/범례 제거, 거대양당만
###############################################################################

# W-NOMINATE 객체에서 거대양당만 필터링하는 함수
filter_wnominate_major_only <- function(wnom_obj, party_data) {
  
  # 거대양당 인덱스 찾기
  keep_idx <- which(party_data$PARTY_GROUP %in% major_groups)
  
  # 새로운 객체 생성 (원본 복사)
  filtered_obj <- wnom_obj
  
  # legislators 필터링
  filtered_obj$legislators <- wnom_obj$legislators[keep_idx, ]
  
  # votes 행렬도 필터링
  if (!is.null(wnom_obj$rollcalls)) {
    if (is.matrix(wnom_obj$rollcalls$votes)) {
      filtered_obj$rollcalls$votes <- wnom_obj$rollcalls$votes[, keep_idx]
    }
    if (!is.null(wnom_obj$rollcalls$legis.data)) {
      filtered_obj$rollcalls$legis.data <- wnom_obj$rollcalls$legis.data[keep_idx, ]
    }
  }
  
  # 색상 벡터 생성 (필터링된 데이터 기준)
  filtered_party_data <- party_data[keep_idx, ]
  colors <- sapply(filtered_party_data$PARTY_GROUP, function(x) group_colors[x])
  
  return(list(obj = filtered_obj, colors = colors))
}

# W-NOMINATE plot 래퍼 (범례/타이틀 제거)
plot_wnominate_clean <- function(wnom_obj, party_data) {
  
  filtered <- filter_wnominate_major_only(wnom_obj, party_data)
  
  if (filtered$obj$dimensions == 1) {
    # 1D: 좌표 + scree plot
    par(mfrow = c(1, 2))
    plot.coords(filtered$obj,
                plotBy     = "party",
                Legend     = FALSE,
                main.title = "")
    plot.scree(filtered$obj)
    
  } else {
    # 2D: 좌표 + angles + scree + cutlines
    par(mfrow = c(2, 2))
    plot.coords(filtered$obj,
                plotBy     = "party",
                Legend     = FALSE,
                main.title = "")
    plot.angles(filtered$obj)
    plot.scree(filtered$obj)
    plot.cutlines(filtered$obj, lwd = 1)
  }
}
###############################################################################
# Fig 0 저장 - 1D (거대양당만)
###############################################################################

pdf(file.path(fig_dir, "fig0a_wnominate_20th_1d_major.pdf"), width = 12, height = 10)
plot_wnominate_clean(wnominate_20_1d, 
                     coords_all %>% filter(AGE_chr == "20"))
dev.off()

pdf(file.path(fig_dir, "fig0b_wnominate_21st_1d_major.pdf"), width = 12, height = 10)
plot_wnominate_clean(wnominate_21_1d,
                     coords_all %>% filter(AGE_chr == "21"))
dev.off()

pdf(file.path(fig_dir, "fig0c_wnominate_22nd_1d_major.pdf"), width = 12, height = 10)
plot_wnominate_clean(wnominate_22_1d,
                     coords_all %>% filter(AGE_chr == "22"))
dev.off()

###############################################################################
# Fig 0 저장 - 2D (거대양당만)
###############################################################################

pdf(file.path(fig_dir, "fig0g_wnominate_20th_2d_major.pdf"), width = 12, height = 10)
plot_wnominate_clean(wnominate_20_2d,
                     coords_all_2d %>% filter(AGE_chr == "20"))
dev.off()

pdf(file.path(fig_dir, "fig0h_wnominate_21st_2d_major.pdf"), width = 12, height = 10)
plot_wnominate_clean(wnominate_21_2d,
                     coords_all_2d %>% filter(AGE_chr == "21"))
dev.off()

pdf(file.path(fig_dir, "fig0i_wnominate_22nd_2d_major.pdf"), width = 12, height = 10)
plot_wnominate_clean(wnominate_22_2d,
                     coords_all_2d %>% filter(AGE_chr == "22"))
dev.off()

cat("W-NOMINATE 기본 진단 플롯 저장 완료 (거대양당만, 범례/타이틀 제거)\n")
cat("  - 1D: 3개 (fig0a-c)\n")
cat("  - 2D: 3개 (fig0g-i)\n")
###############################################################################
# Fig 1-8, W: 이전 코드 그대로 (ggplot 그래프들)
###############################################################################

# --- color 버전 ---
p1_color <- ggplot(d1_major, aes(x = coord1D, fill = PARTY_GROUP, color = PARTY_GROUP)) +
  geom_density(alpha = 0.35, linewidth = 0.8) +
  geom_vline(xintercept = 0, color = "gray50", linewidth = 0.4) +
  scale_fill_manual(values  = group_colors, breaks = major_groups) +
  scale_color_manual(values = group_colors, breaks = major_groups) +
  scale_x_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
  labs(x = x_lab_1d, y = "Density", fill = NULL, color = NULL) +
  th +
  guides(fill = guide_legend(nrow = 2), color = guide_legend(nrow = 2))

ggsave(file.path(fig_dir, "fig1a_1d_density_major_color.pdf"),
       p1_color + facet_wrap(~AGE_f, ncol = 1), width = 7, height = 11, 
       useDingbats = FALSE)

# --- linetype 버전 ---
p1_lty <- ggplot(d1_major, aes(x = coord1D, linetype = PARTY_GROUP)) +
  geom_density(color = "black", fill = NA, linewidth = 0.8) +
  geom_vline(xintercept = 0, color = "gray50", linewidth = 0.4) +
  scale_linetype_manual(values = linetype_map, breaks = major_groups) +
  scale_x_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
  labs(x = x_lab_1d, y = "Density", linetype = NULL) +
  th +
  guides(linetype = guide_legend(nrow = 2))

ggsave(file.path(fig_dir, "fig1b_1d_density_major_linetype.pdf"),
       p1_lty + facet_wrap(~AGE_f, ncol = 1), width = 7, height = 11, 
       useDingbats = FALSE)

# 전체정당 - factor 순서 지정
d1_all$PARTY_GROUP <- factor(d1_all$PARTY_GROUP, levels = party_order)
d2_all$PARTY_GROUP <- factor(d2_all$PARTY_GROUP, levels = party_order)

p2 <- ggplot(d1_all, aes(x = coord1D, linetype = PARTY_GROUP)) +
  geom_density(color = "black", fill = NA, linewidth = 0.8) +
  geom_vline(xintercept = 0, color = "gray50", linewidth = 0.4) +
  scale_linetype_manual(values = linetype_map, breaks = party_order) +
  scale_x_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
  labs(x = x_lab_1d, y = "Density", linetype = NULL) +
  th +
  guides(linetype = guide_legend(nrow = 3))

ggsave(file.path(fig_dir, "fig2_1d_density_all.pdf"),
       p2 + facet_wrap(~AGE_f, ncol = 1), width = 7, height = 12, 
       useDingbats = FALSE)

p3 <- ggplot(d1_major, aes(x = coord1D, y = 0, color = PARTY_GROUP, shape = PARTY_GROUP)) +
  geom_jitter(height = 0.4, size = 1.5, alpha = 0.7, width = 0) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray40", linewidth = 0.4) +
  scale_color_manual(values = group_colors, breaks = major_groups) +
  scale_shape_manual(values = shape_map, breaks = major_groups) +
  scale_x_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
  labs(x = x_lab_1d, y = NULL, color = NULL, shape = NULL) +
  th +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(),
        panel.grid.major.y = element_blank()) +
  guides(color = guide_legend(nrow = 2, override.aes = list(size = 3)))

set.seed(42)
ggsave(file.path(fig_dir, "fig3_1d_strip_major.pdf"),
       p3 + facet_wrap(~AGE_f, ncol = 1), width = 9, height = 11, 
       useDingbats = FALSE)

p4 <- ggplot(d1_all, aes(x = coord1D, y = 0, color = PARTY_GROUP, shape = PARTY_GROUP)) +
  geom_jitter(height = 0.4, size = 1.5, alpha = 0.7, width = 0) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray40", linewidth = 0.4) +
  scale_color_manual(values = group_colors, breaks = party_order) +
  scale_shape_manual(values = shape_map, breaks = party_order) +
  scale_x_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
  labs(x = x_lab_1d, y = NULL, color = NULL, shape = NULL) +
  th +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(),
        panel.grid.major.y = element_blank()) +
  guides(color = guide_legend(nrow = 3, override.aes = list(size = 3)))

set.seed(42)
ggsave(file.path(fig_dir, "fig4_1d_strip_all.pdf"),
       p4 + facet_wrap(~AGE_f, ncol = 1), width = 9, height = 12, 
       useDingbats = FALSE)

age_let <- c("20" = "a", "21" = "b", "22" = "c")
for (a in age_lv) {
  d <- d2_major %>% filter(AGE_chr == a)
  p <- ggplot(d, aes(x = coord1D, y = coord2D, color = PARTY_GROUP, shape = PARTY_GROUP)) +
    geom_point(size = 2, alpha = 0.7) +
    geom_hline(yintercept = 0, color = "gray60", linewidth = 0.3, linetype = "dashed") +
    geom_vline(xintercept = 0, color = "gray60", linewidth = 0.3, linetype = "dashed") +
    scale_color_manual(values = group_colors, breaks = major_groups) +
    scale_shape_manual(values = shape_map, breaks = major_groups) +
    scale_x_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
    scale_y_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
    labs(x = "1st Dimension", y = "2nd Dimension", color = NULL, shape = NULL) +
    th + theme(aspect.ratio = 1) +
    guides(color = guide_legend(nrow = 2, override.aes = list(size = 3)))
  ggsave(file.path(fig_dir, sprintf("fig5%s_2d_%s대_major.pdf", age_let[a], a)),
         p, width = 7, height = 8, 
         useDingbats = FALSE)
}

for (a in age_lv) {
  d <- d2_all %>% filter(AGE_chr == a)
  p <- ggplot(d, aes(x = coord1D, y = coord2D, color = PARTY_GROUP, shape = PARTY_GROUP)) +
    geom_point(size = 2, alpha = 0.7) +
    geom_hline(yintercept = 0, color = "gray60", linewidth = 0.3, linetype = "dashed") +
    geom_vline(xintercept = 0, color = "gray60", linewidth = 0.3, linetype = "dashed") +
    scale_color_manual(values = group_colors, breaks = party_order) +
    scale_shape_manual(values = shape_map, breaks = party_order) +
    scale_x_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
    scale_y_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
    labs(x = "1st Dimension", y = "2nd Dimension", color = NULL, shape = NULL) +
    th + theme(aspect.ratio = 1) +
    guides(color = guide_legend(nrow = 2, override.aes = list(size = 3)))
  ggsave(file.path(fig_dir, sprintf("fig6%s_2d_%s대_all.pdf", age_let[a], a)),
         p, width = 7, height = 9, 
         useDingbats = FALSE)
}

p7 <- ggplot(d2_major, aes(x = coord1D, y = coord2D, color = PARTY_GROUP, shape = PARTY_GROUP)) +
  geom_point(size = 1.8, alpha = 0.75) +
  geom_hline(yintercept = 0, color = "gray70", linewidth = 0.3) +
  geom_vline(xintercept = 0, color = "gray70", linewidth = 0.3) +
  facet_wrap(~AGE_f, ncol = 1) +
  scale_color_manual(values = group_colors, breaks = major_groups) +
  scale_shape_manual(values = shape_map, breaks = major_groups) +
  scale_x_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
  scale_y_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
  labs(x = "1st Dimension", y = "2nd Dimension", color = NULL, shape = NULL) +
  th + theme(aspect.ratio = 1) +
  guides(color = guide_legend(nrow = 2, override.aes = list(size = 3)))
ggsave(file.path(fig_dir, "fig7_2d_facet_major.pdf"), p7, width = 8, height = 18, 
       useDingbats = FALSE)

p8 <- ggplot(d2_all, aes(x = coord1D, y = coord2D, color = PARTY_GROUP, shape = PARTY_GROUP)) +
  geom_point(size = 1.8, alpha = 0.75) +
  geom_hline(yintercept = 0, color = "gray70", linewidth = 0.3) +
  geom_vline(xintercept = 0, color = "gray70", linewidth = 0.3) +
  facet_wrap(~AGE_f, ncol = 1) +
  scale_color_manual(values = group_colors, breaks = party_order) +
  scale_shape_manual(values = shape_map, breaks = party_order) +
  scale_x_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
  scale_y_continuous(limits = c(-1, 1), breaks = seq(-1, 1, 0.5)) +
  labs(x = "1st Dimension", y = "2nd Dimension", color = NULL, shape = NULL) +
  th + theme(aspect.ratio = 1) +
  guides(color = guide_legend(nrow = 2, override.aes = list(size = 3)))
ggsave(file.path(fig_dir, "fig8_2d_facet_all.pdf"), p8, width = 8, height = 20, 
       useDingbats = FALSE)

theta     <- seq(0, 2 * pi, length.out = 300)
circle_df <- data.frame(x = cos(theta), y = sin(theta))

for (a in age_lv) {
  d <- d2_all %>% filter(AGE_chr == a)
  p <- ggplot(d, aes(x = coord1D, y = coord2D, color = PARTY_GROUP, shape = PARTY_GROUP)) +
    geom_path(data = circle_df, aes(x = x, y = y),
              color = "black", linewidth = 0.5, inherit.aes = FALSE) +
    geom_point(size = 1.8, alpha = 0.85) +
    scale_color_manual(values = group_colors, breaks = party_order) +
    scale_shape_manual(values = shape_map, breaks = party_order) +
    coord_fixed(xlim = c(-1.1, 1.1), ylim = c(-1.1, 1.1)) +
    labs(x = "First Dimension", y = "Second Dimension", color = NULL, shape = NULL) +
    th +
    guides(color = guide_legend(nrow = 2, override.aes = list(size = 3)))
  ggsave(file.path(fig_dir, sprintf("figW_%s대_wnominate_coords.pdf", a)),
         p, width = 7, height = 8, 
         useDingbats = FALSE)
}

cat("\n전체 Figure 저장 완료:", fig_dir, "\n")

###############################################################################
# JPG 저장 - Overleaf용 (글자 크기 적절히 조정)
###############################################################################

# save_jpg <- function(plot_obj, filename, width, height, dpi = 300) {
#   ggsave(
#     filename = file.path(fig_dir, filename),
#     plot     = plot_obj,
#     width    = width,
#     height   = height,
#     dpi      = dpi,
#     device   = "jpeg",
#     quality  = 90,
#     units    = "in"
#   )
# }
# 
# # 글자 키우는 theme 오버라이드
# th_jpg <- th + theme(
#   text         = element_text(size = 20),
#   axis.title   = element_text(size = 16),
#   axis.text    = element_text(size = 16),
#   strip.text   = element_text(size = 16),
#   legend.text  = element_text(size = 16)
# )
# 
# # ── Fig 1a: 1D density ────────────────────────────────────────
# save_jpg(
#   p1_color + facet_wrap(~AGE_f, ncol = 1) + th_jpg,
#   "fig1a_1d_density_major_color.jpg",
#   width = 5, height = 8     # PDF보다 작게 → 텍스트 상대적으로 커짐
# )
# 
# # ── Fig 3: 1D strip ───────────────────────────────────────────
# set.seed(42)
# save_jpg(
#   p3 + facet_wrap(~AGE_f, ncol = 1) + th_jpg,
#   "fig3_1d_strip_major.jpg",
#   width = 6, height = 8
# )
# 
# # ── Fig 7: 2D facet ───────────────────────────────────────────
# save_jpg(
#   p7 + th_jpg,
#   "fig7_2d_facet_major.jpg",
#   width = 5, height = 13
# )
# 
# # ── Fig 0a-c: 기본 plot (1D, appendix) ───────────────────────
# save_base_plot_jpg <- function(plot_fn, filename,
#                                width = 8, height = 7, dpi = 300) {
#   jpeg(
#     filename = file.path(fig_dir, filename),
#     width    = width * dpi,
#     height   = height * dpi,
#     res      = dpi,
#     quality  = 90,
#     units    = "px",
#     pointsize = 18    # base plot 글자 크기
#   )
#   plot_fn()
#   dev.off()
# }
# 
# save_base_plot_jpg(
#   function() plot_wnominate_clean(wnominate_20_1d,
#                                   coords_all %>% filter(AGE_chr == "20")),
#   "fig0a_wnominate_20th_1d_major.jpg"
# )
# save_base_plot_jpg(
#   function() plot_wnominate_clean(wnominate_21_1d,
#                                   coords_all %>% filter(AGE_chr == "21")),
#   "fig0b_wnominate_21st_1d_major.jpg"
# )
# save_base_plot_jpg(
#   function() plot_wnominate_clean(wnominate_22_1d,
#                                   coords_all %>% filter(AGE_chr == "22")),
#   "fig0c_wnominate_22nd_1d_major.jpg"
# )
# 
# # ── Fig 0g-i: 기본 plot (2D, appendix) ───────────────────────
# save_base_plot_jpg(
#   function() plot_wnominate_clean(wnominate_20_2d,
#                                   coords_all_2d %>% filter(AGE_chr == "20")),
#   "fig0g_wnominate_20th_2d_major.jpg"
# )
# save_base_plot_jpg(
#   function() plot_wnominate_clean(wnominate_21_2d,
#                                   coords_all_2d %>% filter(AGE_chr == "21")),
#   "fig0h_wnominate_21st_2d_major.jpg"
# )
# save_base_plot_jpg(
#   function() plot_wnominate_clean(wnominate_22_2d,
#                                   coords_all_2d %>% filter(AGE_chr == "22")),
#   "fig0i_wnominate_22nd_2d_major.jpg"
# )
# 
# cat("JPG 저장 완료\n")