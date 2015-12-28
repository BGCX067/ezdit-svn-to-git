proc ::svnWrapper::svn_del_init {target} {
	variable svnInfo
	set path [::svnWrapper::msgbox_new ".__svn_del__" [::msgcat::mc "Delete"]]
	set cmd [list | $svnInfo(CMD) del $target --force]
	 
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
