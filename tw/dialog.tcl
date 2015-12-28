package provide ::tw::dialog  $::tw::OPTS(version)

::oo::class create ::tw::dialog {
	constructor {path args} {
		my variable PRIV OPTS
		
		array set OPTS [list \
			-title "" \
			-grab "" \
			-position "" \
			-modal 1 \
			-cancel 1 \
			-buttons "" \
			-default "" \
			-command {} \
		]
		array set OPTS $args
		
		array set PRIV [list \
			btnSN 0\
			ret "" \
		]		
		
		set PRIV(path) $path
	}

	destructor {
		my variable PRIV OPTS
		array unset PRIV
		array unset OPTS
	}
	
	method body {parent} {
		
	}
	
	method bottom {parent} {
		my variable PRIV OPTS
		
		set win $PRIV(path)
		set cut 0
		foreach {txt id} [lreverse $OPTS(-buttons)] {
			set btn [ttk::button $parent.$cut -text $txt -command [list [self object] close $id]]
			
			if {$id == $OPTS(-default)} {
				$btn configure -default active
				bind $win <Return> [list  $btn invoke]
			}
			pack $btn -side right -padx 3 -pady 3
			incr cut
		}
	}	
	
	method close {ret} {
		my variable PRIV OPTS
		set PRIV(ret) $ret
		
		if {$OPTS(-command) != ""} {
			if {[eval [linsert $OPTS(-command) end $ret]] == -1} {return}
		}
		
		after idle [destroy $PRIV(path)]
	}

	method data {} {
		my variable PRIV OPTS
		return $PRIV(ret)
	}

	method move_center {{width ""} {height ""}} {
		my variable PRIV OPTS
		
		update
		set win $PRIV(path)
		foreach {s x y} [split [wm geometry [winfo parent $win]] "+"] {break}
		foreach {w h} [split $s "x"] {break}
		
		set oX [expr $x+$w/2]
		set oY [expr $y+$h/2]
	
		foreach {s x y} [split [wm geometry $win] "+"] {break}
		foreach {w h} [split $s "x"] {break}
		
		if {$width != ""} {set w $width}
		if {$height != ""} {set h $height}
	
		set oX [expr $oX-$w/2]
		set oY [expr $oY-$h/2]
	
		wm geometry $win ${w}x${h}+${oX}+${oY}
		
	}	
	
	method move_near {{width ""} {height ""}} {
		my variable PRIV OPTS
		
		update
		set win $PRIV(path)
		lassign [winfo pointerxy [winfo parent $win]] oX oY
	
		foreach {s x y} [split [wm geometry $win] "+"] {break}
		foreach {w h} [split $s "x"] {break}	
		
		set oX [expr $oX + 10]
		set oY [expr $oY - 10]
		
		if {$width != ""} {set w $width}
		if {$height != ""} {set h $height}		
	
		wm geometry $win ${w}x${h}+${oX}+${oY}
	}
	
	method show {{geometry ""}} {
		my variable PRIV OPTS
		
		set win [toplevel $PRIV(path)]
		wm title $win $OPTS(-title)
		wm transient $win .
		wm withdraw $win
		wm state $win normal		
		
		pack [ttk::frame $win.body] -expand 1 -fill both -side top
		pack [ttk::frame $win.bottom] -fill x
		
		my body $win.body

		if {$OPTS(-buttons) != ""} {my bottom $win.bottom}

		if {$OPTS(-cancel)} {
			wm protocol $win WM_DELETE_WINDOW   [list [self object] close ""]
		} else {
			wm protocol $win WM_DELETE_WINDOW   {namespace eval :: {}}
		}

		update

		if {$OPTS(-position) == "near" } {my move_near}
		if {$OPTS(-position) == "center" } {my move_center}

		if {$OPTS(-grab) == "global"} {
			grab -global  $win
		} elseif {$OPTS(-grab) == "local"} {
			grab $win	
		}

		if {$geometry != ""} {wm geometry $win $geometry}
		
		if {$OPTS(-modal) == 0} {return}
		
		tkwait window $win
		
		return $PRIV(ret)
	}
}

::oo::class create ::tw::dialog::msgbox {
	superclass ::tw::dialog
	constructor {path args} {
		my variable PRIV OPTS
		
		array set opts [list \
			-icon "" \
			-message "" \
			-detail "" \
		]
		array set opts $args
		
		next $path {*}[array get opts]	
	}
	
	method body {parent} {
		my variable PRIV OPTS

		set fmeMain $parent	

		if {$OPTS(-icon) != ""} {
			set lblIcon [ttk::label $fmeMain.icon -image $OPTS(-icon)]
			pack $lblIcon -padx 2 -pady 2 -side left  -anchor nw
		}
	
		set body [ttk::frame $fmeMain.body]
		
		set  lblMessage [ttk::label $body.lblMessage -text $OPTS(-message) -anchor nw]
		pack $lblMessage -expand 1 -fill both -padx 2 -pady 2 -side top
		
		if {$OPTS(-detail) != ""} {
			set lblDetail [ttk::label $body.lblDetail \
								-text $OPTS(-detail) \
								-anchor nw ]
			pack $lblDetail -fill x -padx 2 -pady 2 -side top
		}
		pack $body -expand 1 -fill both -side left
	}
}

::oo::class create ::tw::dialog::inputbox {
	superclass ::tw::dialog
	constructor {path args} {
		my variable PRIV OPTS

		array set opts [list \
			-icon "" \
			-message "" \
			-detail "" \
			-value "" \
		]
		
		array set opts $args
		
		next $path {*}[array get opts]	
	}
	
	method body {parent} {
		my variable PRIV OPTS
		
		set fmeMain $parent
	
		if {[info exists OPTS(-icon)]} {
			set lblIcon [ttk::label $fmeMain.icon -image $OPTS(-icon)]
			pack $lblIcon -padx 2 -pady 2 -side left  -anchor nw
		}
	
		set body [ttk::frame $fmeMain.body]
		set lblMessage [ttk::label $body.lblMessage -text $OPTS(-message) -anchor nw]
		
		pack $lblMessage -expand 1 -fill both -padx 2 -pady 2 -side top
		
		if {[info exists OPTS(-detail)]} {
			set lblDetail [ttk::label $body.lblDetail \
								-text $OPTS(-detail) \
								-anchor nw ]
			pack $lblDetail -fill x -padx 2 -pady 2 -side top
		}
		
		set txtInput [ttk::entry $body.txt -textvariable [self namespace]::OPTS(-value)]
		$txtInput selection range 0 end
		focus $txtInput

		pack $txtInput -expand 1 -fill x -padx 2 -pady 2 -side top
		pack $body -expand 1 -fill both
	}
	
	method data {} {
		my variable PRIV OPTS
		return $OPTS(-value)
	}
		
}

::oo::class create ::tw::dialog::fontbox {
	superclass ::tw::dialog
	constructor {path args} {
		my variable PRIV OPTS

		array set opts [list \
			-size "" \
			-family "" \
		]
		
		set PRIV(font) [font create]
		
		array set opts $args

		if {$opts(-size) != ""} {font configure $PRIV(font) -size $opts(-size)}
		if {$opts(-family) != ""} {font configure $PRIV(font) -family $opts(-family)}
		
		next $path {*}[array get opts]	
	}
	
	method destructor {} {
		my variable PRIV OPTS
		font delete $PRIV(font)
		next
	}
	
	method body {parent} {
		my variable PRIV OPTS
		
		set fme $parent
		
		set OPTS(-size) [font configure $PRIV(font) -size]
		set OPTS(-family) [font configure $PRIV(font) -family]
		if {[string index $OPTS(-family) 0] == "\{" && [string index $OPTS(-family) end] == "\}"} {
			set OPTS(-family) [string range $OPTS(-family) 1 end-1]
		}
		
		set fonts [list] 
		foreach f [lsort -dictionary [font families]] {lappend fonts $f}
		set sizes [list] 
		foreach f [list 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24] {lappend sizes $f}			
		
		set lblFont [ttk::label $fme.lbl -text [::msgcat::mc "Font"]]
		set cmbFont [ttk::combobox $fme.cmbFont \
			-state readonly \
			-values $fonts \
			-textvariable [self namespace]::OPTS(-family)]

		set cmbSize [ttk::combobox $fme.cmbSize \
			-state readonly \
			-values $sizes \
			-textvariable [self namespace]::OPTS(-size)]	
		
		set btnPreview [ttk::button $fme.btn -text [::msgcat::mc "Preview"] \
			-command [namespace code {
					font configure $PRIV(font) -size $OPTS(-size) -family $OPTS(-family)
		}]]
		
		set txt [text $fme.txt  -height 3 -bd 2 -width 25 \
			-relief groove \
			-font $PRIV(font)]	
		$txt insert end "Test : 123 abc ABC"
		
		grid $lblFont $cmbFont $cmbSize -sticky "news" -padx 5 -pady 5
		grid $btnPreview -sticky "news" -padx 5 -pady 5
		grid $txt  - - -sticky "news" -padx 5 -pady 5
		
		grid rowconfigure $fme 2 -weight 1
		grid columnconfigure $fme 1 -weight 1		
		
	}
	
	method data {} {
		my variable PRIV OPTS
		return [list -size $OPTS(-size) -family $OPTS(-family)]
	}
		
}


