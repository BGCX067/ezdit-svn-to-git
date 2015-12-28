proc ::svnWrapper::svn_properties_init {target} {
	variable svnInfo
	variable wInfo
	
	set path ".__svn_properties_init__"
	if {[winfo exists $path]} {destroy $path}
	Dialog $path -title [::msgcat::mc "Properties"] -modal local
	set fmeMain [$path getframe]
	
	set lblTarget [label $fmeMain.lblTarget -text [::msgcat::mc "Target : %s" $target] -anchor w -justify left]
	set fmeBody [ScrolledWindow $fmeMain.fmeBody -auto horizontal -relief groove -bd 1]
	set tree [treectrl $fmeBody.list \
		-font [::crowFont::get_font smaller] \
		-showroot no \
		-showline no \
		-width 400 \
		-selectmod single \
		-showrootbutton no \
		-showbuttons no \
		-showheader yes \
		-scrollmargin 16 \
		-highlightthickness 0 \
		-relief flat \
		-bd 0 \
		-bg white \
		-xscrolldelay "500 50" \
		-yscrolldelay "500 50"]
	$fmeBody setwidget $tree
	
	set fmeFun [frame $fmeMain.fmeFun]
	pack [button $fmeFun.btnAdd -text [::msgcat::mc "Add"] -width 10 -command {::svnWrapper::svn_properties_add "Add Properties"}] \
		-side left -fill both -pady 1
	pack [button $fmeFun.btnEdit -text [::msgcat::mc "Edit"] -width 10 -command {::svnWrapper::svn_properties_edit}] \
		-side left -fill both -padx 5 -pady 1
	pack [button $fmeFun.btnRemove -text [::msgcat::mc "Remove"] -width 10 -command {::svnWrapper::svn_properties_remove}] \
		-side left -fill both -pady 1
	
	pack [button $fmeFun.btnOk -text [::msgcat::mc "Ok"] -width 10 -command [list $path enddialog ""]] \
		-side right -fill both -pady 1	
	
	pack $lblTarget -fill x -padx 2 -pady 1
	pack $fmeBody -fill both -expand 1 -padx 2 -pady 1
	pack $fmeFun -fill x -padx 2 -pady 1 
	
	$tree column create -tag colProperty -font [::crowFont::get_font smaller] \
		-itembackground {#e0e8f0 {}} -expand no -text [::msgcat::mc "Property"]
	$tree column create -tag colValue -font [::crowFont::get_font smaller] \
		-itembackground {#e0e8f0 {}} -expand yes -text [::msgcat::mc "Value"]
	
	$tree element create rect rect -open news -showfocus yes -fill [list #a5c4c4 {selected}] 	
	
	$tree element create txtProperty text -lines 1
	$tree style create styProperty
	$tree style elements styProperty [list rect txtProperty]
	$tree style layout styProperty txtProperty -padx {0 4} -squeeze x -expand ns
	$tree style layout styProperty rect -union {txtProperty} -iexpand news -ipadx 2	
	
	$tree element create txtValue text -lines 1
	$tree style create styValue
	$tree style elements styValue [list rect txtValue]
	$tree style layout styValue txtValue -padx {0 4} -squeeze x -expand ns
	$tree style layout styValue rect -union {txtValue} -iexpand news -ipadx 2		
	
	set wInfo(svn_properties_tree) $tree
	set wInfo(svn_properties_target) $target
	
	$tree notify install <Header-invoke>
	$tree notify bind $tree <Header-invoke> {
		if {[%T column cget %C -arrow] eq "down"} {
			set order -increasing
			set arrow up
		} else {
			set order -decreasing
			set arrow down
		}
		foreach col [%T column list] {
			%T column configure $col -arrow none
		}
		%T column configure %C -arrow $arrow
		%T item sort root $order -column %C -dictionary
	}	
	
	::svnWrapper::svn_properties_refresh
	$path draw
	
	destroy $path
	unset wInfo(svn_properties_tree) 
	unset wInfo(svn_properties_target)
	return
}

proc ::svnWrapper::svn_properties_add {title {property ""} {value ""}} {
	variable wInfo
	variable svnInfo
		
	set wInfo(txtValue,var) $value
	set wInfo(txtProperty,var) $property
	
	set path ".__svn_properties_add__"
	if {[winfo exists $path]} {destroy $path}
		
	Dialog $path -title $title -modal local
	set fmeMain [$path getframe]	
	set fmeProperty [frame $fmeMain.fmeProperty]
	pack [label $fmeProperty.lblTitle -text [::msgcat::mc "Property :"] -anchor w -justify left] -side left -pady 1
	pack [entry $fmeProperty.txtProperty -textvariable ::svnWrapper::wInfo(txtProperty,var) -takefocus 1] -side left -expand 1 -fill both
	
	label $fmeMain.lblValue -text [::msgcat::mc "Value :"] -anchor w -justify left
	set fmeBody [ScrolledWindow $fmeMain.fmeBody -auto horizontal -relief groove -bd 1]
	$fmeBody setwidget [text $fmeBody.txtValue -wrap none -undo 1 \
		-relief flat -bd 0 -bg white -spacing3 2 -width 30 -height 5 \
		-spacing1 1 -highlightthickness 0 -takefocus 1]
	$fmeBody.txtValue insert end $value
	
	set fmeBtn [frame $fmeMain.fmeBtn]
	pack [button $fmeBtn.btnCancel -text [::msgcat::mc "Cancel"] -width 10 -command [list $path enddialog -1]] \
		-side right -padx 1 -pady 1	
	button $fmeBtn.btnOk -text [::msgcat::mc "Ok"] -width 10 -command [format {
		set ::svnWrapper::wInfo(txtValue,var) [%s get 1.0 end]
		%s enddialog "OK"
	} $fmeBody.txtValue $path]
	pack $fmeBtn.btnOk	-side right -padx 3 -pady 1
	
	pack $fmeProperty -fill x -padx 1 -pady 1
	pack $fmeMain.lblValue -fill x -padx 1
	pack $fmeBody -expand 1 -fill both -padx 1
	pack $fmeBtn -fill x -padx 1 -pady 1
	
	set ret [$path draw]
	destroy $path
	
	if {$ret eq -1 || [string trim $wInfo(txtProperty,var)] eq ""} {
		unset wInfo(txtProperty,var)
		unset wInfo(txtValue,var)
		return
	}

	$wInfo(svn_properties_tree) item delete all
#	set wInfo(svn_properties_result) ""
	set cmd [list | $svnInfo(CMD) propset [string trim $wInfo(txtProperty,var)] [string trim $wInfo(txtValue,var)] $wInfo(svn_properties_target)]

	::svnWrapper::svn_exec $cmd "" "" ""
	
	::svnWrapper::svn_properties_refresh
	
	unset wInfo(txtProperty,var)
	unset wInfo(txtValue,var)
	return
}

proc ::svnWrapper::svn_properties_edit {} {
	variable wInfo
	set tree $wInfo(svn_properties_tree)
	set item [lindex [$tree selection get] 0]
	if {$item eq ""} {
		tk_messageBox -title [::msgcat::mc "error"] -icon error \
			-message [::msgcat::mc "Please select a property first!"]
		return
	}
	set property [$tree item text $item colProperty]
	set value 	[$tree item text $item colValue]
	::svnWrapper::svn_properties_add "Edit properties" $property $value
}

proc ::svnWrapper::svn_properties_remove {} {
	variable wInfo
	variable svnInfo
	
	set tree $wInfo(svn_properties_tree)
	set item [lindex [$tree selection get] 0]
	if {$item eq ""} {
		tk_messageBox -title [::msgcat::mc "error"] -icon error \
			-message [::msgcat::mc "Please select a property first!"]
		return
	}
	set property [$tree item text $item colProperty]
	set ret [tk_messageBox -title [::msgcat::mc "Remove properties"] -icon info  -type yesno\
			-message [::msgcat::mc "Are you want to remove '%s' propeties?" $property]]
	if {$ret ne "yes"} {return}
	set cmd [list | $svnInfo(CMD) propdel $property $wInfo(svn_properties_target)]

	::svnWrapper::svn_exec $cmd "" "" ""
	::svnWrapper::svn_properties_refresh
	return
}

proc ::svnWrapper::svn_properties_refresh {} {
	variable wInfo	
	variable svnInfo
	set wInfo(svn_properties_counter) 0
	$wInfo(svn_properties_tree) item delete all
	set cmd [list | $svnInfo(CMD) proplist $wInfo(svn_properties_target) --verbose --non-interactive]
	::svnWrapper::svn_exec $cmd ::svnWrapper::svn_properties_recv "" ""
	unset wInfo(svn_properties_counter)
	return
}

proc ::svnWrapper::svn_properties_recv {data} {
	variable wInfo
	
	if {$wInfo(svn_properties_counter) == 0} {
		set wInfo(svn_properties_counter) 1
		return
	}
	
	set idx [string first " : " $data]
	set property [string trimleft [string range $data 0 [expr $idx -1]]]
	set value [string range $data [expr $idx +3] end]
	
	set tree $wInfo(svn_properties_tree)
	set item [$tree item create -button no]
	
	$tree item lastchild 0 $item
	$tree item style set $item 0 styProperty 1 styValue
	$tree item text $item 0 $property 1 $value

	return
}
