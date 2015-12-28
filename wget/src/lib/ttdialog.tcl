package provide ttdialog 1.0



namespace eval ::ttdialog {
	variable Priv
	array set Priv [list messageBox_ret -1 dialog_ret -1]
}

proc ::ttdialog::dialog_basic {path arglist} {
	variable Priv
	array set opts [list \
		-title "" \
		-default "" \
		-buttons "yes yes" \
	]

	array set opts $arglist
	
	set win [toplevel $path]
	pack [ttk::frame $win.body] -expand 1 -fill both -side top
	pack [ttk::frame $win.fmeBtn] -fill x
	set cut 0
	foreach {ret txt} [lreverse $opts(-buttons)] {
		set btn [ttk::button $win.fmeBtn.$cut -text $txt -command [format {
			set ::ttdialog::Priv(dialog_ret) "%s"
			destroy "%s"
		} $ret $win]]
		if {$ret == $opts(-default)} {
			$btn configure -default active
			bind $win <Return> [list  $btn invoke]
		}
		pack $btn -side right -padx 3 -pady 3
		incr cut
	}	
	
	wm title $win $opts(-title)
	update
	wm transient $win .
	update
	wm withdraw $win
	wm state $win normal
	wm protocol $win WM_DELETE_WINDOW [format {
		set ::ttdialog::Priv(dialog_ret) -1
		after idle [list destroy "%s"]
	} $win]
	return $win
}

proc ::ttdialog::clientframe {path} {
	return $path.body
}

proc ::ttdialog::dialog {path args} {
	variable Priv	
	return [::ttdialog::dialog_basic $path $args]
}

proc ::ttdialog::dialog_wait {path} {
	tkwait variable ::ttdialog::Priv(dialog_ret)
	return $::ttdialog::Priv(dialog_ret)	
}

proc ::ttdialog::dialog_move_center {path {width ""} {height ""}} {
	#tkwait visibility $path
	update
	foreach {s x y} [split [wm geometry .] "+"] {break}
	foreach {w h} [split $s "x"] {break}
	
	set oX [expr $x+$w/2]
	set oY [expr $y+$h/2]

	foreach {s x y} [split [wm geometry $path] "+"] {break}
	foreach {w h} [split $s "x"] {break}
	
	if {$width != ""} {set w $width}
	if {$height != ""} {set h $height}

	
	
	set oX [expr $oX-$w/2]
	set oY [expr $oY-$h/2]

	wm geometry $path ${w}x${h}+${oX}+${oY}
	
}

proc ::ttdialog::dialog_move_near {path} {
	#tkwait visibility $path
	update
	lassign [winfo pointerxy .] oX oY

	foreach {s x y} [split [wm geometry $path] "+"] {break}
	foreach {w h} [split $s "x"] {break}	
	
	set oX [expr $oX + 10]
	set oY [expr $oY - 10]

	wm geometry $path ${w}x${h}+${oX}+${oY}
	
}

proc ::ttdialog::inputBox {path args} {
	variable Priv
	array set opts [list \
		-title "" \
		-message "" \
		-default "" \
		-value "" \
		-buttons "yes yes" \
	]
	array set opts $args
	
	set win [::ttdialog::dialog_basic $path [array get opts]]
	set fmeMain [::ttdialog::clientframe $win]

	if {[info exists opts(-icon)]} {
		set lblIcon [ttk::label $fmeMain.icon -image $opts(-icon)]
	}

	set body [ttk::frame $fmeMain.body]
	set lblMessage [ttk::label $body.lblMessage -text $opts(-message) -anchor nw]
	
	pack $lblMessage -expand 1 -fill both -padx 2 -pady 2 -side top
	
	if {[info exists opts(-detail)]} {
		set lblDetail [ttk::label $body.lblDetail \
							-text $opts(-detail) \
							-anchor nw ]
		pack $lblDetail -fill x -padx 2 -pady 2 -side top
	}
	
	set Priv($path,txtvar) $opts(-value)
	set txtInput [ttk::entry $body.txt -textvariable ::ttdialog::Priv($path,txtvar)]
	
	
	pack $txtInput -expand 1 -fill x -padx 2 -pady 2 -side top
	pack $body -expand 1 -fill both
	
	
	grab set $win
	focus $txtInput
	$txtInput selection range 0 end
#	::ttdialog::dialog_move_center $win
	::ttdialog::dialog_move_near $win
	tkwait variable ::ttdialog::Priv(dialog_ret)
	array unset opts
	destroy $path
	return [list $::ttdialog::Priv(dialog_ret) $::ttdialog::Priv($path,txtvar)]
}

proc ::ttdialog::messageBox {path args} {
	variable Priv
	array set opts [list \
		-title "" \
		-message "" \
		-default "" \
		-buttons "yes yes" \
	]
	array set opts $args
	
	set win [::ttdialog::dialog_basic $path [array get opts]]
	set fmeMain [::ttdialog::clientframe $win]

	if {[info exists opts(-icon)]} {
		set lblIcon [ttk::label $fmeMain.icon -image $opts(-icon)]
	}

	set body [ttk::frame $fmeMain.body]
	set lblMessage [ttk::label $body.lblMessage -text $opts(-message) -anchor nw]
	
	pack $lblMessage -expand 1 -fill both -padx 2 -pady 2 -side top
	
	if {[info exists opts(-detail)]} {
		set lblDetail [ttk::label $body.lblDetail \
							-text $opts(-detail) \
							-anchor nw ]
		pack $lblDetail -fill x -padx 2 -pady 2 -side top
	}
	
	pack $body -expand 1 -fill both
	
	
	grab set $win
	focus $win
#	::ttdialog::dialog_move_center $win
	::ttdialog::dialog_move_near $win
	tkwait variable ::ttdialog::Priv(dialog_ret)
	array unset opts
	destroy $path
	return $::ttdialog::Priv(dialog_ret)
}
