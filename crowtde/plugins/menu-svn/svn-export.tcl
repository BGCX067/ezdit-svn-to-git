 proc ::svnWrapper::svn_export_init {target} {
	variable svnInfo
	variable wInfo
	set path ".__svn_export__"
	
	if {[winfo exists $path]} {destroy $path}	
	Dialog $path -title [::msgcat::mc "Export"] -modal local
	set fmeMain [$path getframe]

	set lblSrc [label $fmeMain.lblSrc -text [::msgcat::mc "Export: %s" $target] -anchor w -justify left]
	set lblExport [label $fmeMain.lblExport -text [::msgcat::mc "Directory:"] -anchor w -justify left]
	set txtExport [entry $fmeMain.txtExport -justify left -textvariable ::svnWrapper::wInfo(txtExportTo,var)]
	set btnSel [button $fmeMain.btnSel -text "..." ]
		

	set fmeBtn [frame $fmeMain.fmeBtn]
	set chkUnversion [checkbutton $fmeBtn.chkUnversion -anchor w  \
		-variable ::svnWrapper::wInfo(chkUnversion,var) \
		-text [::msgcat::mc "Include unversion file(s)"] -onvalue "--no-ignore" -offvalue ""]	
	set btnOk [button $fmeBtn.btnOk -width 6 -text [::msgcat::mc "Ok"] \
		-command [list $path enddialog "OK"]]
	set btnCancel [button $fmeBtn.btnCancel -width 6 -text [::msgcat::mc "Cancel"] \
		-command [list $path enddialog "CANCEL"]]
	pack $chkUnversion -side left -expand 1 -fill x -padx 10 -pady 2	
	pack $btnOk -side left -expand 0 -padx 10 -pady 2
	pack $btnCancel -side left -expand 0 -padx 10 -pady 2
	
	grid $lblSrc - - -sticky "news"
	grid $lblExport $txtExport $btnSel -sticky "news"
	grid $fmeBtn - - -sticky "news"
	grid rowconfigure $fmeMain 0 -weight 1
	grid columnconfigure $fmeMain 1 -weight 1
	
	$btnSel configure -command [format {
			set ret [tk_chooseDirectory -title [::msgcat::mc "Choose Directory"]]
			if {$ret != -1} {
				set ::svnWrapper::wInfo(txtExportTo,var) $ret
			}
#			"%s" configure -state normal
	} $btnOk]
	set ret [$path draw]
	
	set flagUnversion $wInfo(chkUnversion,var)
	set flagTo $wInfo(txtExportTo,var)
	destroy $path
	array unset wInfo chkUnversion,var
	array unset wInfo txtExportTo,var

	if {$ret ne "OK"} {return}

	if {$flagTo eq ""} {
		tk_messageBox -message [::msgcat::mc "Directory can't empty."] \
			-title [::msgcat::mc "Error!"] -type ok -icon error
		return
	}	
	
	set path [::svnWrapper::msgbox_new ".__svn_export_exec__" [::msgcat::mc "Export"]]	
	set cmd [list | $svnInfo(CMD) export]
	if {$flagUnversion ne ""} {lappend cmd $flagUnversion}
	lappend cmd $target $flagTo

	::svnWrapper::msgbox_btn_state $path disabled
	after 50 [list ::svnWrapper::svn_exec \
			$cmd \
			[list ::svnWrapper::msgbox_put $path] \
			[list ::svnWrapper::msgbox_put $path] \
			[list ::svnWrapper::msgbox_btn_state $path normal]]
	$path draw
	catch {::svnWrapper::msgbox_destroy $path}	
	return
	
}
