# scripts/00_run_all.R
# Execution de tout le pipeline

cat("\n========================================\n")
cat("PIPELINE GOLD PRODUCTION DATABASE\n")
cat("========================================\n")

# 1. Importation des sources
cat("\n1. Importation des sources...\n")
source("scripts/01_import_ridgway.R")
source("scripts/01_import_castaneda.R")
source("scripts/01_import_craig.R")
source("scripts/01_import_tepaske.R")
source("scripts/01_import_soetbeer.R")
source("scripts/01_import_bgs.R")

# 2. Fusion
cat("\n2. Fusion des sources...\n")
source("scripts/02_fusion_sources.R")

# 3. Visualisation
cat("\n3. Visualisation...\n")
source("scripts/03_visualize_data.R")

cat("\n========================================\n")
cat("PIPELINE TERMINE\n")
cat("========================================\n")