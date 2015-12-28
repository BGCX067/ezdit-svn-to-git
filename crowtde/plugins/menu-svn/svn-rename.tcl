proc ::svnWrapper::svn_rename_init {target} {
	variable svnInfo
	set ret [::inputDlg::show ".__svn_rename_new__" [::msgcat::mc "Rename"] [file tail $target]]
	if {[lindex $ret 0] ne "OK"} {return}
	::svnWrapper::svn_rename_exec $target [lindex $ret 1]
	return
}

proc ::svnWrapper::svn_rename_exec {target newname} {
	variable svnInfo
	set path [::svnWrapper::msgbox_new ".__svn_rename__" [::msgcat::mc "Rename"]]
	set fname [file join [file dirname $target] $newname]
	set cmd [list | $svnInfo(CMD) move --force $target $fname]

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
