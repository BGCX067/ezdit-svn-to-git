proc ::svnWrapper::svn_add_init {{target ""}} {
	variable svnInfo

	set path [::svnWrapper::msgbox_new ".__svn_add__" [::msgcat::mc "Add"]]
	set cmd [list | $svnInfo(CMD) add $target]
	 
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
