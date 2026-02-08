**************************************************
* main_do.do
** Author: Tianyu Zheng
** Date: April 10, 2025
** Version: Stata/MP 18.0
**************************************************

*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------

/* Preliminary Analysis */

*-------------------------------------------------------------------------------

** Table : Summary Statistics
** total / urban / rural

use "process/data_processed.dta", clear

gen log_income = log(income)
label var log_income "Log Annual Income"

gen age = 2018 - year
label var age "Age in 2018"

eststo clear

estpost summarize age female sib rank househead child edu log_income
eststo total

preserve
keep if rural == 1
estpost summarize age female sib rank househead child edu log_income
eststo rural
restore

preserve
keep if rural == 0
estpost summarize age female sib rank househead child edu log_income
eststo urban
restore

esttab total rural urban using "table/summary.tex", replace ///
    cells("mean(fmt(3)) sd(fmt(3))") ///
    title("Summary Statistics") ///
	label ///
    tex
	
*-------------------------------------------------------------------------------

** Table : Distribution of Samples by Family Size and Birth Order

use "process/data_processed.dta", clear

tabout family_cat rank_cat using "table/dist_size_order.tex", ///
    style(tex) replace cells(freq col) clab(N_%) ///
    topf("table/header.tex") botf("table/footer.tex")
	
*-------------------------------------------------------------------------------

** Table & Figure: Income, Family Size, Rank among Siblings, Educational Attainment

use "process/data_processed.dta", clear
estimates clear

gen log_income = log(income)
label var log_income "Log Income"

gen log_asset = log(fin_asset)
label var log_asset "Log Assets"

gen age = 2018 - year
label var age "Age in 2018"

gen age_sqrt = age^2
label var age_sqrt "Age^2"

keep if age >= 30 & age < 55
	
eststo clear

// Model 1-2: log_income without education control
reg log_income age age_sqrt female child i.family_cat i.rank_cat
estadd local FE "No"
estadd local EduControl "No"
eststo Model1

areg log_income age age_sqrt female child i.family_cat i.rank_cat, absorb(prov)
estadd local FE "Yes"
estadd local EduControl "No"
eststo Model2

// Model 3-4: log_income with education control
reg log_income age age_sqrt edu female child i.family_cat i.rank_cat
estadd local FE "No"
estadd local EduControl "Yes"
eststo Model3

areg log_income age age_sqrt edu female child i.family_cat i.rank_cat, absorb(prov)
estadd local FE "Yes"
estadd local EduControl "Yes"
eststo Model4

// Model 5-6: log_asset with education control
reg log_asset age age_sqrt female child i.family_cat i.rank_cat, absorb(prov)
estadd local FE "Yes"
estadd local EduControl "No"
eststo Model5

areg log_asset age age_sqrt edu female child i.family_cat i.rank_cat, absorb(prov)
estadd local FE "Yes"
estadd local EduControl "Yes"
eststo Model6

// Table
esttab Model1 Model2 Model3 Model4 Model5 Model6 using "table/income.tex", replace ///
    keep(age age_sqrt female child edu 2.family_cat 3.family_cat 4.family_cat 5.family_cat 6.family_cat 2.rank_cat 3.rank_cat 4.rank_cat 5.rank_cat 6.rank_cat) ///
    stats(FE EduControl r2 N, fmt(s s 3 0)) ///
    se star(* 0.1 ** 0.05 *** 0.01) ///
    title("Family Size and Birth Order Effects on Income") ///
    collabels("OLS (1)" "FE (2)" "OLS (3)" "FE (4)" "FE (5)" "FE (6)") ///
    alignment(D{.}{.}{-1}) ///
    compress nogap ///
    label booktabs ///
    refcat(2.family_cat "Family Size" 2.rank_cat "Birth Order", nolabel)

// Figure
coefplot Model2 Model4, ///
    keep(2.family_cat 3.family_cat 4.family_cat 5.family_cat 6.family_cat) ///
    vertical ///
	connect (l) ///
	ciopts(lpattern(dash)) ///
    xlabel(1 "2" 2 "3" 3 "4" 4 "5" 5 "6+") ///
    yline(0, lcolor(red) lpattern(dash)) ///
    title("The Impact of Family Size on Log Income") ///
	xtitle("Family Size", size(medsmall)) ///
	ytitle("Coeffcient Estimates") ///
    legend(label(2 "Without Edu Control") label(4 "With Edu Control")) ///
    scheme(s1color) ///
    plotregion(color(white)) graphregion(color(white))

graph export "fig/income.png", replace

*-------------------------------------------------------------------------------

** FIGURE: Distribution of Family Size by Birth Year

use "process/data_processed.dta", clear

* Calculate percentages by year
contract year family_cat, freq(count)
bysort year: egen total = total(count)
gen pct = (count/total)*100

reshape wide pct count, i(year) j(family_cat)

twoway (line pct6 year, lcolor(maroon%80) lwidth(medthick)) ///
       (line pct5 year, lcolor(cranberry%80) lwidth(medthick)) ///
       (line pct4 year, lcolor(erose%80) lwidth(medthick)) ///
       (line pct3 year, lcolor(eltgreen%80) lwidth(medthick)) ///
       (line pct2 year, lcolor(ebblue%80) lwidth(medthick)) ///
       (line pct1 year, lcolor(navy%80) lwidth(medthick)), ///
       title("Family Size Distribution by Birth Year", size(medlarge) margin(medium)) ///
       xtitle("Birth Year", size(medsmall)) ///
       ytitle("Percentage of Sample (%)", size(medsmall)) ///
       xlabel(1960(10)1990, grid gstyle(dot)) ///
       ylabel(0(10)60, grid gstyle(dot) format(%2.0f)) ///
       legend(pos(6) cols(6) size(vsmall) symxsize(*0.7) ///
              order(6 5 4 3 2 1) ///
              label(1 "6+ child") ///
              label(2 "5 child") ///
              label(3 "4 child") ///
              label(4 "3 child") ///
              label(5 "2 child") ///
              label(6 "1 child")) ///
       graphregion(color(white)) plotregion(color(white)) ///
	   xline(1973, lpattern(dash) lcolor(black) lwidth(medthin)) ///
       xline(1979, lpattern(dash) lcolor(black) lwidth(medthin)) ///
	   text(50 1973.2 "1973: Family Planning Policy", placement(e) size(vsmall)) ///
       text(35 1979.2 "1979: One Child Policy", placement(e) size(vsmall))
	   
graph export "fig/family_size_dist.png", replace

*-------------------------------------------------------------------------------

** FIGURE: Distribution of Highest Grade Completed by Birth Cohort

use "process/data_processed.dta", clear

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
	
graph export "fig/highest_edu_dist.png", replace

*-------------------------------------------------------------------------------

** FIGURE: Average Educational Attainment by Birth Year

use "process/data_processed.dta", clear

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

graph export "fig/avg_edu_year.png", replace

*-------------------------------------------------------------------------------

** FIGURES: Educational Attainment by Family Size

use "process/data_processed.dta", clear

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
       
graph export "fig/edu_size.png", replace width(2000)

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
       
graph export "fig/junior_comp_size.png", replace width(2000)

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
	
graph export "fig/highschool_comp_size.png", replace width(2000)


*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------

/* Decollective */

*-------------------------------------------------------------------------------

/* Difference-in-Differnce */

use "process/data_processed.dta", clear

estimates clear

// Merge policy implementation data
rename prov_birth province
merge m:1 province using "data/policy_time.dta"
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
esttab model_edu junior_artic senior_artic using "./table/did_decollective.tex", replace ///
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

graph export "./fig/did_decollective_edu.png", replace width(2000)

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

graph export "./fig/did_decollective_artic.png", replace width(2000)

*-------------------------------------------------------------------------------

/* Event Study */

// Create and adjust event time (shift to avoid negative values)
gen event_time = grade_9_year - time + 5
keep if inrange(event_time, 0, 10)

label define event_time_lbl ///
    0 "-5" 1 "-4" 2 "-3" 3 "-2" 4 "-1" ///
    5 "0" 6 "+1" 7 "+2" 8 "+3" 9 "+4" 10 "+5"
label values event_time event_time_lbl

// Run regression with family size interactions
reghdfe junior_artic i.family_cat##ib4.event_time, ///  // Using t=-1 (event_time=4) as reference
    absorb(prov_birth grade_9_year) vce(cluster prov_birth)
estimates store event_junior_artic

reghdfe senior_artic i.family_cat##ib4.event_time, ///  // Using t=-1 (event_time=4) as reference
    absorb(prov_birth grade_12_year) vce(cluster prov_birth)
estimates store event_senior_artic

reghdfe edu i.family_cat##ib4.event_time, ///  // Using t=-1 (event_time=4) as reference
    absorb(prov_birth year) vce(cluster prov_birth)
estimates store event_edu

* Event Study Table for Junior High Articulation
esttab event_edu event_junior_artic event_senior_artic using "./table/event_decollective.tex", replace ///
    b(3) se(3) nobaselevels noomitted ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    label booktabs ///
    title("Event Study: Impact of Decollectivization on Junior High Articulation by Family Size") ///
	mgroups("Years of Education" "Junior High Completion" "Senior High Completion", ///
			pattern(1 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
    keep(*.family_cat#*.event_time) ///
    stats(N r2, fmt(0 3) labels("Observations" "R-squared")) ///
    addnotes("Notes: Table shows coefficients from family size × event time interactions." ///
             "The omitted category is t=-1 (1 year before policy implementation)." ///
             "Standard errors clustered at province level in parentheses." ///
             "*** p<0.01, ** p<0.05, * p<0.10.") ///
    prehead("\begin{table}[htbp]\centering\small\caption{@title}") ///
    postfoot("\end{table}")

*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------

/* Family Planning Policy */
use "process/data_processed.dta", clear

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
    using "table/first_born.tex", replace ///
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
