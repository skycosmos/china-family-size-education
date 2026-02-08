**************************************************
* 01_prelim_analysis.do
** Author: Tianyu Zheng
** Date: April 10, 2025
** Version: Stata/MP 18.0
**************************************************

/* Preliminary Analysis */

** Table : Summary Statistics
** total / urban / rural

use "$CLEAN/data_processed.dta", clear

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

esttab total rural urban using "$RESULT/tables/summary.tex", replace ///
    cells("mean(fmt(3)) sd(fmt(3))") ///
    title("Summary Statistics") ///
	label ///
    tex
	
*-------------------------------------------------------------------------------

** Table : Distribution of Samples by Family Size and Birth Order

use "$CLEAN/data_processed.dta", clear

tabout family_cat rank_cat using "$RESULT/tables/dist_size_order.tex", ///
    style(tex) replace cells(freq col) clab(N_%) ///
    topf("$RESULT/tables/header.tex") botf("$RESULT/tables/footer.tex")

*-------------------------------------------------------------------------------

** FIGURE: Distribution of Family Size by Birth Year

use "$CLEAN/data_processed.dta", clear

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
	   
graph export "$RESULT/figures/family_size_dist.png", replace