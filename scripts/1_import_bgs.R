# ============================================================================
# scripts/1_import_bgs.R
# Importation des données BGS (British Geological Survey) 1971-2014
# ============================================================================

source("scripts/0_setup.R")

# ----------------------------------------------------------------------------
# 1. Lecture du fichier BGS
# ----------------------------------------------------------------------------

bgs_raw <- read_csv("DATA/bgs_1971_2014.csv", show_col_types = FALSE)

# ----------------------------------------------------------------------------
# 2. Nettoyage et sélection des colonnes utiles
# ----------------------------------------------------------------------------

bgs_clean <- bgs_raw %>%
  # Extraire l'année depuis la colonne datetime
  mutate(
    year = as.numeric(format(year, "%Y"))
  ) %>%
  # Garder uniquement les colonnes utiles
  select(
    year,
    country = country_trans,
    country_iso2 = country_iso2_code,
    country_iso3 = country_iso3_code,
    quantity,
    units
  ) %>%
  # Filtrer les valeurs valides
  filter(
    !is.na(quantity),
    quantity > 0,
    !is.na(country)
  ) %>%
  # Convertir kg en tonnes
  mutate(
    production_tonnes = ifelse(units == "kilograms", quantity / 1000, quantity),
    source = "BGS",
    source_priority = 5  # Priorité élevée (source officielle récente)
  ) %>%
  select(year, country, country_iso2, country_iso3, production_tonnes, source, source_priority) %>%
  arrange(country, year)

# ----------------------------------------------------------------------------
# 3. Statistiques
# ----------------------------------------------------------------------------

cat("\n=== STATISTIQUES BGS ===\n")
cat("Nombre d'observations :", nrow(bgs_clean), "\n")
cat("Période couverte :", range(bgs_clean$year, na.rm = TRUE), "\n")
cat("Nombre de pays :", n_distinct(bgs_clean$country), "\n")

# Top 10 des producteurs BGS
cat("\nTop 10 producteurs BGS (total 1971-2014) :\n")
bgs_clean %>%
  group_by(country) %>%
  summarise(total = sum(production_tonnes, na.rm = TRUE)) %>%
  arrange(desc(total)) %>%
  head(10) %>%
  print()

# ----------------------------------------------------------------------------
# 4. Sauvegarde
# ----------------------------------------------------------------------------

write_csv(bgs_clean, "data/processed/bgs_production.csv")
saveRDS(bgs_clean, "data/processed/bgs_production.rds")

message("\n1_import_bgs.R exécuté avec succès")
source("scripts/1_import_bgs.R")