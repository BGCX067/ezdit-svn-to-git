namespace eval ::itemTemplBlank {}
proc ::itemTemplBlank::init {fpath} {
	close [open $fpath w]
	return ""
}
