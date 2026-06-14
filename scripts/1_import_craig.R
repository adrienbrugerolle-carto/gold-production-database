# ============================================================================
# 1_import_craig.R
# Import des donnees Craig & Rimstidt (1998)
# Source: Craig, J.R., Rimstidt, J.D. (1998)
#         Gold production history of the United States
#         Ore Geology Reviews, 13(6), 407-464
# ============================================================================

# ----------------------------------------------------------------------------
# 1. Preparation
# ----------------------------------------------------------------------------

source("scripts/0_setup.R")

# ----------------------------------------------------------------------------
# 2. Import du fichier CSV
# ----------------------------------------------------------------------------

# Le fichier CSV doit se trouver dans data/processed/
file_path <- here("data", "processed", "craig_states_1799_1995.csv")

# Verifier que le fichier existe
if (!file.exists(file_path)) {
  stop("Fichier non trouve : ", file_path,
       "\nVeuillez placer le fichier craig_states_1799_1995.csv dans data/processed/")
}

# Lecture du CSV
craig_states <- read_csv(file_path, na = "NA", show_col_types = FALSE)

# ----------------------------------------------------------------------------
# 3. Apercu des donnees
# ----------------------------------------------------------------------------

message("\n--- Apercu des donnees Craig ---")
glimpse(craig_states)

message("\n--- Premieres lignes ---")
head(craig_states)

message("\n--- Dernieres lignes ---")
tail(craig_states)

message("\n--- Statistiques sommaires ---")
summary(craig_states)

# ----------------------------------------------------------------------------
# 4. Verifications
# ----------------------------------------------------------------------------

# Annees couvertes
years <- range(craig_states$year, na.rm = TRUE)
message("\nPeriode couverte : ", years[1], " - ", years[2])

# Etats presents
states <- unique(craig_states$state)
message("Nombre d'etats : ", length(states))
message("Etats : ", paste(sort(states), collapse = ", "))

# Valeurs manquantes
na_count <- sum(is.na(craig_states$production_oz))
message("Valeurs manquantes (production_oz) : ", na_count)

# ----------------------------------------------------------------------------
# 5. Production totale par an
# ----------------------------------------------------------------------------

total_us <- craig_states %>%
  group_by(year) %>%
  summarise(production_oz = sum(production_oz, na.rm = TRUE), .groups = "drop")

message("\n--- Production totale US (premieres annees) ---")
head(total_us)

message("\n--- Production totale US (dernieres annees) ---")
tail(total_us)

# ----------------------------------------------------------------------------
# 6. Sauvegarde de l'objet R
# ----------------------------------------------------------------------------

saveRDS(craig_states, here("data", "processed", "craig_states.rds"))
saveRDS(total_us, here("data", "processed", "total_us.rds"))

message("\nDonnees sauvegardees dans data/processed/")
message("  - craig_states.rds")
message("  - total_us.rds")

# ----------------------------------------------------------------------------
# 7. Nettoyage de l'environnement (optionnel)
# ----------------------------------------------------------------------------

# Conserver uniquement les objets importants
rm(years, states, na_count, file_path)

message("\n1_import_craig.R execute avec succes")