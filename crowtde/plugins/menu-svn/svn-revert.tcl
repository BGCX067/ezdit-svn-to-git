proc ::svnWrapper::svn_revert_init {{target ""}} {
	variable svnInfo
	set path [::svnWrapper::msgbox_new ".__svn_revert__" [::msgcat::mc "Revert"]]
	set cmd [list | $svnInfo(CMD) revert --recursive $target]
	 
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
