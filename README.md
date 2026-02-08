# Educational Inequality and Family Size: Evidence from the 1980s Rural Economic Reform in China

## Project Overview

This research explores the causal effects of the 1980s institutional de-collectivization reform in rural China on human capital accumulation and economic outcomes. Using household and individual-level survey data from rural and urban China, the project employs difference-in-differences estimation and event study methodologies to identify the long-term impacts on education, income, and family composition outcomes.

The analysis leverages provincial variation in policy implementation timing to construct plausibly exogenous treatment variation, exploiting the fact that individuals in different birth cohorts were exposed to these policy changes at critical stages of their educational development. This approach allows the study to disentangle the effects of institutional change from other confounding factors.

## Research Questions

1. **De-collectivization and Educational Articulation**: Did the transition from collective per-capita rationing system to household-based agriculture economy in the early 1980s affect the rate at which students progressed through critical educational milestones (junior high and senior high completion)? How did this vary by family size?

2. **Family Planning Policy and Birth Order Effects**: How did the restrictions on fertility under the family planning policy affect the relative educational attainment of first-born versus later-born children, particularly conditional on family size?

3. **Institutional Shocks and Income Distribution**: What are the long-term economic consequences of these policy changes, as reflected in adult income levels and household financial status?

## Data

Chinese Household Income Project (CHIP) 2018

## Project Structure

```
thesis_pku/
├── 0_raw/                          # Raw data files
│   ├── rural_household.dta         # Rural household-level data
│   ├── rural_person.dta            # Rural individual-level data
│   ├── urban_household.dta         # Urban household-level data
│   ├── urban_person.dta            # Urban individual-level data
│   ├── policy_time.dta             # De-collectivization timing by province
│   └── descriptions/               # Data documentation
│
├── 1_clean/                        # Cleaned data
│   └── data_processed.dta          # Merged, cleaned dataset for analysis
│
├── 2_analysis/                     # Analysis scripts
│   ├── do/
│   │   ├── master.do               # Main execution script (runs all analyses)
│   │   ├── 00_data_clean.do        # Data merging and variable creation
│   │   ├── 01_prelim_analysis.do   # Descriptive statistics and data exploration
│   │   ├── 02_income_analysis.do   # Income analysis by family characteristics
│   │   ├── 03_edu_distribution.do  # Educational attainment distribution
│   │   ├── 04_decollective_did.do  # DiD estimation: de-collectivization effects
│   │   ├── 05_decollective_event_study.do # Event study: de-collectivization
│   │   └── 06_family_planning_policy.do   # Family planning policy analysis
│   ├── logs/                       # Execution logs
│   └── output/                     # Intermediate output
│
└── 3_results/                      # Final results
    ├── estimates/                  # Regression estimates
    ├── figures/                    # Analysis figures
    └── tables/                     # Publication-ready tables
        ├── summary.tex             # Summary statistics
        ├── income.tex              # Income analysis tables
        ├── did_decollective.tex    # DiD estimation results
        ├── event_decollective.tex  # Event study results
        ├── first_born.tex          # First-born effects
        ├── dist_size_order.tex     # Distribution by size and order
        ├── header.tex              # Table formatting
        └── footer.tex              # Table formatting
```

## Data Sources

### Raw Data Files
- **Rural Household Data** (`rural_household.dta`): Household-level information from rural survey
- **Rural Person Data** (`rural_person.dta`): Individual-level demographic, education, and income data for rural respondents
- **Urban Household Data** (`urban_household.dta`): Household-level information from urban survey
- **Urban Person Data** (`urban_person.dta`): Individual-level data for urban respondents
- **Policy Implementation Data** (`policy_time.dta`): Province-level de-collectivization timing

### Sample Information
- **Coverage**: Rural and urban areas across multiple Chinese provinces
- **Survey Year**: 2018 (reference year for demographic calculations)
- **Age Range**: Focus on working-age population (ages 30-55 in analysis)

## Key Variables

### Individual Characteristics
- **Demographic**: Birth year, gender, age, marital status
- **Education**: Years of completed education, educational attainment levels
- **Health**: Self-reported health status
- **Family**: Number of siblings, birth order rank, dependent children

### Economic Outcomes
- **Income**: Annual income (log-transformed for analysis)
- **Financial Assets**: Household financial assets
- **Financial Debt**: Outstanding household debt

### Geographic/Policy Variables
- **Province of Birth**: Birth province (linked to policy timing)
- **Urban/Rural Status**: Classification of current residence
- **Decollective Year**: Policy implementation year by province

## Methodology

### Data Processing (00_data_clean.do)
- Merges person-level and household-level data for rural and urban samples
- Creates derived variables: age, education levels, health indicators
- Constructs measures of household financial status
- Combines rural and urban samples into unified analysis dataset

### Descriptive Analysis (01_prelim_analysis.do)
- Summary statistics by urban/rural status
- Distribution of key variables

### Income Analysis (02_income_analysis.do)
- Analyzes relationship between family characteristics and income
- Sample restriction: ages 30-55 (prime working years)
- Variables: log income, log assets, age, education

### Educational Distribution (03_edu_distribution.do)
- Examines variation in educational attainment
- Analysis by birth cohort and family characteristics

### De-collectivization Analysis
- **DiD Estimation (04_decollective_did.do)**
  - Estimates causal effect of de-collectivization on education
  - Treatment definition: Policy implementation in birth province
  - Outcome: Years of education and educational articulation
  - Articulation indicators: Completion of grades 9 (junior high) and 12 (senior high)
  
- **Event Study (05_decollective_event_study.do)**
  - Traces effects over time relative to policy implementation
  - Identifies pre-trends and dynamic treatment effects

### Family Planning Policy Analysis (06_family_planning_policy.do)
- Examines effects of family planning restrictions on household outcomes
- Analyzes birth order effects and sibling composition impacts

## How to Run

### Prerequisites
- Stata/MP 18.0 or compatible version
- All raw data files in `0_raw/` directory

### Setup: Configure Root Folder Path

Before running the analysis, you must update the root folder path in [master.do](2_analysis/do/master.do) to match your local machine:

1. Open [2_analysis/do/master.do](2_analysis/do/master.do) in a text editor
2. Locate this line (typically line 10):
   ```stata
   global ROOT "/Users/tianyu/Downloads/thesis_pku"
   ```
3. Replace the path with your actual project directory:
   ```stata
   global ROOT "/path/to/your/project_folder"
   ```

4. Save the file

This global macro defines all other paths (RAW, CLEAN, DO, LOG, RESULT) automatically.

### Execution

After configuring the root path, run the complete analysis pipeline:

```bash
cd /path/to/your/project_folder
stata do 2_analysis/do/master.do
```

The master script will:
1. Set up project paths based on the ROOT global
2. Create necessary directories (`1_clean/`, `2_analysis/logs/`, `3_results/`)
3. Clean and process data (creates `1_clean/data_processed.dta`)
4. Run all analysis scripts sequentially:
   - Data cleaning and variable creation
   - Descriptive statistics
   - Income analysis
   - Educational distribution analysis
   - De-collectivization DiD estimation
   - Event Study analysis on De-collectivization
   - Family planning policy analysis
5. Generate publication-ready tables in `3_results/tables/` and figures in `3_results/figures/`
6. Create execution log in `2_analysis/logs/master.log`

## Outputs

### Tables (in 3_results/tables/)
- **summary.tex**: Descriptive statistics
- **income.tex**: Income analysis results
- **dist_size_order.tex**: Educational distribution by family characteristics
- **did_decollective.tex**: De-collectivization DiD estimates
- **event_decollective.tex**: De-collectivization Event study results
- **first_born.tex**: Birth order effects under Family Planning Policy

### Logs (in 2_analysis/logs/)
- Execution logs from each analysis run

### Figures (in 3_results/figures/)
- Visualizations from analysis

## Author & Date

- **Author**: Tianyu Zheng
- **Project End**: April 10, 2025
- **Software**: Stata/MP 18.0

## Notes

- All analysis uses 2018 survey reference year for age calculations
- Policy variation (de-collectivization timing) provides identification for causal estimates
- Event study analysis restricted to birth cohorts experiencing policy variation (1970-1995)

## Version History

| Date | Version | Changes |
|------|---------|---------|
| April 10, 2025 | 1.0 | Final Version |

---

*For detailed methodology and results, see the thesis document. For questions about data or code, refer to individual script comments.*
