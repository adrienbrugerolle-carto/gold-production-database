# scripts/01_import_craig.R (version corrigée)
# Importation des données Craig & Rimstidt (1998)

library(tidyverse)

cat("\n--- IMPORTATION: CRAIG & RIMSTIDT (1998) ---\n")

# Lire le fichier
craig_raw <- read_csv("data-raw/raw/craig_states_1799_1995_V2.csv",
                      show_col_types = FALSE,
                      col_names = FALSE)

cat("  Dimensions :", nrow(craig_raw), "x", ncol(craig_raw), "\n")

# Ligne 1 = noms des états (colonnes 2 à n)
state_names <- as.character(craig_raw[1, 2:ncol(craig_raw)])
state_names <- state_names[!is.na(state_names) & state_names != "NA"]
cat("  États :", length(state_names), "\n")

# Ligne 2 = années (colonne 1), valeurs à partir de la colonne 2
# Les données commencent à la ligne 3
years <- as.numeric(craig_raw[2, 1])
# Les années sont en colonne 1, on les extrait de la ligne 2
years <- as.numeric(craig_raw[2, 1])
# En fait, les années sont dans la colonne 1 de chaque ligne
# Les données commencent à la ligne 2

# Approche plus simple : extraire par état
all_craig <- list()

# Les états sont en ligne 1, colonnes 2 à n
# Les données commencent à la ligne 2

for (i in 1:length(state_names)) {
  state_name <- state_names[i]
  col_index <- i + 1  # +1 car colonne 1 = années
  
  # Extraire les données pour cet état
  state_data <- craig_raw %>%
    # Les années sont dans la colonne 1
    mutate(
      year = as.numeric(X1),
      value = as.numeric(.[[col_index]])
    ) %>%
    filter(!is.na(year), !is.na(value), value > 0) %>%
    mutate(
      production_kg = value * 0.0311035,  # onces -> kg
      source = "craig",
      country = state_name,
      unit = "kg"
    ) %>%
    select(year, production_kg, source, country, unit)
  
  if (nrow(state_data) > 0) {
    all_craig[[state_name]] <- state_data
    cat("    ", state_name, ":", nrow(state_data), "observations\n")
  }
}

if (length(all_craig) > 0) {
  craig <- bind_rows(all_craig)
  cat("\n  Total Craig :", nrow(craig), "observations\n")
  cat("  États :", n_distinct(craig$country), "\n")
  cat("  Periode :", min(craig$year), "-", max(craig$year), "\n")
  
  save(craig, file = "data/craig.rda")
  cat("  Sauvegarde : data/craig.rda\n")
} else {
  cat("\n  Aucune donnee Craig importee\n")
}

cat("--- IMPORTATION CRAIG TERMINEE ---\n")