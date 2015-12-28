namespace eval ::tbar {
	variable Priv
	array set Priv ""
}

proc ::tbar::init {path} {
	variable Priv
		
	set ibox $::dApp::Priv(ibox)
	set tbar [::toolbar::toolbar $path -relief groove]
	set Priv(btnPrev) [$tbar add button -image "toolbar.btnPrev" -command {::rframe::cd_prev} -state disabled]
	set Priv(btnNext) [$tbar add button -image "toolbar.btnNext" -command {::rframe::cd_next} -state disabled]
	set Priv(btnUp) [$tbar add button -image "toolbar.btnUp" -command {::rframe::cd_up} -state disabled]
	$tbar add separator
	set Priv(btnHome) [$tbar add button -image "toolbar.btnHome" -command {::rframe::chdir $::env(HOME)}]
	$tbar add separator
	set Priv(btnSearch) [$tbar add button  -image "toolbar.btnSearch" ]
	$tbar add separator
	
	$tbar add label -text [::msgcat::mc "Path:"] -justify left
	set p [$tbar add entry -textvariable ::rframe::Priv(pwd) -justify left]
	pack $p -expand 1 -fill x -padx 10 -ipady 2
	
	trace add variable ::rframe::Priv write {::tbar::btn_state_ch}
	return [$tbar frame]
}

proc ::tbar::btn_state_ch {name1 name2 op} {
	variable Priv
	if {$name1 == "Priv" && $name2 == "historyIdx"} {
		if {$::rframe::Priv(historyIdx) == 0} {
			$Priv(btnPrev) configure -state disabled
		} else {
			$Priv(btnPrev) configure -state normal
		}

		if {$::rframe::Priv(historyIdx) >= ([llength $::rframe::Priv(historyList)]-1)} {
			$Priv(btnNext) configure -state disabled
		} else {
			$Priv(btnNext) configure -state normal
		}		
	}
	if {$name1 == "Priv" && $name2 == "pwd"} {
		if {![file exists $::rframe::Priv(pwd)] } {
			$Priv(btnUp) configure -state disabled
		} else {
			$Priv(btnUp) configure -state normal
		}
	}
}
