namespace eval ::mbar {
}

proc ::mbar::init {path} {
	set mbar [menu $path -type menubar]
	
	# ===========================example code=============================
	set mfile [menu $mbar.file  -postcommand ::mbar::mfile_post]
	$mfile add command \
		-compound left \
		-label [::msgcat::mc "Exit"] \
		-accelerator "Ctrl-q" \
		-state normal  \
		-command {exit}

	$mbar add cascade  -label [::msgcat::mc "File"] -menu $mfile
	bind . <Control-q> {exit}
	# ====================================================================


	return $path
}

# ===========================example code=============================
proc ::mbar::mfile_post {} {
	
}
# ====================================================================

