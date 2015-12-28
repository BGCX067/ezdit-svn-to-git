namespace eval ::lframe {
	variable Priv
	array set Priv ""
}

proc ::lframe::init {path} {
	variable Priv
	
	set fMain [::ttk::frame $path]
	
	set sw [ScrolledWindow $fMain.sw]
	set tree [treectrl $sw.tree \
		-width 120 \
		-showroot no \
		-selectmod single \
		-showrootbutton no \
		-showbuttons no \
		-showheader no \
		-showlines no \
		-scrollmargin 16 \
		-xscrolldelay "500 50" \
		-yscrolldelay "500 50" \
		-highlightthickness 0 \
		-relief groove \
		-bd 2 \
		-bg white]
	$sw setwidget $tree
	set Priv(tree) $tree

	$tree column create -tag colItem -expand yes
	$tree element create eIcon image 
	$tree element create eName text -justify left
	$tree element create eSel rect \
		-fill [list "#C0C0C0" {selected focus} "#ffffff" {}] \
		-outline [list "#808080" {selected focus} "#ffffff" {}] \
		-outlinewidth 1 \
		-showfocus 0

	$tree configure -treecolumn colItem

	$tree style create styIcon
	$tree style elements styIcon {eSel eIcon eName}
	$tree style layout styIcon eIcon  -iexpand ns -ipady {10 10} -ipadx {10 10}
	$tree style layout styIcon eName	 -iexpand ns -ipady {10 10} 
	$tree style layout styIcon eSel -union {eName} -iexpand we -padx 2 -pady 2
	
	$tree element create eSep rect -fill "#b0b0b0"
	$tree element create eSepTxt text
	$tree style create stySep
	$tree style elements stySep {eSep}
	$tree style layout stySep eSep -height 1 -iexpand "x" -pady 10 -padx 4
	
	bind $tree <Button-1> [list ::lframe::tree_btn1_dclick %x %y]
	
	::lframe::refresh

	pack $sw -expand 1 -fill both
	return $path
}


proc ::lframe::tree_item_add {parent fpath img} {
	variable Priv
	set tree $Priv(tree)
	
	set item [$tree item create -button no]
	$tree item style set $item 0 styIcon
	$tree item lastchild $parent $item

	$tree item element configure $item 0 eIcon \
		-image [list $img.mark {selected focus} $img {}]

	set fname [file tail $fpath]
	if {$fname == ""} {set fname $fpath}
	$tree item element configure $item 0 eName -text $fname -data $fpath
	return $item
}

proc ::lframe::tree_separator_add {parent} {
	variable Priv
	set tree $Priv(tree)
	
	set item [$tree item create -button no]
	$tree item style set $item 0 stySep
	$tree item lastchild $parent $item
	return $item
}

proc ::lframe::tree_btn1_dclick {posx posy} {
	variable Priv
	set tree $Priv(tree)
		
	set ninfo [$tree identify $posx $posy]
	if {[llength $ninfo] != 6} {return}
	foreach {what itemId where columnId type name} $ninfo {}
	if {$what eq "item" && $where eq "column"} {
		set parent [$tree item parent $itemId]
		set idata [$tree item element cget $itemId 0 eName -data]
		
		
		# 檢查 目錄是不是存在/可不可以存取
		#
		if {[file isdirectory $idata]} {::rframe::chdir $idata}

	}
}

proc ::lframe::refresh {} {
	variable Priv
	set tree $Priv(tree)
	$tree item delete all
	
	set item [::lframe::tree_item_add 0 [::msgcat::mc "Home"] lframe.home]
	$tree item element configure $item 0 eName -data [file normalize $::env(HOME)]
	
#	set item [::lframe::tree_item_add 0 [::msgcat::mc "Desktop"] lframe.desktop]
#	$tree item element configure $item 0 eName -data $::env(DESK_FOLDER)	
	
	foreach v [file volumes] {
		set type [::libCrowFM::get_volume_type $v]
		set item [::lframe::tree_item_add 0 $v lframe.$type]
	}
	::lframe::tree_separator_add 0
	
	# load bookmarks
	foreach {bk} [::libCrowFM::bookmark_ls] {
		set item [::lframe::tree_item_add 0 [string trim $bk] lframe.bookmark]
	}
}
