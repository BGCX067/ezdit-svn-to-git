proc ::svnWrapper::svn_move_init {target} {
	variable svnInfo
	set ret [tk_chooseDirectory -title [::msgcat::mc "Move to:"] -mustexist 1]
	if {$ret eq "" || $ret eq "-1"} {return}
	::svnWrapper::svn_move_exec $target $ret
	return
}

proc ::svnWrapper::svn_move_exec {target dpath} {
	variable svnInfo
	set path [::svnWrapper::msgbox_new ".__svn_move__" [::msgcat::mc "Move"]]
	set fname [file join $dpath [file tail $target]]
	set cmd [list | $svnInfo(CMD) move $target $fname]
	puts $cmd
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
