**************************************************
* 03_edu_distribution.do
** Author: Tianyu Zheng
** Date: April 10, 2025
** Version: Stata/MP 18.0
**************************************************

/* Educational Attainment Distribution */

** FIGURE: Distribution of Highest Grade Completed by Birth Cohort

use "$CLEAN/data_processed.dta", clear

* Create cohort indicators more efficiently
egen cohort = cut(year), at(1960,1970,1980,1990) icodes
replace cohort = cohort + 1  // adjust to 1-based indexing
keep if inlist(cohort,1,2,3) & !missing(edu)

* Label cohorts with improved formatting
label define cohort_lbl 1 "1960-69" 2 "1970-79" 3 "1980-89"
label values cohort cohort_lbl

* Set graph scheme for consistent styling
set scheme s1color

* Create histogram plot with fractions
histogram edu, by(cohort, ///
    cols(3) ///
    title("Distribution of Highest Grade Completed by Birth Cohort", size(medium))) ///
    discrete width(1) ///
    fraction ///
    xtitle("Highest Grade Completed", size(small)) ///
    ytitle("Fraction of Cohort", size(small)) ///
    xlabel(0(2)16, labsize(small)) ///
    ylabel(0(0.1)0.3, labsize(small) format(%3.1f)) ///
    graphregion(color(white)) ///
    plotregion(margin(sides)) ///
    fcolor("32 78 132") lcolor("32 78 132%70") ///
    name(cohort_hists, replace)

* Combine graphs
graph combine cohort_hists, ///
    graphregion(color(white)) ///
    imargin(medium) ///
    cols(3) ysize(5) xsize(9)
	
graph export "$RESULT/figures/highest_edu_dist.png", replace

*-------------------------------------------------------------------------------

** FIGURE: Average Educational Attainment by Birth Year

use "$CLEAN/data_processed.dta", clear

* Create completion indicators
gen primary_complete = (edu >= 5) if !missing(edu)
gen junior_high_complete = (edu >= 9) if !missing(edu)
gen high_school_complete = (edu >= 12) if !missing(edu)

* Calculate means by birth year
collapse (mean) mean_edu=edu mean_primary=primary_complete ///
         mean_junior=junior_high_complete mean_high=high_school_complete, ///
         by(year)

* Label variables for graph
label var mean_edu "Avg. Years of Education"
label var mean_primary "≥ Primary (5 yrs)"
label var mean_junior "≥ Junior High (9 yrs)"
label var mean_high "≥ High School (12 yrs)"

* Combine both graphs into one with dual axes
twoway (line mean_primary year, lcolor(ebblue) lwidth(medthick)) ///
       (line mean_junior year, lcolor(emerald) lwidth(medthick)) ///
       (line mean_high year, lcolor(cranberry) lwidth(medthick)) ///
       (scatter mean_edu year, yaxis(2) mcolor(dkorange) msymbol(O) ///
        msize(medium) connect(l) lcolor(dkorange) lwidth(medthick)), ///
       title("Educational Attainment by Birth Year", size(medlarge)) ///
       xtitle("Birth Year", size(medsmall)) ///
       ytitle("Completion Rate", axis(1) size(medsmall)) ///
       ytitle("Years of Education", axis(2) size(medsmall)) ///
       legend(pos(6) row(1) size(small) ///
              order(1 2 3 4) ///
              label(1 "Primary") ///
              label(2 "Junior High") ///
              label(3 "Senior High") ///
              label(4 "Avg. Edu Years")) ///
       xlabel(1960(10)1990, grid gstyle(dot)) ///
       ylabel(0(0.2)1, axis(1) grid gstyle(dot)) ///
       ylabel(, axis(2) grid gstyle(dot)) ///
       graphregion(color(white)) plotregion(color(white))

** "Note: Completion rates represent proportion attaining at least the specified education level."

graph export "$RESULT/figures/avg_edu_year.png", replace

*-------------------------------------------------------------------------------

** FIGURES: Educational Attainment by Family Size

use "$CLEAN/data_processed.dta", clear

gen junior_complete = (edu >= 9) if !missing(edu)
gen highschool_complete = (edu >= 12) if !missing(edu)

collapse (mean) mean_edu=edu junior_rate=junior_complete highschool_rate=highschool_complete, ///
         by(year family_cat)

* FIGURE : Average Years of Education by Family Size
twoway (line mean_edu year if family_cat == 1, lcolor(navy) lwidth(medthick)) ///
       (line mean_edu year if family_cat == 2, lcolor(ebblue) lwidth(medthick)) ///
       (line mean_edu year if family_cat == 3, lcolor(eltgreen) lwidth(medthick)) ///
       (line mean_edu year if family_cat == 4, lcolor(erose) lwidth(medthick)) ///
       (line mean_edu year if family_cat == 5, lcolor(cranberry) lwidth(medthick)) ///
       (line mean_edu year if family_cat == 6, lcolor(maroon) lwidth(medthick)), ///
       title("Average Years of Education by Family Size", size(medlarge)) ///
       xtitle("Birth Year", size(medsmall)) ///
       ytitle("Years of Education", size(medsmall)) ///
       xlabel(1960(10)1990, grid gstyle(dot)) ///
       ylabel(, grid gstyle(dot)) ///
       legend(pos(6) cols(6) size(vsmall) symxsize(*0.7) ///
              order(1 2 3 4 5 6) ///
              label(1 "1 child") ///
              label(2 "2 child") ///
              label(3 "3 child") ///
              label(4 "4 child") ///
              label(5 "5 child") ///
              label(6 "6+ child")) ///
       graphregion(color(white)) plotregion(color(white))
       
graph export "$RESULT/figures/edu_size.png", replace width(2000)

* FIGURE : Junior High Completion Rate (≥9 years) by Family Size
twoway (line junior_rate year if family_cat == 1, lcolor(navy) lwidth(medthick)) ///
       (line junior_rate year if family_cat == 2, lcolor(ebblue) lwidth(medthick)) ///
       (line junior_rate year if family_cat == 3, lcolor(eltgreen) lwidth(medthick)) ///
       (line junior_rate year if family_cat == 4, lcolor(erose) lwidth(medthick)) ///
       (line junior_rate year if family_cat == 5, lcolor(cranberry) lwidth(medthick)) ///
       (line junior_rate year if family_cat == 6, lcolor(maroon) lwidth(medthick)), ///
       title("Junior High Completion Rate by Family Size", size(medlarge)) ///
       xtitle("Birth Year", size(medsmall)) ///
       ytitle("Completion Rate", size(medsmall)) ///
       xlabel(1960(10)1990, grid gstyle(dot)) ///
       ylabel(0(0.2)1, grid gstyle(dot) format(%2.1f)) ///
       legend(pos(6) cols(6) size(vsmall) symxsize(*0.7) ///
              order(1 2 3 4 5 6) ///
              label(1 "1-child") ///
              label(2 "2-child") ///
              label(3 "3-child") ///
              label(4 "4-child") ///
              label(5 "5-child") ///
              label(6 "6+ child")) ///
       graphregion(color(white)) plotregion(color(white))
	   
* Note: Completion rate = proportion with ≥9 years of education.
       
graph export "$RESULT/figures/junior_comp_size.png", replace width(2000)

* FIGURE : High School Completion Rate (≥12 years) by Family Size
twoway (line highschool_rate year if family_cat == 1, lcolor(navy) lwidth(medthick)) ///
       (line highschool_rate year if family_cat == 2, lcolor(ebblue) lwidth(medthick)) ///
       (line highschool_rate year if family_cat == 3, lcolor(eltgreen) lwidth(medthick)) ///
       (line highschool_rate year if family_cat == 4, lcolor(erose) lwidth(medthick)) ///
       (line highschool_rate year if family_cat == 5, lcolor(cranberry) lwidth(medthick)) ///
       (line highschool_rate year if family_cat == 6, lcolor(maroon) lwidth(medthick)), ///
       title("High School Completion Rate by Family Size", size(medlarge)) ///
       xtitle("Birth Year", size(medsmall)) ///
       ytitle("Completion Rate", size(medsmall)) ///
       xlabel(1960(10)1990, grid gstyle(dot)) ///
       ylabel(0(0.2)1, grid gstyle(dot) format(%2.1f)) ///
       legend(pos(6) cols(6) size(vsmall) symxsize(*0.7) ///
              order(1 2 3 4 5 6) ///
              label(1 "1 child") ///
              label(2 "2 child") ///
              label(3 "3 child") ///
              label(4 "4 child") ///
              label(5 "5 child") ///
              label(6 "6+ child")) ///
       graphregion(color(white)) plotregion(color(white))
       
* Note: Completion rate = proportion with ≥12 years of education.
	
graph export "$RESULT/figures/highschool_comp_size.png", replace width(2000)