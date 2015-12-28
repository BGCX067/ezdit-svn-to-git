namespace eval ::sbar {
	variable Priv
	array set Priv ""
}

proc ::sbar::init {path} {
	variable Priv	

	::ttk::frame $path
	
	return $path
}