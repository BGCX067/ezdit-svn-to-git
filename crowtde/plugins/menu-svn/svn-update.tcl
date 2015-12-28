proc ::svnWrapper::svn_update_init {{target ""}} {
	variable svnInfo
	variable wInfo
	
	set path ".__svn_update__"
	Dialog $path -title [::msgcat::mc "SVN Update"] -modal local
	set fmeMain [$path getframe]
	set fmeLogin [labelframe $fmeMain.fmeLogin]
	set chkLogin [checkbutton $fmeLogin.chkLogin -text [::msgcat::mc "Login"] \
		-command [list ::svnWrapper::svn_update_chkLogin_click $fmeLogin.txtUser $fmeLogin.txtPasswd] \
		-onvalue 1 -offvalue 0 -variable ::svnWrapper::wInfo(chkLogin,var)]
	set lblUser [label $fmeLogin.lblUser -text [::msgcat::mc "Username:"] -anchor w -justify left]
	set txtUser [entry $fmeLogin.txtUser -textvariable ::svnWrapper::wInfo(txtUser,var) -takefocus 1]
	set lblPasswd [label $fmeLogin.lblPasswd -text [::msgcat::mc "Passwd:"] -anchor w -justify left]
	set txtPasswd [entry $fmeLogin.txtPasswd -show "*" -textvariable ::svnWrapper::wInfo(txtPasswd,var) -takefocus 1]
	
	::svnWrapper::svn_update_chkLogin_click $txtUser $txtPasswd
	$fmeLogin configure -labelwidget $chkLogin
	
	grid $lblUser $txtUser -padx 3 -pady 3 -sticky "news"
	grid $lblPasswd $txtPasswd -padx 3 -pady 3 -sticky "news"
	grid columnconfigure $fmeLogin 2 -weight 1

	set fmeBtn [frame $fmeMain.fmeBtn]
	set btnOk [button $fmeBtn.btnOk -width 6 -text [::msgcat::mc "Update"] \
		-command [list $path enddialog "OK"]]
	set btnCancel [button $fmeBtn.btnCancel -width 6 -text [::msgcat::mc "Cancel"] \
		-command [list $path enddialog "CANCEL"]]		
	pack $btnCancel -side right -expand 0 -padx 10 -pady 2
	pack $btnOk -side right -expand 0 -padx 10 -pady 2
	
	grid $fmeLogin -pady 3 -padx 1 -sticky "news"
	grid $fmeBtn -pady 3 -padx 1 -sticky "news"	
	
	set ret [$path draw]
	destroy $path
	if {$ret ne "OK"} {return}
	
	::svnWrapper::svn_update_exec $target
#	set path [::svnWrapper::msgbox_new ".__svn_update_exec__" [::msgcat::mc "Update"]]
#
#	if {$wInfo(chkLogin,var)} {	
#		set cmd [list | $svnInfo(CMD) update $target --non-interactive --username $wInfo(txtUser,var) --password $wInfo(txtPasswd,var)	]
#	} else {
#		set cmd [list | $svnInfo(CMD) update $target --non-interactive]
#	}
#	::svnWrapper::msgbox_btn_state $path disabled
#	after 50 [list ::svnWrapper::svn_exec \
#			$cmd \
#			[list ::svnWrapper::msgbox_put $path] \
#			[list ::svnWrapper::msgbox_put $path] \
#			[list ::svnWrapper::msgbox_btn_state $path normal]]
#	$path draw
#	catch {::svnWrapper::msgbox_destroy $path}
	
	return
}

proc ::svnWrapper::svn_update_chkLogin_click {txtUser txtPasswd} {
	variable wInfo
	if {$wInfo(chkLogin,var)} {
		set state normal
	} else {
		set state disabled
	}
	$txtUser configure -state $state
	$txtPasswd configure -state $state	
}

proc ::svnWrapper::svn_update_exec {target} {
	variable wInfo
	variable svnInfo
	set path [::svnWrapper::msgbox_new ".__svn_update_exec__" [::msgcat::mc "Update"]]

	if {$wInfo(chkLogin,var)} {	
		set cmd [list | $svnInfo(CMD) update $target --non-interactive --username $wInfo(txtUser,var) --password $wInfo(txtPasswd,var)	]
	} else {
		set cmd [list | $svnInfo(CMD) update $target --non-interactive]
	}
	::svnWrapper::msgbox_btn_state $path disabled
	after 50 [list ::svnWrapper::svn_exec \
			$cmd \
			[list ::svnWrapper::msgbox_put $path] \
			[list ::svnWrapper::msgbox_put $path] \
			[list ::svnWrapper::msgbox_btn_state $path normal]]
	$path draw
	catch {::svnWrapper::msgbox_destroy $path}
}
