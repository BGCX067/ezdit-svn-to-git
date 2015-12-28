namespace eval ::templSVN {
	variable wInfo
	array set wInfo ""
}

proc ::templSVN::init {projectPath} {
	if {[catch [list exec $::svnWrapper::svnInfo(CMD) --help]]} {
		tk_messageBox -title [::msgcat::mc "error"] -icon error -message [::msgcat::mc "Can't fond svn command"]
		return
	}
	return [::svnWrapper::svn_checkout_init $projectPath]
}
