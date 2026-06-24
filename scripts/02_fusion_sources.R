# scripts/02_fusion_sources.R
# Fusion de toutes les sources avec déduplication TePaske

library(tidyverse)

cat("\n--- FUSION DES SOURCES ---\n")

dir.create("fusion", showWarnings = FALSE)

# Liste de toutes les sources
source_files <- c(
  "ridgway_annual",
  "ridgway_decadal",
  "castaneda",
  "craig",
  "tepaske",
  "soetbeer",
  "bgs",
  "clio"
)

all_data <- list()

for (src in source_files) {
  file_path <- paste0("data/", src, ".rda")
  if (file.exists(file_path)) {
    load(file_path)
    data <- get(src)
    if (nrow(data) > 0) {
      all_data[[src]] <- data
      cat("  ", src, ":", nrow(data), "observations\n")
    } else {
      cat("  ", src, ": dataset vide (ignore)\n")
    }
  } else {
    cat("  ", src, ": fichier non trouve\n")
  }
}

# Fusion brute
combined_data <- bind_rows(all_data, .id = "source")

# --- DEDUPLICATION DES DOUBLONS TEPASKE ---
# Les données TePaske ont des doublons entre les fichiers :
# - Latine America 1493 1810 - new granada (fichier principal)
# - South America 1533 1810 - new-granada (fichier détail)
#
# Règle : conserver la version du fichier principal (Latine America)
# et supprimer les versions des fichiers détail (South America, Mexico, Peru, Brazil, Carribean)

cat("\n  Deduplication des donnees TePaske...\n")

# Compter les observations avant déduplication
tepaske_before <- combined_data %>%
  filter(source == "tepaske") %>%
  nrow()

# Identifier les entités TePaske à conserver (fichier principal)
tepaske_keep <- combined_data %>%
  filter(
    source == "tepaske",
    str_detect(country, "^Latine America 1493 1810 - ")
  ) %>%
  distinct(country) %>%
  pull(country)

# Entités à supprimer (fichiers détail)
tepaske_remove <- combined_data %>%
  filter(
    source == "tepaske",
    !str_detect(country, "^Latine America 1493 1810 - ")
  ) %>%
  distinct(country) %>%
  pull(country)

cat("  Entités conservées (fichier principal) :", length(tepaske_keep), "\n")
cat("  Entités supprimées (fichiers détail) :", length(tepaske_remove), "\n")

# Supprimer les doublons
combined_data <- combined_data %>%
  filter(
    !(source == "tepaske" & country %in% tepaske_remove)
  )

tepaske_after <- combined_data %>%
  filter(source == "tepaske") %>%
  nrow()

cat("  TePaske avant :", tepaske_before, "observations\n")
cat("  TePaske après  :", tepaske_after, "observations\n")
cat("  Supprimés      :", tepaske_before - tepaske_after, "observations\n")

# Sauvegarde de toutes les sources
save(combined_data, file = "fusion/all_sources.rda")
cat("\n  Sauvegarde : fusion/all_sources.rda\n")

# Donnees finales avec selection des sources
final_data <- combined_data %>%
  filter(
    source %in% c("ridgway_annual", "castaneda", "bgs", "tepaske", "soetbeer", "clio", "craig") |
      source == "ridgway_decadal"
  ) %>%
  group_by(country, year) %>%
  slice_max(order_by = case_when(
    source == "bgs" ~ 7,
    source == "clio" ~ 6,
    source == "ridgway_annual" ~ 5,
    source == "castaneda" ~ 4,
    source == "craig" ~ 3,
    source == "tepaske" ~ 3,
    source == "soetbeer" ~ 2,
    source == "ridgway_decadal" ~ 1,
    TRUE ~ 0
  ), n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  arrange(country, year)

save(final_data, file = "fusion/final.rda")
cat("  Sauvegarde : fusion/final.rda\n")

# Resume
cat("\n--- RESUME ---\n")
cat("  Toutes les sources :", nrow(combined_data), "observations\n")
cat("  Donnees finales :", nrow(final_data), "observations\n")
cat("  Periode :", min(final_data$year), "-", max(final_data$year), "\n")
cat("  Pays :", n_distinct(final_data$country), "\n")

# Sources dans le jeu final
cat("\n  Sources dans le jeu final :\n")
final_data %>%
  group_by(source) %>%
  summarise(
    observations = n(),
    min_year = min(year),
    max_year = max(year)
  ) %>%
  arrange(desc(observations)) %>%
  print()

# Vérification New Granada (ne doit plus avoir de doublon)
cat("\n  Verification New Granada (TePaske) :\n")
new_granada <- final_data %>%
  filter(source == "tepaske", str_detect(tolower(country), "new granada"))

if (nrow(new_granada) > 0) {
  cat("    Entités New Granada :\n")
  new_granada %>%
    distinct(country) %>%
    print()
  
  cat("    Production totale :", round(sum(new_granada$production_kg, na.rm = TRUE), 0), "kg\n")
}

cat("--- FUSION TERMINEE ---\n")