namespace eval ::sbar {
	variable Priv
	array set Priv [list \
		msg "" \
		tok "" \
		tid "" \
	]
}

proc ::sbar::init {path} {
	variable Priv
	
	set ibox $::dApp::Priv(ibox)
	
	set fme [ttk::frame $path -borderwidth 1 -relief groove]
	set lblMsg [ttk::label $path.lblMsg -textvariable ::sbar::Priv(msg) -anchor w -justify left]
	
	set lblNum [::ttk::label $path.lblNum -text "相簿類型 : " -justify left -anchor w ]
	set txtNum [::ttk::label $path.txtNum -textvariable ::dApp::Priv(cmdNs) -justify left -anchor w -width 8]	
		
	
	set pbar [::ttk::progressbar $path.pbar -orient horizontal]
	
	set sizegrip [ttk::sizegrip $path.srip]

	pack $lblMsg -expand 1 -fill x -padx 3 -side left -pady 2
	pack $lblNum $txtNum -side left
	pack [::ttk::label $path.span -width 3] -side left 
	pack $pbar -side left -pady 3 
	pack $sizegrip -expand 0 -padx 5 -side left -pady 4 -pady 1
	
	set Priv(pbar) $pbar
	set Priv(tok) ::sbar::tok
	interp alias {} $Priv(tok) {} ::sbar::dispatch
	set ::dApp::Priv(win,sbar) ::sbar::tok

	return $path
}

proc ::sbar::cmd_pbar_set {max val} {
	variable Priv
	$Priv(pbar) configure -maximum $max -value $val
}

proc ::sbar::cmd_put {msg {tout 5000}} {
	variable Priv
	
	catch {after cancel $Priv(tid)}
	set Priv(msg) $msg
	if {$tout >= 0} {set Priv(tid) [after $tout [list set ::sbar::Priv(msg) ""]]}
}

proc ::sbar::dispatch {args} {
	variable Priv
	
	set cmd ::sbar::cmd_[lindex $args 0]
	foreach arg [lrange $args 1 end] {lappend cmd $arg}
	return [eval $cmd]	
}


