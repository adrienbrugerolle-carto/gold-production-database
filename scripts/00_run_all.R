# scripts/00_run_all.R
# Pipeline complet

cat("\n========================================\n")
cat("PIPELINE GOLD PRODUCTION DATABASE\n")
cat("========================================\n")

# 1. Importation
cat("\n1. Importation des sources...\n")
source("scripts/01_import_ridgway.R")
source("scripts/01_import_castaneda.R")
source("scripts/01_import_craig.R")
source("scripts/01_import_tepaske.R")
source("scripts/01_import_soetbeer.R")
source("scripts/01_import_bgs.R")
source("scripts/01_import_clio.R")

# 2. Fusion
cat("\n2. Fusion des sources...\n")
source("scripts/02_fusion_sources.R")

# 3. Catégorisation des entités
cat("\n3. Catégorisation des entités...\n")
source("scripts/03_categorize_entities.R")

# 4. Analyse
cat("\n4. Analyse des données...\n")
source("scripts/04_analyze_rushes.R")

cat("\n========================================\n")
cat("PIPELINE TERMINE\n")
cat("========================================\n")