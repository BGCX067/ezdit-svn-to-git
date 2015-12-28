package require treectrl
package require autoscroll
package require ttdialog


namespace eval ::vbrowser {
	variable Priv
	
	array set Priv [list \
		albumId "" \
		sn 0 \
		cacheDir [file join $::dApp::Priv(rcPath) "cache"] \
		delay "" \
	]
	if {![file exists $Priv(cacheDir)]} {file mkdir $Priv(cacheDir)}
}

proc ::vbrowser::download_cb {tok total current} {
	variable Priv
	
	set sbar $::dApp::Priv(win,sbar)
	$sbar pbar_set $total $current
	
	if {$::abrowser::Priv(runStart) == 0 && $tok != ""} {
		catch {::http::cleanup $tok}
		$sbar pbar_set 0 0
	}
	#puts " "
}

proc ::vbrowser::friend_list_build {} {
	variable Priv
	
	set ibox $::dApp::Priv(ibox)
	
	if {$Priv(albumId) == ""} {
		tk_messageBox -title [::msgcat::mc "錯誤"] \
			-message  [::msgcat::mc "請先列出影音清單"]\
			-type ok \
			-icon error
		return
	}	
	
	set data ""
	set data [::${::dApp::Priv(cmdNs)}::vfriend_list $Priv(albumId)]
	if {$data == ""} {
		tk_messageBox -title [::msgcat::mc "資訊"] \
			-message  [::msgcat::mc "找不到好友的相簿"]\
			-type ok \
			-icon info				
		return
	}
	
	catch {destroy $Priv(menuFriends)}
	set m [menu .menuFriend -tearoff 0	]
	set Priv(menuFriends) $m
		
	foreach {item} $data {
		lassign $item group id title
		$m add command \
			-compound left \
			-image [$ibox get empty] \
			-label $title \
			-command {}
	}

	
	set geo [winfo geometry $Priv(btnFriend)]
	lassign [split $geo "x"] w geo
	lassign [split $geo "+"] h x y
	set x [winfo rootx $Priv(btnFriend)]
	incr y [winfo rooty $Priv(btnFriend)] 		
	
	tk_popup $m $x [expr $y + $h]	
	
}

proc ::vbrowser::init {wpath} {
	variable Priv
	
	set ibox $::dApp::Priv(ibox)
	
	::ttk::frame $wpath
	
	set fmeTitle [::ttk::frame $wpath.fmeTitle]
		
	set btnGo [ttk::button $fmeTitle.btnGo \
		-style "Toolbutton" \
		-image [$ibox get download_start] \
		-command {::vbrowser::video_download_start} ]
		
	set btnFind [ttk::button $fmeTitle.btnFind \
		-style "Toolbutton" \
		-image [$ibox get video_list] \
		-command {::vbrowser::video_list_start $::vbrowser::Priv(albumId)} ]		
	set btnFriends [ttk::button $fmeTitle.btnFriends \
		-style "Toolbutton" \
		-image [$ibox get friends] \
		-command {::vbrowser::friend_list_build} ]	
	
	set lblNum [::ttk::label $fmeTitle.lblNum -text [::msgcat::mc "找到的項目 : "] -justify left -anchor w]
	set txtNum [::ttk::label $fmeTitle.txtNum -textvariable ::vbrowser::Priv(sn) -justify left -anchor w]	
	
	set lblSel [::ttk::label $fmeTitle.lblSel -text [::msgcat::mc "已選取的項目 : "] -justify left -anchor w]
	set txtSel [::ttk::label $fmeTitle.txtSel -textvariable ::vbrowser::Priv(selCut) -justify left -anchor w]		
	
	pack $btnFriends -side left -padx 3
	pack $lblNum $txtNum $lblSel $txtSel -side left -padx 3
	pack $btnGo -side right -padx 3

	set Priv(btnFind) $btnFriends
	set Priv(btnFriend) $btnFriends
	set Priv(btnGo) $btnGo

	::tooltip::tooltip $btnGo [::msgcat::mc "開始下載"]
	::tooltip::tooltip $btnFind [::msgcat::mc "列出影音清單"]
	::tooltip::tooltip $btnFriends [::msgcat::mc "好友的影音清單"]
	
	set tree [::vbrowser::tree_init $wpath.tree]
	pack $fmeTitle -fill x -pady 2
	pack $tree -expand 1 -fill both -padx 2 -pady 2
	
	return $wpath
}

proc ::vbrowser::tree_init {wpath} {
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
	$tree notify install <Edit-begin>
	$tree notify install <Edit-accept>
	$tree notify install <Edit-end>
	
	$tree column create -tag colBook
	$tree element create eImg image -image [$ibox get video]
	$tree element create eKey image -image [$ibox get key]
	$tree element create eBorder border -relief groove -background black -thickness 1
	$tree element create eBorder2 border -relief groove -background white -fill 1 -thickness 1
	$tree element create eId text  -justify center -wrap none \
		-font [font create -size 9 -weight bold ] -fill [list "#808080" {selected focus} "#808080" {}]	
	$tree element create eTitle text  -justify center -wrap none \
		-font [font create -size 9] -fill [list "#808080" {selected focus} "#808080" {}]
	$tree element create eDate text  -justify center -wrap none \
		-font [font create -size 9] -fill [list "#808080" {selected focus} "#808080" {}]		
	$tree element create ePw text  -justify center -wrap none \
		-font [font create -size 9] -fill [list "#808080" {selected focus} "#808080" {}]

	$tree element create eRect image \
		-image [list [$ibox get video_bg3] {DOWNLOAD} [$ibox get video_bg2] {CHECK} [$ibox get video_bg] {}]

	$tree style create styBook
	$tree style elements styBook {eRect eImg eTitle eDate eBorder eKey eBorder2 ePw eId}
	$tree style layout styBook eRect -detach 1 -sticky "we" -iexpand "we" -pady {5 0}
	$tree style layout styBook eImg -sticky "news" -expand "news" -pady {25 35} -maxwidth 95 -maxheight 95
	$tree style layout styBook eBorder -detach 1 -union {eImg} -ipadx 1 -ipady 1
	$tree style layout styBook eTitle -detach 1 -sticky "we" -iexpand "we" -pady {120 0} \
		-maxwidth 70 -minwidth 70 -minheight 13
	$tree style layout styBook eDate -detach 1 -sticky "we" -iexpand "we" -pady {134 0} \
		-maxwidth 70 -minwidth 70 -minheight 13		
	$tree style layout styBook eKey -detach 1 -pady {12 0} -padx {15 0} -visible [list 1 {KEY} 0 {}]
	$tree style layout styBook ePw -detach 1  -pady {14 0} -padx {35 0} -expand "e" -sticky "we" \
		-maxwidth 60 -minwidth 60 -minheight 13 -visible [list 1 {KEY} 0 {}]
	$tree style layout styBook eBorder2 -detach 1 -union {ePw} -ipadx 2 -ipady 2 -visible [list 1 {KEY} 0 {}]
	$tree style layout styBook eId -detach 1 -pady {11 0} -padx {0 15} -expand "w"

	
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

	bind $tree <Motion> {::vbrowser::tree_item_motion %x %y %X %Y} 

	bind $tree <Double-Button-1> {::vbrowser::tree_btn1_dclick %x %y}

	bind $tree <<MenuPopup>> {::vbrowser::tree_btn3_click %x %y %X %Y}

	bind $tree <ButtonRelease-1> {::vbrowser::tree_btn1_click %x %y %X %Y}
	
	bind $tree <Control-a> {

		set tree $::vbrowser::Priv(tree)
		set ::vbrowser::Priv(selCut) 0
		$tree item state set all "CHECK"
		set  ::vbrowser::Priv(selCut) [expr [$tree item count] -1 ]
	}

	bind $tree <Control-i> {
		set tree $::vbrowser::Priv(tree)
		set ::vbrowser::Priv(selCut) 0
		$tree item state set all "!CHECK"
	}
	
	focus $tree

	return $wpath
}

proc ::vbrowser::tree_btn1_click {posx posy posX posY} {
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
					incr Priv(selCut) -1
				 } else {
				 	$tree item state set $itemId "CHECK"
				 	incr Priv(selCut)
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

proc ::vbrowser::tree_btn1_dclick {posx posy} {
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

proc ::vbrowser::tree_btn3_click {posx posy posX posY} {
	variable Priv
	set tree $Priv(tree)
	set ninfo [$tree identify $posx $posy]
	if {[llength $ninfo] < 4} {return}
	foreach {what itemId where columnId type name} $ninfo {}
	if {$what eq "item" && $where eq "column"} {
		set item [lindex $ninfo 1]
		set parent [$tree item parent $itemId]
		tk_popup [::vbrowser::tree_item_menu $item] $posX $posY
	}
}

proc ::vbrowser::tree_item_add {id title date img url key} {
	variable Priv
	
	incr Priv(sn)
	set ibox $::dApp::Priv(ibox)
	
	set tree $Priv(tree)
	set item [$tree item create -parent 0]
	$tree item style set $item 0 styBook
	$tree item element configure $item colBook eId -text $Priv(sn) -data [list $id $title $date $url $key]
	$tree item element configure $item colBook eTitle -text $title
	$tree item element configure $item colBook eDate -text $date
	$tree item element configure $item colBook ePw -text [::msgcat::mc "輸入密碼"]
	$tree item element configure $item colBook eImg -image $img

	
	if {$key == 1} {$tree item state set $item "KEY"}
	
	
	
	return $item
}

proc ::vbrowser::tree_item_clear {} {
	variable Priv
	set tree $Priv(tree)
	$tree item delete all
	set Priv(albumNum) 0
	set Priv(selCut) 0
	set Priv(sn) 0
}

proc ::vbrowser::tree_item_menu {item} {
	variable Priv
	
	set ibox $::dApp::Priv(ibox)
	
	set tree $Priv(tree)	
	if {[winfo exists $tree.m]} {destroy $tree.m}
	set m [menu $tree.m -tearoff 0]
	lassign [$tree item element cget $item colBook eId -data] id book title num img new key f url		

	$m add command -compound left \
		-label  [::msgcat::mc "切換選取狀態"] \
		-image [$ibox get empty] \
		-command [list $tree item state set $item "~CHECK"]
	$m add command -compound left \
		-image [$ibox get empty] \
		-label  [::msgcat::mc "全選"] \
		-accelerator "Control-a" \
		-command [list event generate $tree <Control-a>]
	$m add command -compound left \
		-image [$ibox get empty] \
		-label  [::msgcat::mc "全部不選"] \
		-accelerator "Control-i" \
		-command [list event generate $tree <Control-i>]
		
	$m add separator	
	
	$m add command -compound left \
		-label  [::msgcat::mc "用瀏覽器開啟影音首頁"] \
		-image [$ibox get  empty] \
		-command [list ::dApp::openurl [::${::dApp::Priv(cmdNs)}::mkurl video $id]]

	set  m2 [menu $m.sub -tearoff 0]
	$m add cascade \
		-menu $m2 \
		-label [::msgcat::mc "參觀 %s 的" $id] \
		-compound left \
		-image [$ibox get  empty]
	$m2 add command \
		-compound left \
		-image [$ibox get  empty] \
		-label  [::msgcat::mc "首頁"] \
		-command [list ::dApp::openurl [::${::dApp::Priv(cmdNs)}::mkurl home $id]]
	$m2 add command \
		-compound left \
		-image [$ibox get  empty] \
		-label  [::msgcat::mc "網誌"] \
		-command [list ::dApp::openurl [::${::dApp::Priv(cmdNs)}::mkurl blog $id]]
	$m2 add command \
		-compound left \
		-image [$ibox get  empty] \
		-label  [::msgcat::mc "相簿" ] \
		-command [list ::dApp::openurl [::${::dApp::Priv(cmdNs)}::mkurl album $id]]
	$m2 add command \
		-compound left \
		-image [$ibox get  empty] \
		-label  [::msgcat::mc "影音" ]\
		-command [list ::dApp::openurl [::${::dApp::Priv(cmdNs)}::mkurl video $id]]
		
					
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

proc ::vbrowser::tree_item_motion {posx posy posX posY} {
	variable Priv
	
	set sbar $::dApp::Priv(win,sbar)
	
	set tree $Priv(tree)	
	set ninfo [$tree identify $posx $posy]
	if {[llength $ninfo] != 6} {return}
	foreach {what itemId where columnId type name} $ninfo {}
	if {$what == "item" && $where == "column" && $type == "elem"} {
		lassign [$tree item element cget $itemId colBook eId -data] id title date url key

		switch -exact -- $name {
			ePw {$tree configure -cursor xterm}
			eKey -
			eChk -
			eBorder {
				$sbar put $title
				set Priv(txtMsg,var) $title
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

proc ::vbrowser::video_download_start {} {
	variable Priv

	if {$Priv(albumId) == ""} {
		tk_messageBox -title [::msgcat::mc "錯誤"] \
			-message  [::msgcat::mc "請先列出影音清單"]\
			-type ok \
			-icon error
		return
	}

	set ibox $::dApp::Priv(ibox)

	set imgStart [$ibox get download_start]
	set imgCurr [$Priv(btnGo) cget -image]
	
	if {$imgCurr != $imgStart} {
		::vbrowser::video_download_stop
		$Priv(btnGo) configure -image [$ibox get download_start]
		return
	}
	
	if {$::abrowser::Priv(runStart)} {
		tk_messageBox -title [::msgcat::mc "錯誤"] \
			-message  [::msgcat::mc "其它的下載工作正在執行，請先停止它們"] \
			-type ok \
			-icon error
		return
	}
	
	set ::abrowser::Priv(runStart) 1
	$Priv(btnGo) configure -image [$ibox get download_stop]
	
	
	set wdir $::dApp::Priv(workspace)
	
	set tree $Priv(tree)
	set dlList [list]
	foreach item [$tree item children 0] {
		if {[$tree item state get $item "CHECK"] == 0} {continue}
		lassign [$tree item element cget $item colBook eId -data] id title date url key
		set pw ""
		if {$key} {set pw [$tree item element cget $item colBook ePw -data]}
		lappend dlList $item [list $id $title $url $pw]
	}
	
	if {$dlList == ""} {
		$Priv(btnGo) configure -image [$ibox get download_start]
		set ::abrowser::Priv(runStart) 0
		tk_messageBox -title [::msgcat::mc "錯誤"] \
			-message  [::msgcat::mc "請先選擇您要下載的影音"]\
			-type ok \
			-icon error
		return
	}
	
	set sn 0
	foreach {item video} $dlList {
		if {$::abrowser::Priv(runStart) == 0} {break}
		$tree item state set $item "DOWNLOAD"
		incr sn
		lassign $video id title url pw
		::output::put_msg [::msgcat::mc "正在下載影音 %s....." $title] ""
		
		if {![file exists [file join $wdir $id]]} {file mkdir [file join $wdir $id]}
		set saveDir [file join $wdir $id video-folder]
		if {![file exists $saveDir]} {file mkdir $saveDir}
		
		set idx1 [string first "&vid=" $url]
		set idx2 [string first "&" $url [incr idx1 5]]
		if {$idx2 == -1} {
			set idx2 end
		} else {
			incr idx2 -1
		}
		set fname [string range $url $idx1 $idx2]
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
			set testName $fname
			append testName "-" [regsub -all {\.} $title "_"]
			set testPath [file join $::dApp::Priv(rcPath) "test-$testName"]
			if {![catch {set fd [open $testPath w]}]} {
				close $fd
				file delete $testPath
				set fname $testName
			}
		}
		append fname ".flv"
		set fpath [file join $saveDir $fname]		
		
		if {$sn > 1 && $::dApp::Priv(delay) > 0} {
			set Priv(delay) "WAIT"
			after $::dApp::Priv(delay) [list set ::vbrowser::Priv(delay) "CONTINUE"]
			tkwait variable ::vbrowser::Priv(delay)
		}				
		
		if {[file exists $fpath] && $::dApp::Priv(policy) == "SKIP"} {
			::output::put_msg [::msgcat::mc "%s 已存在" $fname] 
			$tree item state set $item "~DOWNLOAD"
			continue
		}	
		
		if {[::${::dApp::Priv(cmdNs)}::video_get $url $fpath $pw ::vbrowser::download_cb] != ""} {
			::output::put_msg [::msgcat::mc "%s 完成"  $fname]
			$tree item state set $item "~DOWNLOAD"
			continue
		}
		::output::put_msg [::msgcat::mc "%s 跳過"  $fname] 
		$tree item state set $item "~DOWNLOAD"
	}
	
	::output::put_msg [::msgcat::mc "結束"]
	$Priv(btnGo) configure -image [$ibox get download_start]
	::vbrowser::download_cb "" 0 0
	set ::abrowser::Priv(runStart) 0
	
}

proc ::vbrowser::video_download_stop {} {
	variable Priv	
	set ::abrowser::Priv(runStart) 0
}

proc ::vbrowser::video_list_start {id} {
	variable Priv
	
	if {$::abrowser::Priv(runStart)} {
		tk_messageBox -title [::msgcat::mc "錯誤"] \
			-message  [::msgcat::mc "其它的下載工作正在執行，請先停止它們"] \
			-type ok \
			-icon error
		return
	}
	
	switch -exact -- $id {
		"人氣相簿" -
		"精選相簿" -
		"隨機推薦" {
			tk_messageBox -title [::msgcat::mc "錯誤"] \
				-message  [::msgcat::mc "無法列出 %s 的影音清單" $id] \
				-type ok \
				-icon error
			return	
		}
		default {
			set ::abrowser::Priv(runStart) 1
			::output::put_msg [::msgcat::mc "正在找出 \[ %s \] 的影音清單..." $id]
			set cacheDir [file join $Priv(cacheDir) $id]
			if {![file exists $cacheDir]} {file mkdir $cacheDir}			
			set pageCut [::${::dApp::Priv(cmdNs)}::video_page_count $id]
			set cmd [list ::${::dApp::Priv(cmdNs)}::video_page_list $id]
		}
	}	
	
	if {$pageCut == 0} {
		::output::put_msg [::msgcat::mc "失敗"]
		set ::abrowser::Priv(runStart) 0
		return
	}
	
	set Priv(albumId) $id
	
	::vbrowser::tree_item_clear
	set cut 0
	::vbrowser::download_cb "" $pageCut 0
	for {set i 1} {$i <= $pageCut} {incr i} {
		if {$::abrowser::Priv(runStart) == 0} {break}
		
		if {($i % 10) == 0 && $::dApp::Priv(delay) > 0} {
			set Priv(delay) "WAIT"
			after $::dApp::Priv(delay) [list set ::vbrowser::Priv(delay) "CONTINUE"]
			::output::put_msg [::msgcat::mc "\t等待抓取間隔....%s (秒 )" [expr $::dApp::Priv(delay) / 1000 ]]
			tkwait variable ::vbrowser::Priv(delay)
		}				
		
		foreach pageInfo [eval [linsert $cmd end $i]] {
			lassign $pageInfo date title url thumb key
			::output::put_msg [::msgcat::mc "\t分析影音 \[ %s \] 的資訊....." $title] ""
			set fpath [file join $cacheDir ${id}_video_[file tail $thumb]]
			if {![file exists $fpath]} {
				if {[::${::dApp::Priv(cmdNs)}::pic_get $thumb $fpath] == "" } {
					::output::put_msg [::msgcat::mc "失敗!!"]
					continue
				}
			}
			file mtime $cacheDir [clock seconds]
			::output::put_msg [::msgcat::mc "完成"]
			set img [image create photo -file $fpath]
			::vbrowser::tree_item_add $id $title $date $img $url $key
			incr cut
			
			if {($cut % 10) == 0 && $::dApp::Priv(delay) > 0} {
				set Priv(delay) "WAIT"
				after $::dApp::Priv(delay) [list set ::vbrowser::Priv(delay) "CONTINUE"]
				::output::put_msg [::msgcat::mc "\t等待抓取間隔....%s (秒 )" [expr $::dApp::Priv(delay) / 1000 ]]
				tkwait variable ::vbrowser::Priv(delay)
			}		
								
			update
		}
		::vbrowser::download_cb "" $pageCut $i
		
	}
	::vbrowser::download_cb "" 100 0
	::output::put_msg [::msgcat::mc "找到 %s 個影音...結束" $cut]
	set ::abrowser::Priv(runStart) 0
}

proc ::vbrowser::video_list_stop {} {
	variable Priv
	set ::abrowser::Priv(runStart) 0
}

