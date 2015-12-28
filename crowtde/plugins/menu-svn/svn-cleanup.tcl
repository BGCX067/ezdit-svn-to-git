proc ::svnWrapper::svn_cleanup_init {{target ""}} {
	variable svnInfo
	set path [::svnWrapper::msgbox_new ".__svn_cleanup__" [::msgcat::mc "Clean up"]]
	set cmd [list | $svnInfo(CMD) cleanup $target]
	 
	::svnWrapper::msgbox_btn_state $path disabled
	::svnWrapper::msgbox_put $path [::msgcat::mc "Please wait"]
	after 50 [list ::svnWrapper::svn_exec \
			$cmd \
			[list ::svnWrapper::msgbox_put $path] \
			[list ::svnWrapper::svn_cleanup_error $path] \
			[list ::svnWrapper::svn_cleanup_ok $path]]
	$path draw
	catch {::svnWrapper::msgbox_destroy $path}
	return
}

proc ::svnWrapper::svn_cleanup_error {path msg} {
	::svnWrapper::msgbox_put $path $msg
	::svnWrapper::msgbox_btn_state $path normal
}

proc ::svnWrapper::svn_cleanup_ok {path} {
	::svnWrapper::msgbox_btn_state $path normal
	::svnWrapper::msgbox_put $path [::msgcat::mc "...ok!"]
}
