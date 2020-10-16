gen period_3y=year
recode period_3y 1995/1996=1 1997/1999=2 2000/2002=3 2003/2005=4 2006/2008=5 2009/2011=6 2012/2014=7
bysort code period_3y: egen rk=rank(year)
drop if year<1995 
drop if year==2015
encode code,gen(id)
gen bis_ratio=(bis_household/bis_total)*100
global Y bis_total bis_firm bis_household bis_ratio
foreach x of varlist $Y {
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
collapse (mean) $Y D* G* g* d* FINAL* INITIAL* wdi_gdppc wdi_inflation wdi_govexp wdi_trade,by(id period_3y)
xtset id period_3y
gen Lincome=log(wdi_gdppc)
gen Linflation=log(wdi_inflation)
gen Lgov=log(wdi_govexp)
gen Ltrade=log(wdi_trade)
global X L.Lincome L.Linflation L.Lgov L.Ltrade	
foreach x in "total" "firm" "household" "ratio"  {
xtreg gbis_`x' INITIALbis_`x' i.period_3y if INITIALbis_`x'!=., fe vce(cluster id)
xtreg gbis_`x' INITIALbis_`x' $X i.period_3y if INITIALbis_`x'!=., fe vce(cluster id)
}
