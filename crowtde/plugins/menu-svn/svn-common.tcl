proc ::svnWrapper::encoding_convert {str} {
	if {[encoding system] eq "utf-8"} {return $str}
	set str [regsub -all {\\} $str {\\\\}]
	set idx [lindex [regexp -inline -indices {\?\\\\[0-9]{1,3}} $str] 0]
	while {$idx ne ""} {
		foreach {idx1 idx2} $idx {}
		set c \\u[format "%x" [string range $str [expr $idx1+3] $idx2]]
		set str [string replace $str $idx1 $idx2 $c]
		set idx [lindex [regexp -inline -indices {\?\\\\[0-9]{1,3}} $str] 0]
	}
	return [encoding convertfrom utf-8 [subst -nocommands -novariables $str]]
}

proc ::svnWrapper::msgbox_btn_state {path state} {
	set btn [$path getframe].fmeBtn.btnOk
	$btn configure -state $state
	return
}

proc ::svnWrapper::msgbox_destroy {path} {

	$path enddialog ""
	after idle [list destroy $path]

	return
}

proc ::svnWrapper::msgbox_new {path title {modal local}} {
	if {[winfo exists $path]} {destroy $path}	
	Dialog $path -title $title -modal $modal
	set fmeMain [$path getframe]
	set fmeBody [ScrolledWindow $fmeMain.fmeBody]	
	set txtMsg [text $fmeBody.txtMsg  -width 60 -height 15 \
		-relief groove -wrap none -highlightthickness 0 -bg white ]
	$fmeBody setwidget $txtMsg
	
	set fmeBtn [frame $fmeMain.fmeBtn]
	set btnOk [button $fmeBtn.btnOk -width 6 -text [::msgcat::mc "Ok"] \
		-command [list $path enddialog "OK"]]
	pack $btnOk -side right -expand 0 -padx 10 -pady 2
	
	grid $fmeBody -sticky "news"
	grid $fmeBtn -sticky "news"
	grid rowconfigure $fmeMain 0 -weight 1
	grid columnconfigure $fmeMain 0 -weight 1
	return $path
}

proc ::svnWrapper::msgbox_put {path msg} {
	set txt [$path getframe].fmeBody.txtMsg
	$txt insert end $msg\n
	$txt see end
	update
	return
}

proc ::svnWrapper::msgbox_txt_state {path state} {
	set txt [$path getframe].fmeBody.txtMsg
	$txt configure -state $state
	return
}

proc ::svnWrapper::svn_exec {cmd {fun_recv ""} {fun_err ""} {fun_final ""}} {
	variable svnInfo
	
	set result ""
	if {[catch {
		switch $::tcl_platform(platform) {
			"windows" {
			        set cat [file join $::crowTde::appPath tools cat.exe]
			}
			default {set cat cat}
		}
		lappend cmd "|&" $cat
		set fd [open $cmd r+]
		set inBuf ""
		set svnInfo(FD) $fd

		fconfigure $fd -blocking 1 -buffering line
		while {![eof $fd]} {
			gets $fd inBuf
			if {[info proc [lindex $fun_recv 0]] ne ""} {
				set fun $fun_recv
				eval [lappend fun [::svnWrapper::encoding_convert $inBuf]]
			}
		}
	} errInfo]} {
		if {[info proc [lindex $fun_err 0]] ne ""} {
			set fun $fun_err
			eval [lappend fun [::svnWrapper::encoding_convert $errInfo]]
		}
		
	}

	catch {close $fd}
	if {[info proc [lindex $fun_final 0]] ne ""} {
		eval $fun_final
	}
	set svnInfo(FD) ""
	return
}

proc ::svnWrapper::svn_info_get {{target ""} args} {
	variable svnInfo
	
	set cmd [list | $svnInfo(CMD) info --xml]
	foreach arg $args {lappend cmd $arg}
	if {$target ne ""} {lappend cmd $target}

	set ret ""
	set result ""
	
	if {[catch {
		set fd [open $cmd r+]
		while {![eof $fd]} {append result [read -nonewline $fd]}
		close $fd
	} errInfo]} {
		catch {close $fd}
		tk_messageBox -icon error -type ok -message [::svnWrapper::encoding_convert $errInfo]
		return "-1"
	}
	
#	puts $result

	set doc [dom parse $result]
	set root [$doc documentElement]
	
	array set arrInfo [list url	""	version ""]
	set arrInfo(version) [[$root selectNodes "/info/entry"] getAttribute "revision"]
	set arrInfo(commitTo) [[$root selectNodes "/info/entry/repository/root"] text]
	set ret [array get arrInfo]
	array unset arrInfo
	
	$doc delete
	return $ret
}

proc ::svnWrapper::svn_status_get {{target ""} args} {
	variable svnInfo
	
	set cmd [list | $svnInfo(CMD) status --xml]
	foreach arg $args {lappend cmd $arg}
	if {$target ne ""} {lappend cmd $target}

	set ret ""
	set result ""
	
	if {[catch {
		set fd [open $cmd r+]
		while {![eof $fd]} {append result [read -nonewline $fd]}
		close $fd
	} errInfo]} {
		catch {close $fd}
		tk_messageBox -icon error -type ok -message [::svnWrapper::encoding_convert $errInfo]
		return "-1"
	}
	
#	puts $result
	
	set doc [dom parse $result]
	set root [$doc documentElement]

	set baseDir $target
	if {[file isfile $baseDir]} {
		set baseDir [file dirname $baseDir]
	}

	foreach node [$root selectNodes "/status/target/entry"] {
		array set arrInfo [list \
			File	""	TextStatus ""	PropertyStatus "" RemoteTextStatus "" RemotePropertyStatus "" \
			Look "" LookComment "" Author "" Revision "" Date ""]		
		set filePath [$node getAttribute "path"]
		if {[file exists $filePath]} {
			set arrInfo(FileType) [string toupper [file type $filePath]]
		} else {
			set arrInfo(FileType) "FILE"
		}
		set arrInfo(File) [string range $filePath [expr [string length $baseDir]+1] end]
		foreach child [$node childNodes] {
			switch -exact -- [$child nodeName] {
				"wc-status" {
					set arrInfo(PropertyStatus) [$child getAttribute "props"]
					set arrInfo(TextStatus) [$child getAttribute "item"]
					set commit [$child selectNodes "commit"]
					if {$commit ne ""} {
						set arrInfo(Revision) [$commit getAttribute "revision"]
						set arrInfo(Author) [[$commit selectNodes "author"] text]
						set date [[$commit selectNodes "date"] text]
						set date [split [lindex [split $date "."] 0] "T"]
						set arrInfo(Date) [list [lindex $date 0] [lindex $date 1]]
					}
					set owner [$child selectNodes "lock/owner"]
					if {$owner ne ""} {set arrInfo(Look) [$owner text]}
					set comment [$child selectNodes "lock/comment"]
					if {$comment ne ""} {set arrInfo(LookComment) [$comment text]}
				}
				"repos-status" {
					set arrInfo(RemotePropertyStatus) [$child getAttribute "props"]
					set arrInfo(RemoteTextStatus) [$child getAttribute "item"]
				}
				default {}
			}
		}
		lappend ret [array get arrInfo]
		array unset arrInfo
	}
	$doc delete
	return $ret
}
