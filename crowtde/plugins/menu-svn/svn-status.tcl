proc ::svnWrapper::svn_status_init {{target ""}} {
	variable svnInfo
	variable wInfo
	
	
	set path ".__svn_status__"
	if {[winfo exists $path]} {destroy $path}
	Dialog $path -title [::msgcat::mc "Status"] -modal local
	set fmeMain [$path getframe]
	set fmeBody [ScrolledWindow $fmeMain.fmeBody]
	
	set tree [treectrl $fmeBody.tree \
		-font [::crowFont::get_font smaller] \
		-height 250 \
		-width 600 \
		-showroot no \
		-showline no \
		-selectmod single \
		-showrootbutton no \
		-showbuttons no \
		-showheader yes \
		-scrollmargin 16 \
		-highlightthickness 0 \
		-relief groove \
		-bg white \
		-xscrolldelay "500 50" \
		-yscrolldelay "500 50"]	
	$fmeBody setwidget $tree

	$tree state define TYPE_FILE 
	$tree state define TYPE_DIRECTORY
	
	foreach {tag descript} [list \
			"FileType" " " \
			"File"	"File" \
			"TextStatus" "Text status" \
			"PropertyStatus" "Property status" \
			"RemoteTextStatus" "Remote text status" \
			"RemotePropertyStatus" "Remote property status" \
			"Look" "Look" \
			"LookComment" "Look comment" \
			"Author" "Author" \
			"Revision" "Revision" \
			"Date" "Date"] {
	$tree column create -tag col$tag -font [::crowFont::get_font smaller] \
		 -expand no -text [::msgcat::mc $descript]				
	}


	$tree element create rect rect \
		-open news -showfocus yes -fill [list #a5c4c4 {selected}] 

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
			colFileType {
				%T item sort root $order -column %C -command [list ::svnWrapper::svn_status_compare %T %C] }
			default {
				%T item sort root $order -column %C -dictionary
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
					::svnWrapper::svn_status_item_menu_popup %W %X %Y $itemId
					
				}
			}
		}
	}	
	
	set fmeBtn [frame $fmeMain.fmeBtn]
	set chkShowIgnore [checkbutton $fmeBtn.chkShowIgnore \
		-anchor w \
		-onvalue "--no-ignore" -offvalue "" \
		-text "Show ignored files" \
		-variable ::svnWrapper::wInfo(chkShowIgnore,var) \
		-command [list ::svnWrapper::svn_status_get $target --non-interactive --show-updates --no-ignore] ]
	
	set btnOk [button $fmeBtn.btnOk -width 6 -text [::msgcat::mc "Ok"] \
		-command [list after idle [list destroy $path]]]
	pack $chkShowIgnore -side left -expand 1 -fill x
	pack $btnOk -expand 0 -padx 10 -pady 2
	
	
	grid $fmeBody -sticky "news" -padx 3  -pady 3
	grid $fmeBtn -sticky "news" -padx 3  -pady 3
	grid rowconfigure $fmeMain 0 -weight 1
	grid columnconfigure $fmeMain 0 -weight 1
	set wInfo(svn_status_target) $target
	set wInfo(svn_status_tree) $tree
	after 50 [list ::svnWrapper::svn_status_exec $tree $target]
	$path draw
	destroy $path
	return
}

proc ::svnWrapper::svn_status_compare {T C item1 item2} {
	set s1 [$T item state forcolumn $item1 $C]
	set s2 [$T item state forcolumn $item2 $C]
	if {$s1 eq $s2} {return 0}
	switch -exact -- [$T column cget $C] {
		"colFileType" {
			if {$s1 eq "TYPE_DIRECTORY"} {return 1}
		}
		"colCheck" {
			if {$s1 eq "CHECKED"} {return 1}
		}
	}
	return -1
}

proc ::svnWrapper::svn_status_item_menu_popup {tree X Y itemId} {
	variable wInfo
	if {[winfo exists $tree.itemMenu]} {destroy $tree.itemMenu}

	set m [menu $tree.itemMenu -tearoff 0]
	set f [$tree item text $itemId colFile]
	switch -exact -- [$tree item text $itemId colTextStatus] {
		"normal" {
			$m add command -compound left -label [::msgcat::mc "Update"] \
				-command [list ::svnWrapper::svn_status_cmd_eval [list ::svnWrapper::svn_update_init $f]]
		}
		"missing" {
			$m add command -compound left -label [::msgcat::mc "Delete"] \
				-command [list ::svnWrapper::svn_status_cmd_eval [list ::svnWrapper::svn_del_init $f]]
			$m add command -compound left -label [::msgcat::mc "Revert"] \
				-command [list ::svnWrapper::svn_status_cmd_eval [list ::svnWrapper::svn_revert_init $f]]	
		}
		"added" -
		"modified" {
			$m add command -compound left -label [::msgcat::mc "Commit"] \
				-command [list ::svnWrapper::svn_status_cmd_eval [list ::svnWrapper::svn_commit_init $f]]
			$m add separator
			$m add command -compound left -label [::msgcat::mc "Delete"] \
				-command [list ::svnWrapper::svn_status_cmd_eval [list ::svnWrapper::svn_del_init $f]]
			$m add command -compound left -label [::msgcat::mc "Revert"] \
				-command [list ::svnWrapper::svn_status_cmd_eval [list ::svnWrapper::svn_revert_init $f]]	
		}
		"unversioned" {
			$m add command -compound left -label [::msgcat::mc "Add"] \
				-command [list ::svnWrapper::svn_status_cmd_eval [list ::svnWrapper::svn_add_init $f]]	
			$m add command -compound left -label [::msgcat::mc "Delete"] \
				-command [list ::svnWrapper::svn_status_cmd_eval [list file delete -force $f]]	
		}
		
	}
	tk_popup $m $X $Y	
	return
}

proc ::svnWrapper::svn_status_exec {tree {target ""}} {
	variable wInfo

	$tree item delete all
	if {$wInfo(chkShowIgnore,var) ne ""} {
		set result [::svnWrapper::svn_status_get $target --show-updates --no-ignore --non-interactive]
	} else {
		set result [::svnWrapper::svn_status_get $target --show-updates --non-interactive]
	}
	if {$result eq "-1"} {return}
	if {$result eq ""} {
		set item [$tree item create -button no]
		set sty styNormal
		$tree item lastchild 0 $item		
		$tree item style set $item \
			colFileType $sty \
			colFile $sty \
			colTextStatus $sty \
			colPropertyStatus $sty \
			colRemoteTextStatus $sty \
			colRemotePropertyStatus $sty \
			colLook $sty \
			colLookComment $sty \
			colAuthor $sty \
			colRevision $sty \
			colDate $sty
		$tree item text $item colFile [::msgcat::mc "File list is empty!"]
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
			colFileType styType \
			colFile $sty \
			colTextStatus $sty \
			colPropertyStatus $sty \
			colRemoteTextStatus $sty \
			colRemotePropertyStatus $sty \
			colLook $sty \
			colLookComment $sty \
			colAuthor $sty \
			colRevision $sty \
			colDate $sty
		$tree item text $item \
			colFile $arrInfo(File) \
			colTextStatus $arrInfo(TextStatus) \
			colPropertyStatus $arrInfo(PropertyStatus) \
			colRemoteTextStatus $arrInfo(RemoteTextStatus) \
			colRemotePropertyStatus $arrInfo(RemotePropertyStatus) \
			colLook $arrInfo(Look) \
			colLookComment $arrInfo(LookComment) \
			colAuthor $arrInfo(Author) \
			colRevision $arrInfo(Revision) \
			colDate $arrInfo(Date)
		$tree item state forcolumn $item colFileType "TYPE_$arrInfo(FileType)"
		array unset arrInfo
	}			
	
}

proc ::svnWrapper::svn_status_cmd_eval {cmd} {
	variable wInfo
	eval $cmd
	::svnWrapper::svn_status_exec $wInfo(svn_status_tree) $wInfo(svn_status_target)
}
