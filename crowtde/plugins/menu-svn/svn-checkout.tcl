proc ::svnWrapper::svn_checkout_init {projectPath} {
	variable wInfo
	array set wInfo ""
	
	set path ".__svn_co__"
	if {[winfo exists $path]} {destroy $path}	
	Dialog $path -title [::msgcat::mc "Checkout from SVN"] -modal local
	set fmeMain [$path getframe]
	
	set fmeRepository [labelframe $fmeMain.fmeRepository -text "Repository:"]
	set lblRepo [label $fmeRepository.lblRepo -text [::msgcat::mc "URL of repository:"] -anchor w -justify left]
	set txtRepo [entry $fmeRepository.txtRepo -textvariable ::svnWrapper::wInfo(txtPepo,var)]
	set lblCoDir [label $fmeRepository.lblCoDir -text [::msgcat::mc "Checkout directory:"] -anchor w -justify left]
	set txtCoDir [entry $fmeRepository.txtCoDir]
#	set btnCoDir [button $fmeRepository.btnCoDir -text [::msgcat::mc "Browse..."] -command [format {
#		set txtCoDir "%s"
#		$txtCoDir configure -state normal
#		set ret [tk_chooseDirectory -title [::msgcat::mc "Choose Directory"] -mustexist 1]
#		if {$ret ne "" && $ret ne "-1"} {
#			$txtCoDir delete 0 end
#			$txtCoDir insert end $ret
#		}
#		$txtCoDir configure -state disabled
#	} $txtCoDir]]
	$txtCoDir insert end $projectPath
	$txtCoDir configure -state disabled -disabledbackground white -disabledforeground black -width 40
	set wInfo(txtPepo,var) "svn://"
	grid $lblRepo $txtRepo - -padx 3 -pady 3 -sticky "news"
	grid $lblCoDir $txtCoDir -padx 3 -pady 3 -sticky "news"
	grid columnconfigure $fmeRepository 1 -weight 1
	
	set fmeRevision [labelframe $fmeMain.fmeRevision -text "Revision:"]
	set rdoHead [radiobutton $fmeRevision.rdoHead -value "0" -text [::msgcat::mc "HEAD revision"] \
		-variable ::svnWrapper::wInfo(rdoRevision,var) -anchor w -justify left]
	set rdoOther [radiobutton $fmeRevision.rdoOther -value "1" -text [::msgcat::mc "Revision"] \
		-variable ::svnWrapper::wInfo(rdoRevision,var) -anchor w -justify left]
	set txtRevision [entry $fmeRevision.txtRevision -textvariable ::svnWrapper::wInfo(txtRevision,var)]
	grid $rdoHead - -padx 3 -pady 3 -sticky "news"
	grid $rdoOther $txtRevision -padx 3 -pady 3 -sticky "news"
	grid columnconfigure $fmeRevision 2 -weight 1
	set wInfo(rdoRevision,var) 0

	set fmeLogin [labelframe $fmeMain.fmeLogin]
	set chkLogin [checkbutton $fmeLogin.chkLogin -text [::msgcat::mc "Login"] \
		-command [list ::svnWrapper::svn_checkout_chkLogin_click $fmeLogin.txtUser $fmeLogin.txtPasswd] \
		-onvalue 1 -offvalue 0 -variable ::svnWrapper::wInfo(chkLogin,var)]
	set lblUser [label $fmeLogin.lblUser -text [::msgcat::mc "Username:"] -anchor w -justify left]
	set txtUser [entry $fmeLogin.txtUser -textvariable ::svnWrapper::wInfo(txtUser,var) -takefocus 1]
	set lblPasswd [label $fmeLogin.lblPasswd -text [::msgcat::mc "Passwd:"] -anchor w -justify left]
	set txtPasswd [entry $fmeLogin.txtPasswd -show "*" -textvariable ::svnWrapper::wInfo(txtPasswd,var) -takefocus 1]
	::svnWrapper::svn_checkout_chkLogin_click $txtUser $txtPasswd
	$fmeLogin configure -labelwidget $chkLogin

	grid $lblUser $txtUser -padx 3 -pady 3 -sticky "news"
	grid $lblPasswd $txtPasswd -padx 3 -pady 3 -sticky "news"
	grid columnconfigure $fmeLogin 2 -weight 1
	
	set fmeBtn [frame $fmeMain.fmeBtn]
	set btnOk [button $fmeBtn.btnOk -width 6 -text [::msgcat::mc "Ok"] \
		-command [list $path enddialog "OK"]]
	set btnCancel [button $fmeBtn.btnCancel -width 6 -text [::msgcat::mc "Cancel"] \
		-command [list $path enddialog "CANCEL"]]		
	pack $btnCancel -side right -expand 0 -padx 10 -pady 2
	pack $btnOk -side right -expand 0 -padx 10 -pady 2


	grid $fmeRepository -pady 3 -padx 1 -sticky "news"
	grid $fmeRevision -pady 3 -padx 1 -sticky "news"
	grid $fmeLogin -pady 3 -padx 1 -sticky "news"
	grid $fmeBtn -pady 3 -padx 1 -sticky "news"

	after 100 [list 	wm resizable $path 0 0]
	
	set ret [$path draw]
#	$txtCoDir configure -state normal
#	set projectPath [$txtCoDir get]
	destroy $path
	if {$ret ne "OK"} {return 0}
	if {$wInfo(txtPepo,var) eq ""} {
		tk_messageBox -message [::msgcat::mc "URL can't empty."] \
			-title [::msgcat::mc "Error!"] -type ok -icon error
		return 0
	}	
	
	set revision ""
	if {$wInfo(rdoRevision,var)} {set revision $wInfo(txtRevision,var)}

	if {$wInfo(chkLogin,var)} {
		::svnWrapper::svn_checkout_run $wInfo(txtPepo,var) $projectPath $revision \
			--username $wInfo(txtUser,var) --password $wInfo(txtPasswd,var)		
	} else {
		::svnWrapper::svn_checkout_run $wInfo(txtPepo,var) $projectPath $revision
	}
	array unset wInfo
	return 1
}

proc ::svnWrapper::svn_checkout_chkLogin_click {txtUser txtPasswd} {
	variable wInfo
	if {$wInfo(chkLogin,var)} {
		set state normal
	} else {
		set state disabled
	}
	$txtUser configure -state $state
	$txtPasswd configure -state $state
}

proc ::svnWrapper::svn_checkout_run {target coDir revision args} {
	variable svnInfo
	
	set path [::svnWrapper::msgbox_new ".__svn_co_exec__" [::msgcat::mc "Checkout"]]	
	set cmd [list | $svnInfo(CMD) checkout $target $coDir --non-interactive]
	if {$revision ne ""} {lappend cmd --revision $revision}
	foreach arg $args {lappend cmd $arg}
	
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
