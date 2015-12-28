namespace eval ::body {
	variable Priv
	array set Priv [list \
		showHidden 1 ]
}

proc ::rframe::init {path} {
	variable Priv
#	puts $path
	set fMain [::ttk::frame $path]

#	set fAddr [::ttk::label $fMain.fAddr]
#	pack $fAddr -fill x -padx 2 -pady 2
#
#	set lblAddr [::ttk::label $fAddr.lbl -text [::msgcat::mc "Path:"] -justify left]
#	set cmbAddr [::ttk::combobox $fAddr.cmb -textvariable ::rframe::Priv(pwd)]
#	set btnAddr [::ttk::button $fAddr.btn -text "" -width 2]
#	pack $lblAddr -side left -fill y -padx 2 -pady 2
#	pack $cmbAddr -side left -fill both -expand 1 -padx 2 -pady 2
#	pack $btnAddr -side left -fill y -padx 2 -pady 2	

	set fScroll [ScrolledWindow $fMain.fScroll]
	set tree [treectrl $fScroll.tree \
		-width 600 \
		-height 400 \
		-itemwidth 160 \
		-itemheight 64 \
		-showroot no \
		-selectmod extended \
		-showrootbutton yes \
		-showbuttons yes \
		-showheader no \
		-showlines no \
		-scrollmargin 16 \
		-xscrolldelay "500 50" \
		-yscrolldelay "500 50" \
		-highlightthickness 0 \
		-wrap window \
		-orient horizontal \
		-itemwidthequal 1 \
		-relief groove \
		-bd 2 \
		-bg white]
	$fScroll setwidget $tree
	pack $fScroll -side top -fill both -expand 1 

#	$tree state define MOTION
#
	$tree column create -tag colItem
	$tree element create eIcon image 
	$tree element create eName text -justify left -wrap char -width 120
	$tree element create eSel rect -fill [list "#808080" {selected focus} "#ffffff" {}]

	$tree style create styIcon
	$tree style elements styIcon {eSel eIcon eName}
	$tree style layout styIcon eIcon -ipadx {5 5} -iexpand "ns"
	$tree style layout styIcon eName -ipadx {0 5} -pady {25 0}
	$tree style layout styIcon eSel -union {eName}
	
	$tree notify install <Edit-begin>
	$tree notify install <Edit-accept>
	$tree notify install <Edit-end>
	
	TreeCtrl::SetEditable $tree {{colItem styIcon eName}}
	TreeCtrl::SetSensitive $tree {{colItem styIcon eIcon eName eSel}}
	TreeCtrl::SetDragImage $tree {}
	bindtags $tree [list $tree TreeCtrlFileList TreeCtrl]
	set ::TreeCtrl::Priv(DirCnt,$tree) 1
	
	$tree notify bind $tree <Edit-begin> {%T item element configure %I %C eName -draw no}
	$tree notify bind $tree <Edit-accept> {::rframe::rename %I %t}
	$tree notify bind $tree <Edit-end> {
		if {[%T item id %I] ne ""} {
			%T item element configure %I %C eName -draw yes
		}
	}

#	
#	bind $tree <Motion> [list ::rframe::tree_item_motion %W %x %y %X %Y]
	bind $tree <Double-Button-1> [list ::rframe::tree_btn1_dclick %x %y]
	bind $tree <Button-1> [list ::rframe::tree_btn1_click %x %y]
	bind $tree <ButtonRelease-3> [list ::rframe::tree_btn3_click %x %y %X %Y]
#	
	bind $tree <F2> [format {
		set tree "%s"
		set item [$tree selection get] 
		if {[llength $item] == 1} {::TreeCtrl::FileListEdit $tree $item colItem eName}
	} $tree]

	set Priv(tree) $tree
	set Priv(historyList) ""
	set	Priv(historyIdx) -1	
	::rframe::chdir [::msgcat::mc "Volumes:"]
	return $path	
}

proc ::rframe::tree_btn1_click {posx posy} {
	variable Priv
	set tree $Priv(tree)
		
	set ninfo [$tree identify $posx $posy]
	if {[llength $ninfo] != 6} {return}
	foreach {what itemId where columnId type name} $ninfo {}
	if {$what eq "item" && $where eq "column"} {
		set parent [$tree item parent $itemId]
		set idata [$tree item element cget $itemId 0 eName -data]
#		$tree toggle $itemId	
		puts "btn1 click"
	}
}

proc ::rframe::tree_btn1_dclick {posx posy} {
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

proc ::rframe::tree_btn3_click {posx posy posX posY} {
	variable Priv
	set tree $Priv(tree)
		
	set ninfo [$tree identify $posx $posy]
	
	if {[llength $ninfo] < 6} {
		tk_popup [::rframe::tree_menu_get] $posX $posY
		return
	}
	foreach {what itemId where columnId type name} $ninfo {}
	if {$what eq "item"} {
		if {[lsearch [$tree selection get] $itemId] == -1} {
			$tree selection modify $itemId all
		} 
	}
	if {$what eq "item" && $where eq "column"} {
		set parent [$tree item parent $itemId]
		set idata [$tree item element cget $itemId 0 eName -data]
		tk_popup [::rframe::tree_item_menu_get $itemId] $posX $posY
	}
}

proc ::rframe::tree_item_add {parent fpath img} {
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

proc ::rframe::tree_item_del {item} {
	variable Priv
	set tree $Priv(tree)
		
	foreach c [$tree item children $item] {::rframe::tree_item_del $c }
	set fpath [$tree item element cget $item 0 txt -data]
	$tree item delete $item
}

proc ::rframe::tree_item_menu_get {item} {
	variable Priv
	set tree $Priv(tree)
	
	set data ""
	if {$item != ""} {
		set data [$tree item element cget $item 0 eName -data]
	}
	
	set itemList [$tree selection get]
	
	set m $tree.m
	catch {destroy $m}
	menu $m -tearoff 0

	# 載入動態menu
	
	# 建立預設的menu
	if {$Priv(pwd) != [::msgcat::mc "Volumes:"]} {
		set mNew $m.new
		if {![winfo exists $mNew]} {
			menu $mNew -tearoff 0
			$mNew add command -compound left -label [::msgcat::mc "Folder"] -command {::rframe::mkdir}
			$mNew add command -compound left -label [::msgcat::mc "Text File"] -command {}
		}
		$m add cascade -menu $mNew -label [::msgcat::mc "New"]
		$m add separator
		$m add command -label [::msgcat::mc "Cut"]
		$m add command -label [::msgcat::mc "Copy"] -command [list ::rframe::copy $itemList]
		set pasteFlag "normal"
		if {![info exists Priv(cp,source)] || $Priv(cp,source) == ""} {set pasteFlag disabled}
		$m add command -label [::msgcat::mc "Paste"] -state $pasteFlag -command [list ::rframe::paste $item]
		$m add command -label [::msgcat::mc "Delete"] -command [list ::rframe::delete $itemList]
		$m add separator
		$m add command -label [::msgcat::mc "Rename"] -command [list ::TreeCtrl::FileListEdit $tree $item colItem eName]
		$m add separator
		$m add command -label [::msgcat::mc "Properties"]
	} else {
#		$m add command -label [::msgcat::mc "Cut"]
		$m add command -label [::msgcat::mc "Copy"] -command [list ::rframe::copy $itemList]
		$m add command -label [::msgcat::mc "Paste"] -command [list ::rframe::paste $item]
#		$m add command -label [::msgcat::mc "Delete"] -command [list ::rframe::delete $itemList]
		$m add separator
		$m add command -label [::msgcat::mc "Rename"] -command [list ::TreeCtrl::FileListEdit $tree $item colItem eName]
		$m add separator
		$m add command -label [::msgcat::mc "Properties"]	
	}
	return $m
}

proc ::rframe::tree_item_motion {posx posy posX posY} {
	variable Priv
	set tree $Priv(tree)
	
	set ninfo [$tree identify $posx $posy]
	if {[llength $ninfo] != 6} {return}
	foreach {what itemId where columnId type name} $ninfo {}
	if {$what == "item" && $where == "column"} {
		if {$type == "elem" && $name == "txt"} {
			$tree configure -cursor hand2
		} else {
			$tree configure -cursor ""
		}
	}
}

proc ::rframe::tree_menu_get {} {
	variable Priv
	set tree $Priv(tree)
	
	set itemList [$tree selection get]

	
	set m $tree.m
	catch {destroy $m}
	menu $m -tearoff 0

	# 載入動態menu
	
	if {$Priv(pwd) != [::msgcat::mc "Volumes:"]} {
		# 建立預設的menu
		set mNew $m.new
		if {![winfo exists $mNew]} {
			menu $mNew -tearoff 0
			$mNew add command -compound left -label [::msgcat::mc "Folder"] -command {::rframe::mkdir}
			$mNew add command -compound left -label [::msgcat::mc "Text File"] -command {}
		}
		
		$m add cascade -menu $mNew -label [::msgcat::mc "New"]
		$m add separator
		set pasteFlag "normal"
		if {![info exists Priv(cp,source)] || $Priv(cp,source) == ""} {set pasteFlag disabled}
		$m add command -label [::msgcat::mc "Paste"] -state $pasteFlag -command [list ::rframe::paste ""]
		$m add separator	
		$m add command -label [::msgcat::mc "Refresh"] -command {::rframe::refresh}
		$m add separator
		$m add command -label [::msgcat::mc "Properties"]
	} else {
	
	}
	return $m
}

proc ::rframe::dialog_move_center {dlg} {
	tkwait visibility $dlg
	foreach {s x y} [split [wm geometry .] "+"] {break}
	foreach {w h} [split $s "x"] {break}
	
	set oX [expr $x+$w/2]
	set oY [expr $y+$h/2]

	foreach {s x y} [split [wm geometry $dlg] "+"] {break}
	foreach {w h} [split $s "x"] {break}	
	
	set oX [expr $oX-$w/2]
	set oY [expr $oY-$h/2]
	grab set $dlg
	wm geometry $dlg ${w}x${h}+${oX}+${oY}
	
}

proc ::rframe::dialog_error_show {errMsg} {
	variable Priv
	set tree $Priv(tree)
	::ttk::dialog $tree.eDlg \
		-icon "error" \
		-title [::msgcat::mc "Error"] \
		-message $errMsg \
		-labels [list ok [::msgcat::mc "Ok"]] \
		-buttons {ok} \
		-cancel {cancel}
		
	::rframe::dialog_move_center $tree.eDlg
	return
}

proc ::rframe::dialog_progress_hide {args} {
	variable Priv

	set tree $Priv(tree)

	set Priv(progress,flag) 0
	set Priv(progress,curr) 0
	set Priv(progress,sizeCurr) 0
	set Priv(progress,sizeMax) "0 MB"	
	if {[winfo exists $Priv(progress,dialog)]} {	after idle [list destroy $Priv(progress,dialog)]	}
	return
}

proc ::rframe::dialog_progress_incr {val} {
	variable Priv

	incr Priv(progress,curr) $val
	set Priv(progress,sizeCurr) [expr int(($Priv(progress,curr)/1048576.0)*10)/10.0]
	return
}

proc ::rframe::dialog_progress_max {max} {
	variable Priv

	$Priv(progress,pbar) configure -maximum $max
	set Priv(progress,sizeMax) [list "/" [expr int(($max/1048576.0)*10)/10.0] "MB"]

	return
}

proc ::rframe::dialog_progress_show {title} {
	variable Priv

	set tree $Priv(tree)

	set Priv(progress,flag) 1
	set Priv(progress,curr) 0	
	set Priv(progress,message) ""
	set Priv(progress,sizeCurr) 0
	set Priv(progress,sizeMax) "0 MB"

	set dlg $tree.pDlg

	::ttk::dialog $dlg \
		-title $title \
		-labels [list cancel [::msgcat::mc "Cancel"]] \
		-buttons {cancel} \
		-cancel {cancel} \
		-command {::rframe::dialog_progress_hide}

	set fme [ttk::dialog::clientframe $dlg]
	set icon [::ttk::label $fme.icon -image [$::dApp::Priv(ibox) get progress]]
	set msg [::ttk::label $fme.msg \
		-textvariable ::rframe::Priv(progress,message) \
		-justify left \
		-anchor w \
		-wraplength 335 \
		-width 65]
	set pbar [ttk::progressbar $fme.pbar -orient horizontal -variable ::rframe::Priv(progress,curr)]
	set sizeCurr [::ttk::label $fme.sizeCurr \
		-textvariable ::rframe::Priv(progress,sizeCurr) \
		-justify left \
		-anchor w]
	set sizeMax [::ttk::label $fme.sizeMax \
		-textvariable ::rframe::Priv(progress,sizeMax) \
		-justify left \
		-anchor w]

	grid $icon $msg -sticky "news" -padx 2 -pady 2
	grid $pbar -  -sticky "news" -padx 2 -pady 2
	grid $sizeCurr $sizeMax  -sticky "news" -pady 2
	grid rowconfigure $fme 1 -weight 1
	grid columnconfigure $fme 1 -weight 1
	
	set Priv(progress,pbar) $pbar
	set Priv(progress,dialog) $dlg
	
	::rframe::dialog_move_center $dlg
	
	return
}

proc ::rframe::chdir {dir {flag 0}} {
	variable Priv
	set tree $Priv(tree)
#	puts dir=$dir
	$tree item delete all
	
	if {$dir == [::msgcat::mc "Volumes:"]} {
		foreach v [file volumes] {
			set type [::libCrow::get_volume_type $v]
			set item [::rframe::tree_item_add 0 $v tree.$type]
		}
	} else {
		foreach d [glob -nocomplain -directory $dir -types {d} *] {
			::rframe::tree_item_add  0 $d "tree.directory"
		}

		if {$Priv(showHidden)} {
			update
			foreach d [glob -nocomplain -directory $dir -types {d hidden} *] {
				::rframe::tree_item_add  0 $d "tree.hidden_directory"
			}
		}
		update
		foreach f [glob -nocomplain -directory $dir -types {c b f p s} *] {
			::rframe::tree_item_add  0 $f "tree.file"
		}
		if {$Priv(showHidden)} {
			update
			foreach f [glob -nocomplain -directory $dir -types {c b f p s hidden} *] {
				::rframe::tree_item_add  0 $f "tree.hidden_file"
			}
		}
		
	}
	set Priv(pwd) $dir
	if {$flag == 0} {
		lappend Priv(historyList) $dir
		set Priv(historyIdx) [expr [llength $Priv(historyList)] - 1]
	}

	return
}

proc ::rframe::cd_next {} {
	variable Priv

	set tree $Priv(tree)

	if {$Priv(historyList) == ""} {return}
	if {$Priv(historyIdx) >= ([llength $Priv(historyList)] - 1)} {return}
	incr Priv(historyIdx) 1
	set dir [lindex $Priv(historyList) $Priv(historyIdx)]	
	
	::rframe::chdir $dir 1
	return
}

proc ::rframe::cd_prev {} {
	variable Priv

	set tree $Priv(tree)

	if {$Priv(historyList) == ""} {return}
	if {$Priv(historyIdx) == 0} {return}
	incr Priv(historyIdx) -1
	set dir [lindex $Priv(historyList) $Priv(historyIdx)]	
	
	::rframe::chdir $dir 1
	return
}

proc ::rframe::cd_up {} {
	variable Priv

	set tree $Priv(tree)

	if {[llength [file split $Priv(pwd)]] == 1} {
		set dir [::msgcat::mc "Volumes:"]
	} else {
		set dir [file dirname $Priv(pwd)]
	}
	
	if {$dir == $Priv(pwd)} {return}
	::rframe::chdir $dir
	return
}

proc ::rframe::copy {items} {
	variable Priv

	set tree $Priv(tree)
	set files ""
	foreach item $items {
		lappend files [$tree item element cget $item colItem eName -data]
	}
	set Priv(cp,source) $files
	set Priv(cp,flag) "COPY"
	return	
}

proc ::rframe::cut {items} {
	variable Priv

	set tree $Priv(tree)
	set files ""
	foreach item $items {
		lappend files [$tree item element cget $item colItem eName -data]
	}
	set Priv(cp,source) $file
	set Priv(cp,flag) "CUT"
	return	
}

proc ::rframe::delete {items} {
	variable Priv

	set tree $Priv(tree)
	
	::ttk::dialog 	$tree.delDlg \
		-title	[::msgcat::mc "Delete"] \
		-message [::msgcat::mc "Are you sure you want to delete '%s' items ." [llength $items]] \
		-icon "question" \
		-labels [list ok [::msgcat::mc "Ok"]  cancel [::msgcat::mc "Cancel"]] \
		-buttons {ok cancel} \
		-default {cancel} \
		-cancel {cancel} \
		-command [list ::rframe::delete_start $items]
		
	::rframe::dialog_move_center $tree.delDlg
	
	return	
}

proc ::rframe::delete_start {items btn} {
	variable Priv
	if {$btn == "cancel"} {return}
	
	set tree $Priv(tree)
	if {[winfo exists $tree.delDlg]} {destroy $tree.delDlg}

	set files ""
	foreach item $items {
		lappend files [$tree item element cget $item colItem eName -data]
	}
		
	::rframe::dialog_progress_show [::msgcat::mc "Delete"]
	
	set max 0
	foreach f $files {
#		catch {
			incr max [::rframe::file_count $f]
			set errMsg ""
#		} errMsg
		if {$errMsg != ""} {
			::rframe::dialog_error_show $errMsg
			::rframe::dialog_progress_hide
			return
		}
		
	}
	::rframe::dialog_progress_max $max

	set cut 0
	foreach f $files {
		set errMsg ""
		catch {
			::rframe::file_delete $f
			set errMsg ""
		} errMsg
		if {$errMsg != ""} {
			::rframe::dialog_error_show $errMsg
			break
		}
		$tree item delete [lindex $items $cut]
		incr cut
	}

	::rframe::dialog_progress_hide
	return
}

proc ::rframe::file_count {fpath} {
	variable Priv
	
	set total [file size $fpath]
	update
	if {$Priv(progress,flag) == 0 } {error ""}
	if {[file isfile $fpath]} {return $total}

	foreach f [glob -nocomplain -directory $fpath *] {
		if {$Priv(progress,flag) == 0 } {error ""}
		if {[file isdirectory $f]} {
			incr total [::rframe::file_count $f]
		} else {
			incr total [file size $f]
		}
		update
	}

	foreach f [glob -nocomplain -directory $fpath -types {hidden} *] {
		if {$Priv(progress,flag) == 0 } {error ""}
		if {[file isdirectory $f]} {
			incr total [::rframe::file_count $f]
		} else {
			incr total [file size $f]
		}
		update
	}
	
	return $total
}

proc ::rframe::file_copy {src dest} {
	variable Priv

	set tree $Priv(tree)

	if {$Priv(progress,flag) == 0 } {error ""}
	if {[file isfile $src]} {
		::rframe::file_copy_loop $src [file join $dest [file tail $src]]	
	} else {
		set dir [file join $dest [file tail $src]]
		file mkdir $dir
		::rframe::dialog_progress_incr	[file size $dir]
		foreach f [glob -nocomplain -directory $src *] {
			if {$Priv(progress,flag) == 0 } {error ""}
			if {[file isfile $f]} {
				::rframe::file_copy_loop $f [file join $dir [file tail $f]]
			} else {
				::rframe::file_copy $f $dir
			}
			update
		}

		foreach f [glob -nocomplain -directory $src -types {hidden} *] {
			if {$Priv(progress,flag) == 0 } {error ""}
			if {[file isfile $f]} {
				::rframe::file_copy_loop $f [file join $dir [file tail $f]]
			} else {
				::rframe::file_copy $f $dir
			}
			update
		}
		
	}
	return
}

proc ::rframe::file_copy_loop {src dest} {
	variable Priv

	set in [open $src r]
	set out [open $dest w]
	fconfigure $in -translation binary -encoding binary -buffersize 524288
	fconfigure $out -translation binary -encoding binary -buffersize 524288
	
#	set Priv(fcopy,flag) 1
#	fcopy $in $out -command [list ::rframe::file_copy_loop_cb $in $out]
#	vwait ::rframe::Priv(fcopy,flag)
	
	if {[file size $src] <= 5242880} {
		::rframe::dialog_progress_incr [fcopy $in $out]
		update
	} else {
		while {![eof $in]} {
			set buf [read $in 524288]
			puts -nonewline $out $buf
			if {$Priv(progress,flag) == 0 } {break}
			::rframe::dialog_progress_incr [string length $buf]
			update
		}
	}
	close $in
	close $out
	return
}

proc ::rframe::file_copy_loop_cb {in out bytes {msg ""}} {
	variable Priv
	::rframe::dialog_progress_incr $bytes
	if {$Priv(progress,flag) == 0 || [string length $msg] != 0 || [eof $in]} {
		close $in
		close $out
		set Priv(fcopy,flag) 0
		::rframe::dialog_error_show $msg
	}
	return
}

proc ::rframe::file_delete {f} {
	variable Priv
	set tree $Priv(tree)

	if {$Priv(progress,flag) == 0 } {error ""}
	if {[file isfile $f]} {
		set Priv(progress,message) $f
		::rframe::dialog_progress_incr [file size $f]
		file delete -force $f
	} else {
		foreach item [glob -nocomplain -directory $f *] {
			if {$Priv(progress,flag) == 0 } {error ""}
			if {[file isfile $item]} {
				set Priv(progress,message) $item
				::rframe::dialog_progress_incr [file size $item]
				file delete -force $item
			} else {
				::rframe::file_delete $item
			}
			update
		}

		foreach item [glob -nocomplain -directory -types {hidden} $f *] {
			if {$Priv(progress,flag) == 0 } {error ""}
			if {[file isfile $item]} {
				set Priv(progress,message) $item
				::rframe::dialog_progress_incr [file size $item]
				file delete -force $item
			} else {
				::rframe::file_delete $item
			}
			update
		}			
		
		set Priv(progress,message) $f
		::rframe::dialog_progress_incr [file size $f]
		file delete -force $f
	}

	return
}

proc ::rframe::mkdir {} {
	variable Priv

	set tree $Priv(tree)
	
	set dir [file join $Priv(pwd) "New Folder"]
	set i 1
	while {[file exists $dir]} {
		set dir [file join $Priv(pwd) "New Folder - $i"]
		incr i
	}
	
	if {[catch {file mkdir $dir}]} {
		::ttk::dialog 	$tree.dlg \
			-title	[::msgcat::mc "Error"] \
			-message [::msgcat::mc "Cannot create directory '%s' ." $dir] \
			-detail [::msgcat::mc "Permission denied !!"] \
			-icon error \
			-labels [list ok [::msgcat::mc "Ok"]] \
			-buttons {ok} \
			-default {ok} \
			-cancel {ok}
		::rframe::dialog_move_center $tree.dlg
		return
	}
	set item [::rframe::tree_item_add 0 $dir "directory"]
	update
	::TreeCtrl::FileListEdit $tree $item colItem eName
	return
}


proc ::rframe::rename {item nName} {
	variable Priv

	set tree $Priv(tree)

	set oName [$tree item element cget $item colItem eName -text]
	if {$oName == $nName} {return}
	set dir [file dirname [$tree item element cget $item colItem eName -data]]
	if {[file exists [file join $dir $nName]]} {
		::ttk::dialog 	$tree.dlg \
			-title	[::msgcat::mc "Error"] \
			-message [::msgcat::mc "Cannot create directory '%s' ." $nName] \
			-detail [::msgcat::mc "File exists !!"] \
			-icon error \
			-labels [list ok [::msgcat::mc "Ok"]] \
			-buttons {ok} \
			-default {ok} \
			-cancel {ok}
		::rframe::dialog_move_center $tree.dlg
		return		
	}

	if {[catch {file rename [file join $dir $oName] [file join $dir $nName]}]} {
		::ttk::dialog 	$tree.dlg \
			-title	[::msgcat::mc "Error"] \
			-message [::msgcat::mc "Cannot rename '%s' ." $nName] \
			-detail [::msgcat::mc "Permission denied !!"] \
			-icon error \
			-labels [list ok [::msgcat::mc "Ok"]] \
			-buttons {ok} \
			-default {ok} \
			-cancel {ok}
		::rframe::dialog_move_center $tree.dlg
		return
	} else {
		$tree item element configure $item colItem eName -text $nName
	}

}

proc ::rframe::paste {item} {
	variable Priv
	set tree $Priv(tree)
#	puts "paste"
#	puts "flag $Priv(cp,flag)"
#	puts "buf $Priv(cp,source)"
	if {![info exists Priv(cp,source)] || $Priv(cp,source) == ""} {return}
	set data ""
	if {$item != ""} {
		set data [$tree item element cget $item colItem eName -data]
		if {[file isfile $data]} {set data [file dirname $data]}
	}
	::rframe::paste_start $data
	set Priv(cp,flag) ""
	set Priv(cp,source) ""
}

proc ::rframe::paste_start {dest} {
	variable Priv
	
	set tree $Priv(tree)

	::rframe::dialog_progress_show [::msgcat::mc "Copy"]

	set src $Priv(cp,source)
	if {$dest == ""} {set dest $Priv(pwd)}
	if {[string first [lindex $src 0] $dest] >=0} {
		::rframe::dialog_progress_hide
		::rframe::dialog_error_show [::msgcat::mc "Incorrectly target '%s' " $dest]
		return
	}

	set max 0
	foreach f $src {
		if {[file dirname $f] == $dest} {continue}		
		set Priv(progress,message) [::msgcat::mc "Copy..."]
		catch {
			incr max [::rframe::file_count $f]
			set hello ""
		} errMsg
		if {$errMsg != ""} {
			::rframe::dialog_error_show $errMsg
			::rframe::dialog_progress_hide
			return
		}
	}

	::rframe::dialog_progress_max $max
	
	set Priv(paste,replaceFlag) ""
	foreach f $src {
		set Priv(progress,message) [::msgcat::mc "Copy '%s' to '$dest'" [file tail $f]]
		if {[file dirname $f] == $dest} {continue}
		set target [file join $dest [file tail $f]]
		if {$Priv(paste,replaceFlag) != "REPLACE_ALL" && [file exists $target]} {
			::ttk::dialog $tree.qDlg \
				-icon "question" \
				-title [::msgcat::mc "Question"] \
				-message [::msgcat::mc "'%s' already exists." [file tail $target]] \
				-labels [list yes [::msgcat::mc "Replace all"] no [::msgcat::mc "Replace"] cancel [::msgcat::mc "Cancel"]] \
				-buttons {yes no cancel} \
				-default {cancel} \
				-cancel {cancel} \
				-command {::rframe::paste_exists_cb}
			::rframe::dialog_move_center $tree.qDlg
			tkwait variable ::rframe::Priv(paste,replaceFlag)
		}
		if {$Priv(paste,replaceFlag) == "CANCEL"} {break}
		catch {
			::rframe::file_copy $f $dest
			set hello ""
		} errMsg
		if {$errMsg != ""} {
			::rframe::dialog_error_show $errMsg
			break
		}
		if {$dest == $Priv(pwd) && $Priv(paste,replaceFlag) != "REPLACE" && $Priv(paste,replaceFlag) != "REPLACE_ALL" } {
			::rframe::tree_item_add 0 [file join $dest [file tail $f]] [file type $f]
		}
	}

	::rframe::dialog_progress_hide
	return

}

proc ::rframe::paste_exists_cb {btn} {
	variable Priv

	set tree $Priv(tree)

	switch -exact -- $btn {
		"cancel" {set Priv(paste,replaceFlag) "CANCEL"}
		"yes" {set Priv(paste,replaceFlag) "REPLACE_ALL"}
		"no" {set Priv(paste,replaceFlag) "REPLACE"}
	}
	return
}

proc ::rframe::refresh {} {
	variable Priv
	::rframe::chdir $Priv(pwd)
	return	
}
