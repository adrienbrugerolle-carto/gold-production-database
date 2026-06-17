# ============================================================================
# scripts/4_detect_gold_rush.R
# Détection des ruées (pics aigus) ET des booms miniers (plateaux)
# ============================================================================

source("scripts/0_setup.R")
library(zoo)
library(plotly)
library(htmlwidgets)

MAX_YEAR <- 1950

# Paramètres pour les ruées (pics aigus)
rush_params <- list(
  country = list(threshold = 2, multiplier = 2.5, decline = 40, window = 5),
  state = list(threshold = 1, multiplier = 2, decline = 30, window = 5),
  province = list(threshold = 1, multiplier = 2, decline = 30, window = 5),
  world = list(threshold = 5, multiplier = 2, decline = 40, window = 5)
)

# Paramètres pour les booms miniers (plateaux)
boom_params <- list(
  country = list(min_level = 10, min_duration = 15, decline = 30),
  state = list(min_level = 5, min_duration = 15, decline = 30),
  province = list(min_level = 5, min_duration = 15, decline = 30),
  world = list(min_level = 50, min_duration = 20, decline = 30)
)

WINDOW_YEARS <- 10
MIN_RUSH_DURATION <- 2

cat("=== PARAMETRES ===\n")
cat("Ruées (pics aigus): seuils adaptés par niveau\n")
cat("Booms miniers (plateaux): production >", boom_params$province$min_level, "t/an pendant >", boom_params$province$min_duration, "ans\n")

# Chargement
all_entities <- readRDS("data/processed/gold_production_all_entities.rds") %>%
  filter(year <= MAX_YEAR)

# Interpolation
interpolate_decadal <- function(data) {
  full_years <- tibble(year = seq(min(data$year), max(data$year), by = 1))
  data %>%
    right_join(full_years, by = "year") %>%
    arrange(year) %>%
    mutate(production_tonnes = approx(year, production_tonnes, xout = year, rule = 2)$y,
           entity = first(entity[!is.na(entity)]),
           parent = first(parent[!is.na(parent)]),
           level = first(level[!is.na(level)]))
}

# Détection des ruées (pics aigus)
detect_rush <- function(data, level_name) {
  p <- rush_params[[level_name]]
  if(is.null(p)) return(data.frame())
  
  data_years <- n_distinct(data$year)
  expected_years <- max(data$year) - min(data$year) + 1
  coverage <- data_years / expected_years
  
  if(coverage < 0.3 & expected_years > 50) {
    data <- interpolate_decadal(data)
  }
  
  rush_candidates <- data %>%
    arrange(year) %>%
    mutate(
      mean_before = rollapplyr(production_tonnes, width = WINDOW_YEARS, FUN = mean, fill = NA, align = "right"),
      ratio = production_tonnes / mean_before,
      is_peak = ratio > p$multiplier & production_tonnes > p$threshold & !is.na(ratio)
    ) %>%
    mutate(peak_group = cumsum(!is_peak)) %>%
    group_by(peak_group) %>%
    summarise(
      entity = first(entity),
      parent = first(parent),
      level = first(level),
      start_year = min(year[is_peak == TRUE], na.rm = TRUE),
      end_year = max(year[is_peak == TRUE], na.rm = TRUE),
      peak_year = year[which.max(production_tonnes)],
      peak_production = max(production_tonnes, na.rm = TRUE),
      duration = end_year - start_year + 1,
      type = "Rush (pic aigu)",
      .groups = "drop"
    ) %>%
    filter(!is.infinite(start_year), duration >= MIN_RUSH_DURATION)
  
  if(nrow(rush_candidates) == 0) return(data.frame())
  
  for(i in 1:nrow(rush_candidates)) {
    peak_yr <- rush_candidates$peak_year[i]
    peak_val <- rush_candidates$peak_production[i]
    after_data <- data %>% filter(year == peak_yr + p$window) %>% pull(production_tonnes)
    
    if(length(after_data) > 0 && !is.na(after_data) && after_data > 0) {
      decline <- (peak_val - after_data) / peak_val * 100
      if(decline >= p$decline) {
        rush_candidates$decline_pct[i] <- decline
      } else {
        rush_candidates$type[i] <- NA
      }
    } else {
      rush_candidates$type[i] <- NA
    }
  }
  
  return(rush_candidates %>% filter(!is.na(type)))
}

# Détection des booms miniers (plateaux)
detect_boom <- function(data, level_name) {
  p <- boom_params[[level_name]]
  if(is.null(p)) return(data.frame())
  
  data_years <- n_distinct(data$year)
  expected_years <- max(data$year) - min(data$year) + 1
  coverage <- data_years / expected_years
  
  if(coverage < 0.3 & expected_years > 50) {
    data <- interpolate_decadal(data)
  }
  
  # Identifier les périodes de production élevée soutenue
  data %>%
    arrange(year) %>%
    mutate(high_prod = production_tonnes > p$min_level) %>%
    mutate(high_group = cumsum(!high_prod)) %>%
    group_by(high_group) %>%
    summarise(
      entity = first(entity),
      parent = first(parent),
      level = first(level),
      start_year = min(year[high_prod == TRUE], na.rm = TRUE),
      end_year = max(year[high_prod == TRUE], na.rm = TRUE),
      peak_year = year[which.max(production_tonnes)],
      peak_production = max(production_tonnes, na.rm = TRUE),
      duration = end_year - start_year + 1,
      mean_production = mean(production_tonnes[high_prod == TRUE], na.rm = TRUE),
      type = "Boom minier (plateau)",
      .groups = "drop"
    ) %>%
    filter(!is.infinite(start_year), duration >= p$min_duration) %>%
    # Vérifier le déclin après le plateau
    mutate(decline_pct = NA) %>%
    rowwise() %>%
    mutate(
      after_prod = ifelse(peak_year + 10 <= max(data$year), 
                          mean(data$production_tonnes[data$year >= peak_year + 5 & data$year <= peak_year + 15], na.rm = TRUE),
                          NA),
      decline_pct = ifelse(!is.na(after_prod) && after_prod > 0,
                           (peak_production - after_prod) / peak_production * 100,
                           NA)
    ) %>%
    ungroup()
}

cat("\n--- Detection des ruées et booms miniers ---\n")

# Détection par niveau
gold_rush <- bind_rows(
  all_entities %>% filter(level == "country") %>%
    group_by(level, entity, parent) %>%
    do(detect_rush(., "country")) %>% ungroup(),
  all_entities %>% filter(level == "state") %>%
    group_by(level, entity, parent) %>%
    do(detect_rush(., "state")) %>% ungroup(),
  all_entities %>% filter(level == "province") %>%
    group_by(level, entity, parent) %>%
    do(detect_rush(., "province")) %>% ungroup()
)

gold_boom <- bind_rows(
  all_entities %>% filter(level == "country") %>%
    group_by(level, entity, parent) %>%
    do(detect_boom(., "country")) %>% ungroup(),
  all_entities %>% filter(level == "state") %>%
    group_by(level, entity, parent) %>%
    do(detect_boom(., "state")) %>% ungroup(),
  all_entities %>% filter(level == "province") %>%
    group_by(level, entity, parent) %>%
    do(detect_boom(., "province")) %>% ungroup()
)

# Fusion et ajout des métadonnées
all_events <- bind_rows(gold_rush, gold_boom) %>%
  mutate(continent = case_when(
    parent %in% c("United States", "Canada", "Mexico") ~ "Amérique du Nord",
    parent %in% c("Brazil", "Peru", "Chile", "Ecuador", "Colombia", "Bolivia", "Argentina") ~ "Amérique du Sud",
    parent %in% c("South Africa", "Ghana", "Mali", "Zimbabwe") ~ "Afrique",
    parent %in% c("Australia", "Papua New Guinea") ~ "Océanie",
    parent %in% c("Russia", "Uzbekistan", "Kazakhstan") ~ "Asie",
    TRUE ~ "Autre"
  ))

cat("\n✓ Ruées détectées:", nrow(gold_rush), "\n")
cat("✓ Booms miniers détectés:", nrow(gold_boom), "\n")
cat("✓ Total événements:", nrow(all_events), "\n")

if(nrow(all_events) > 0) {
  
  write_csv(all_events, "data/processed/gold_rush_detected.csv")
  saveRDS(all_events, "data/processed/gold_rush_detected.rds")
  
  cat("\n--- TOP EVENEMENTS ---\n")
  print(all_events %>%
          arrange(desc(peak_production)) %>%
          select(type, entity, parent, start_year, end_year, peak_production, duration) %>%
          head(20))
  
  # Frise avec deux types d'événements
  top_events <- all_events %>% arrange(desc(peak_production)) %>% head(40)
  
  p_static <- ggplot(top_events, aes(y = reorder(paste0(entity, " (", level, ")"), start_year), 
                                     x = start_year, xend = end_year, color = type)) +
    geom_segment(aes(x = start_year, xend = end_year, yend = reorder(paste0(entity, " (", level, ")"), start_year)), 
                 linewidth = 3, alpha = 0.8) +
    geom_point(aes(x = peak_year), size = 3) +
    labs(title = "Ruées et booms miniers (1493-1950)",
         subtitle = "Rouge = pics aigus (ruées) | Bleu = plateaux durables (booms)",
         x = "Année", y = "", color = "Type d'événement") +
    xlim(1480, 1960) + theme_minimal() +
    theme(panel.grid.major.y = element_blank(), legend.position = "bottom") +
    scale_color_manual(values = c("Rush (pic aigu)" = "#e41a1c", "Boom minier (plateau)" = "#377eb8"))
  
  ggsave("outputs/figures/gold_rush_timeline.png", p_static, width = 14, height = 12)
  cat("\n✓ Frise: outputs/figures/gold_rush_timeline.png\n")
}

cat("\n4_detect_gold_rush.R exécuté\n")