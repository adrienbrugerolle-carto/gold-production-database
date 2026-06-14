# ============================================================================
# scripts/1_import_soetbeer.R
# Importation des données Soetbeer (production mondiale 1493-1810)
# ============================================================================

source("scripts/0_setup.R")

# ----------------------------------------------------------------------------
# 1. Lecture du fichier Soetbeer
# ----------------------------------------------------------------------------

soetbeer_raw <- read_csv("DATA/soetbeer_1493_1810_world.csv")

# Garder seulement les colonnes utiles et supprimer les colonnes vides
soetbeer_clean <- soetbeer_raw %>%
  select(decade, gold_kg, silver_kg) %>%
  filter(!is.na(gold_kg)) %>%
  mutate(
    # Convertir les décennies en année médiane (ex: "1493–1500" -> 1496)
    year = map_dbl(decade, ~ {
      years <- as.numeric(strsplit(.x, "–")[[1]])
      round(mean(years))
    }),
    # Convertir kg en tonnes (1 tonne = 1000 kg)
    production_tonnes = gold_kg / 1000,
    source = "Soetbeer",
    country = "World"
  ) %>%
  select(year, country, production_tonnes, source) %>%
  arrange(year)

# ----------------------------------------------------------------------------
# 2. Statistiques
# ----------------------------------------------------------------------------

cat("\n=== STATISTIQUES SOETBEER ===\n")
cat("Nombre d'observations :", nrow(soetbeer_clean), "\n")
cat("Période couverte :", range(soetbeer_clean$year, na.rm = TRUE), "\n")
cat("Production totale :", sum(soetbeer_clean$production_tonnes, na.rm = TRUE), "tonnes\n")

cat("\nPremières années :\n")
print(head(soetbeer_clean, 10))

cat("\nDernières années :\n")
print(tail(soetbeer_clean, 10))

# ----------------------------------------------------------------------------
# 3. Sauvegarde
# ----------------------------------------------------------------------------

write_csv(soetbeer_clean, "data/processed/soetbeer_production.csv")
saveRDS(soetbeer_clean, "data/processed/soetbeer_production.rds")

message("\n1_import_soetbeer.R exécuté avec succès")
