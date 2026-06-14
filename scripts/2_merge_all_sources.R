# ============================================================================
# scripts/2_merge_all_sources.R
# Fusion de Craig (USA), Castaneda (monde) et CLIO (monde historique)
# ============================================================================

source("scripts/0_setup.R")

# ----------------------------------------------------------------------------
# 1. Chargement des trois sources
# ----------------------------------------------------------------------------

# CLIO
clio_data <- readRDS("data/processed/clio_production_long.rds") %>%
  rename(country = country_name) %>%
  mutate(source = "CLIO", source_priority = 1)

# Craig : production USA (déjà en tonnes dans craig_total_tonnes)
craig_usa <- craig_total_tonnes %>%
  mutate(country = "United States", source = "Craig", source_priority = 3)

# Castaneda : production mondiale
castaneda_world <- castaneda_prod %>%
  mutate(country = "World", source = "Castaneda", source_priority = 2)

# ----------------------------------------------------------------------------
# 2. Fusion avec priorité
# ----------------------------------------------------------------------------

# Union de toutes les sources
all_sources <- bind_rows(
  clio_data %>% select(year, country, production_tonnes, source, source_priority),
  craig_usa %>% select(year, country, production_tonnes, source, source_priority),
  castaneda_world %>% select(year, country, production_tonnes, source, source_priority)
)

# Règle de priorité : Craig (USA, priorité 3) > Castaneda (monde, 2) > CLIO (1)
final_production <- all_sources %>%
  group_by(country, year) %>%
  slice_max(order_by = source_priority, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  arrange(country, year)

# ----------------------------------------------------------------------------
# 3. Statistiques et vérifications
# ----------------------------------------------------------------------------

cat("\n=== STATISTIQUES FINALES ===\n")
cat("Nombre de pays :", n_distinct(final_production$country), "\n")
cat("Période couverte :", range(final_production$year, na.rm = TRUE), "\n")
cat("Nombre total d'observations :", nrow(final_production), "\n")

cat("\nRépartition par source :\n")
print(table(final_production$source))

# Vérifier les USA (comparaison Craig vs CLIO)
usa_comparison <- final_production %>%
  filter(country == "United States", year >= 1800, year <= 1900) %>%
  select(year, production_tonnes, source)

cat("\nUSA - comparaison des sources (1800-1900) :\n")
print(head(usa_comparison, 20))

# ----------------------------------------------------------------------------
# 4. Sauvegarde
# ----------------------------------------------------------------------------

write_csv(final_production, "data/processed/gold_production_final.csv")
saveRDS(final_production, "data/processed/gold_production_final.rds")

message("\n2_merge_all_sources.R exécuté avec succès")
