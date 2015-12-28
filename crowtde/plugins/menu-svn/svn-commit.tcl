proc ::svnWrapper::svn_commit_init {{target ""}} {
	variable svnInfo
	variable wInfo
	
	set result [::svnWrapper::svn_info_get $target]
	if {$result == -1} {return}
	array set arrInfo [list commitTo "" revision ""]
	array set arrInfo $result
	
	set path ".__svn_commit_init__"
	if {[winfo exists $path]} {destroy $path}
	Dialog $path -title [::msgcat::mc "Commit"] -modal local
	set fmeMain [$path getframe]
	
	set fmeTitle [frame $fmeMain.fmeTitle -bd 2 -relief groove]
	pack [label $fmeTitle.lblTitle \
		-anchor w -justify left \
		-text [::msgcat::mc "Commit to : %s" $arrInfo(commitTo)]] -expand 1 -fill both
	
	set fmeMsg [frame $fmeMain.fmeMsg -bd 2 -relief groove]
	pack [label $fmeMsg.lblMsg \
		-anchor w -justify left -text [::msgcat::mc "Message : "]] -expand 1 -fill x -side top
	pack [text $fmeMsg.txtMsg \
		-bd 2 -relief groove -height 6 -wrap none \
		-highlightthickness 0 -bg white] -expand 1 -fill both -side top
	set txtMsg $fmeMsg.txtMsg
	
	set fmeBody [ScrolledWindow $fmeMain.fmeBody]
	set tree [treectrl $fmeBody.tree \
		-font [::crowFont::get_font smaller] \
		-height 250 \
		-width 500 \
		-showroot no \
		-showline no \
		-selectmod extended \
		-showrootbutton no \
		-showbuttons no \
		-showheader yes \
		-scrollmargin 16 \
		-highlightthickness 0 \
		-relief groove \
		-bg white \
		-xscrolldelay "500 50" \
		-yscrolldelay "500 50"]	
	
	$tree state define CHECKED 
	$tree state define UNCHECKED
	$tree state define TYPE_FILE 
	$tree state define TYPE_DIRECTORY
		
	$fmeBody setwidget $tree
	
	foreach {tag descript} [list \
			"Check" " " \
			"FileType"	"FileType" \
			"File"	"File" \
			"TextStatus" "Text status" \
			"PropertyStatus" "Property status" \
			"Look" "Look"] {
	$tree column create -tag col$tag -font [::crowFont::get_font smaller] \
		 -expand no -text [::msgcat::mc $descript]				
	}
	
	$tree element create rect rect \
		-open news -showfocus yes -fill [list #a5c4c4 {selected}] 

	$tree element create imgCheck image \
		-image [list [::crowImg::get_image checked] CHECKED \
					 [::crowImg::get_image unchecked] UNCHECKED]
	$tree style create styCheck 
	$tree style elements styCheck [list rect imgCheck]
	$tree style layout styCheck imgCheck -padx {0 4} -expand news
	$tree style layout styCheck rect -union {imgCheck} -iexpand news -ipadx 2

	$tree element create imgType image \
		-image [list [::crowImg::get_image file] TYPE_FILE \
					 [::crowImg::get_image folder] TYPE_DIRECTORY]
	$tree style create styType 
	$tree style elements styType [list rect imgType]
	$tree style layout styType imgType -padx {0 4} -expand news
	$tree style layout styType rect -union {imgType} -iexpand news -ipadx 2

	$tree element create txtNormal text -lines 1	
	$tree style create styNormal 
	$tree style elements styNormal [list rect txtNormal]
	$tree style layout styNormal txtNormal -padx {0 4} -squeeze x -expand ns
	$tree style layout styNormal rect -union {txtNormal} -iexpand news -ipadx 2
	
	$tree element create txtModified text -lines 1 -fill "blue"
	$tree style create styModified 
	$tree style elements styModified [list rect txtModified]
	$tree style layout styModified txtModified -padx {0 4} -squeeze x -expand ns
	$tree style layout styModified rect -union {txtModified} -iexpand news -ipadx 2

	$tree element create txtDeleted text -lines 1 -fill "red"
	$tree style create styDeleted 
	$tree style elements styDeleted [list rect txtDeleted]
	$tree style layout styDeleted txtDeleted -padx {0 4} -squeeze x -expand ns
	$tree style layout styDeleted rect -union {txtDeleted} -iexpand news -ipadx 2	

	$tree notify install <Header-invoke>
	$tree notify bind $tree <Header-invoke> {
		if {[%T column cget %C -arrow] eq "down"} {
			set order -increasing
			set arrow up
		} else {
			set order -decreasing
			set arrow down
		}
		foreach col [%T column list] {
			%T column configure $col -arrow none
		}
		%T column configure %C -arrow $arrow
		switch [%T column cget %C -tag] {
			colCheck -
			colFileType {
				%T item sort root $order -column %C -command [list ::svnWrapper::svn_status_compare %T %C] 
			}
			default {
				%T item sort root $order -column %C -dictionary
			}
		}
	}
	
	bind $tree <ButtonRelease-1> {
		set id [%W identify %x %y]
		if {[llength $id] != 6} {
			%W selection clear
		} else {
			foreach {what itemId where columnId type name} $id {}
			if { $what eq "item" && $where eq "column"} {
				if {$columnId <=1} {
					%W selection clear
					%W selection add $itemId	
				}
				set tag [%W column cget $columnId -tag]
				if {$tag eq "colCheck"} {
					if {[%W item state forcolumn $itemId colCheck] eq "CHECKED"} {
						%W item state forcolumn $itemId colCheck [list !CHECKED UNCHECKED]
					} else {
						%W item state forcolumn $itemId colCheck [list CHECKED !UNCHECKED]
					}
					
				}
			}
		}
	}
	
	bind $tree <ButtonRelease-3> {
		set id [%W identify %x %y]
		if {$id eq ""} {
			%W selection clear
		} else {
			if {[llength $id] == 6} {
				foreach {what itemId where columnId type name} $id {}
				if {$what eq "item" && $where eq "column"} {
					#%W selection modify $itemId all
					set state [%W item state forcolumn $itemId 0]
					::svnWrapper::svn_commit_item_menu_popup %W %X %Y $itemId
					
				}
			}
		}
	}		

	set fmeBtn [frame $fmeMain.fmeBtn]
	set fmeLogin [frame $fmeBtn.fmeLogin -bd 2 -relief groove]
	set chkLogin [checkbutton $fmeLogin.chkLogin -text [::msgcat::mc "Login"] \
		-command [list ::svnWrapper::svn_commit_chkLogin_click $fmeLogin.txtUser $fmeLogin.txtPasswd] \
		-onvalue 1 -offvalue 0 -variable ::svnWrapper::wInfo(chkLogin,var)]
	set lblUser [label $fmeLogin.lblUser -text [::msgcat::mc "Username:"] -anchor w -justify left]
	set txtUser [entry $fmeLogin.txtUser -textvariable ::svnWrapper::wInfo(txtUser,var) -takefocus 1]
	set lblPasswd [label $fmeLogin.lblPasswd -text [::msgcat::mc "Passwd:"] -anchor w -justify left]
	set txtPasswd [entry $fmeLogin.txtPasswd -show "*" -textvariable ::svnWrapper::wInfo(txtPasswd,var) -takefocus 1]
	
	::svnWrapper::svn_commit_chkLogin_click $txtUser $txtPasswd
#	$fmeLogin configure -labelwidget $chkLogin
	grid $chkLogin $lblUser $txtUser $lblPasswd $txtPasswd -sticky "news" -pady 2 -padx 2
	grid columnconfigure $fmeLogin 5 -weight 1

	set btnCommit [button $fmeBtn.btnCommit -width 6 -text [::msgcat::mc "Commit"] \
		-command [list after idle [list ::svnWrapper::svn_commit_exec $path $tree $txtMsg $target]]]
	set btnCancel [button $fmeBtn.btnCancel -width 6 -text [::msgcat::mc "Cancel"] \
		-command [list after idle [list destroy $path]]]		
	pack $fmeLogin -side left -expand 1 -fill x
	pack $btnCommit -side left -expand 0 -padx 10 -pady 2
	pack $btnCancel -side left -expand 0 -padx 10 -pady 2
	set wInfo(svn_commit_check,btnCommit) $btnCommit
	set wInfo(svn_commit_check,btnCancel) $btnCancel
	
	grid $fmeTitle -padx 3 -pady 3 -sticky "news"
	grid $fmeMsg -padx 3 -pady 3 -sticky "news"
	grid $fmeBody -padx 3 -pady 3 -sticky "news"
	grid $fmeBtn -padx 3  -pady 3 -sticky "news"
	grid rowconfigure $fmeMain 2 -weight 1
	grid columnconfigure $fmeMain 0 -weight 1
	set wInfo(svn_commit_target) $target
	set wInfo(svn_commit_tree) $tree
	
	update
	after 50 [list ::svnWrapper::svn_commit_refresh $tree $target]
	$path draw
	destroy $path
	return
}

proc ::svnWrapper::svn_commit_refresh {tree {target ""}} {
	variable wInfo
	
	$tree item delete all
	set result [::svnWrapper::svn_status_get $target]
	if {$result == -1} {return}
	if {$result eq ""} {
		set item [$tree item create -button no]
		$tree item lastchild 0 $item
		set sty styNormal
		$tree item style set $item \
			colCheck styCheck \
			colFileType styType \
			colFile $sty \
			colTextStatus $sty \
			colPropertyStatus $sty \
			colLook $sty
		$tree item text $item \
			colFile [::msgcat::mc "No files were changed or added since the last commit."]
		$wInfo(svn_commit_check,btnCommit) configure -state disabled
		return
	} 

	foreach data $result {
		array set arrInfo $data
		set item [$tree item create -button no]
		$tree item lastchild 0 $item
		
		switch -exact -- $arrInfo(TextStatus) {
			"modified" {set sty styModified}
			"missing" -
			"deleted" {set sty styDeleted}
			default {set sty styNormal}
		}

		$tree item style set $item \
			colCheck styCheck \
			colFileType styType \
			colFile $sty \
			colTextStatus $sty \
			colPropertyStatus $sty \
			colLook $sty
			
		$tree item text $item \
			colFile $arrInfo(File) \
			colTextStatus $arrInfo(TextStatus) \
			colPropertyStatus $arrInfo(PropertyStatus) \
			colLook $arrInfo(Look)
		
		$tree item state forcolumn $item colFileType "TYPE_$arrInfo(FileType)"
		if {$arrInfo(TextStatus) eq "unversioned"} {
			$tree item state forcolumn $item colCheck "UNCHECKED"
		} else {
			$tree item state forcolumn $item colCheck "CHECKED"
		}
		update
		array unset arrInfo
	}			

}

proc ::svnWrapper::svn_commit_exec {parent tree txtMsg {target ""}} {
	variable svnInfo
	variable wInfo
	
	set commitData ""
	set commitMessage [string trim [$txtMsg get 1.0 end]]
	foreach item [$tree item children 0] {
		if {[$tree item state forcolumn $item colCheck] eq "UNCHECKED"} {continue}
		set status [$tree item text $item colTextStatus]
		set fname [$tree item text $item colFile]
		if {[file isdirectory $target]} {
			set fname [file join $target $fname]
		} else {
			set fname $target
		}	
		switch -exact -- $status {
			"unversioned" {
				exec $svnInfo(CMD) add $fname
				set status added
			}
			"missing" {
				exec $svnInfo(CMD) delete $fname
				set status deleted			
			}
		}
		append commitData "$fname\n"
	}
		
	set path [::svnWrapper::msgbox_new ".__svn_commit_run__" [::msgcat::mc "Commit"]]
	
	if {$commitData eq ""} {
		::svnWrapper::msgbox_put $path [::msgcat::mc "Not thing to do."]\n
	} else {
		set rcDir [file join $::env(HOME) ".CrowTDE"]
		if {![file exists $rcDir]} {file mkdir $rcDir}
		set tmpFile [file join $rcDir "svn_commit.tmp"]
		set fd [open $tmpFile w]
		puts $fd $commitData
		close $fd
		
		::svnWrapper::msgbox_btn_state $path disabled
		set cmd [list | $svnInfo(CMD) commit --message $commitMessage --targets $tmpFile --non-interactive]
		if {$wInfo(chkLogin,var)} {
			lappend cmd --username $wInfo(txtUser,var) --password $wInfo(txtPasswd,var)
		}
		
		after 50 [list ::svnWrapper::svn_exec \
			$cmd \
			[list ::svnWrapper::msgbox_put $path] \
			[list ::svnWrapper::msgbox_put $path] \
			[list ::svnWrapper::msgbox_btn_state $path normal]]
	}
	$path draw
	catch {file delete $tmpFile}
	catch {::svnWrapper::msgbox_destroy $path}
	$parent enddialog ""
	return
}

proc ::svnWrapper::svn_commit_chkLogin_click {txtUser txtPasswd} {
	variable wInfo
	if {$wInfo(chkLogin,var)} {
		set state normal
	} else {
		set state disabled
	}
	$txtUser configure -state $state
	$txtPasswd configure -state $state	
}


proc ::svnWrapper::svn_commit_item_menu_popup {tree X Y itemId} {
	variable wInfo
	if {[winfo exists $tree.itemMenu]} {destroy $tree.itemMenu}

	set m [menu $tree.itemMenu -tearoff 0]
	set f [$tree item text $itemId colFile]
	switch -exact -- [$tree item text $itemId colTextStatus] {
		"normal" {
			destroy $m 
			return
		}
		"missing" {
			$m add command -compound left -label [::msgcat::mc "Delete"] \
				-command [list ::svnWrapper::svn_commit_cmd_eval [list ::svnWrapper::svn_del_init $f]]
			$m add command -compound left -label [::msgcat::mc "Revert"] \
				-command [list ::svnWrapper::svn_commit_cmd_eval [list ::svnWrapper::svn_revert_init $f]]	
		}
		"added" -
		"modified" {
			$m add command -compound left -label [::msgcat::mc "Delete"] \
				-command [list ::svnWrapper::svn_commit_cmd_eval [list ::svnWrapper::svn_del_init $f]]
			$m add command -compound left -label [::msgcat::mc "Revert"] \
				-command [list ::svnWrapper::svn_commit_cmd_eval [list ::svnWrapper::svn_revert_init $f]]	
		}
		"unversioned" {
			$m add command -compound left -label [::msgcat::mc "Add"] \
				-command [list ::svnWrapper::svn_commit_cmd_eval [list ::svnWrapper::svn_add_init $f]]	
			$m add command -compound left -label [::msgcat::mc "Delete"] \
				-command [list ::svnWrapper::svn_commit_cmd_eval [list file delete -force $f]]	
		}
		
	}
	tk_popup $m $X $Y	
	return
}

proc ::svnWrapper::svn_commit_cmd_eval {cmd} {
	variable wInfo
	eval $cmd
	::svnWrapper::svn_commit_refresh $wInfo(svn_commit_tree) $wInfo(svn_commit_target)
}
