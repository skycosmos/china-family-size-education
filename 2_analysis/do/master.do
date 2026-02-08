**************************************************
* master.do
** Author: Tianyu Zheng
** Date: April 10, 2025
** Version: Stata/MP 18.0
**************************************************

clear all
set more off
version 18

** SET PROJECT ROOT
global ROOT "/Users/tianyu/Downloads/thesis_pku"

** DEFINE PATHS
global RAW     "$ROOT/0_raw"
global CLEAN   "$ROOT/1_clean"
global DO      "$ROOT/2_analysis/do"
global LOG     "$ROOT/2_analysis/logs"
global RESULT  "$ROOT/3_results"

** Create folders if missing
foreach f in "$CLEAN" "$LOG" "$RESULT" {
    capture mkdir `f'
}

* Close any previous log
capture log close

* Start new log for master.do
log using "$LOG/master.log", replace text

** Run pipeline
do "$DO/00_data_clean.do"
do "$DO/01_prelim_analysis.do"
do "$DO/02_income_analysis.do"
do "$DO/03_edu_distribution.do"
do "$DO/04_decollective_did.do"
do "$DO/05_decollective_event_study.do"
do "$DO/06_family_planning_policy.do"

log close