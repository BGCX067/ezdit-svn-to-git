package require treectrl
package require autoscroll
package require ttdialog


namespace eval ::abrowser {
	variable Priv
	
	# mode ALBUM PICTURE VIEW
	array set Priv [list \
		mode ALBUM \
		albumId "" \
		albumNum 0 \
		selCut 0 \
		runStart 0 \
		cacheDir [file join $::dApp::Priv(rcPath) "cache"] \
		sn 0 \
	]
	if {![file exists $Priv(cacheDir)]} {file mkdir $Priv(cacheDir)}
	if {[file exists [file join $Priv(cacheDir) "人氣相簿"] ]} {file delete -force [file join $Priv(cacheDir) "人氣相簿"] }
	if {[file exists [file join $Priv(cacheDir) "隨機推薦"] ]} {file delete -force [file join $Priv(cacheDir) "隨機推薦"] }
	if {[file exists [file join $Priv(cacheDir) "精選相簿"] ]} {file delete -force [file join $Priv(cacheDir) "精選相簿"] }
}

proc ::abrowser::bookmark_add {} {
	variable Priv
	
	if {$Priv(albumId) == ""} {
		tk_messageBox -title [::msgcat::mc "錯誤"] \
			-message  [::msgcat::mc "請先列出相簿清單"]\
			-type ok \
			-icon error
		return
	}
	if {$Priv(albumId) == "隨機推薦" || $Priv(albumId) == "人氣相簿" || $Priv(albumId) == "精選相簿"} {
		tk_messageBox -title [::msgcat::mc "錯誤"] \
			-message  [::msgcat::mc "%s不可以加入我的最愛" $Priv(albumId)]\
			-type ok \
			-icon error
		return
	}
	
	if {[::bookmark::category_list] == ""} {
		tk_messageBox -title [::msgcat::mc "錯誤"] \
			-message  [::msgcat::mc "請先建立一個分類"]\
			-type ok \
			-icon error
		return		
	}
	
	set tree $Priv(tree)
	set id $Priv(albumId)
	
	set win ".dApp_dialog"
	catch {destroy $win}
	set win [::ttdialog::dialog $win \
		-title [::msgcat::mc "新增我的最愛"] \
		-buttons [list  [::msgcat::mc "增加"] "add" [::msgcat::mc "取消"] "cancel" ] \
	]
	set fme [::ttdialog::clientframe $win]
	
	array set caMap [list]
	foreach {caId caTitle} [::bookmark::category_list] {
		set caMap($caTitle) $caId
	}
	
	set Priv(txtName,var) $id
	set Priv(cmbCat,var) [lindex [lsort [array names caMap] ]  0]
	set lblMsg [::ttk::label $fme.lblMsg -text [::msgcat::mc "等待加入的帳號 : %s" $id] -anchor w -justify left]
	set lblCat [::ttk::label $fme.lblCat -text [::msgcat::mc "分類:"] -anchor w -justify left]
	set cmbCat [::ttk::combobox $fme.cmbCat \
		-state "readonly" \
		-values [lsort [array names caMap] ] \
		-textvariable ::abrowser::Priv(cmbCat,var)]
	set lblName [::ttk::label $fme.lblName -text [::msgcat::mc "標題:"] -anchor w -justify left]
	set txtName [::ttk::entry $fme.txtName -textvariable ::abrowser::Priv(txtName,var)]
	
	grid $lblMsg - -sticky "news" -pady 3 -padx 2
	grid $lblCat $cmbCat -sticky "news" -pady 3 -padx 2
	grid $lblName $txtName -sticky "news" -pady 3 -padx 2
	
	set ret [::ttdialog::dialog_wait $win]
	if {$ret == "cancel" || $Priv(txtName,var) == ""} {return}
	::bookmark::book_add $caMap($Priv(cmbCat,var)) $id $Priv(txtName,var)
}

proc ::abrowser::book_download_start {} {
	variable Priv

	if {$Priv(albumId) == ""} {
		tk_messageBox -title [::msgcat::mc "錯誤"] \
			-message  [::msgcat::mc "請先列出相簿清單"]\
			-type ok \
			-icon error
		return
	}

	set ibox $::dApp::Priv(ibox)

	set imgStart [$ibox get download_start]
	set imgCurr [$Priv(btnGo) cget -image]
	
	if {$imgCurr != $imgStart} {
		::abrowser::book_download_stop
		$Priv(btnGo) configure -image [$ibox get download_start]
		return
	}
	
	if {$Priv(runStart)} {
		tk_messageBox -title [::msgcat::mc "錯誤"] \
			-message  [::msgcat::mc "其它的下載工作正在執行，請先停止它們"] \
			-type ok \
			-icon error
		return
	}
	
	set Priv(runStart) 1
	$Priv(btnGo) configure -image [$ibox get download_stop]
	
	set tree $Priv(tree)
	set dlList [list]
	foreach item [$tree item children 0] {
		if {[$tree item state get $item "CHECK"] == 0} {continue}
		lappend dlList $item [::abrowser::tree_item_get $item]
	}
	
	if {$dlList == ""} {
		$Priv(btnGo) configure -image [$ibox get download_start]
		set Priv(runStart) 0
		tk_messageBox -title [::msgcat::mc "錯誤"] \
			-message  [::msgcat::mc "請先選擇您要下載的相簿"]\
			-type ok \
			-icon error
		return
	}
	
	set wdir $::dApp::Priv(workspace)
	
	foreach {item bookInfo} $dlList {
		if {$Priv(runStart) == 0} {break}
		$tree item state set $item "DOWNLOAD"
		array unset opts
		array set opts $bookInfo
		
		::output::put_msg [::msgcat::mc "正在下載相簿 %s:%s....." $opts(id) $opts(title)]
		::output::put_msg [::msgcat::mc "\t正在分析總頁數....."] ""
		set maxPage [::${::dApp::Priv(cmdNs)}::pic_page_count $opts(id) $opts(book) $opts(pw)]
		::output::put_msg [::msgcat::mc "找到%s頁" $maxPage]
		if { $maxPage== 0} {
			::output::put_msg [::msgcat::mc "失敗"]
			$tree item state set $item "~DOWNLOAD"
			continue
		}
		
		if {![file exists [file join $wdir $opts(id)]]} {file mkdir [file join $wdir $opts(id)]}
		set saveDir [file join $wdir $opts(id) $opts(book)]
		if {$::dApp::Priv(naming) == "ID+TITLE" && $opts(title) != ""} {
				set title $opts(title)
				regsub -all {\.}  $title "_" title
				regsub -all {\\}  $title "_" title
				regsub -all {\/}  $title "_" title
				regsub -all {\:}  $title "_" title
				regsub -all {\*}  $title "_" title
				regsub -all {\?}  $title "_" title
				regsub -all {\"}  $title "_" title
				regsub -all {\>}  $title "_" title
				regsub -all {\<}  $title "_" title
				regsub -all {\|}  $title "_" title				
				regsub -all {\~}  $title "_" title				
				if {![file exists "$saveDir-$title"]} { catch {file mkdir "$saveDir-$title"}}
				if {[file exists "$saveDir-$title"]} {	set saveDir "$saveDir-$title" }
		}
		if {![file exists $saveDir]} {file mkdir $saveDir}
		
		set picList [list]
		set dlCut 0
		for {set i 1} {$i <= $maxPage} {incr i} {
			::output::put_msg [::msgcat::mc "\t正在分析第 %s 頁....." $i] ""
			set picList [list]
			foreach picInfo [::${::dApp::Priv(cmdNs)}::pic_page_list $opts(id) $opts(book) $i $opts(pw)] {
				if {$Priv(runStart) == 0} {break}
				lappend picList $picInfo
			}
			::output::put_msg [::msgcat::mc "完成"]
			
			if {$picList == ""} {continue}
			set picTotal [llength $picList]
			set len [expr [string length $picTotal] -1]
			set cut 0
			foreach picInfo $picList {
				incr dlCut
				incr cut
				if {$Priv(runStart) == 0} {break}
				
				if {$dlCut > 1 && $::dApp::Priv(delay) > 0} {
					set Priv(delay) "WAIT"
					after $::dApp::Priv(delay) [list set ::abrowser::Priv(delay) "CONTINUE"]
					tkwait variable ::abrowser::Priv(delay)
				}
				
				set j [string range 0000$cut end-$len end]
				::output::put_msg [::msgcat::mc "\t正在下載 \[p%s/%s %s/%s\] : %s >> " $i $maxPage $j  $picTotal $opts(title)] ""
				::output::put_msg [::abrowser::${::dApp::Priv(cmdNs)}_pic_download $saveDir $bookInfo $picInfo]
			}
			if {$Priv(runStart) == 0} {break}	
		}

		#if {$picList == ""} {
		$tree item state set $item "~DOWNLOAD"
		continue
		#}

	}
	
	::output::put_msg [::msgcat::mc "結束"]
	$Priv(btnGo) configure -image [$ibox get download_start]
	::abrowser::download_cb "" 0 0
	set Priv(runStart) 0
	
}

proc ::abrowser::book_download_stop {} {
	variable Priv	
	set Priv(runStart) 0
}

proc ::abrowser::book_list_start {id} {
	variable Priv
	
	
	if {$id == "人氣相簿" || $id== "精選相簿" || $id == "隨機推薦"} {
		if {$::dApp::Priv(cmdNs) == "xuite"} {
			tk_messageBox -title [::msgcat::mc "資訊"] \
				-message  [::msgcat::mc "目前沒有提供這項功能。"]\
				-type ok \
				-icon info
				return
		}
	}	
	
	set cacheSize $::dApp::Priv(thumbCacheSize)
	set clist [glob -nocomplain -directory $Priv(cacheDir) -types {d} *]
	set dlist [list]
	if {[llength $clist] > $cacheSize} {
		foreach {dir} $clist {
			set mtime [file mtime $dir]
			append mtime "\x2" $dir
			lappend dlist  $mtime
		}
		set dlist [lrange [lsort -decreasing $dlist] $cacheSize end]
		foreach {dir} $dlist {
			lassign [split $dir "\x2"] t dir
			file delete -force $dir

		}
	}
	
	if {$Priv(runStart)} {
		tk_messageBox -title [::msgcat::mc "錯誤"] \
			-message  [::msgcat::mc "其它的下載工作正在執行，請先停止它們"] \
			-type ok \
			-icon error
		return 0
	}
	
	set Priv(prevBook) $id
	set Priv(runStart) 1
	set Priv(mode) ALBUM
	
	set cacheDir [file join $Priv(cacheDir) $id]
	if {![file exists $cacheDir]} {file mkdir $cacheDir}
	
	::output::put_msg [::msgcat::mc "正在找出 \[ %s \] 的相簿清單..." $id]

	if {$id == "人氣相簿" || $id== "精選相簿" || $id == "隨機推薦"} {
		set pageCut  $::dApp::Priv(hotPageMax)
	} else {
		set pageCut [::${::dApp::Priv(cmdNs)}::book_page_count $id]
	}
	if {$pageCut == 0} {
		::output::put_msg [::msgcat::mc "失敗"]
		set Priv(runStart) 0
		return 0
	}
	
	set Priv(albumId) $id
	 ::abrowser::tree_item_clear
	 
	$Priv(btnPreview) configure -state normal
	
	set cut 0
	set ret 1
	::abrowser::download_cb "" $pageCut 0
	for {set i 1} {$i <= $pageCut} {incr i} {
		if {$Priv(runStart) == 0} {set ret 0 ; break}
		foreach pageInfo [::${::dApp::Priv(cmdNs)}::book_page_list $id $i] {
			if {$Priv(runStart) == 0} {set ret 0 ; break}
			
			lassign $pageInfo id2 book title descript thumb new key
			::output::put_msg [::msgcat::mc "\t分析相簿 \[ %s \] 的資訊....." $title] ""
			set ftail [file tail [lindex [split $thumb "?"] 0]]
			set fpath [file join $cacheDir ${id2}_${book}_$ftail]
			if {![file exists $fpath]} {
				if {[::${::dApp::Priv(cmdNs)}::pic_get $thumb $fpath] == "" } {
					file copy [file join $::dApp::Priv(appPath) images t1.jpg] $fpath
				}
			}
			file mtime $cacheDir [clock seconds]
			
			if {[catch {set img [image create photo -file $fpath]}]} {
				::output::put_msg [::msgcat::mc "失敗!!"]
				continue
			}
			::abrowser::tree_item_add $id2 $book $title $descript $img $new $key ""
			incr cut
			::output::put_msg [::msgcat::mc "完成"]
			
			if {($cut % 10) == 0 && $::dApp::Priv(delay) > 0} {
				set Priv(delay) "WAIT"
				after $::dApp::Priv(delay) [list set ::abrowser::Priv(delay) "CONTINUE"]
				::output::put_msg [::msgcat::mc "\t等待抓取間隔....%s (秒 )" [expr $::dApp::Priv(delay) / 1000 ]]
				tkwait variable ::abrowser::Priv(delay)
			}	
						
			update
		}
		::abrowser::download_cb "" $pageCut $i
	}
	::abrowser::download_cb "" $pageCut 0
	::output::put_msg [::msgcat::mc "找到 %s 本相簿...結束" $cut]
	set Priv(runStart) 0
	return $ret
}

proc ::abrowser::book_list_stop {} {
	variable Priv
	set Priv(runStart) 0
}

proc ::abrowser::download_cb {tok total current} {
	variable Priv
	
	set sbar $::dApp::Priv(win,sbar)
	$sbar pbar_set $total $current
	
	if {$Priv(runStart) == 0 && $tok != ""} {
		catch {::http::cleanup $tok}
		$sbar pbar_set 0 0
	}
	#puts " "
}

proc ::abrowser::friend_list_build {} {
	variable Priv
	
	set ibox $::dApp::Priv(ibox)
	
	if {$Priv(albumId) == ""} {
		tk_messageBox -title [::msgcat::mc "錯誤"] \
			-message  [::msgcat::mc "請先列出相簿清單"]\
			-type ok \
			-icon error
		return
	}	
	
	set data ""
	::output::put_msg [::msgcat::mc "正在分析好友資訊，請稍後...."] ""
	set data [::${::dApp::Priv(cmdNs)}::friend_list $Priv(albumId)]
	if {$data == ""} {
		::output::put_msg [::msgcat::mc "失敗!!"]	
		return
	}
	
	::output::put_msg [::msgcat::mc "完成!!"]
	
	catch {destroy $Priv(menuFriends)}
	set m [menu .menuFriend -tearoff 0	]
	set Priv(menuFriends) $m
		
	foreach {item} $data {
		lassign $item group id title
		$m add command \
			-compound left \
			-image [$ibox get empty] \
			-label $title \
			-command [list ::tbar::book_list $id]
	}

	
	set geo [winfo geometry $Priv(btnFriend)]
	lassign [split $geo "x"] w geo
	lassign [split $geo "+"] h x y
	set x [winfo rootx $Priv(btnFriend)]
	incr y [winfo rooty $Priv(btnFriend)] 		
	
	tk_popup $m $x [expr $y + $h]	
	
}

proc ::abrowser::home_set {} {
	variable Priv
	if {$Priv(albumId) == ""} {
		tk_messageBox -title [::msgcat::mc "錯誤"] \
			-message  [::msgcat::mc "請先列出相簿清單"]\
			-type ok \
			-icon error
		return
	}
	set fpath [file join $::dApp::Priv(rcPath) "home.txt"]
	set fd [open $fpath w]
	puts -nonewline $fd "$dApp::Priv(cmdNs),$Priv(albumId)"
	close $fd
}

proc ::abrowser::home_get {} {
	variable Priv

	set fpath [file join $::dApp::Priv(rcPath) "home.txt"]
	if {![file exists $fpath]} {return ""}
	set fd [open $fpath r]
	set ret [string trim [read -nonewline $fd]]
	close $fd
	
	if {[string first "," $ret] == -1} {
		set ret [list $::dApp::Priv(cmdNs) $ret]
	} else {
		set ret [split $ret ","]
	}
	
	return $ret
}

proc ::abrowser::init {wpath} {
	variable Priv
	
	set ibox $::dApp::Priv(ibox)
	
	::ttk::frame $wpath
	
	set fmeTitle [::ttk::frame $wpath.fmeTitle]
	
	set btnHome [ttk::button $fmeTitle.btnHome \
		-style "Toolbutton" \
		-image [$ibox get set_home] \
		-command {::abrowser::home_set}]
	set btnBk [ttk::button $fmeTitle.btnBk \
		-style "Toolbutton" \
		-image [$ibox get bookmark_add] \
		-command {::abrowser::bookmark_add}]
	
	set btnPrevPage [ttk::button $fmeTitle.btnPrevPage \
		-style "Toolbutton" \
		-image [$ibox get prev_page] \
		-command {
			pack forget $::abrowser::Priv(btnPrevPage)
			::abrowser::book_list_start $::abrowser::Priv(prevBook)
		} ]		
	
	set btnPreview [ttk::button $fmeTitle.btnPreview \
		-state disabled \
		-style "Toolbutton" \
		-image [$ibox get pic_list_start] \
		-command {
			if {[::abrowser::pic_list_start]} {
				pack $::abrowser::Priv(btnPrevPage) -side right -padx 3
			}
		} ]		
		
	set btnGo [ttk::button $fmeTitle.btnGo \
		-style "Toolbutton" \
		-image [$ibox get download_start] \
		-command {
			if {$::abrowser::Priv(mode) == "ALBUM"} {		
				::abrowser::book_download_start
			} elseif {$::abrowser::Priv(mode) == "PICTURE"} {
				::abrowser::pic_download_start
			}
		} ]
	set btnFriends [ttk::button $fmeTitle.btnFriends \
		-style "Toolbutton" \
		-image [$ibox get friends] \
		-command {::abrowser::friend_list_build} ]
	
	set lblNum [::ttk::label $fmeTitle.lblNum -text [::msgcat::mc "找到的項目 : "] -justify left -anchor w]
	set txtNum [::ttk::label $fmeTitle.txtNum -textvariable ::abrowser::Priv(albumNum) -justify left -anchor w]	
	
	set lblSel [::ttk::label $fmeTitle.lblSel -text [::msgcat::mc "已選取的項目 : "] -justify left -anchor w]
	set txtSel [::ttk::label $fmeTitle.txtSel -textvariable ::abrowser::Priv(selCut) -justify left -anchor w]		
	
	pack  $btnHome $btnBk $btnFriends  -side left -padx 3
	pack $lblNum $txtNum $lblSel $txtSel -side left -padx 3
	
	pack $btnGo -side right -padx 3
	pack $btnPreview -side right -padx 3

	set Priv(btnFriend) $btnFriends
	set Priv(btnGo) $btnGo
	set Priv(btnPreview) $btnPreview
	set Priv(btnPrevPage) $btnPrevPage
	
	::tooltip::tooltip $btnHome [::msgcat::mc "設為首頁相簿"]
	::tooltip::tooltip $btnGo [::msgcat::mc "開始下載"]
	::tooltip::tooltip $btnBk [::msgcat::mc "加入我的最愛"]
	::tooltip::tooltip $btnFriends [::msgcat::mc "好友的相簿清單"]
	::tooltip::tooltip $btnPreview [::msgcat::mc "預覽選取的相簿"]
	::tooltip::tooltip $btnPrevPage [::msgcat::mc "上一頁"]
	
	set tree [::abrowser::tree_init $wpath.tree]
	pack $fmeTitle -fill x -pady 2
	pack $tree -expand 1 -fill both -padx 2 -pady 2
	
	return $wpath
}

proc ::abrowser::pic_download_start {} {
	variable Priv
	
	set tree $Priv(tree)
	
	set ibox $::dApp::Priv(ibox)

	set imgStart [$ibox get download_start]
	set imgCurr [$Priv(btnGo) cget -image]
	
	if {$imgCurr != $imgStart} {
		::abrowser::pic_download_stop
		$Priv(btnGo) configure -image [$ibox get download_start]
		return
	}
	
	if {$Priv(runStart)} {
		tk_messageBox -title [::msgcat::mc "錯誤"] \
			-message  [::msgcat::mc "其它的下載工作正在執行，請先停止它們"] \
			-type ok \
			-icon error
		return
	}	
	
	$Priv(btnGo) configure -image [$ibox get download_stop]
	set Priv(runStart) 1
	
	set wdir $::dApp::Priv(workspace)

	set dlList [list]
	foreach item [$tree item children 0] {
		if {[$tree item state get $item "CHECK"] == 0} {continue}
		lappend dlList $item [::abrowser::tree_item_get $item]
	}
	
	if {$dlList == ""} {
		$Priv(btnGo) configure -image [$ibox get download_start]
		set Priv(runStart) 0
		tk_messageBox -title [::msgcat::mc "錯誤"] \
			-message  [::msgcat::mc "請先選擇您要下載的相片"]\
			-type ok \
			-icon error		
		return
	}

	set prevbook ""
	set picTotal [expr [llength $dlList] /2 ]
	set dlCut 0
	set sn 0
	foreach {item bookInfo} $dlList {
		if {$Priv(runStart) == 0} {break}
		$tree item state set $item "DOWNLOAD"
		array unset opts
		array set opts $bookInfo

		if {![file exists [file join $wdir $opts(id)]]} {file mkdir [file join $wdir $opts(id)]}
		set saveDir [file join $wdir $opts(id) $opts(book)]
		if {![file exists "$saveDir-$opts(title)"]} { 
			if {[catch {file mkdir "$saveDir-$opts(title)"}]} {
				catch {file mkdir $saveDir}
			} else {
				set saveDir "$saveDir-$opts(title)" 
			}
		} else {
			set saveDir "$saveDir-$opts(title)" 
		}
								

		if {$prevbook != $opts(book)} {
			set prevbook $opts(book)
			set dlCut 0
		}
		incr dlCut
		incr sn
		if {$sn > 1 && $::dApp::Priv(delay) > 0} {
			set Priv(delay) "WAIT"
			after $::dApp::Priv(delay) [list set ::abrowser::Priv(delay) "CONTINUE"]
			tkwait variable ::abrowser::Priv(delay)
		}
		set i [string range 0000$sn end-3 end]
		::output::put_msg [::msgcat::mc "\t正在下載 %s 項目中的第 %s 個項目..... " $picTotal $i] ""
		
		set picInfo $opts(data)
		::output::put_msg [::abrowser::${::dApp::Priv(cmdNs)}_pic_download $saveDir $bookInfo $picInfo]
		$tree item state set $item "~DOWNLOAD"
	}
	 
	::output::put_msg [::msgcat::mc "結束"]
	$Priv(btnGo) configure -image [$ibox get download_start]
	::abrowser::download_cb "" 0 0
	set Priv(runStart) 0	 
	 
}

proc ::abrowser::pic_download_stop {} {
	variable Priv
	set Priv(runStart) 0
}

proc ::abrowser::pic_list_start {} {
	variable Priv
	set tree $Priv(tree)
	
	if {$Priv(albumId) == ""} {
		tk_messageBox -title [::msgcat::mc "錯誤"] \
			-message  [::msgcat::mc "請先列出相簿清單"]\
			-type ok \
			-icon error
		return 0
	}
	
	set ibox $::dApp::Priv(ibox)

	set imgStart [$ibox get pic_list_start]
	set imgCurr [$Priv(btnPreview) cget -image]
	
	if {$imgCurr != $imgStart} {
		::abrowser::pic_list_stop
		$Priv(btnPreview) configure -image [$ibox get pic_list_start] -state disabled
		return 0
	}	
	
	if {$Priv(runStart)} {
		tk_messageBox -title [::msgcat::mc "錯誤"] \
			-message  [::msgcat::mc "其它的下載工作正在執行，請先停止它們"] \
			-type ok \
			-icon error
		return 0
	}
		 
	set dlList [list]
	foreach item [$tree item children 0] {
		if {[$tree item state get $item "CHECK"] == 0} {continue}
		lappend dlList [::abrowser::tree_item_get $item]
	}
	
	if {$dlList == ""} {
		$Priv(btnPreview) configure -image [$ibox get pic_list_start] -state normal
		set Priv(runStart) 0
		tk_messageBox -title [::msgcat::mc "錯誤"] \
			-message  [::msgcat::mc "請先選擇您要下載的相簿"]\
			-type ok \
			-icon error
		return 0
	}
	
	set Priv(runStart) 1
	set Priv(mode) "PICTURE"
	 $Priv(btnPreview) configure -image [$ibox get pic_list_stop]		 	
	
	::abrowser::tree_item_clear
	foreach bookInfo $dlList {
		if {$Priv(runStart) == 0} {break}
		array unset opts
		array set opts $bookInfo

		::output::put_msg [::msgcat::mc "正在預覽相簿 %s:%s....." $opts(id) $opts(title)]
		::output::put_msg [::msgcat::mc "\t正在分析總頁數....."] ""
		set maxPage [::${::dApp::Priv(cmdNs)}::pic_page_count $opts(id) $opts(book) $opts(pw)]
		::output::put_msg [::msgcat::mc "找到%s頁" $maxPage]
		if { $maxPage== 0} {
			::output::put_msg [::msgcat::mc "失敗"]
			continue
		}
		
		set picList [list]
		for {set i 1} {$i <= $maxPage} {incr i} {
			if {$Priv(runStart) == 0} {break}
			
			
			if {($i % 10) == 0 && $::dApp::Priv(delay) > 0} {
				set Priv(delay) "WAIT"
				after $::dApp::Priv(delay) [list set ::abrowser::Priv(delay) "CONTINUE"]
				::output::put_msg [::msgcat::mc "\t等待抓取間隔....%s (秒 )" [expr $::dApp::Priv(delay) / 1000]]
				tkwait variable ::abrowser::Priv(delay)
			}						
			
			::output::put_msg [::msgcat::mc "\t正在分析第 %s 頁....." $i] ""
			foreach picInfo [::${::dApp::Priv(cmdNs)}::pic_page_list $opts(id) $opts(book) $i $opts(pw)] {
				lappend picList $picInfo
			}
			::output::put_msg [::msgcat::mc "完成"]
		}
		if {$picList == ""} {continue}		
		
		set cacheDir [file join $Priv(cacheDir) $opts(id)]
		if {![file exists $cacheDir]} {file mkdir $cacheDir}		
		set sn 0
		set picCut [llength $picList]
		foreach picInfo $picList {
			if {$Priv(runStart) == 0} {break}		
			incr sn
			
			if {($sn % 10) == 0 && $::dApp::Priv(delay) > 0} {
				set Priv(delay) "WAIT"
				after $::dApp::Priv(delay) [list set ::abrowser::Priv(delay) "CONTINUE"]
				::output::put_msg [::msgcat::mc "\t等待抓取間隔....%s (秒 )" [expr $::dApp::Priv(delay) / 1000 ]]
				tkwait variable ::abrowser::Priv(delay)
			}
						
			::abrowser::download_cb "" $picCut $sn
			lassign $picInfo picId picTitle picThumb picUrl picData
			::output::put_msg [::msgcat::mc "\t正在分析項目編號 \[ %s \] 的資訊....." $picId] ""
			set ftail [file tail [lindex [split $picThumb "?"] 0]]
			set fpath [file join $cacheDir $opts(id)_$opts(book)_[file tail $ftail]]
			if {![file exists $fpath]} {
				if {[::${::dApp::Priv(cmdNs)}::pic_get $picThumb $fpath] == "" } {
					::output::put_msg [::msgcat::mc "失敗!!"]
					continue
				}
			}
			file mtime $cacheDir [clock seconds]
			::output::put_msg [::msgcat::mc "完成"]
			set img [image create photo -file $fpath]
			::abrowser::tree_item_add  $opts(id) $opts(book) $opts(title) $picTitle $img 0 0 $opts(pw) $picInfo
			update
		}
	}
	
	::abrowser::download_cb "" 100 0
	$Priv(btnPreview) configure -image [$ibox get pic_list_start] -state disabled
 	::output::put_msg [::msgcat::mc "完成"]
	 set Priv(runStart) 0
	 return 1
}

proc ::abrowser::pic_list_stop {} {
	variable Priv
	set Priv(runStart) 0
}

proc ::abrowser::tree_init {wpath} {
	variable Priv
	
	set ibox $::dApp::Priv(ibox)

	set fme [::ttk::frame $wpath]
	set tree [treectrl $fme.tree \
		-bg white \
		-height 210 \
		-highlightthickness 0 \
		-itemwidthequal 1 \
		 -itemwidth 128 \
		 -itemheight 155 \
		-orient horizontal \
		 -relief groove \
		-showroot no \
		-showline no \
		-selectmod multiple \
		-showrootbutton no \
		-showbuttons no \
		-showheader 0 \
		-scrollmargin 1 \
		-wrap window \
		 ]
		 
	set Priv(tree) $tree
	set vs [ttk::scrollbar $fme.vs -command [list $tree yview] -orient vertical]
	set hs [ttk::scrollbar $fme.hs -command [list $tree xview] -orient horizontal]
	$tree configure -xscrollcommand [list $hs set] -yscrollcommand [list $vs set]
	
	::autoscroll::autoscroll $vs
	::autoscroll::autoscroll $hs	
	
	grid $tree $vs -sticky "news"
	grid $hs - -sticky "we"
	grid rowconfigure $fme 0 -weight 1
	grid columnconfigure $fme 0 -weight 1
	
	$tree state define CHECK
	$tree state define DOWNLOAD
	$tree state define KEY
	$tree state define NEW
	$tree notify install <Edit-begin>
	$tree notify install <Edit-accept>
	$tree notify install <Edit-end>
	
	$tree column create -tag colBook
	$tree element create eImg image -image [$ibox get book]
	$tree element create eNew image -image [$ibox get new_album]
	$tree element create eKey image -image [$ibox get key]
	$tree element create eBorder border -relief groove -background black -thickness 1
	$tree element create eBorder2 border -relief groove -background white -fill 1 -thickness 1
	$tree element create eId text  -justify center -wrap none \
		-font [font create -size 9 -weight bold ] -fill [list "#808080" {selected focus} "#808080" {}]	
	$tree element create eTitle text  -justify center -wrap none \
		-font [font create -size 9] -fill [list "#808080" {selected focus} "#808080" {}]
	$tree element create eNum text  -justify center -wrap none \
		-font [font create -size 9] -fill [list "#808080" {selected focus} "#808080" {}]		
	$tree element create ePw text  -justify center -wrap none \
		-font [font create -size 9] -fill [list "#808080" {selected focus} "#808080" {}]

	$tree element create eRect image \
		-image [list [$ibox get book_bg3] {DOWNLOAD} [$ibox get book_bg2] {CHECK} [$ibox get book_bg] {}]

	$tree style create styBook
	$tree style elements styBook {eRect eImg eTitle eNum eBorder eKey eBorder2 ePw eId eNew}
	$tree style layout styBook eRect -detach 1 -sticky "we" -iexpand "we" -pady {5 0}
	$tree style layout styBook eImg -sticky "news" -expand "news" -pady {25 35} -maxwidth 95 -maxheight 95
	$tree style layout styBook eBorder -detach 1 -union {eImg} -ipadx 1 -ipady 1
	$tree style layout styBook eTitle -detach 1 -sticky "we" -iexpand "we" -pady {120 0} \
		-maxwidth 70 -minwidth 70 -minheight 13
	$tree style layout styBook eNum -detach 1 -sticky "we" -iexpand "we" -pady {134 0} \
		-maxwidth 70 -minwidth 70 -minheight 13		
	$tree style layout styBook eKey -detach 1 -pady {12 0} -padx {15 0} -visible [list 1 {KEY} 0 {}]
	$tree style layout styBook ePw -detach 1  -pady {14 0} -padx {35 0} -expand "e" -sticky "we" \
		-maxwidth 60 -minwidth 60 -minheight 13 -visible [list 1 {KEY} 0 {}]
	$tree style layout styBook eBorder2 -detach 1 -union {ePw} -ipadx 2 -ipady 2 -visible [list 1 {KEY} 0 {}]
	$tree style layout styBook eId -detach 1 -pady {11 0} -padx {0 15} -expand "w"
	$tree style layout styBook eNew -detach 1 -pady {140 0} -padx {10 0} -visible [list 1 {NEW} 0 {}]

	
	TreeCtrl::SetEditable $tree {{colBook styBook ePw}}
	TreeCtrl::SetSensitive $tree {{colBook styBook}}
	TreeCtrl::SetDragImage $tree {}		

	bindtags $tree [list $tree TreeCtrlFileList TreeCtrl]
	set ::TreeCtrl::Priv(DirCnt,$tree) 1

	$tree notify bind $tree <Edit-begin> {
		%T item element configure %I %C %E -draw no + %E -draw no
		%T see %I
		update
	}
	$tree notify bind $tree <Edit-accept> {
		set t1 [%T item element cget %I %C %E -text]
		set t2 %t
		if {$t1 ne $t2} {
			%T item element configure %I %C %E -text "####" -data $t2
		}
	}
	$tree notify bind $tree <Edit-end> {
		if {[%T item id %I] ne ""} {
			%T item element configure %I %C %E -draw yes + %E -draw yes
		}
	}

	bind $tree <Motion> {::abrowser::tree_item_motion %x %y %X %Y} 

	bind $tree <Double-Button-1> {::abrowser::tree_btn1_dclick %x %y}

	bind $tree <<MenuPopup>> {::abrowser::tree_btn3_click %x %y %X %Y}

	bind $tree <ButtonRelease-1> {::abrowser::tree_btn1_click %x %y %X %Y}
	
	bind $tree <Control-a> {
		set tree $::abrowser::Priv(tree)
		set ::abrowser::Priv(selCut) 0
		$tree item state set all "CHECK"
		set  ::abrowser::Priv(selCut) [expr [$tree item count] -1 ]
	}

	bind $tree <Control-i> {
		set tree $::abrowser::Priv(tree)
		set ::abrowser::Priv(selCut) 0
		$tree item state set all "!CHECK"
	}	
	
	focus $tree

	return $wpath
}

proc ::abrowser::tree_btn1_click {posx posy posX posY} {
	variable Priv
	set tree $Priv(tree)	
	set ninfo [$tree identify $posx $posy]
	if {[llength $ninfo] != 6} {return}
	foreach {what itemId where columnId type name} $ninfo {}
	if {$what == "item" && $where == "column" && $type == "elem"} {
		switch -exact -- $name {
			eImg -
			eBorder -
			eChk {
				if {[$tree item state get $itemId "CHECK"] == 1} {
					$tree item state set $itemId "~CHECK"
					incr ::abrowser::Priv(selCut) -1
				 } else {
				 	$tree item state set $itemId "CHECK"
				 	incr ::abrowser::Priv(selCut)
				 }
			}
			ePw -
			eBorder2 -
			eKey {
				::TreeCtrl::FileListEdit $tree $itemId $columnId ePw
			}
		}
	}
}

proc ::abrowser::tree_btn1_dclick {posx posy} {
	variable Priv
	set tree $Priv(tree)

	set ninfo [$tree identify $posx $posy]
	if {[llength $ninfo] != 6} {return}
	foreach {what itemId where columnId type name} $ninfo {}
	if {$what eq "item" && $where eq "column"} {
		set parent [$tree item parent $itemId]
#		set idata [$tree item element cget $itemId 0 txt -data]
		
	}
}

proc ::abrowser::tree_btn3_click {posx posy posX posY} {
	variable Priv
	set tree $Priv(tree)
	set ninfo [$tree identify $posx $posy]
	if {[llength $ninfo] < 4} {return}
	foreach {what itemId where columnId type name} $ninfo {}
	if {$what eq "item" && $where eq "column"} {
		set item [lindex $ninfo 1]
		set parent [$tree item parent $itemId]
		tk_popup [::abrowser::tree_item_menu $item] $posX $posY
	}
}

proc ::abrowser::tree_item_add {id book title descript img new key pw {data ""}} {
	variable Priv
	
	set ibox $::dApp::Priv(ibox)
	
	incr Priv(sn)
	
	set tree $Priv(tree)
	set item [$tree item create -parent 0]
	$tree item style set $item 0 styBook
	$tree item element configure $item colBook eId -text $Priv(sn) -data [list \
		id $id \
		book $book \
		title $title \
		descript $descript \
		img $img \
		new $new \
		key $key \
		pw $pw \
		data $data]
	$tree item element configure $item colBook eTitle -text $title
	$tree item element configure $item colBook eNum -text $descript
	$tree item element configure $item colBook ePw -text [::msgcat::mc "輸入密碼"]
	$tree item element configure $item colBook eImg -image $img
	
	if {$Priv(mode) == "ALBUM"} {
		$tree item element configure $item colBook eRect \
			-image [list  [$ibox get book_bg3] {DOWNLOAD} [$ibox get book_bg2] {CHECK} [$ibox get book_bg] {}]	
	} elseif {$Priv(mode) == "PICTURE"} {
		$tree item element configure $item colBook eRect \
			-image [list [$ibox get pic_bg3] {DOWNLOAD} [$ibox get pic_bg2] {CHECK} [$ibox get pic_bg] {}]			
	}
	
	if {$key == 1} {$tree item state set $item "KEY"}
	if {$new == 1} {$tree item state set $item "NEW"}
	
	incr Priv(albumNum)
	
	return $item
}

proc ::abrowser::tree_item_clear {} {
	variable Priv
	set tree $Priv(tree)
	$tree item delete all
	set Priv(albumNum) 0
	set Priv(selCut) 0
	set Priv(sn) 0
}

proc ::abrowser::tree_item_get {item} {
	variable Priv
	set tree $Priv(tree)

	array set opts [$tree item element cget $item colBook eId -data]
	if {$Priv(mode) == "ALBUM"} {
		set opts(pw) [$tree item element cget $item colBook ePw -data]
	}
	return [array get opts]
}

proc ::abrowser::tree_item_menu {item} {
	variable Priv
	
	set ibox $::dApp::Priv(ibox)
	
	set tree $Priv(tree)	
	if {[winfo exists $tree.m]} {destroy $tree.m}
	set m [menu $tree.m -tearoff 0]

	array set opts [::abrowser::tree_item_get $item]

	$m add command -compound left \
		-label  [::msgcat::mc "切換選取狀態"] \
		-image [$ibox get empty] \
		-command [format {
			set tree $::abrowser::Priv(tree)
			set item "%s"
			if {[$tree item state get $item "CHECK"] == 1} {
				$tree item state set $item "~CHECK"
				incr ::abrowser::Priv(selCut) -1
			 } else {
				 $tree item state set $item "CHECK"
				 incr ::abrowser::Priv(selCut)
			 }			
		} $item]
		
	$m add command -compound left \
		-image [$ibox get empty] \
		-label  [::msgcat::mc "全選"] \
		-accelerator "Control-a" \
		-command {
			set tree $::abrowser::Priv(tree)
			set ::abrowser::Priv(selCut) 0
			$tree item state set all "CHECK"
			set  ::abrowser::Priv(selCut) [expr [$tree item count] -1 ]
		}
	$m add command -compound left \
		-image [$ibox get empty] \
		-label  [::msgcat::mc "全部不選"] \
		-accelerator "Control-i" \
		-command {
			set tree $::abrowser::Priv(tree)
			set ::abrowser::Priv(selCut) 0
			$tree item state set all "!CHECK"
		}	
		
	$m add separator	
	
	set  m2 [menu $m.sub -tearoff 0]
	$m add cascade \
		-menu $m2 \
		-label [::msgcat::mc "參觀 %s 的" $opts(id)] \
		-compound left \
		-image [$ibox get  empty]
	$m2 add command \
		-compound left \
		-image [$ibox get  empty] \
		-label  [::msgcat::mc "首頁"] \
		-command [list ::dApp::openurl [::${::dApp::Priv(cmdNs)}::mkurl home $opts(id)]]
	$m2 add command \
		-compound left \
		-image [$ibox get  empty] \
		-label  [::msgcat::mc "網誌"] \
		-command [list ::dApp::openurl [::${::dApp::Priv(cmdNs)}::mkurl blog $opts(id)]]
	$m2 add command \
		-compound left \
		-image [$ibox get  empty] \
		-label  [::msgcat::mc "相簿" ] \
		-command [list ::dApp::openurl [::${::dApp::Priv(cmdNs)}::mkurl album $opts(id)]]
	$m2 add command \
		-compound left \
		-image [$ibox get  empty] \
		-label  [::msgcat::mc "影音" ]\
		-command [list ::dApp::openurl [::${::dApp::Priv(cmdNs)}::mkurl video $opts(id)]]
	
	$m add command -compound left \
		-label  [::msgcat::mc "用瀏覽器開啟相簿"] \
		-image [$ibox get  empty] \
		-command [list ::dApp::openurl [::${::dApp::Priv(cmdNs)}::mkurl book $opts(id) $opts(book)]]

	if {$Priv(mode) == "ALBUM"} {
		$m add command \
			-compound left \
			-label  [::msgcat::mc "預覽選取的相簿"] \
			-image [$ibox get  empty] \
			-command [list $Priv(btnPreview) invoke]

	}
					
	$m add separator

	$m add command -compound left \
		-label  [::msgcat::mc "加入我的最愛"] \
		-image [$ibox get  emtpy] \
		-command [list ::abrowser::bookmark_add]

#	$m add separator	
		
	$m add command \
		-compound left \
		-label  [::msgcat::mc "開始下載"] \
		-image [$ibox get  empty] \
		-command [list $Priv(btnGo) invoke]
		

		
	return $m
}

proc ::abrowser::tree_item_motion {posx posy posX posY} {
	variable Priv
	
	set sbar $::dApp::Priv(win,sbar)
	
	set tree $Priv(tree)	
	set ninfo [$tree identify $posx $posy]
	if {[llength $ninfo] != 6} {return}
	foreach {what itemId where columnId type name} $ninfo {}
	if {$what == "item" && $where == "column" && $type == "elem"} {
		array set opts [::abrowser::tree_item_get $itemId]
		switch -exact -- $name {
			ePw {$tree configure -cursor xterm}
			eKey -
			eChk -
			eBorder {
				if {$::abrowser::Priv(albumId) == "精選相簿" || $::abrowser::Priv(albumId) == "人氣相簿" || $::abrowser::Priv(albumId) == "隨機推薦"} {
					$sbar put $opts(descript)
					set Priv(txtMsg,var) $opts(descript)
				} else {
					if {$::abrowser::Priv(mode) == "ALBUM"} {		
						$sbar put $opts(title)
						set Priv(txtMsg,var) $opts(title)
					} elseif {$::abrowser::Priv(mode) == "PICTURE"} {
						$sbar put $opts(descript)
						set Priv(txtMsg,var) $opts(descript)
					}
				}
				$tree configure -cursor hand2
			}
			default {
				$sbar put ""
				set Priv(txtMsg,var) ""
				$tree configure -cursor ""
			}
		}
	}
}


proc ::abrowser::pixnet_pic_download {saveDir bookInfo picInfo} {
	array set opts $bookInfo
	
	lassign $picInfo pid title thumb url type

	set fname $pid
	set ext [file extension $url]
				
	if {$::dApp::Priv(naming) == "ID+TITLE" && $title != ""} {
		set testName $fname
		append testName "-" [regsub -all {[?*|%/\\:|"<>~]} $title "_"]
		set testPath [file join $::dApp::Priv(rcPath) "test-$testName$ext"]
		if {![catch {set fd [open $testPath w]}]} {
			close $fd
			file delete $testPath
			set fname $testName
		} 
	}

	if {$::dApp::Priv(includeRaw) && $type eq "pic"} {
		set fpath [file join $saveDir $fname$ext]
		if {[file exists $fpath] && $::dApp::Priv(policy) == "SKIP"} {
			return [::msgcat::mc "%s 已存在" [file tail $fpath]]
		}
		if {[::pixnet::pic_get $url $fpath ::abrowser::download_cb] != ""} {
			return [::msgcat::mc "%s 完成" [file tail $fpath]]
		} 
	}
	
	if { $type eq "flv"} {
		set fpath [file join $saveDir $fname$ext]
		if {[file exists $fpath] && $::dApp::Priv(policy) == "SKIP"} {
			return [::msgcat::mc "%s 已存在" [file tail $fpath]]
		}	
		set url "http://colo-tfn-0.pixnet.tw$url"
		if {[::pixnet::pic_get $url $fpath ::abrowser::download_cb] != ""} {
			return [::msgcat::mc "%s 完成" [file tail $fpath]]
		} 	
	}

	if { $type eq "pic"} {
		set fpath [file join $saveDir normal_$fname$ext]
		if {[file exists $fpath] && $::dApp::Priv(policy) == "SKIP"} {
			return [::msgcat::mc "%s 已存在" [file tail $fpath]]
		}
		regsub "thumb_" $thumb "normal_" url
		if {[::pixnet::pic_get $url $fpath ::abrowser::download_cb] != ""} {
			return [::msgcat::mc "%s 完成" [file tail $fpath]]
		} 	else {
			set fpath [file join $saveDir $fname$ext]
			if {[file exists $fpath] && $::dApp::Priv(policy) == "SKIP"} {
				return [::msgcat::mc "%s 已存在" [file tail $fpath]]
			}		
			regsub "thumb_" $thumb "" url
			if {[::pixnet::pic_get $url $fpath ::abrowser::download_cb] != ""} {
				return [::msgcat::mc "%s 完成" [file tail $fpath]]
			}
		}
	}
	
	return [::msgcat::mc "跳過"]		

}

proc ::abrowser::pchome_pic_download {saveDir bookInfo picInfo} {
	array set opts $bookInfo
	lassign $picInfo f title thumb url
	
	set fname $f
	if {$::dApp::Priv(naming) == "ID+TITLE" && $title != ""} {
		regsub -all {\.}  $title "_" title
		regsub -all {\\}  $title "_" title
		regsub -all {\/}  $title "_" title
		regsub -all {\:}  $title "_" title
		regsub -all {\*}  $title "_" title
		regsub -all {\?}  $title "_" title
		regsub -all {\"}  $title "_" title
		regsub -all {\>}  $title "_" title
		regsub -all {\<}  $title "_" title
		regsub -all {\|}  $title "_" title		
		regsub -all {\~}  $title "_" title	
		set testName $fname
		append testName "-" $title
		set testPath [file join $::dApp::Priv(rcPath) "test-$testName"]
		if {![catch {set fd [open $testPath w]}]} {
			close $fd
			file delete $testPath
			set fname $testName
		}
	}	
	set ext [file extension $url]
	set fpath [file join $saveDir $fname$ext]
	if {[file exists $fpath] && $::dApp::Priv(policy) == "SKIP"} {
		return [::msgcat::mc "%s 已存在" [file tail $fpath]]
	}
	if {[::pchome::pic_get $url $fpath  ::abrowser::download_cb] != ""} {
		return [::msgcat::mc "%s 完成" [file tail $fpath]]
	}
	return [::msgcat::mc "跳過"]			
}

proc ::abrowser::wretch_pic_download {saveDir bookInfo picInfo} {
	array set opts $bookInfo
	lassign $picInfo f title thumb url cut

	set fname $f
	if {$::dApp::Priv(naming) == "ID+TITLE" && $title != ""} {
		regsub -all {\.}  $title "_" title
		regsub -all {\\}  $title "_" title
		regsub -all {\/}  $title "_" title
		regsub -all {\:}  $title "_" title
		regsub -all {\*}  $title "_" title
		regsub -all {\?}  $title "_" title
		regsub -all {\"}  $title "_" title
		regsub -all {\>}  $title "_" title
		regsub -all {\<}  $title "_" title
		regsub -all {\|}  $title "_" title	
		regsub -all {\~}  $title "_" title
		set testName $fname
		append testName "-" $title
		set testPath [file join $::dApp::Priv(rcPath) "test-$testName"]
		if {![catch {set fd [open $testPath w]}]} {
			close $fd
			file delete $testPath
			set fname $testName
		}
	}	
	
	set fpath [file join $saveDir $fname.jpg]
	if {$::dApp::Priv(includeRaw)} {	
		
		regsub -all $f  $url "o$f.jpg" ourl

		set fpath [file join $saveDir o$fname.jpg]
		if {[file exists $fpath] && $::dApp::Priv(policy) == "SKIP"} {
			return [::msgcat::mc "%s 已存在" [file tail $fpath]]
		}
		if {[::wretch::pic_get $ourl $fpath ::abrowser::download_cb] != ""} {
			return [::msgcat::mc "%s 完成" [file tail $fpath]]
		}
	}
	
	regsub -all $f  $url "$f.jpg" ourl
	set fpath [file join $saveDir $fname.jpg]
	if {[file exists $fpath] && $::dApp::Priv(policy) == "SKIP"} {
		return [::msgcat::mc "%s 已存在" [file tail $fpath]]
	}
	if {[::wretch::pic_get $ourl $fpath  ::abrowser::download_cb] != ""} {
		return [::msgcat::mc "%s 完成" [file tail $fpath]]
	}
	
	if {$::dApp::Priv(includeMp3)} {
		regsub -all $f  $url "$f.mp3" ourl
		set fpath [file join $saveDir $fname.mp3]
		if {[file exists $fpath] && $::dApp::Priv(policy) == "SKIP"} {
			return [::msgcat::mc "%s 已存在" [file tail $fpath]]
		}
		if {[::wretch::pic_get $url $fpath ::abrowser::download_cb] != ""} {
			return [::msgcat::mc "%s 完成" [file tail $fpath]]
		}
	}

	if {$::dApp::Priv(includeVideo)} {
		set vurl [::wretch::media_find $opts(id) $opts(book) $f $cut $opts(pw)]
		if {$vurl == ""} {return [::msgcat::mc "跳過"]	}
		set fpath [file join $saveDir $fname.flv]
		if {[file exists $fpath] && $::dApp::Priv(policy) == "SKIP"} {
			return [::msgcat::mc "%s 已存在" [file tail $fpath]]
		}
		if {[::wretch::pic_get $vurl $fpath ::abrowser::download_cb] != ""} {
			return [::msgcat::mc "%s 完成"  [file tail $fpath]]
		}
	}
	return [::msgcat::mc "跳過"]			
}


proc ::abrowser::yam_pic_download {saveDir bookInfo picInfo} {
	array set opts $bookInfo
	lassign $picInfo f title thumb url
	
	set fname $f
	if {$::dApp::Priv(naming) == "ID+TITLE" && $title != ""} {
		regsub -all {\.}  $title "_" title
		regsub -all {\\}  $title "_" title
		regsub -all {\/}  $title "_" title
		regsub -all {\:}  $title "_" title
		regsub -all {\*}  $title "_" title
		regsub -all {\?}  $title "_" title
		regsub -all {\"}  $title "_" title
		regsub -all {\>}  $title "_" title
		regsub -all {\<}  $title "_" title
		regsub -all {\|}  $title "_" title	
		regsub -all {\~}  $title "_" title
		set testName $fname
		append testName "-" $title
		set testPath [file join $::dApp::Priv(rcPath) "test-$testName"]
		if {![catch {set fd [open $testPath w]}]} {
			close $fd
			file delete $testPath
			set fname $testName
		}
	}
	
	set fpath [file join $saveDir $fname.jpg]
	if {[file exists $fpath] && $::dApp::Priv(policy) == "SKIP"} {
		return [::msgcat::mc "%s 已存在" [file tail $fpath]]
	}
	if {[::yam::pic_get $url $fpath  ::abrowser::download_cb] != ""} {
		return [::msgcat::mc "%s 完成" [file tail $fpath]]
	}
	
	
	return [::msgcat::mc "跳過"]			
}

proc ::abrowser::xuite_pic_download {saveDir bookInfo picInfo} {
	lassign $picInfo pid title thumb furl purl
	set fname [string range $pid 0 end-4]
	set fnameo [string range $fname 0 end-2]
	set ext [file extension $furl]	
	if {$::dApp::Priv(naming) == "ID+TITLE" && $title != ""} {
		set testName $fname
		set testNameo $fnameo
		append testName "-" [regsub -all {[?*|%/\\:|"<>]} $title "_"]
		append testNameo "-" [regsub -all {[?*|%/\\:|"<>]} $title "_"]
		set testPath [file join $::dApp::Priv(rcPath) "test-$testName"]
		if {![catch {set fd [open $testPath w]}]} {
			close $fd
			file delete $testPath
			set fname $testName
			set fnameo $testNameo
		} 
	}
	set saveDiro $saveDir
	set fpath [append saveDir / $fname$ext]
	set fpatho [append saveDiro / $fnameo$ext]
	if {$::dApp::Priv(includeRaw)} {
		if {[::xuite::pic_get_full $purl $fpatho ::abrowser::download_cb] != ""} {
			return [::msgcat::mc "%s 完成" [file tail $fpatho]]
		} 	
	}
	if {[file exists $fpath] && $::dApp::Priv(policy) == "SKIP"} {
		return [::msgcat::mc "%s 已存在" [file tail $fpath]]
	}
	if {[::xuite::pic_get $furl $fpath  ::abrowser::download_cb] != ""} {
		return [::msgcat::mc "%s 完成" [file tail $fpath]]
	}
	return [::msgcat::mc "跳過"]		
}
