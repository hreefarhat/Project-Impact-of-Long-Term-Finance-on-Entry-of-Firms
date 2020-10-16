
*Period and group
gen period_3y=year
recode period_3y 1995/1996=1 1997/1999=2 2000/2002=3 2003/2005=4 2006/2008=5 2009/2011=6 2012/2014=7
bysort code period_3y: egen rk=rank(year)

encode code,gen(id)
encode INC_GR,gen(inc_gr)
xtset id year

*Ratio
gen ratio_HC=(sect_household/sect_total)*100
gen ratio_FC=(sect_firm/sect_total)*100

gen ratio_HOME=(sect_home/sect_household)*100
gen ratio_NONHOME=(sect_nonhome/sect_household)*100

gen ratio_agri=(sect_agri/sect_firm)*100
gen ratio_industry=(sect_industry/sect_firm)*100
gen ratio_construction=(sect_construction/sect_firm)*100
gen ratio_transport=(sect_transport/sect_firm)*100
gen ratio_trade=(sect_trade/sect_firm)*100
gen ratio_misc=(sect_misc/sect_firm)*100

*Growth and difference 
global Y1 sect_total sect_firm sect_household
global Y2 sect_home sect_nonhome
global Y3 sect_agri sect_industry sect_const sect_transport sect_trade sect_misc
foreach x of varlist $Y1 $Y2 $Y3 ratio_*{
gen temp_min=`x' if rk==1 
bysort code period_3y: egen MIN=min(temp_min)
gen temp_max=`x' if rk==3 
bysort code period_3y: egen MAX=min(temp_max)
gen D`x'=MAX-MIN
gen G`x'=(D`x'/MIN)*100
gen FINAL`x'=MAX
gen INITIAL`x'=MIN
drop temp_* MIN MAX
xtset id year
gen g`x'=((`x'-L.`x')/L.`x')*100
gen d`x'=(`x'-L.`x')
}

gen sample=1 if sect_total!=.
gen sample_firm=1 if sect_agri!=. & sect_industry!=. & sect_construction!=. & sect_transport!=. & sect_trade!=. & sect_misc!=.
gen sample_house=1 if sect_home!=.


******TABLE 1: Total credit, firm credit and household credit, summary statistics
foreach x in "sect_total" "sect_house" "sect_firm" "ratio_HC" "ratio_FC" {
table sample, c(count `x' mean `x' sd `x' min `x') 
table sample, c(min `x' p25 `x' media `x' p75 `x' max `x')
}


******TABLE 2: 
table inc_gr, c(mean sect_total mean sect_house mean sect_firm mean ratio_HC mean ratio_FC) 

sum sect_total,d
gen fd_gr=1 if sect_total<r(p25)
replace fd_gr=2 if sect_total>=r(p25) & sect_total<r(p50)
replace fd_gr=3 if sect_total>=r(p50) & sect_total<r(p75)
replace fd_gr=4 if sect_total>=r(p75) & sect_total!=.
table fd_gr, c(mean sect_total mean sect_house mean sect_firm mean ratio_HC mean ratio_FC) 


******TABLE 3
*Panel A
foreach x in "sect_house" "sect_home" "sect_nonhome" "ratio_HOME" "ratio_NONHOME" {
table sample, c(count `x' mean `x' sd `x' min `x') 
table sample, c(min `x' p25 `x' media `x' p75 `x' max `x')
}

*Panel B
foreach x in "sect_firm" "sect_agri" "sect_industry" "sect_construction" "sect_transport" "sect_trade" "sect_misc" {
table sample_firm, c(count `x' mean `x' sd `x' min `x') 
table sample_firm, c(min `x' p25 `x' media `x' p75 `x' max `x')
}
foreach x in "ratio_agri" "ratio_industry" "ratio_construction" "ratio_transport" "ratio_trade" "ratio_misc" {
table sample_firm, c(count `x' mean `x' sd `x' min `x') 
table sample_firm, c(min `x' p25 `x' media `x' p75 `x' max `x')
}


******TABLE 4
table inc_gr, c(mean ratio_HOME mean ratio_NONHOME mean ratio_agri mean ratio_industry)
table inc_gr, c(mean ratio_construction mean ratio_transport mean ratio_trade mean ratio_misc)

table fd_gr, c(mean ratio_HOME mean ratio_NONHOME mean ratio_agri mean ratio_industry)
table fd_gr, c(mean ratio_construction mean ratio_transport mean ratio_trade mean ratio_misc)


******Preparation of data (for subsequent tables)
collapse (mean) $Y1 $Y2 $Y3 ratio_* D* G* g* d* FINAL* INITIAL* wdi_gdppc wdi_inflation wdi_govexp wdi_trade wdi_education icrg_qog CVH_foreign_banks inc_gr*,by(code period_3y)
encode code, gen(id)
xtset id period_3y
global Y1 sect_total sect_firm sect_household ratio_HC
global Y2 sect_home sect_nonhome ratio_HOME
global Y3 sect_agri sect_industry sect_const sect_transport sect_trade

gen Lincome=log(wdi_gdppc)
gen Linflation=log(wdi_inflation)
gen Lgov=log(wdi_govexp)
gen Ltrade=log(wdi_trade)
global X L.Lincome L.Linflation L.Lgov L.Ltrade	

******TABLE 5
foreach x of varlist $Y1 {
xtreg g`x' INITIAL`x' i.period_3y if INITIALsect_total!=., fe vce(cluster id)
xtreg g`x' INITIAL`x' i.period_3y $X if INITIALsect_total!=., fe vce(cluster id)
}

******TABLE 6
foreach x of varlist $Y2 {
xtreg g`x' INITIAL`x' i.period_3y if INITIALsect_home!=., fe vce(cluster id)
xtreg g`x' INITIAL`x' i.period_3y $X if INITIALsect_home!=., fe vce(cluster id)
}

******TABLE 7
foreach x of varlist $Y3 {
xtreg g`x' INITIAL`x' i.period_3y if INITIALsect_firm!=., fe vce(cluster id)
xtreg g`x' INITIAL`x' i.period_3y $X if INITIALsect_firm!=., fe vce(cluster id)
}	

******TABLE 8
gen CRISIS=1 if period_3y>=6
replace CRISIS=0 if period_3y<6
foreach x of varlist $Y1 $Y2 $Y3 { 
gen GDPpc_`x'=INITIAL`x'*Lincome
gen FD_`x'=INITIAL`x'*INITIALsect_total
gen CRISIS_`x'=`x'*CRISIS
}
foreach x of varlist $Y1 {
xtreg g`x' INITIAL`x' GDPpc_`x' i.period_3y $X if INITIALsect_total!=., fe vce(cluster id)
xtreg g`x' INITIAL`x' FD_`x' i.period_3y $X if INITIALsect_total!=., fe vce(cluster id)
xtreg g`x' INITIAL`x' CRISIS_`x' i.period_3y $X if INITIALsect_total!=., fe vce(cluster id)
}


******TABLE 9
	***Institutions	(columns 1-2)
foreach x of varlist $Y1 {
xtreg g`x' INITIAL`x' $X i.period_3y if INITIALsect_total!=. & icrg!=., fe vce(cluster id)
xtreg g`x' INITIAL`x' $X icrg i.period_3y if INITIALsect_total!=., fe vce(cluster id)
}	
	
	***education (columns 3-4)
foreach x of varlist $Y1 {
xtreg g`x' INITIAL`x' $X i.period_3y if INITIALsect_total!=. & wdi_educ!=., fe vce(cluster id)
xtreg g`x' INITIAL`x' $X wdi_educ i.period_3y if INITIALsect_total!=., fe vce(cluster id)
}	
	***Foreign banks (columns 5-6)
foreach x of varlist $Y1 {
xtreg g`x' INITIAL`x' $X i.period_3y if INITIALsect_total!=. & CVH_foreign_banks!=., fe vce(cluster id)
xtreg g`x' INITIAL`x' $X CVH_foreign_banks i.period_3y if INITIALsect_total!=., fe vce(cluster id)
}	

