
# Gold Production Historical Database

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![R](https://img.shields.io/badge/R-4.6%2B-blue.svg)](https://www.r-project.org/)
[![tidyverse](https://img.shields.io/badge/tidyverse-2.0.0-orange.svg)](https://www.tidyverse.org/)

## Overview

This database compiles historical gold mine production data from **1493 to 2024** across **141 countries**, integrating **6 major sources**.

### Key Features

- Time span: 1493 - 2024 (531 years)
- Geographic coverage: 141 countries/territories
- Total observations: 10,137
- Sources: BGS, CLIO INFRA, Craig, Castaneda, Soetbeer, TePaske
- Unit: Metric tonnes (standardized across all sources)

## Top 10 Producers (Cumulative Production)

| Rank | Country | Total Production (tonnes) |
|------|---------|--------------------------|
| 1 | South Africa | 53,273 |
| 2 | United States | 17,894 |
| 3 | Australia | 16,321 |
| 4 | Russia | 14,171 |
| 5 | Canada | 12,640 |
| 6 | China | 10,808 |
| 7 | Brazil | 5,953 |
| 8 | Peru | 5,245 |
| 9 | Ghana | 4,914 |
| 10 | Indonesia | 4,727 |

## Data Sources

| Source | Period | Coverage | Priority |
|--------|--------|----------|----------|
| BGS (British Geological Survey) | 1971-2024 | World | 6 (highest) |
| Craig and Rimstidt (1998) | 1799-1995 | United States | 5 |
| TePaske (2010) | 1493-1810 | Latin America | 4 |
| Soetbeer (1880) | 1493-1810 | World | 3 |
| Castaneda (2013) | 1492-2012 | World | 2 |
| CLIO INFRA (2015) | 1681-2012 | World | 1 |

## Repository Structure

- scripts/ - R scripts for import and fusion
- data/processed/ - Cleaned datasets
- outputs/figures/ - Generated visualizations
- DATA/ - Raw source files

## Usage in R

library(tidyverse)
gold_data <- readRDS("data/processed/gold_production_final.rds")

# Plot global production
gold_data %>%
  filter(country == "World") %>%
  ggplot(aes(x = year, y = production_tonnes)) +
  geom_line() +
  scale_y_log10()

## References

- British Geological Survey (BGS). World mineral statistics dataset.
- Castaneda, J. E. (2013). A new estimate of the stock of gold (1492-2012).
- Craig, J. R., & Rimstidt, J. D. (1998). Gold production history of the United States. Ore Geology Reviews, 13(6), 407-464.
- Klein Goldewijk, K., & Fink-Jensen, J. (2015). Gold production. IISH Data Collection.
- Soetbeer, A. (1880). Edelmetall-produktion und werthverhaltniss zwischen gold und silber.
- TePaske, J. J. (2010). A new world of gold and silver. Brill.

## License

MIT License. Data sources: please cite original sources accordingly.

## Contact

Author: Adrien Brugerolle
GitHub: adrienbrugerolle-carto

Last updated: June 2026

