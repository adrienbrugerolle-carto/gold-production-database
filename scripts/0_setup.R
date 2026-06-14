# ============================================================================
# 0_setup.R
# Script d'initialisation du projet Gold Production Database
# ============================================================================

# ----------------------------------------------------------------------------
# 1. Installation des packages (si non presets)
# ----------------------------------------------------------------------------

packages <- c(
  "tidyverse",
  "here",
  "janitor",
  "lubridate",
  "readr",
  "fs",
  "DBI",
  "RSQLite",
  "knitr",
  "kableExtra",
  "ggplot2",
  "dplyr",
  "tidyr"
)

installed <- installed.packages()
to_install <- packages[!(packages %in% installed)]
if (length(to_install) > 0) {
  install.packages(to_install)
}

invisible(lapply(packages, library, character.only = TRUE))

# ----------------------------------------------------------------------------
# 2. Chemins absolus avec {here}
# ----------------------------------------------------------------------------

project_root <- here::here()

dir_raw <- here("data", "raw")
dir_processed <- here("data", "processed")
dir_external <- here("data", "external")
dir_scripts <- here("scripts")
dir_outputs <- here("outputs")
dir_figures <- here("outputs", "figures")
dir_tables <- here("outputs", "tables")
dir_reports <- here("outputs", "reports")
dir_docs <- here("docs")

# ----------------------------------------------------------------------------
# 3. Creation des dossiers (si absents)
# ----------------------------------------------------------------------------

dirs_to_create <- c(
  dir_raw, dir_processed, dir_external,
  dir_figures, dir_tables, dir_reports,
  dir_docs
)

for (d in dirs_to_create) {
  if (!dir.exists(d)) {
    dir.create(d, recursive = TRUE)
    message("Dossier cree : ", d)
  }
}

# ----------------------------------------------------------------------------
# 4. Options globales
# ----------------------------------------------------------------------------

options(readr.num_columns = 0)
options(scipen = 999)

tryCatch(
  Sys.setlocale("LC_TIME", "en_US.UTF-8"),
  error = function(e) message("Locale en_US non disponible, utilisation de la locale par defaut")
)

options(repr.plot.width = 10, repr.plot.height = 6)

# ----------------------------------------------------------------------------
# 5. Fonctions utilitaires
# ----------------------------------------------------------------------------

utils_file <- here("scripts", "functions", "utils.R")
if (file.exists(utils_file)) {
  source(utils_file)
  message("Fonctions utilitaires chargees depuis ", utils_file)
} else {
  message("Fichier utils.R non trouve. Creez-le dans scripts/functions/")
}

# ----------------------------------------------------------------------------
# 6. Verification de l'environnement
# ----------------------------------------------------------------------------

message("\n========================================")
message("Environnement de travail initialise")
message("========================================")
message("Racine du projet : ", project_root)
message("Donnees brutes   : ", dir_raw)
message("Donnees traitees : ", dir_processed)
message("Graphiques       : ", dir_figures)
message("========================================\n")

# ----------------------------------------------------------------------------
# 7. Message final
# ----------------------------------------------------------------------------

message("0_setup.R execute avec succes")
message("Les dossiers sont prets")
message("Packages charges : ", paste(packages, collapse = ", "))
