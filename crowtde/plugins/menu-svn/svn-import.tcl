proc ::svnWrapper::svn_import_init {target} {
	variable svnInfo
	variable wInfo
	array set wInfo ""
	
	set path ".__svn_import__"
	if {[winfo exists $path]} {destroy $path}	
	Dialog $path -title [::msgcat::mc "Import"] -modal local
	set fmeMain [$path getframe]
	
	set fmeRepository [labelframe $fmeMain.fmeRepository -text [::msgcat::mc "Repository:"]]
	set lblRepo [label $fmeRepository.lblRepo -text [::msgcat::mc "URL of repository:"] -anchor w -justify left]
	set txtRepo [entry $fmeRepository.txtRepo -textvariable ::svnWrapper::wInfo(txtPepo,var)]
	set wInfo(txtPepo,var) "svn://"
	grid $lblRepo -padx 3 -pady 3 -sticky "news"
	grid $txtRepo -padx 3 -pady 3 -sticky "news"
	grid columnconfigure $fmeRepository 0 -weight 1

	set fmeMsg [labelframe $fmeMain.fmeMsg -text [::msgcat::mc "Import Message:"]]
	set txtMsg [text $fmeMsg.txtMsg -width 10 \
		-bd 2 -relief groove -height 6 -wrap none \
		-highlightthickness 0 -bg white]
	pack $txtMsg -expand 1 -fill both -padx 3 -pady 3
	
	set fmeLogin [labelframe $fmeMain.fmeLogin -bd 2 -relief groove]
	set chkLogin [checkbutton $fmeLogin.chkLogin -text [::msgcat::mc "Login"] \
		-command [list ::svnWrapper::svn_import_chkLogin_click $fmeLogin.txtUser $fmeLogin.txtPasswd] \
		-onvalue 1 -offvalue 0 -variable ::svnWrapper::wInfo(chkLogin,var)]
	set lblUser [label $fmeLogin.lblUser -text [::msgcat::mc "Username:"] -anchor w -justify left]
	set txtUser [entry $fmeLogin.txtUser -textvariable ::svnWrapper::wInfo(txtUser,var) -takefocus 1]
	set lblPasswd [label $fmeLogin.lblPasswd -text [::msgcat::mc "Passwd:"] -anchor w -justify left]
	set txtPasswd [entry $fmeLogin.txtPasswd -show "*" -textvariable ::svnWrapper::wInfo(txtPasswd,var) -takefocus 1]
	
	$fmeLogin configure -labelwidget $chkLogin
	::svnWrapper::svn_import_chkLogin_click $txtUser $txtPasswd
	grid $lblUser $txtUser $lblPasswd $txtPasswd -sticky "news" -pady 2 -padx 2
	grid columnconfigure $fmeLogin 5 -weight 1

	grid $lblUser $txtUser -padx 3 -pady 3 -sticky "news"
	grid $lblPasswd $txtPasswd -padx 3 -pady 3 -sticky "news"
	grid columnconfigure $fmeLogin 2 -weight 1
	
	set fmeBtn [frame $fmeMain.fmeBtn]
	set chkInclude [checkbutton $fmeBtn.chkInclude -onvalue 1 -offvalue 0 \
		-text [::msgcat::mc "Include ignored files"] -anchor w -justify left \
		-variable ::svnWrapper::wInfo(chkInclude,var)]
	set btnOk [button $fmeBtn.btnOk -width 6 -text [::msgcat::mc "Ok"] \
		-command [list $path enddialog "OK"]]
	set btnCancel [button $fmeBtn.btnCancel -width 6 -text [::msgcat::mc "Cancel"] \
		-command [list $path enddialog "CANCEL"]]
	pack $chkInclude -side left -expand 1 -fill x
	pack $btnCancel -side right -expand 0 -padx 10 -pady 2
	pack $btnOk -side right -expand 0 -padx 10 -pady 2


	grid $fmeRepository -pady 3 -padx 1 -sticky "news"
	grid $fmeMsg -pady 3 -padx 1 -sticky "news"
	grid $fmeLogin -pady 3 -padx 1 -sticky "news"
	grid $fmeBtn -pady 3 -padx 1 -sticky "news"

	after 100 [list 	wm resizable $path 0 0]
	
	set ret [$path draw]
	if {$ret == -1} {return}
	set msg [string trim [$txtMsg get 1.0 end]]
	destroy $path
	if {$ret ne "OK"} {return 0}
	if {$wInfo(txtPepo,var) eq ""} {
		tk_messageBox -message [::msgcat::mc "URL can't empty."] \
			-title [::msgcat::mc "Error!"] -type ok -icon error
		return
	}	
	
	set cmd [list | $svnInfo(CMD) import $target $wInfo(txtPepo,var) --non-interactive]
	if {$msg ne ""} {lappend cmd --message $msg}
	if {$wInfo(chkLogin,var)} {lappend cmd --username $wInfo(txtUser,var) --password $wInfo(txtPasswd,var)}	
	if {$wInfo(chkInclude,var)} {lappend cmd --no-ignore}
#	puts DEBUG==$cmd
	
	set path [::svnWrapper::msgbox_new ".__svn_import_run__" [::msgcat::mc "Import"]]
	::svnWrapper::msgbox_btn_state $path disabled
	after 50 [list ::svnWrapper::svn_exec \
		$cmd \
		[list ::svnWrapper::msgbox_put $path] \
		[list ::svnWrapper::msgbox_put $path] \
		[list ::svnWrapper::msgbox_btn_state $path normal]]
	$path draw
	catch {::svnWrapper::msgbox_destroy $path}

	return 1
}

proc ::svnWrapper::svn_import_chkLogin_click {txtUser txtPasswd} {
	variable wInfo
	if {$wInfo(chkLogin,var)} {
		set state normal
	} else {
		set state disabled
	}
	$txtUser configure -state $state
	$txtPasswd configure -state $state	
}
