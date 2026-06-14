# ============================================================================
# scripts/2_merge_all_sources_CORRECTED.R
# Version avec unités cohérentes
# ============================================================================

source("scripts/0_setup.R")

# ----------------------------------------------------------------------------
# 1. Chargement avec unités correctes
# ----------------------------------------------------------------------------

# CLIO (tonnes) - déjà bon
clio_data <- readRDS("data/processed/clio_production_long.rds") %>%
  rename(country = country_name) %>%
  mutate(source = "CLIO", source_priority = 1)

# Craig (onces -> tonnes) - déjà bon
craig_total <- readRDS("data/processed/total_us.rds")
craig_usa <- craig_total %>%
  mutate(
    production_tonnes = production_oz / 32150.7,
    source = "Craig",
    source_priority = 5,
    country = "United States"
  ) %>%
  select(year, country, production_tonnes, source, source_priority)

# Castaneda (tonnes) - déjà bon
castaneda <- read_csv("data/processed/castaneda_world_production.csv", show_col_types = FALSE)
castaneda_world <- castaneda %>%
  filter(!is.na(production_tonnes)) %>%
  select(year, production_tonnes) %>%
  mutate(
    country = "World",
    source = "Castaneda",
    source_priority = 2
  )

# Soetbeer (tonnes) - NE PAS DIVISER
soetbeer_data <- readRDS("data/processed/soetbeer_production.rds") %>%
  mutate(
    country = "World",
    source = "Soetbeer",
    source_priority = 3
  )

# TePaske (kg -> tonnes) - CORRIGÉ
tepaske_data <- readRDS("data/processed/tepaske_by_country.rds") %>%
  mutate(
    production_tonnes = production_tonnes / 1000,  # kg -> tonnes
    source = "TePaske",
    source_priority = 4
  )

# ----------------------------------------------------------------------------
# 2. Fusion
# ----------------------------------------------------------------------------

all_sources <- bind_rows(
  clio_data %>% select(year, country, production_tonnes, source, source_priority),
  craig_usa,
  castaneda_world,
  soetbeer_data,
  tepaske_data
)

final_production <- all_sources %>%
  group_by(country, year) %>%
  slice_max(order_by = source_priority, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  arrange(country, year)

# ----------------------------------------------------------------------------
# 3. Top 10 réaliste (production totale par pays)
# ----------------------------------------------------------------------------

cat("\n=== TOP 10 PRODUCTEURS (production totale corrigée en tonnes) ===\n")
top10_corrected <- final_production %>%
  group_by(country) %>%
  summarise(
    total_production = sum(production_tonnes, na.rm = TRUE),
    n_years = n_distinct(year),
    annual_avg = total_production / n_years
  ) %>%
  arrange(desc(total_production)) %>%
  head(10)

print(top10_corrected)

# ----------------------------------------------------------------------------
# 4. Sauvegarde
# ----------------------------------------------------------------------------

write_csv(final_production, "data/processed/gold_production_final_corrected.csv")
saveRDS(final_production, "data/processed/gold_production_final_corrected.rds")

cat("\n✅ Fichier sauvegardé : gold_production_final_corrected.csv\n")