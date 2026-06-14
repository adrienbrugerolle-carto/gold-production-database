# ============================================================================
# scripts/1_import_tepaske.R
# Importation des données TePaske (Amérique espagnole)
# ============================================================================

source("scripts/0_setup.R")

# ----------------------------------------------------------------------------
# 1. Fonction pour importer un fichier TePaske
# ----------------------------------------------------------------------------

import_tepaske_file <- function(file_path, source_name) {
  # Lire le fichier
  df <- read_csv(file_path, show_col_types = FALSE)
  
  # Renommer la première colonne (décennie)
  names(df)[1] <- "decade"
  
  # Convertir en format long
  df_long <- df %>%
    pivot_longer(cols = -decade, names_to = "country", values_to = "production_tonnes") %>%
    mutate(
      # Convertir la décennie en année médiane (ex: "1691–1700" -> 1695)
      year = map_dbl(decade, ~ {
        years <- as.numeric(strsplit(.x, "–")[[1]])
        round(mean(years))
      }),
      production_tonnes = as.numeric(production_tonnes),
      source = source_name
    ) %>%
    filter(!is.na(production_tonnes), production_tonnes > 0) %>%
    select(year, country, production_tonnes, source)
  
  return(df_long)
}

# ----------------------------------------------------------------------------
# 2. Importer tous les fichiers
# ----------------------------------------------------------------------------

tepaske_brazil <- import_tepaske_file("DATA/tepaske_brazil_1691_1810.csv", "TePaske_Brazil")
tepaske_caribbean <- import_tepaske_file("DATA/tepaske_carribean_1493_1555.csv", "TePaske_Caribbean")
tepaske_latin_america <- import_tepaske_file("DATA/tepaske_latine_america_1493_1810.csv", "TePaske_LatinAmerica")
tepaske_mexico <- import_tepaske_file("DATA/tepaske_mexico_1521_1810.csv", "TePaske_Mexico")
tepaske_peru <- import_tepaske_file("DATA/tepaske_peru_1531_1810.csv", "TePaske_Peru")
tepaske_south_america <- import_tepaske_file("DATA/tepaske_south_america_1533_1810.csv", "TePaske_SouthAmerica")

# ----------------------------------------------------------------------------
# 3. Fusionner tous les TePaske
# ----------------------------------------------------------------------------

tepaske_all <- bind_rows(
  tepaske_brazil,
  tepaske_caribbean,
  tepaske_latin_america,
  tepaske_mexico,
  tepaske_peru,
  tepaske_south_america
)

# ----------------------------------------------------------------------------
# 4. Statistiques
# ----------------------------------------------------------------------------

cat("\n=== STATISTIQUES TEPASKE ===\n")
cat("Nombre d'observations :", nrow(tepaske_all), "\n")
cat("Période couverte :", range(tepaske_all$year, na.rm = TRUE), "\n")
cat("Sources :", paste(unique(tepaske_all$source), collapse = ", "), "\n")

cat("\nProduction totale par source :\n")
tepaske_all %>%
  group_by(source) %>%
  summarise(total = sum(production_tonnes, na.rm = TRUE)) %>%
  arrange(desc(total)) %>%
  print()

cat("\nPremières observations :\n")
print(head(tepaske_all, 15))

# ----------------------------------------------------------------------------
# 5. Sauvegarde
# ----------------------------------------------------------------------------

write_csv(tepaske_all, "data/processed/tepaske_production.csv")
saveRDS(tepaske_all, "data/processed/tepaske_production.rds")

message("\n1_import_tepaske.R exécuté avec succès")
