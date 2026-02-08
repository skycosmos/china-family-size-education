**************************************************
* 05_decollective_event_study.do
** Author: Tianyu Zheng
** Date: April 10, 2025
** Version: Stata/MP 18.0
**************************************************

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
esttab event_edu event_junior_artic event_senior_artic using "$RESULT/tables/event_decollective.tex", replace ///
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