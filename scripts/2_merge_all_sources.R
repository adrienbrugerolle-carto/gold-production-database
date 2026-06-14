# ============================================================================
# scripts/2_merge_all_sources.R - Version avec BGS
# Fusion de TOUTES les sources : BGS, CLIO, Craig, Castaneda, Soetbeer, TePaske
# ============================================================================

source("scripts/0_setup.R")

# ----------------------------------------------------------------------------
# 1. Chargement de toutes les sources
# ----------------------------------------------------------------------------

# BGS (priorité 6 - source officielle récente)
bgs_data <- readRDS("data/processed/bgs_production.rds") %>%
  select(year, country, production_tonnes, source, source_priority) %>%
  mutate(source_priority = 6)

# CLIO (priorité 1)
clio_data <- readRDS("data/processed/clio_production_long.rds") %>%
  rename(country = country_name) %>%
  mutate(source = "CLIO", source_priority = 1)

# Craig (USA) (priorité 5)
craig_total <- readRDS("data/processed/total_us.rds")
craig_usa <- craig_total %>%
  mutate(
    production_tonnes = production_oz / 32150.7,
    source = "Craig",
    source_priority = 5,
    country = "United States"
  ) %>%
  select(year, country, production_tonnes, source, source_priority)

# Castaneda (priorité 2)
castaneda <- read_csv("data/processed/castaneda_world_production.csv", show_col_types = FALSE)
castaneda_world <- castaneda %>%
  filter(!is.na(production_tonnes)) %>%
  select(year, production_tonnes) %>%
  mutate(
    country = "World",
    source = "Castaneda",
    source_priority = 2
  )

# Soetbeer (priorité 3)
soetbeer_data <- readRDS("data/processed/soetbeer_production.rds") %>%
  mutate(
    country = "World",
    source = "Soetbeer",
    source_priority = 3
  )

# TePaske (priorité 4)
tepaske_data <- readRDS("data/processed/tepaske_by_country.rds") %>%
  mutate(
    production_tonnes = production_tonnes / 1000,  # kg -> tonnes
    source = "TePaske",
    source_priority = 4
  )

# ----------------------------------------------------------------------------
# 2. Harmonisation des noms de pays
# ----------------------------------------------------------------------------

# Standardiser les noms BGS
bgs_data <- bgs_data %>%
  mutate(country = case_when(
    country == "United States" ~ "United States",
    country == "United Kingdom" ~ "United Kingdom",
    country == "Russia" ~ "Russia",
    country == "Ivory Coast" ~ "Côte d'Ivoire",
    TRUE ~ country
  ))

# Standardiser les noms CLIO
clio_data <- clio_data %>%
  mutate(country = case_when(
    country == "United States" ~ "United States",
    country == "United Kingdom" ~ "United Kingdom",
    country == "Russia" ~ "Russia",
    TRUE ~ country
  ))

# ----------------------------------------------------------------------------
# 3. Fusion avec priorité
# ----------------------------------------------------------------------------

all_sources <- bind_rows(
  bgs_data,
  clio_data %>% select(year, country, production_tonnes, source, source_priority),
  craig_usa,
  castaneda_world,
  soetbeer_data,
  tepaske_data
)

# Appliquer la priorité (plus le nombre est élevé, plus prioritaire)
final_production <- all_sources %>%
  group_by(country, year) %>%
  slice_max(order_by = source_priority, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  arrange(country, year)

# ----------------------------------------------------------------------------
# 4. Statistiques détaillées
# ----------------------------------------------------------------------------

cat("\n========================================\n")
cat("STATISTIQUES DE LA BASE FINALE (avec BGS)\n")
cat("========================================\n\n")

cat("Nombre total de pays :", n_distinct(final_production$country), "\n")
cat("Période couverte :", range(final_production$year, na.rm = TRUE), "\n")
cat("Nombre total d'observations :", nrow(final_production), "\n\n")

cat("Répartition par source :\n")
source_counts <- table(final_production$source)
print(source_counts)

cat("\nTop 10 des producteurs mondiaux (production totale) :\n")
final_production %>%
  group_by(country) %>%
  summarise(total_production = sum(production_tonnes, na.rm = TRUE)) %>%
  arrange(desc(total_production)) %>%
  head(10) %>%
  print()

cat("\nAperçu des données (premières lignes) :\n")
print(head(final_production, 15))

# ----------------------------------------------------------------------------
# 5. Sauvegarde
# ----------------------------------------------------------------------------

write_csv(final_production, "data/processed/gold_production_final.csv")
saveRDS(final_production, "data/processed/gold_production_final.rds")

# Sauvegarder aussi toutes les sources pour comparaison
write_csv(all_sources, "data/processed/gold_production_all_sources.csv")
saveRDS(all_sources, "data/processed/gold_production_all_sources.rds")

cat("\n========================================\n")
cat("FICHIERS SAUVEGARDÉS :\n")
cat("  - gold_production_final.csv/rds (version prioritaire)\n")
cat("  - gold_production_all_sources.csv/rds (toutes les sources)\n")
cat("========================================\n")

message("\n2_merge_all_sources.R exécuté avec succès")