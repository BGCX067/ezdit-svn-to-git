proc ::svnWrapper::svn_resolved_init {target} {
	variable svnInfo
	set path [::svnWrapper::msgbox_new ".__svn_resolved__" [::msgcat::mc "Resolved"]]
	set cmd [list | $svnInfo(CMD) resolved $target]
	 
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
