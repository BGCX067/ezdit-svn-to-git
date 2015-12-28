namespace eval ::tbar {
}

proc ::tbar::init {path} {
	set tbar [::toolbar::toolbar $path -relief groove]
	
	# ===========================example code=============================
	$tbar add label \
		-text "debug"
	$tbar add entry \
		-textvariable ::imap::Priv(debug) -width 5
	$tbar add label \
		-text "max thread"
	$tbar add entry \
		-textvariable ::gvfs::Priv(maxThread) -width 5
	$tbar add label \
		-text "split size"
	$tbar add entry \
		-textvariable ::gvfs::Priv(splitSize) -width 10
	$tbar add button \
		-text [::msgcat::mc "Browse"] \
		-tooltip [::msgcat::mc "Browse"] \
		-command {::body::frame_show fmeTree}
	$tbar add button \
		-text [::msgcat::mc "Queue"] \
		-tooltip [::msgcat::mc "Queue"] \
		-command {::body::frame_show fmeQueue}	
		#-image [image create photo -file "./images/computer.png"]
	
	#$tbar add label -text "Label" -tooltip "Label"
	#$tbar add checkbutton -text "Hello" -tooltip "eeee"
	#$tbar add combobox -values "1 2 3 4 56"
	#$tbar  add separator
	# ====================================================================
	
	return [$tbar frame]
}
