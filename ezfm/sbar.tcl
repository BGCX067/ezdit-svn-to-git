namespace eval ::sbar {
	variable Priv
	array set Priv ""
}

proc ::sbar::init {path} {
	variable Priv
	
	set sbar [::ttk::frame $path]

	::ttk::label $sbar.padding
	::ttk::label $sbar.count  -justify left -anchor w
	
	pack $sbar.padding -padx 5 -side left
	pack $sbar.count -expand 0 -fill y -padx 1 -pady 1 -side left

	set Priv(lblFileCount) $sbar.count
	
	trace add variable ::rframe::Priv(fileCount) write {::sbar::trace_fileCount}
	
	return $path
}

proc ::sbar::trace_fileCount {name1 name2 op} {
	variable Priv
	$Priv(lblFileCount) configure -text [::msgcat::mc " '%s' items" $::rframe::Priv(fileCount)]
}
