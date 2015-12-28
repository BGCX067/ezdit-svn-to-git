namespace eval ::body {
	variable Priv
	array set Priv [list currPath "" cmbPath "" cpBuf ""]

	set Priv(gdisk,count) 0
	set Priv(task,count) 0	

}

proc ::body::btn_page {path} {
	
	set ibox $::dApp::Priv(ibox)
	
	set btnPage [::ttk::menubutton $path \
		-style "Toolbutton" \
		-image [$ibox get star] ]

	if {[winfo exists $btnPage.popMenu]} {destroy $btnPage.popMenu}
	set m [menu $btnPage.popMenu -tearoff 0]

	$m add command -compound left \
		-image [$ibox get home] \
		-label [::msgcat::mc "Browse"] \
		-command {
		::body::cmd_cd "."
		::body::frame_show fmeBrowse
		
	}
	$m add command -compound left \
		-image [$ibox get task] \
		-label [::msgcat::mc "Queue"] \
		-command {
			::body::queue_refresh
			::body::frame_show fmeQueue
	}
	$m add command -compound left \
		-image [$ibox get site-small] \
		-label [::msgcat::mc "Site Manager"] \
		-command {
			::body::siteMgr_refresh	
			::body::frame_show fmeSiteMgr
	}
	$m add separator
	$m add command -compound left \
		-label [::msgcat::mc "About"] \
		-command {::about::show}	

	$btnPage configure -menu $m
	
	::tooltip::tooltip $btnPage [::msgcat::mc "Change page"]
	
	return $path
}

proc ::body::cmd_cd {dir} {
	variable Priv
	
	set ibox $::dApp::Priv(ibox)
	set node [::gvfs::cmd_cd $dir]
	if {$node == ""} {
		::body::cmd_cd "."
		return
	}
	array set meta [::gvfs::cmd_meta $node]
	
	set Priv(currMetaId) $meta(metaId)
	$Priv(tree) item delete all
	array unset Priv nitem,*
	foreach item [::gvfs::cmd_list] {
		array set meta [::gvfs::cmd_meta $item]
		set treeitem [::body::tree_item_add 0 \
				[$ibox get $meta(type)] \
				$meta(name) \
				$meta(size) \
				$meta(ctime) \
				$meta(cmd) \
				$item]
		if {$meta(type) == "file" && $meta(cmd) == "" && $meta(complete) == 0} {$Priv(tree) item state set $treeitem "FRAGMENT" }
	}

	if {$dir == "."} {
		set dir $Priv(currPath) 
	} elseif {$dir == ".."} {
		set dir [file dirname $Priv(currPath)]
	} elseif {$dir == "/"} {
		set dir "/"
	} else {
		set dir [file join $Priv(currPath) $dir]
	}

	set Priv(currPath) $dir
	
	set values [list]
	while {$dir != "/"} {
		set dir [file dirname $dir]
		lappend values $dir
	}
	$Priv(cmbPath) configure -values $values
	
	::body::tree_item_sort	
}

proc ::body::cmd_cut {items} {
	variable Priv
	set tree $Priv(tree)
	
	set Priv(cpBuf) ""
	
	foreach item $items {
		set node [$tree item element cget $item cName eTxt -data]
		lappend Priv(cpBuf) $node
	}
	
	::gutil::msg_put [::msgcat::mc "Cut %s items" [llength $items]]
}

proc ::body::cmd_delete {items} {
	variable Priv
	set tree $Priv(tree)
	
	set ans [tk_messageBox -icon "question" \
		-default "no" \
		-title [::msgcat::mc "Confirm"] \
		-message [::msgcat::mc "Are you sure? You want to delete selected items ." [llength $items]] \
		-type yesno]
	if {$ans == "no"} {return}	

	set nodes ""
	foreach item $items {
		set node [$tree item element cget $item cName eTxt -data]
		set name [$tree item element cget $item cName eTxt -text]
		if {[::gvfs::cmd_locked $node ALL]} {
			set ans [tk_messageBox -icon "error" \
				-default "ok" \
				-title [::msgcat::mc "Error"] \
				-message [::msgcat::mc "Can't delete '%s'. The item is locked." $name] \
				-type ok]			
				return
		}
		lappend nodes $node
	}

	foreach node $nodes {::gvfs::cmd_delete $node}
	::body::cmd_cd "."
	::body::queue_refresh
}

proc ::body::cmd_delete_force {items} {
	variable Priv
	set tree $Priv(tree)
	
	set ans [tk_messageBox -icon "question" \
		-default "no" \
		-title [::msgcat::mc "Confirm"] \
		-message [::msgcat::mc "Are you sure? You want to delete selected items from file system but GMail." [llength $items]] \
		-type yesno]
	if {$ans == "no"} {return}	

	foreach item $items {
		set node [$tree item element cget $item cName eTxt -data]
#		if {[::gvfs::cmd_locked $node ALL]} {
#			set ans [tk_messageBox -icon "error" \
#				-default "ok" \
#				-title [::msgcat::mc "Error"] \
#				-message [::msgcat::mc "Can't delete '%s'. The item is locked."] \
#				-type ok]			
#				return
#		}		
		$::gvfs::Priv(fstok) item_del $node
	}

	::body::cmd_cd "."
}

proc ::body::cmd_download {{items ""} {saveDir ""}} {
	variable Priv
	
	set tree $Priv(tree)
	if {$items == ""} {set items [$tree selection get]}
	if {$items == ""} {return}
	
	if {$saveDir == ""} {
		set saveDir [tk_chooseDirectory -title [::msgcat::mc "Save to..."] -mustexist 1]
		
		if {$saveDir != "" && $saveDir != "-1"} {
			set rcDir $::gvfs::Priv(rcDir)
			set hisFile [file join $rcDir history.txt]
			if {![file exists $hisFile]} {close [open $hisFile w]}
			set fd [open $hisFile r]
			set data [split [read $fd] "\n"]
			close $fd
			set fd [open $hisFile w]
			foreach h [lrange [linsert $data 0 $saveDir] 0 4] {puts -nonewline $fd "$h\n"}
			close $fd
		} else {
			return 0
		}
	}


	set nodes ""
	foreach item $items {
		set node [$tree item element cget $item cName eTxt -data]
		set name [$tree item element cget $item cName eTxt -text]
		if {[::gvfs::cmd_locked $node [list UPLOAD DELETE]]} {
		set ans [tk_messageBox -icon "error" \
			-default "ok" \
			-title [::msgcat::mc "Error"] \
			-message [::msgcat::mc "Can't download '%s'. The item is locked." $name] \
			-type ok]			
			return
		}
		lappend nodes $node
	}

	if {$nodes == ""} {return}

	set flag ""
	set nodes2 ""
	foreach node $nodes {
		array set meta [::gvfs::cmd_meta $node]
		set fpath [file join $saveDir $meta(name)]
		if {[file exists $fpath]} {
			if {$flag == ""} {
				set win ._dapp_inputBox
				set ans [::ttdialog::messageBox $win \
					-title [::msgcat::mc "Error"] \
					-message [::msgcat::mc "The '%s' already exists in the directory. What do you want to do?" $meta(name)] \
					-buttons [list [::msgcat::mc "Skip"] skip \
										[::msgcat::mc "Skip All"] skipall \
										[::msgcat::mc "Replace"] replace \
										[::msgcat::mc "Replace All"] replaceall \
										[::msgcat::mc "Cancel"] cancel] \
				]
				if {$ans == "cancel"} {return}
				if {$ans == "skip"} {continue}
				if {$ans == "skipall"} {set flag $ans}
				if {$ans == "replaceall"} {set flag $ans}
			}
			if {$flag == "skipall"} {continue}
		}
		lappend nodes2 $node
	}
	if {$nodes2 == ""} {return}
	foreach node $nodes2 {::gvfs::cmd_download $node $saveDir}
	::body::cmd_cd "."
	::body::queue_refresh
}

proc ::body::cmd_mkdir {} {
	variable Priv
	
	set ibox $::dApp::Priv(ibox)
	
	if {$Priv(currPath) != "/" && [::gvfs::cmd_node $Priv(currMetaId)] == ""} {
		::body::cmd_cd "/"
		return
	}
	
	set dir [::msgcat::mc "New Folder"]
	set i 1
	while {[::gvfs::cmd_exists $dir]} {
		set dir  [::msgcat::mc "New Folder - %s" $i]
		incr i
	}
	set node [::gvfs::cmd_mkdir $dir]
	if {$node == ""} {return}
	array set meta [::gvfs::cmd_meta $node]

	set treeitem [::body::tree_item_add 0 \
			[$ibox get $meta(type)] \
			$meta(name) \
			$meta(size) \
			$meta(ctime) \
			$meta(cmd) \
			$node]	
		::TreeCtrl::FileListEdit $Priv(tree) $treeitem cName eTxt

}

proc ::body::cmd_paste {{target ""}} {
	variable Priv

	if {$target == ""} {set target [::gvfs::cmd_pwd]}

	array set meta [::gvfs::cmd_meta $target]
	if {$meta(type) == "file"} {set target [::gvfs::cmd_pwd]}

	set tree $Priv(tree)
	
	foreach node $Priv(cpBuf) {
		if {[$node parentNode] == $target} {return}
		array set meta [::gvfs::cmd_meta $node]
		if {[::gvfs::cmd_exists $meta(name) $target]} {
			tk_messageBox -title [::msgcat::mc "Error"] \
				-message [::msgcat::mc "'%s' already in the directory. Please rename and try again." $meta(name)]  \
				-icon error \
				-type ok
			return
		}
	}

	set idList ""
	foreach node $Priv(cpBuf) {::gvfs::cmd_mv $node $target}

	set Priv(cpBuf) ""
	::body::cmd_cd "."	
}

proc ::body::cmd_upload {{fpath ""}} {
	variable Priv
	
	if {$fpath == ""} {
		set ans [tk_getOpenFile \
					-title [::msgcat::mc "Choose file"] \
					-multiple 0 \
					-filetypes [list [list ALL *]]]
		if {$ans == "" || $ans == -1} {return}
		set fpath $ans
	}
	
	set node [::gvfs::cmd_pwd]
	set fname [file tail $fpath]
	if {[::gvfs::cmd_locked $node [list DELETE]]} {
	set ans [tk_messageBox -icon "error" \
		-default "ok" \
		-title [::msgcat::mc "Error"] \
		-message [::msgcat::mc "Can't upload '%s'. The parent directory is locked." $fname] \
		-type ok]			
		return
	}
	
	if {[::gvfs::cmd_exists $fname] == 1} {
		tk_messageBox -title [::msgcat::mc "Error"] \
			-message [::msgcat::mc "'%s' already exists. Please rename and try again." $fname]  \
			-type ok \
			-icon error
		return
	}	

	::gvfs::cmd_upload $fpath
	::body::cmd_cd "."
	::body::queue_refresh

}
proc ::body::compare_state {tree col order item1 item2} {
	set node1 [$tree item element cget $item1 $col eTxt -data]
	set node2 [$tree item element cget $item2 $col eTxt -data]

	array set meta1 [::gvfs::cmd_meta $node1]
	array set meta2 [::gvfs::cmd_meta $node2]

	set type $meta1(type)
	set type2 $meta2(type)
	set name $meta1(name)
	set name2 $meta2(name)

	if {$type == $type2} {
		if {$name == $name2} {return 0}
		if {$type == "file"} {
			if {$name > $name2} {return 1}
			return -1
		} else {
			if {$name > $name2} {return 1}
			return -1	
		}
	}
	if {$type == "directory" && $type2 == "file"} {
		if {$order == "-increasing"} {
			return 1
		} else {
			return -1
		}
	} else {
		if {$order == "-increasing"} {
			return -1
		} else {
			return 1
		}
	}
}

proc ::body::init {path} {
	variable Priv
	
	::ttk::frame $path

	set Priv(fmeBrowse) [::body::tree_init $path.tree]
	set Priv(fmeQueue) [::body::queue_init $path.queue]
	set Priv(fmeSiteMgr) [::body::siteMgr_init $path.siteMgr]

	::body::frame_show fmeBrowse
	
	::body::cmd_cd /

	return $path

}

proc ::body::frame_show {fme} {
	variable Priv
	pack forget $Priv(fmeQueue)
	pack forget $Priv(fmeBrowse)
	pack forget $Priv(fmeSiteMgr)
	pack $Priv($fme) -fill both -expand 1 -padx 2
}

proc ::body::queue_cancel {} {
	variable Priv
	set ans [tk_messageBox -icon "question" \
		-title [::msgcat::mc "Confirm"] \
		-message [::msgcat::mc "Are you sure? You want to delete selected items."] \
		-type yesno]
	if {$ans == "no"} {return}
	
	set tree $Priv(queue)
	foreach {item} [$tree selection get] {
		set qid [$tree item element cget $item cFile eFile -data]
		$tree item delete $item
		::gvfs::queue_del $qid
	}
}

proc ::body::queue_clear {} {
	::gvfs::queue_clear
	::body::queue_refresh	
}

proc ::body::queue_init {path} {
	variable Priv
	
	set ibox $::dApp::Priv(ibox)	

	::ttk::frame $path
		
	
	set fmeTbar [::ttk::frame $path.fmeTbar]

	set btnClear [::ttk::button $fmeTbar.btnClear \
		-compound left \
		-text [::msgcat::mc "Clear"] \
		-style "Toolbutton" \
		-image [$ibox get queue_clear] \
		-command {::body::queue_clear}]
		
	set btnStart [::ttk::checkbutton $fmeTbar.btnStart \
		-compound left \
		-text [::msgcat::mc "Start"] \
		-variable ::gvfs::Priv(queueStart) \
		-style "Toolbutton" \
		-image [$ibox get flag_running] \
		-command {
			if {$::gvfs::Priv(queueStart)} {
				::body::queue_start
			} else {
				::body::queue_stop
			}
	}]
			
	set btnPage [::body::btn_page $fmeTbar.btnPage]


	::tooltip::tooltip $btnStart [::msgcat::mc "Queue status"]
	::tooltip::tooltip $btnClear [::msgcat::mc "Clear finished item"]

	
	pack $btnStart -side left	-pady 1
	pack $btnClear -side left -padx 3
	pack $btnPage -side left -expand 1 -anchor e
	
	
	set sw [ScrolledWindow $path.sw]
	set fmeMain [$sw getframe]
	set tree [treectrl $fmeMain.tree \
		-relief groove \
		-width 600 \
		-height 400 \
		-showroot no \
		-showline no \
		-selectmod extended \
		-showrootbutton no \
		-showbuttons no \
		-showheader yes \
		-scrollmargin 1 \
		-highlightthickness 0 \
		-itemwidthequal 1 ]
	
	$tree state define "DELETE"
	$tree state define "UPLOAD"
	$tree state define "DOWNLOAD"
	$tree state define "STOP"
	$tree state define "WAIT"
	$tree state define "RUNNING"
	$tree state define "FINISH"
	$tree state define "ERROR"		
	
	$tree column create -tag cFlag -itembackground {"#EDF3FE" {}} -text [::msgcat::mc "State"]
	$tree column create -tag cPbr -itembackground {"#EDF3FE" {}} -text [::msgcat::mc "Progress"]
	$tree column create -tag cSpeed -itembackground {"#EDF3FE" {}} -text [::msgcat::mc "Speed"] -width 100
	$tree column create -tag cSize -itembackground {"#EDF3FE" {}} -text [::msgcat::mc "Total transmission"] -width 100
	$tree column create -tag cRemain -itembackground {"#EDF3FE" {}} -text [::msgcat::mc "Remain time"] -width 100
	$tree column create -tag cFile -itembackground {"#EDF3FE" {}} -text [::msgcat::mc "Filename"] -expand 1 -weight 1
	
	$tree element create eRect rect -outlinewidth 0 -fill [list "#738499" {selected focus}]
	$tree element create eFlag image \
		-image [list  \
				[$ibox get flag_stop] {STOP} \
				[$ibox get flag_wait] {WAIT} \
				[$ibox get flag_running] {RUNNING} \
				[$ibox get flag_finish] {FINISH} \
				[$ibox get flag_error] {ERROR} \
	]	
	$tree element create eCmd image \
		-image [list  \
				[$ibox get cmd_upload] {UPLOAD} \
				[$ibox get cmd_download] {DOWNLOAD} \
				[$ibox get cmd_delete] {DELETE} \
				[$ibox get cmd_none] {}]
	$tree element create eFile text -fill [list "#ffffff" {selected focus} "#000000" {}]
	$tree element create ePbr window -clip 0 -destroy 1 
	$tree element create eSpeed text -fill [list "#ffffff" {selected focus} "#000000" {}] -text "                    "
	$tree element create ePercent text -fill [list "#ffffff" {selected focus} "#000000" {}] -text "               "
	$tree element create eSize text -fill [list "#ffffff" {selected focus} "#000000" {}] -text "                    "
	$tree element create eRemain text -fill [list "#ffffff" {selected focus} "#000000" {}] -text "                    "
	$tree element create eMsg text -fill [list "#ffffff" {selected focus} "#000000" {}] -text ""
	
	$tree style create styFlag
	$tree style elements styFlag {eRect eFlag eCmd}
	$tree style layout styFlag eFlag -iexpand news
	$tree style layout styFlag eCmd -detach 1 -iexpand wn -ipady {0 10} -ipadx {0 10}
	$tree style layout styFlag eRect -union {eFlag eCmd} -iexpand news

	$tree style create stySpeed
	$tree style elements stySpeed {eRect eSpeed}
	$tree style layout stySpeed eSpeed -iexpand news 
	$tree style layout stySpeed eRect -union {eSpeed} -iexpand news

	$tree style create stySize
	$tree style elements stySize {eRect eSize}
	$tree style layout stySize eSize -iexpand news 
	$tree style layout stySize eRect -union {eSize} -iexpand news

	$tree style create styRemain
	$tree style elements styRemain {eRect eRemain}
	$tree style layout styRemain eRemain -iexpand news 
	$tree style layout styRemain eRect -union {eRemain} -iexpand news

	$tree style create styPbr
	$tree style elements styPbr {eRect ePbr ePercent}
	$tree style layout styPbr ePbr -pady 5 -padx 5
	$tree style layout styPbr ePercent  -pady 8
	$tree style layout styPbr eRect -union {ePbr ePercent} -iexpand news
	
	$tree style create styFile
	$tree style elements styFile {eRect eFile}
	$tree style layout styFile eFile -iexpand nes -ipadx {10 0}
	$tree style layout styFile eRect -union {eFile} -iexpand news
	
	foreach s {Flag Pbr Speed Size Remain File} {$tree column configure c$s -itemstyle sty$s}

	switch $::dApp::Priv(os) {
		"win32" -
		"linux" {
			set e "<ButtonRelease-3>"
		}
		"darwin" {
			set e "<ButtonRelease-2>"
		}
	}	
	
	bind $tree $e {
		set id [%W identify %x %y]
		if {[llength $id] == 6} {
			foreach {what itemId where columnId type name} $id {}
			if {$what eq "item" && $where eq "column"} {
				::body::queue_item_menu_popup $itemId %X %Y 
			}
		} else {
			::body::queue_item_menu_popup 0 %X %Y 
		}
	}
	
	bind $tree <Button-1> {
		set id [%W identify %x %y]
		if {[llength $id] == 6} {
			foreach {what itemId where columnId type name} $id {}
			if {$what eq "item" && $where eq "column"} {
				set qid [%W item element cget $itemId cFile eFile -data]
				lassign [::gvfs::queue_query $qid] qid type metaId gdiskId subject file start len flag
				set ::body::Priv(localUrl) [::msgcat::mc "Local URL : %%s " [file nativename $file]]
				set node [::gvfs::cmd_node $metaId]
				set ::body::Priv(remoteUrl) [::msgcat::mc "Remote URL : %%s " [::gvfs::cmd_path $node]] 
			}
		}
	}

	set Priv(queue) $tree
	$sw setwidget $tree		

	set Priv(localUrl) ""
	set Priv(remoteUrl) ""

	set fmeSbar [::ttk::frame $path.fmeSbar]
	set lblLocal [::ttk::label $fmeSbar.lblLocal -textvariable ::body::Priv(localUrl) -wraplength 600]
	set lblRemote [::ttk::label $fmeSbar.lblRemote -textvariable ::body::Priv(remoteUrl) -wraplength 600]
	set btnThread [::ttk::menubutton $fmeSbar.bthThread \
		-compound left \
		-image [$ibox get thread] \
		-text [::msgcat::mc "Max thread"] ]


	set m [menu $btnThread.popMenu -tearoff 0]
	for {set i 1} {$i < 6} {incr i} {
		$m add radiobutton \
			-value $i \
			-label $i -variable ::gvfs::Priv(maxThread)
	}
	
	$btnThread configure -menu $m
	
	set btnSplit [::ttk::menubutton $fmeSbar.bthSplit \
		-compound left \
		-image [$ibox get split] \
		-text [::msgcat::mc "File split"] ]


	set m [menu $btnSplit.popMenu -tearoff 0]
	foreach {lbl val} [list 512K 512 1M 1024 2M 2048 5M 5120 10M 10240 15M 15360] {
		$m add radiobutton \
			-value [expr 1024*$val] \
			-label $lbl -variable ::gvfs::Priv(splitSize)
	}
	
	$btnSplit configure -menu $m

	grid $lblLocal -row 0 -column 0
	grid $lblRemote -row 1 -column 0
	grid $btnThread -row 0 -column 1 -rowspan 2 -sticky ns -padx 2 -pady 2
	grid $btnSplit -row 0 -column 2 -rowspan 2 -sticky ns -padx 2 -pady 2
	grid columnconfigure $fmeSbar 0 -weight 1
	
	pack $fmeTbar -fill x -padx 2
	pack $sw -fill both -padx 2 -expand 1
	pack $fmeSbar -fill x
	
	return $path	
}

proc ::body::queue_item_add {qid type metaId fpath flag} {
	variable Priv
	
	set ::gvfs::Priv(percent,$qid) ""
	set ::gvfs::Priv(speed,$qid) ""
	set ::gvfs::Priv(size,$qid) ""
	set ::gvfs::Priv(remainT,$qid) ""
	
	set tree $Priv(queue)
	set item [$tree item create -parent 0 -open 0]
	set win [::ttk::progressbar $tree.pbar$qid -orient horizontal -maximum 0 -value 0]
	$tree item element configure $item cFile eFile  -text  [file tail $fpath] -data $qid
	$tree item element configure $item cPbr ePbr  -window $win
	$tree item element configure $item cPbr ePercent  -textvariable ::gvfs::Priv(percent,$qid)
	$tree item element configure $item cSpeed eSpeed  -textvariable ::gvfs::Priv(speed,$qid)
	$tree item element configure $item cSize eSize  -textvariable ::gvfs::Priv(size,$qid)
	$tree item element configure $item cRemain eRemain  -textvariable ::gvfs::Priv(remainT,$qid)
	$tree item state set $item $flag
	$tree item state set $item $type
	set ::gvfs::Priv(pbar,$qid) $tree.pbar$qid

	
	return $item
}

proc ::body::queue_item_menu_popup {itemId X Y} {
	variable Priv
	set tree $Priv(queue)
	set ibox $::dApp::Priv(ibox)
	
	set cut [$tree item count]
	
	set items [$tree selection get]

	if {[winfo exists $tree.popMenu]} {destroy $tree.popMenu}
	set m [menu $tree.popMenu -tearoff 0]

	set state "normal"
	# only root item
	if {$cut == 1} {set state disabled}
	$m add command -compound left -state $state -label [::msgcat::mc "Clear"] -command {::body::queue_clear}
#	$m add separator
#	if {$::gvfs::Priv(queueStart)} {
#		$m add command -compound left -label [::msgcat::mc "Stop Queue"] -command {::body::queue_stop}
#	} else {
#		$m add command -compound left -label [::msgcat::mc "Start Queue"] -command {::body::queue_start}
#	}
#	$m add separator
	$m add command -compound left -state $state -label [::msgcat::mc "Reset"] -command {::body::queue_reset}
	
	set state "normal"
	if {$items == ""} {set state disabled}	
	$m add command -compound left \
		-state $state \
		-image [$ibox get queue_delete] \
		-label [::msgcat::mc "Delete"] \
		-command {::body::queue_cancel}

	tk_popup $m $X $Y
}

proc ::body::queue_refresh {args} {
	variable Priv
	set tree $Priv(queue)
	array unset Priv qitem,*
	$tree item delete all
	array unset ::gvfs::Priv pbr,*
	array unset ::gvfs::Priv speed,*
	array unset ::gvfs::Priv size,*
	array unset ::gvfs::Priv percent,*
	array unset ::gvfs::Priv remainT,*
	
	set running 0
	set stop 0
	set finish 0
	set error 0
	foreach {item} [::gvfs::queue_list] {
		lassign $item qId type metaId gdiskId subject file start len flag
		switch -exact -- $type {
			"DELETE" {}
			"UPLOAD" {set file $file.part.$start}
			"DOWNLOAD" {}
		}
		incr [string tolower $flag]
		
		set Priv(qitem,$qId) [::body::queue_item_add $qId $type $metaId $file $flag]
	}
	set Priv(task,count) [::gvfs::task_count]
	
	::gutil::msg_put [::msgcat::mc "Running:(%s)  Waiting:(%s)  Error:(%s)  Finish:(%s)" $running $stop $error $finish] -1
	
	if {$::gvfs::Priv(queueStart)} {::body::queue_start}
	return 
}

proc ::body::queue_reset {} {
	variable Priv
	set tree $Priv(queue)
	set ibox $::dApp::Priv(ibox)
	
	set cut [$tree item count]
	
	set items [$tree selection get]
	if {$items == ""} {return}
	
	foreach {item} $items {
		set qid [$tree item element cget $item cFile eFile -data]
			::gvfs::queue_reset $qid
	}
	::body::queue_refresh
}

proc ::body::queue_start {} {
	::gvfs::queue_start
}

proc ::body::queue_state {qid state} {
	variable Priv
	set tree $Priv(queue)
	
	$tree item state set $Priv(qitem,$qid) $state
}

proc ::body::queue_stop {} {
	::gvfs::queue_stop
	after 1500 [list ::body::queue_refresh]
}

proc ::body::siteMgr_add {} {
	variable Priv
	set tree $Priv(siteMgr)

	set dlg $tree.dlgAdd

	catch {destroy $dlg}
	set win [::ttdialog::dialog $dlg \
				-title [::msgcat::mc "New gDisk"] \
				-buttons [list  [::msgcat::mc "Ok"] ok [::msgcat::mc "Cancel"] cancel] \
				-default ok \
			]
	
	set f [::ttdialog::clientframe $dlg]
	
	set ::body::Priv(dlg,txtUser) "user@gmail.com"
	set ::body::Priv(dlg,txtPw) ""
	set lblUser [::ttk::label $f.lblUser -text [::msgcat::mc "Username : "]]
	set txtUser [::ttk::entry $f.txtUser -textvariable ::body::Priv(dlg,txtUser)]
	set lblPw [::ttk::label $f.lblPw -text [::msgcat::mc "Password : "] ]
	set txtPw [::ttk::entry $f.txtPw -textvariable ::body::Priv(dlg,txtPw) -show "*"]
	
	grid $lblUser $txtUser -sticky "news" -padx 2 -pady 2
	grid $lblPw $txtPw -sticky "news" -padx 2 -pady 2
	grid columnconfigure $f 1 -weight 1
	
	$txtUser select range 0 4
	after idle [focus $txtUser]
	set ret [::ttdialog::dialog_wait $win]
	catch {destroy $dlg}
	
	if {$ret == "cancel" || $ret == -1} {return}
	set user [string trim $::body::Priv(dlg,txtUser)]
	set passwd [string trim $::body::Priv(dlg,txtPw)]

	if {$user == "" || $passwd == ""} {
		tk_messageBox -title [::msgcat::mc "Error"] \
			-message [::msgcat::mc "Username and Password can not empty!"] \
			-type "ok" \
			-icon "error" \
			-default "ok"

		return
	}
	
	set Priv(siteMsg) [::msgcat::mc "Trying to login '%s' please wait ! " $user]
	update
	
	set ret [::gutil::mkdir [lindex [split $user "@"] 0] $passwd "GDisk"]
	
	if {$ret == 0} {
		tk_messageBox -title [::msgcat::mc "Error"] \
			-message [::msgcat::mc "Can't login to '%s', please try again." $user] \
			-icon "error" \
			-type "ok" \
			-default ok
		catch {destroy $dlg}
		return
	}
	
	if {[::gvfs::gdisk_add [lindex [split $user "@"] 0] $passwd] == 0} {
		tk_messageBox -title [::msgcat::mc "Error"] \
			-message [::msgcat::mc "GDisk already exists or arrived maximum limit." $user] \
			-icon "error" \
			-type "ok" \
			-default ok
		set Priv(siteMsg) ""
		return
	}

	set Priv(siteMsg) [::msgcat::mc "Success!" $user]
	::body::siteMgr_refresh

	return
}

proc ::body::siteMgr_del {} {
	variable Priv
	set tree $Priv(siteMgr)
	
	
	set items [$tree selection get]
	
	if {$items == ""} {return}
	
	set cut [$tree item count]
	
	set ans [tk_messageBox -icon "question" \
		-default "no" \
		-title [::msgcat::mc "Confirm"] \
		-message [::msgcat::mc "Are you sure? You want to delete selected items ." [llength $items]] \
		-type yesno]
	if {$ans == "no"} {return}
	
	
	foreach {item} $items {
		set data [$tree item element cget $item cSite eTxt -data]
		foreach {gdisk user passwd} $data { ::gvfs::gdisk_del $gdisk}
		$tree item delete $item
	}	
}

proc ::body::siteMgr_init {path} {
	variable Priv
	
	set ibox $::dApp::Priv(ibox)	

	::ttk::frame $path
		
	
	set fmeTbar [::ttk::frame $path.fmeTbar]

	set btnAdd [::ttk::button $fmeTbar.btnAdd \
		-style "Toolbutton" \
		-image [$ibox get site_add] \
		-command {::body::siteMgr_add}]
		
	set btnDel [::ttk::button $fmeTbar.btnDel \
		-style "Toolbutton" \
		-image [$ibox get site_del] \
		-command {::body::siteMgr_del}]
			
	set btnPage [::body::btn_page $fmeTbar.btnPage]

	::tooltip::tooltip $btnAdd [::msgcat::mc "New"]
	::tooltip::tooltip $btnDel [::msgcat::mc "Delete"]

	pack $btnAdd -side left	-fill y -pady 1
	pack $btnDel -side left -fill y -padx 5 -pady 1
	pack $btnPage -side left -expand 1 -anchor e
	
	
	set sw [ScrolledWindow $path.sw]
	set fmeMain [$sw getframe]
	set tree [treectrl $fmeMain.tree \
		-relief groove \
		-width 600 \
		-height 400 \
		-showroot no \
		-showline no \
		-selectmod single \
		-showrootbutton no \
		-showbuttons no \
		-showheader no \
		-scrollmargin 1 \
		-wrap window \
		-bg white \
		-relief groove	\
		-orient horizontal \
		-highlightthickness 0 \
		-itemheight 120 \
		-itemwidth 130 \
		-itemwidthequal 1 ]
	
	$tree state define "MASTER"
	
	$tree column create -tag cSite 
	$tree element create eRect rect -outlinewidth 1 -fill [list "#e0e0e0" {selected focus}] -outline [list "#a0a0a0" {selected focus}]
	$tree element create eIcon image -image [list [$ibox get site] {MASTER} [$ibox get site] {}]
	$tree element create eTxt text -wrap none
	
	$tree style create stySite
	$tree style elements stySite {eRect eIcon eTxt}
	$tree style layout stySite eIcon -width 60 -height 60 -sticky "we" -ipadx {5 0}
	$tree style layout stySite eTxt -detach 1 -expand nwe -ipady {0 5} -width 90 -squeeze x
	$tree style layout stySite eRect -union {eIcon eTxt} -ipadx {5 5} -ipady {5 5} -pady {10 10} -padx {15 10}

	$tree column configure cSite -itemstyle stySite

	switch $::dApp::Priv(os) {
		"win32" -
		"linux" {
			set e "<ButtonRelease-3>"
		}
		"darwin" {
			set e "<ButtonRelease-2>"
		}
	}	
	
	bind $tree $e {
		set id [%W identify %x %y]
		if {[llength $id] == 6} {
			foreach {what itemId where columnId type name} $id {}
			if {$what eq "item" && $where eq "column"} {
				::body::siteMgr_item_menu_popup $itemId %X %Y 
			}
		} else {
			::body::siteMgr_item_menu_popup 0 %X %Y 
		}
	}
	
	bind $tree <Button-1> {
		set id [%W identify %x %y]
		if {[llength $id] == 6} {
			foreach {what itemId where columnId type name} $id {}
			if {$what eq "item" && $where eq "column"} {
				set data [%W item element cget $itemId cSite eTxt -data]
				foreach {gdisk user passwd} $data { 
					set ::body::Priv(siteMsg) $user
				}
			}
		}
	}	

	set Priv(siteMgr) $tree
	$sw setwidget $tree		

	set Priv(siteMsg) ""
	set fmeSbar [::ttk::frame $path.fmeSbar]
	set lblMsg [::ttk::label $fmeSbar.lblMsg -textvariable ::body::Priv(siteMsg) -wraplength 500]
	set lblMax [::ttk::label $fmeSbar.lblMax \
		-compound left \
		-image [$ibox get gdisk] \
		-text [::msgcat::mc "Max : %s" $::gvfs::Priv(maxGDisk)]]
	set btnBackup [::ttk::button $fmeSbar.btnBack \
		-compound left \
		-image [$ibox get backup] \
		-text [::msgcat::mc "Backup"] \
		-command {::gvfs::meta_backup}]
	set btnRecover [::ttk::button $fmeSbar.btnRecover \
		-compound left \
		-image [$ibox get recover] \
		-text [::msgcat::mc "Recover"] \
		-command {::gvfs::meta_recover}]		
		
	pack $lblMsg -expand 1 -fill x -padx 2 -side left
	#pack $btnBackup $btnRecover $lblMax -side left -padx 2 -ipady 2 -pady 2
	pack $lblMax -side left -padx 2 -ipady 2 -pady 2
	pack $fmeTbar -fill x -padx 2
	pack $sw -fill both -padx 2 -expand 1
	pack $fmeSbar -fill x
	
	
	return $path	
}

proc ::body::siteMgr_item_add {gdisk user passwd master} {
	variable Priv
	set tree $Priv(siteMgr)

	set item [$tree item create -parent 0 -open 0]
	$tree item element configure $item cSite eTxt -text [lindex [split $user "@"] 0] -data [list $gdisk $user $passwd]
	if {$master} {$tree item state set $item "MASTER"}
	return $item
}

proc ::body::siteMgr_item_menu_popup {item X Y} {
	variable Priv
	set tree $Priv(siteMgr)
	
	set ibox $::dApp::Priv(ibox)
	
	set cut [$tree item count]
	
	set items [$tree selection get]

	if {[winfo exists $tree.popMenu]} {destroy $tree.popMenu}
	set m [menu $tree.popMenu -tearoff 0]

	set state "normal"
	# only root item
	#if {$cut == 1} {set state disabled}
	$m add command -compound left -state $state \
		-label [::msgcat::mc "New"] \
		-command {::body::siteMgr_add}
#	$m add separator
	$m add command -compound left \
		-label [::msgcat::mc "Delete"] -command {::body::siteMgr_del}

#	$m add command -compound left \
#		-label [::msgcat::mc "Set as backup disk."] -command {::body::siteMgr_master}

	tk_popup $m $X $Y	
	
}

proc ::body::siteMgr_master {} {
	variable Priv
	set tree $Priv(siteMgr)
	
	set ibox $::dApp::Priv(ibox)
	
	set items [$tree selection get]
	
	if {$items == ""} {return}
	
	foreach item $items {
		set data [$tree item element cget $item cSite eTxt -data]
		foreach {gdisk user passwd} $data {	
			::gvfs::gdisk_master $gdisk
		}
	}
	::body::siteMgr_refresh 
	
}

proc ::body::siteMgr_refresh {} {
	variable Priv
	set tree $Priv(siteMgr)

	$tree item delete all
	foreach {user passwd master} [::gvfs::gdisk_list] {
		::body::siteMgr_item_add $user $user $passwd $master
	}

	set Priv(gdisk,count) [::gvfs::gdisk_count]

	return 
}

proc ::body::tree_init {path} {
	variable Priv
	
	set ibox $::dApp::Priv(ibox)	

	::ttk::frame $path
	
	set fmeTbar [::ttk::frame $path.fmeTbar]
	set btnUp [::ttk::button $fmeTbar.btnUp \
		-image [$ibox get directory-up] -style "Toolbutton" -command {
			if {$::body::Priv(currPath) != "/"} {::body::cmd_cd ".."}
	}]
	::tooltip::tooltip $btnUp [::msgcat::mc "Go up"]
	
	set cmbPath [::ttk::combobox $fmeTbar.cmbPath -values "" -textvariable ::body::Priv(currPath) -state readonly]
	set lblPath [::ttk::label $fmeTbar.lblPath -text [::msgcat::mc "Location:"] ]
	set btnPage [::body::btn_page $fmeTbar.btnPage]	

	set Priv(cmbPath) $cmbPath
	
	bind $cmbPath <<ComboboxSelected>> {
		foreach dir [file split $::body::Priv(currPath)] {
			::body::cmd_cd $dir
		}
		after idle [list $::body::Priv(cmbPath) selection clear]
	}

	pack $btnUp -side left -pady 1 -padx 2
	pack $lblPath -side left
	pack $cmbPath -side left -expand 1 -fill x
	pack $btnPage -side left

	set sw [ScrolledWindow $path.sw]
	set fmeMain [$sw getframe]
	set tree [treectrl $fmeMain.tree \
		-relief groove \
		-width 600 \
		-height 400 \
		-itemheight 30 \
		-showroot no \
		-showline no \
		-selectmod extended \
		-showrootbutton no \
		-showbuttons no \
		-scrollmargin 1 \
		-highlightthickness 0 \
		-showheader 1 \
		-itemwidthequal 1 ]
	
	$tree state define "DELETE"
	$tree state define "UPLOAD"
	$tree state define "DOWNLOAD"
	$tree state define "FRAGMENT"
	
	$tree column create -tag cName \
		-itembackground {"#EDF3FE" {}} \
		-text [::msgcat::mc "Name"]  \
		-justify left  -expand 1 -weight 1
	$tree column create -tag cSize \
		-itembackground {"#EDF3FE" {}} \
		-text [::msgcat::mc "Size"] -justify left -expand 0 -weight 0
	$tree column create -tag cCTime \
		-itembackground {"#EDF3FE" {}} \
		-text [::msgcat::mc "Create time"] -justify left -expand 0 -weight 0
	
	$tree configure -treecolumn cName
	
	$tree element create eIcon image -image [$ibox get default]
	$tree element create eCmd image \
		-image [list  \
				[$ibox get cmd_upload] {UPLOAD} \
				[$ibox get cmd_download] {DOWNLOAD} \
				[$ibox get cmd_delete] {DELETE} \
				[$ibox get cmd_fragment] {FRAGMENT} \
				[$ibox get cmd_none] {}]
	$tree element create eTxt text -fill [list "#ffffff" {selected focus} "#000000" {}]
	$tree element create eRect rect \
		-outlinewidth 0 \
		-fill [list "#738499" {selected focus}] 
	
	$tree style create styName
	$tree style elements styName {eRect eIcon eTxt eCmd}
	$tree style layout styName eIcon -iexpand "ns" -sticky "w" -ipadx {5 5}
	$tree style layout styName eTxt -iexpand "ns"  -sticky "w"
	$tree style layout styName eCmd -union {eIcon} -detach 1 \
		-sticky "w" \
		-expand ns
	
	$tree style layout styName eRect -union {eIcon eTxt} -iexpand nse
	
	$tree style create stySize
	$tree style elements stySize {eRect eTxt}
	$tree style layout stySize eTxt -iexpand "nse" -sticky "w" -ipadx {5 15}
	$tree style layout stySize eRect -union {eTxt} 	
	$tree style create styCTime
	$tree style elements styCTime {eRect eTxt}
	$tree style layout styCTime eTxt -iexpand "nse" -sticky "w" -ipadx {5 15}
	$tree style layout styCTime eRect -union {eTxt} 
	
	$tree notify install <Edit-begin>
	$tree notify install <Edit-accept>
	$tree notify install <Edit-end>

	
	TreeCtrl::SetEditable $tree {{cName styName eTxt}}
	TreeCtrl::SetSensitive $tree {{cName styName eRect eIcon eTxt} {cSize stySize eTxt} {cCTime styCTime eTxt}}
	TreeCtrl::SetDragImage $tree {{cName styName eIcon eTxt}}		

	bindtags $tree [list $tree TreeCtrlFileList TreeCtrl]
	

	$tree notify bind $tree <Edit-begin> {
		%T item element configure %I %C %E -draw no + %E -draw no
		%T see %I
		update
	}
	$tree notify bind $tree <Edit-accept> {
		set t1 [%T item element cget %I %C %E -text]
		set t2 %t
		if {$t1 ne $t2} {
			set node [%T item element cget %I %C %E -data]
			if {[::gvfs::cmd_rename $node $t2]} {
				%T item element configure %I %C %E -text $t2
				::body::cmd_cd "."
			}
		}
	}
	$tree notify bind $tree <Edit-end> {
		if {[%T item id %I] ne ""} {
			%T item element configure %I %C %E -draw yes + %E -draw yes
		}
		
	}
	
	$tree notify install <Header-invoke>
	$tree notify bind $tree <Header-invoke> {
		set tree %T
		set col %C
		if {[$tree column cget $col -arrow] == "down"} {
			set arrow up
		} else {
			set arrow down	
		}
		foreach c [$tree column list] {$tree column configure $c -arrow none}
		$tree column configure $col -arrow $arrow
		::body::tree_item_sort
	}
	$tree column configure cName -arrow up
	
	$tree notify install <Drag-begin>
	$tree notify bind $tree <Drag-begin> {set ::TreeCtrl::Priv(DirCnt,%T) [%T item count]}	
	$tree notify install <Drag-receive>
	$tree notify install <Drag-end>	
	$tree notify bind $tree <Drag-receive> {
		set node [%T item element cget %I cName eTxt -data]
		array set meta [::gvfs::cmd_meta $node]

		if {$meta(type) == "directory"} {
			::body::cmd_cut %l
			::body::cmd_paste $node
		}
	}	
	$tree notify bind $tree <Drag-end> {}
	
	bind $tree <Double-ButtonRelease-1> {
		set tree %W
		set id [$tree identify %x %y]
		if {[llength $id] == 6} {
			foreach {what itemId where columnId type name} $id {}
			if { $what eq "item" && $where eq "column"} {
				set node [$tree item element cget $itemId $columnId eTxt -data]
				array set meta [::gvfs::cmd_meta $node]
				if {$meta(type) == "directory"} { ::body::cmd_cd $meta(name)}
			}
		}
	}

	switch $::dApp::Priv(os) {
		"win32" -
		"linux" {
			set e "<ButtonRelease-3>"
		}
		"darwin" {
			set e "<ButtonRelease-2>"
		}
	}	
	
	bind $tree $e {
		set id [%W identify %x %y]
		if {[llength $id] == 6} {
			foreach {what itemId where columnId type name} $id {}
			if {$what eq "item" && $where eq "column"} {
				::body::tree_item_menu_popup $itemId %X %Y 
			}
		} else {
			::body::tree_item_menu_popup 0 %X %Y 
		}
	}
	
	set fmeSbar [::ttk::frame $path.fmeSbar]

	set ::gutil::Priv(msg) ""
	
	set msg [::ttk::label $fmeSbar.lblMsg \
			-textvariable ::gutil::Priv(msg) \
			-anchor w \
			-justify left]
	
	set fmeState [::ttk::frame $fmeSbar.fmeState]
	set lblQueue [::ttk::label $fmeState.lblQueue \
		-compound left \
		-text [::msgcat::mc "Queue"] \
		-image [$ibox get red-light] \
		-anchor w \
		-justify left]	
	set lblQueueCut [::ttk::label $fmeState.lblQueueCut \
		-compound left \
		-image [$ibox get state-queue] \
		-textvariable ::body::Priv(task,count) \
		-anchor w \
		-justify left]
	set lblGDiskCut [::ttk::label $fmeState.lblGDiskCut \
		-compound left \
		-image [$ibox get state-gdisk] \
		-textvariable ::body::Priv(gdisk,count) \
		-anchor w \
		-justify left]
	pack  $lblQueueCut $lblGDiskCut $lblQueue -expand 1 -fill both -padx 5 -side left

	::tooltip::tooltip $lblQueue [::msgcat::mc "Queue status"]
	::tooltip::tooltip $lblQueueCut [::msgcat::mc "Tasks"]
	::tooltip::tooltip $lblGDiskCut [::msgcat::mc "gDisks"]

	set ::body::Priv(gdisk,count) [::gvfs::gdisk_count]
	set Priv(queueState,wdg) $lblQueue
	if {$::gvfs::Priv(queueStart)} {$lblQueue configure -image [$ibox get green-light]}
	
	trace add variable ::gvfs::Priv(queueStart) write ::body::queue_trace_state
	proc ::body::queue_trace_state {args} {
		set ibox $::dApp::Priv(ibox)
		if {$::gvfs::Priv(queueStart) == 1} {
			$::body::Priv(queueState,wdg) configure -image [$ibox get green-light]
		} else {
			$::body::Priv(queueState,wdg) configure -image [$ibox get red-light]
		}
	}

	set fmeBtn [::ttk::frame $fmeSbar.fmeBtn]
	set btnUpload [::ttk::button $fmeBtn.btnUpload \
		-text [::msgcat::mc "Upload"] \
		-compound left \
		-image [$ibox get up] \
		-command {::body::cmd_upload}]
	set btnDownload [::ttk::button $fmeBtn.btnDownload \
		-text [::msgcat::mc "Download"] \
		-compound left -image [$ibox get down] \
		-command {
			::body::cmd_download
		}]
#	set btnStart [::ttk::checkbutton $fmeBtn.btnStart \
#		-variable ::gvfs::Priv(queueStart) \
#		-style "Toolbutton" \
#		-image [$ibox get flag_running] \
#		-command {
#			if {$::gvfs::Priv(queueStart)} {
#				::body::queue_start
#			} else {
#				::body::queue_stop
#			}
#	}]
	#pack $btnStart -side right -pady 2
	pack $btnDownload  -side right  -pady 2  -ipady 2
	pack $btnUpload -side right -pady 2 -ipady 2 -padx 3
	
	pack $fmeBtn -side right
	pack $fmeState -side right -padx 3
	pack $msg -side right -expand 1 -fill both
	
	set Priv(tree) $tree
	$sw setwidget $tree
	
	pack $fmeTbar -side top -fill x
	pack $sw -side top -fill both -expand 1
	pack $fmeSbar -side top -fill x
	
	return $path	
}

proc ::body::tree_item_add {parentNode icon name size ctime qcmd data} {
	variable Priv
	set tree $Priv(tree)

	set util "B"
	if {$size > 1024} {
		set util "KB"
		set size [expr $size/1024.0]
		if {$size > 1024} {
			set util "MB"
			set size [expr $size/1024]
		}
		foreach {main remain} [split $size "."] {break}
		set remain [string index $remain 0]
		if {$remain == 0 } {
			set size $main
		} else {
			set size $main.$remain
		}		
	}

	set item [$tree item create -parent $parentNode -open 0]
	$tree item style set $item 0 styName 1 stySize 2 styCTime
	$tree item element configure $item cName eTxt -text $name -data $data
	$tree item element configure $item cName eIcon -image $icon
	$tree item element configure $item cSize eTxt -text "$size $util"
	$tree item element configure $item cCTime eTxt -text $ctime
	$tree item state set $item $qcmd
	
	set Priv(nitem,$data) $item
	
	return $item
}

proc ::body::tree_item_menu_popup {itemId X Y} {
	variable Priv
	set tree $Priv(tree)
	set ibox $::dApp::Priv(ibox)
	
	set items [$tree selection get]

	if {[winfo exists $tree.popMenu]} {destroy $tree.popMenu}
	if {[winfo exists $tree.popMenu.popMenu]} {destroy $tree.popMenu.popMenu}
	set m [menu $tree.popMenu -tearoff 0]
	set mDownload [menu $m.popMenu -tearoff 0]
	set state "normal"
	if {$items == ""} {set state "disabled"}


	$m add cascade -compound left -state $state -label [::msgcat::mc "Download to ..."] \
		-image [$ibox get down] \
		-menu $mDownload
	$m add separator	
#	$m add command -compound left \
#		-label [::msgcat::mc "Upload"] \
#		-image [$ibox get up] \
#		-command {}	
	$m add command -compound left -label [::msgcat::mc "Create folder"] \
		-image [$ibox get directory-new] \
		-command {::body::cmd_mkdir}

	
	$m add command -compound left -state $state \
		-image [$ibox get cut] \
		-label [::msgcat::mc "Cut"] \
		-command [list ::body::cmd_cut $items]
	set stateBuf "normal"

	if {$Priv(cpBuf) == ""} {set stateBuf "disabled"}
	set node ""
	if {$itemId != 0} {
		set node [$tree item element cget $itemId cName eTxt -data]
	}
	$m add command -compound left -state $stateBuf \
		-image [$ibox get paste] \
		-label [::msgcat::mc "Paste"] \
		-command [list ::body::cmd_paste $node]
	$m add command -compound left -state $state \
		-label [::msgcat::mc "Delete"] \
		-image [$ibox get delete] \
		-command [list ::body::cmd_delete $items]
	$m add command -compound left -state $state \
		-label [::msgcat::mc "Delete Force"] \
		-image [$ibox get delete_force] \
		-command [list ::body::cmd_delete_force $items]		
	$m add separator

	$m add command -compound left \
		-image [$ibox get refresh] \
		-label [::msgcat::mc "Refresh"] \
		-command {::body::cmd_cd "."}		

	$mDownload add command -compound left \
		-label [::msgcat::mc "Choose Directory"] \
		-command [list ::body::cmd_download $items ]

	$mDownload add separator
	
	$mDownload add command -compound left -label [::msgcat::mc "Destop"] \
		-command [list ::body::cmd_download $items $::dApp::Priv(Desktop)]
	
	
	set rcDir $::gvfs::Priv(rcDir)
	set hisFile [file join $rcDir history.txt]
	if {![file exists $hisFile]} {close [open $hisFile w]}
	set fd [open $hisFile r]
	set data [split [read $fd] "\n"]
	close $fd
	
	if {$data != ""} {$mDownload add separator}
	foreach h $data {
		if {[string trim $h] == "" || ![file exists $h]} {continue}
		$mDownload add command -compound left -label $h \
			-command [list ::body::cmd_download $items $h]
	}
	
	tk_popup $m $X $Y
}

proc ::body::tree_item_state {node} {
	variable Priv
	set tree $Priv(tree)
		
	if {![info exists Priv(nitem,$node)]} {return}

	set item $Priv(nitem,$node)
	array set meta [::gvfs::cmd_meta $node]

	$tree item state set $item [list !DELETE !UPLOAD !DOWNLOAD]
	
	$tree item state set $item $meta(cmd)
	if {$meta(type) == "file" && $meta(cmd) == "" && $meta(complete) == 0} {
		$Priv(tree) item state set $item "FRAGMENT" 
	}


	if {$meta(type) == "file" && $meta(cmd) == "DELETE" && $meta(parts) == "0"} {
		$tree item delete $item

	}

}

proc ::body::tree_item_sort {} {
	variable Priv
	set tree $Priv(tree)
	set col ""
	foreach c [$tree column list] {
		set arrow [$tree column cget $c -arrow]
		if {$arrow == "down" || $arrow == "up"} {
			set col $c
			break
		}
	}
	if {$col == ""} {return}
	if {[$tree column cget $col -arrow] == "down"} {
		set order -decreasing
	} else {
		set order -increasing
	}
	switch [$tree column cget $col -tag] {
		cName {
			$tree item sort root $order -column $col -command [list ::body::compare_state  $tree $col $order]
		}
		cSize {
			$tree item sort root $order -column $col -dictionary
		}
		cCTime {
			$tree item sort root $order -column $col -dictionary
		}
	}	
}
