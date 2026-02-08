**************************************************
* 04_decollective_did.do
** Author: Tianyu Zheng
** Date: April 10, 2025
** Version: Stata/MP 18.0
**************************************************

/* Decollective */

/* Difference-in-Differnce */

use "$CLEAN/data_processed.dta", clear

estimates clear

// Merge policy implementation data
rename prov_birth province
merge m:1 province using "$RAW/policy_time.dta"
drop prov_name _merge
rename province prov_birth

// Calculate school entry and graduation years
gen entry_year = year + 6  // Started school at age 6
gen grade_9_year = entry_year + 9  // Completed 9th grade at age 15 (6+9)
gen grade_12_year = entry_year + 12 // Completed 12th grade at age 18 (6+12)

// Create articulation indicators (restricted to 1970-1995 window)
gen junior_artic = (edu > 9) if inrange(grade_9_year, 1970, 1995) & edu >= 9
gen senior_artic = (edu > 12) if inrange(grade_12_year, 1970, 1995) & edu >= 12

// Years of Education
gen post = (year >= time)
reghdfe edu i.family_cat##post, absorb(year prov_birth) vce(cluster prov_birth)
estimates store model_edu

/* Regression Analysis */
// 9th Grade Articulation Rate
preserve
keep if inrange(grade_9_year, 1970, 1995)
replace post = (grade_9_year >= time)
reghdfe junior_artic i.family_cat##post, absorb(grade_9_year prov_birth) vce(cluster prov_birth) 
estimates store junior_artic
restore

// 12th Grade Articulation Rate
preserve
keep if inrange(grade_12_year, 1970, 1995)
replace post = (grade_12_year >= time)
reghdfe senior_artic i.family_cat##post, absorb(grade_12_year prov_birth) vce(cluster prov_birth)
estimates store senior_artic
restore

// Set display format for coefficients
set cformat %9.3f
	
// Main results table
esttab model_edu junior_artic senior_artic using "$RESULT/tables/did_decollective.tex", replace ///
    b(3) se(3) nobaselevels noomitted ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    label booktabs nomtitles ///
    title("DiD Estimates of Decollectivization Impact on Education") ///
    mgroups("Years of Education" "Junior High Articulation" "Senior High Articulation", ///
            pattern(1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
    keep(*.family_cat 1.post *.family_cat#*.post) ///
    order(*.family_cat 1.post *.family_cat#1.post) ///
    coeflabels(1.family_cat "1 child" ///
               2.family_cat "2 child" ///
               3.family_cat "3 child" ///
               4.family_cat "4 child" ///
               5.family_cat "5 child" ///
               6.family_cat "6+ child" ///
               1.post "Post-Decollective" ///
               1.family_cat#1.post "1 child × Post" ///
               2.family_cat#1.post "2 child × Post" ///
               3.family_cat#1.post "3 child × Post" ///
               4.family_cat#1.post "4 child × Post" ///
               5.family_cat#1.post "5 child × Post" ///
               6.family_cat#1.post "6+ child × Post") ///
    stats(N r2, fmt(0 3) labels("Observations" "R-squared")) ///
    addnotes("Notes: Standard errors in parentheses. *** p<0.01, ** p<0.05, * p<0.10.") ///
    prehead("\begin{table}[htbp]\centering\small") ///
    postfoot("\end{table}")
	
* Figure : Years of Education
coefplot (model_edu, keep(*.family_cat#1.post) ///
             recast(connected) lwidth(medthick) lcolor(navy) ///
             msymbol(O) msize(medlarge) mcolor(navy) ///
             ciopts(recast(rline) lpattern(dash) lcolor(navy*.6))), ///
    vertical ///
    xlabel(1 "2 child" 2 "3 child" 3 "4 child" 4 "5 child" 5 "6+ child", labsize(small)) ///
    ytitle("Coefficient Estimate", size(medsmall)) ///
    title("Treatment effects on Years of Education", size(medlarge)) ///
    subtitle("Family Size × Post-Decollectivization Interaction", size(medsmall)) ///
    legend(off) ///
    scheme(s1color) ///
    plotregion(fcolor(white)) ///
    graphregion(fcolor(white) margin(l=2 r=2)) ///
    note("Note: Dashed lines represent 95% confidence intervals.", size(vsmall)) ///
    yline(0, lcolor(gray) lpattern(solid) lwidth(medium)) ///
    xtitle("Family Size", size(medsmall)) ///
    ylabel(-2(0.5)0.5, nogrid)

graph export "$RESULT/figures/did_decollective_edu.png", replace width(2000)

* Figure : Articulation Rates
coefplot (junior_artic, keep(*.family_cat#1.post) ///
             recast(connected) lwidth(medthick) lcolor(cranberry) ///
             msymbol(D) msize(medlarge) mcolor(cranberry) ///
             ciopts(recast(rline) lpattern(dash) lcolor(cranberry*.6))) ///
         (senior_artic, keep(*.family_cat#1.post) ///
             recast(connected) lwidth(medthick) lcolor(forest_green) ///
             msymbol(S) msize(medlarge) mcolor(forest_green) ///
             ciopts(recast(rline) lpattern(dash) lcolor(forest_green*.6))), ///
    vertical ///
    xlabel(1 "2 child" 2 "3 child" 3 "4 child" 4 "5 child" 5 "6+ child", labsize(small)) ///
    ytitle("Coefficient Estimate", size(medsmall)) ///
    title("Treatment effects on School Articulation Rates", size(medlarge)) ///
    subtitle("Family Size × Post-Decollectivization Interaction", size(medsmall)) ///
    legend(order(2 "Junior High Articulation" 4 "Senior High Articulation") ///
           pos(6) rows(1) size(small)) ///
    scheme(s1color) ///
    plotregion(fcolor(white)) ///
    graphregion(fcolor(white) margin(l=2 r=2)) ///
    note("Note: Dashed lines represent 95% confidence intervals.", size(vsmall)) ///
    yline(0, lcolor(gray) lpattern(solid) lwidth(medium)) ///
    xtitle("Family Size", size(medsmall)) ///
    ylabel(-0.5(0.1)0.1, nogrid)

graph export "$RESULT/figures/did_decollective_artic.png", replace width(2000)

