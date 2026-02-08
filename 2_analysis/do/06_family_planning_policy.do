**************************************************
* 06_family_planning_policy.do
** Author: Tianyu Zheng
** Date: April 10, 2025
** Version: Stata/MP 18.0
**************************************************

/* Family Planning Policy */
use "$CLEAN/data_processed.dta", clear

/* Educational Attainment and Rank among Siblings */

estimates clear

gen junior_high_complete = (edu >= 9) if !missing(edu)
gen high_school_complete = (edu >= 12) if !missing(edu)

keep if sib == 2
gen first_born = (rank == 1) if !missing(rank)
gen post1 = (year > 1973)
gen post2 = (year > 1979)

reghdfe edu female first_born 1.first_born#1.female 1.first_born#1.post1 1.first_born#1.post2, absorb(prov_birth year) vce(cluster prov_birth)
estimates store first_born_edu

reghdfe junior_high_complete female first_born 1.first_born#1.female 1.first_born#1.post1 1.first_born#1.post2, absorb(prov_birth year) vce(cluster prov_birth)
estimates store first_born_junior

reghdfe high_school_complete female first_born 1.first_born#1.female 1.first_born#1.post1 1.first_born#1.post2, absorb(prov_birth year) vce(cluster prov_birth)
estimates store first_born_senior

// Export to LaTeX
esttab first_born_edu first_born_junior first_born_senior ///
    using "$RESULT/tables/first_born.tex", replace ///
    b(3) se(3) nobaselevels noomitted ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    label booktabs nomtitle ///
    title("Impact of Birth Order on Educational Outcomes for 2-Children Families") ///
    mgroups("Years of Education" "Junior High Completion" "Senior High Completion", ///
            pattern(1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
    keep(first_born 1.first_born#0.female 1.first_born#1.post1 1.first_born#1.post2 female) ///
    order(first_born 1.first_born#0.female 1.first_born#1.post1 1.first_born#1.post2 female) ///
    coeflabels(first_born "First-born" ///
               1.first_born#0.female "First-born × Female" ///
               1.first_born#1.post1 "First-born × Post-1973" ///
               1.first_born#1.post2 "First-born × Post-1979" ///
               female "Female") ///
    stats(N r2, fmt(0 3) labels("Observations" "R-squared")) ///
    addnotes("Notes: All specifications include province-of-birth and year fixed effects." ///
             "Standard errors clustered at province-of-birth level in parentheses." ///
             "*** p<0.01, ** p<0.05, * p<0.10.") ///
    prehead("\begin{table}[htbp]\centering\small\caption{@title}") ///
    postfoot("\end{table}")
