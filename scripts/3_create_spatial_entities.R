# ============================================================================
# scripts/3_create_spatial_entities.R
# Unification de toutes les entités spatiales (avec correction TePaske kg->tonnes)
# ============================================================================

source("scripts/0_setup.R")

# ----------------------------------------------------------------------------
# 1. Chargement des données
# ----------------------------------------------------------------------------

final_production <- readRDS("data/processed/gold_production_final.rds")
craig_states <- readRDS("data/processed/craig_states.rds")

# TePaske avec correction kg -> tonnes
tepaske_detailed <- readRDS("data/processed/tepaske_detailed_clean.rds") %>%
  mutate(production_tonnes = production_tonnes / 1000)

cat("\n=== CHARGEMENT OK ===\n")

# ----------------------------------------------------------------------------
# 2. Niveau 1: Monde
# ----------------------------------------------------------------------------

world_data <- final_production %>%
  filter(country == "World") %>%
  mutate(
    level = "world",
    entity = "World",
    parent = NA_character_
  ) %>%
  select(year, level, entity, parent, production_tonnes, source)

# ----------------------------------------------------------------------------
# 3. Niveau 2: Pays
# ----------------------------------------------------------------------------

country_data <- final_production %>%
  filter(country != "World") %>%
  mutate(
    level = "country",
    entity = country,
    parent = "World"
  ) %>%
  select(year, level, entity, parent, production_tonnes, source)

# ----------------------------------------------------------------------------
# 4. Niveau 3: États américains (Craig)
# ----------------------------------------------------------------------------

us_states_data <- craig_states %>%
  mutate(
    production_tonnes = production_oz / 32150.7,
    level = "state",
    entity = state,
    parent = "United States",
    source = "Craig"
  ) %>%
  filter(!is.na(production_tonnes), production_tonnes > 0) %>%
  select(year, level, entity, parent, production_tonnes, source)

# ----------------------------------------------------------------------------
# 5. Niveau 4: Provinces TePaske (corrigé)
# ----------------------------------------------------------------------------

tepaske_provinces <- tepaske_detailed %>%
  filter(!is.na(province), province != "NA") %>%
  mutate(
    level = "province",
    entity = province,
    parent = country,
    source = "TePaske"
  ) %>%
  select(year, level, entity, parent, production_tonnes, source)

# ----------------------------------------------------------------------------
# 6. Fusion
# ----------------------------------------------------------------------------

all_entities <- bind_rows(world_data, country_data, us_states_data, tepaske_provinces) %>%
  arrange(level, parent, entity, year)

cat("\n=== FUSION OK ===\n")
cat("Total observations:", nrow(all_entities), "\n")
cat("Niveaux:", paste(unique(all_entities$level), collapse = ", "), "\n")

# ----------------------------------------------------------------------------
# 7. Sauvegarde
# ----------------------------------------------------------------------------

write_csv(all_entities, "data/processed/gold_production_all_entities.csv")
saveRDS(all_entities, "data/processed/gold_production_all_entities.rds")

cat("\n=== FICHIERS SAUVEGARDES ===\n")
cat("- gold_production_all_entities.csv\n")
cat("- gold_production_all_entities.rds\n")

# ----------------------------------------------------------------------------
# 8. Vérification TePaske (Minas Gerais)
# ----------------------------------------------------------------------------

minas_check <- all_entities %>%
  filter(entity == "minas_gerais") %>%
  arrange(desc(production_tonnes)) %>%
  head(10)

cat("\n=== MINAS GERAIS (production max) ===\n")
print(minas_check)

message("\n3_create_spatial_entities.R exécuté avec succès")