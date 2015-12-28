package require treectrl
package require autoscroll
package require ttdialog

namespace eval ::bookmark {
	variable Priv

	array set Priv [list \
		rcFile [file join $::dApp::Priv(rcPath) "bookmark.xml"] \
	]
}


proc ::bookmark::tree_init {wpath} {
	variable Priv
	
	set fme [::ttk::frame $wpath]
	
	set tree [treectrl $fme.tree \
		-showroot no \
		-linestyle dot \
		-selectmod browse \
		-showrootbutton yes \
		-showbuttons yes \
		-showheader no \
		-showlines yes \
		-scrollmargin 16 \
		-xscrolldelay "500 50" \
		-yscrolldelay "500 50" \
		-highlightthickness 0 \
		-relief groove \
		-height 1 \
		-bd 1]
	set Priv(tree) $tree
	set vs [ttk::scrollbar $fme.vs -command [list $tree yview] -orient vertical]
	set hs [ttk::scrollbar $fme.hs -command [list $tree xview] -orient horizontal]
	$tree configure -xscrollcommand [list $hs set] -yscrollcommand [list $vs set]
	
	::autoscroll::autoscroll $vs
	::autoscroll::autoscroll $hs	

	$tree column create -tag colStation -expand yes
	$tree element create img image -height 24 -width 24 
	$tree element create txt text -fill [list black {selected focus}] -justify left
	$tree element create rect rect -showfocus yes -fill [list #e6e4e4 {selected}]
	
	$tree configure -treecolumn colStation
	
	$tree style create style
	$tree style elements style {rect img txt}
	$tree style layout style img -expand ns -pady {5 0}
	$tree style layout style txt -expand ns -pady {5 0} -padx {6 0}
	$tree style layout style rect -union {txt} -ipadx 1 -iexpand ns 

	$tree notify install <Edit-begin>
	$tree notify install <Edit-accept>
	$tree notify install <Edit-end>
	
	TreeCtrl::SetEditable $tree {{colStation style txt}}

	$tree notify bind $tree <Edit-begin> {%T item element configure %I %C rect -draw no + txt -draw no}
	$tree notify bind $tree <Edit-accept> {
		set t1 [%T item element cget %I %C txt -text]
		set t2 %t
		# cmd rename
		
		if {$t1 ne $t2} {
			if {[%T item parent %I] == 0} {
				set caid [%T item element cget %I %C txt -data]
				#puts $caid
				::bookmark::category_rename $caid $t2
			} else {
				lassign [%T item element cget %I %C txt -data] type bid
				::bookmark::book_rename $bid $t2
			}
			%T item element configure %I %C txt -text $t2
		}
	}
	$tree notify bind $tree <Edit-end> {
		if {[%T item id %I] ne ""} {
			%T item element configure %I %C rect -draw yes + txt -draw yes
		}
	}		

	bind $tree <Double-Button-1> {::bookmark::tree_btn1_dclick %x %y} 
	bind $tree <ButtonRelease-1> {::bookmark::tree_btn1_click %x %y}


	bind $tree <<MenuPopup>> {::bookmark::tree_btn3_click %x %y %X %Y} 


	grid $tree $vs -sticky "news"
	grid $hs - -sticky "we"
	grid rowconfigure $fme 0 -weight 1
	grid columnconfigure $fme 0 -weight 1

	return $wpath
}

proc ::bookmark::tree_btn1_click {posx posy} {
	variable Priv
	
	set tree $Priv(tree)
	set ninfo [$tree identify $posx $posy]
	if {[llength $ninfo] != 6} {return}
	foreach {what itemId where columnId type name} $ninfo {}
	if {$what eq "item" && $where eq "column"} {
		set parent [$tree item parent $itemId]
		set frm [$tree item element cget $itemId 0 txt -data]

	}
}

proc ::bookmark::tree_btn1_dclick {posx posy} {
	variable Priv
	set tree $Priv(tree)

	set ninfo [$tree identify $posx $posy]
	if {[llength $ninfo] != 6} {return}
	foreach {what itemId where columnId type name} $ninfo {}
	if {$what eq "item" && $where eq "column"} {
		set parent [$tree item parent $itemId]
		lassign [$tree item element cget $itemId 0 txt -data] type id

		if {$parent != 0} {
			set ::dApp::Priv(cmdNs) $type
			::tbar::book_list $id
		}
	}
}

proc ::bookmark::tree_btn3_click {posx posy posX posY} {
	variable Priv
	
	set tree $Priv(tree)
	set ninfo [$tree identify $posx $posy]

	if {[llength $ninfo] != 6} {return}
	foreach {what itemId where columnId type name} $ninfo {}
	if {$what eq "item" && $where eq "column"} {
		focus $tree
		$tree selection modify $itemId all
		
		set item [lindex $ninfo 1]
		set parent [$tree item parent $itemId]
		set idata [$tree item element cget $item 0 txt -data]
		if {$parent == 0} {
			tk_popup [::bookmark::category_menu_post $item] $posX $posY
		} else {
			tk_popup [::bookmark::book_menu_post $item] $posX $posY
		}

	}
}

proc ::bookmark::book_add {caId id title} {
	variable Priv
	
	set tok [::ttrc::openrc 	$Priv(rcFile)]
	foreach sess [$tok session_list] {
		if {[$sess nodeName] == $caId} {
			set item [$tok item_add $sess $id]
			$tok attr_set $item title $title type $::dApp::Priv(cmdNs)
			$tok close
			::bookmark::tree_refresh
			return
		}
	}
	$tok close
	 ::bookmark::tree_refresh
	
}	

proc ::bookmark::book_del {bId} {
	variable Priv
	
	set tok [::ttrc::openrc 	$Priv(rcFile)]
	foreach sess [$tok session_list] {
		set item [$sess selectNode "./$bId"]
		if {$item != ""} {
			$tok item_del $sess $item
			$tok close
			::bookmark::tree_refresh
			return
		}
	}
	
	$tok close
	::bookmark::tree_refresh
}


proc ::bookmark::book_rename {bId title} {
	variable Priv
	
	set tok [::ttrc::openrc 	$Priv(rcFile)]
	foreach sess [$tok session_list] {
		set item [$sess selectNode "./$bId"]
		if {$item != ""} {
			$tok attr_set  $item title $title
			break
		}
	}
	
	$tok close
	#::bookmark::tree_refresh
}

proc ::bookmark::book_menu_post {item} {
	variable Priv

	set ibox $::dApp::Priv(ibox)

	set tree $Priv(tree)	
	if {[winfo exists $tree.m]} {destroy $tree.m}
	set m [menu $tree.m -tearoff 0]
	lassign [$tree item element cget $item 0 txt -data] type id

	set  m2 [menu $m.sub -tearoff 0]
	$m add cascade \
		-label [::msgcat::mc "參觀 %s 的" $id] \
		-compound left \
		-image [$ibox get empty] \
		-menu $m2
		
	$m2 add command \
		-compound left \
		-image [$ibox get empty] \
		-label  [::msgcat::mc "首頁"] \
		-command [list ::dApp::openurl [::${type}::mkurl home $id]]
		
	$m2 add command \
		-compound left \
		-image [$ibox get empty] \
		-label  [::msgcat::mc "網誌"] \
		-command [list ::dApp::openurl [::${type}::mkurl blog $id]]
		
	$m2 add command \
		-compound left \
		-image [$ibox get empty] \
		-label  [::msgcat::mc "相簿"] \
		-command [list ::dApp::openurl [::${type}::mkurl album $id]]
		
	$m2 add command \
		-compound left \
		-image [$ibox get empty] \
		-label  [::msgcat::mc "影音"] \
		-command [list ::dApp::openurl [::${type}::mkurl video $id]]

	$m add separator
	$m add command \
		-compound left \
		-label  [::msgcat::mc "查看相簿"] \
		-image [$ibox get empty] \
		-command [format {
			set ::dApp::Priv(cmdNs) %s
			::tbar::book_list %s
		} $type $id]

	$m add command \
		-compound left \
		-image [$ibox get empty] \
		-label  [::msgcat::mc "重新命名"] \
		-command [list ::TreeCtrl::FileListEdit $tree $item colStation txt]


#	$m add separator

	$m add command \
		-compound left \
		-image [$ibox get empty] \
		-label  [::msgcat::mc "刪除書籤"] \
		-command [format {
			set win ._dialog_2
			catch {destroy $win}
			set ret [::ttdialog::messageBox $win -title [::msgcat::mc "刪除書籤"] \
				-message [::msgcat::mc "確定要刪除這個項目嗎?"] \
				-buttons [list "確定" ok "取消" cancel] \
				-default cancel]
			
			if {$ret == "ok"} { ::bookmark::book_del "%s" }
		} $id]

	return $m
}

proc ::bookmark::tree_item_add {parent btn img txt {data ""}} {
	variable Priv
	
	set ibox $::dApp::Priv(ibox)
	set tree $Priv(tree)
	set item [$tree item create -button $btn]
	$tree item style set $item 0 style
	$tree item lastchild $parent $item
	if {$parent == 0} {
		$tree item element configure $item 0 img -image [list [$ibox get category_open] open  [$ibox get category_close] {}]
	} else {
		$tree item element configure $item 0 img -image $img
	}
	$tree item element configure $item 0 txt -text $txt -data $data
	if {$btn == "yes"} { $tree item collapse $item}

	return $item
}

proc ::bookmark::tree_item_del {item} {
	variable wInfo
	set tree $Priv(tree)
	$tree item delete $item
}

proc ::bookmark::tree_refresh {} {
	variable Priv
	set tree $Priv(tree)
	
	set ibox $::dApp::Priv(ibox)
	
	$tree item delete 0 end
	
	set tok [::ttrc::openrc 	$Priv(rcFile)]
	set ret ""
	foreach sess [$tok session_list] {
		set id [$sess nodeName] 
		set title [$tok attr_get $sess name]
		set parent [::bookmark::tree_item_add 0 yes [$ibox get books] $title $id]
		foreach node [$tok session_items $sess] {
			set id [$node nodeName] 
			set title [$tok attr_get $node title]
			set type [$tok attr_get $node type]
			if {$type == ""} {set type "wretch"}
			set item [::bookmark::tree_item_add $parent no [$ibox get bookmark] $title [list $type $id]]
		}
	}	
	$tok close

}

proc ::bookmark::init {wpath} {
	variable Priv
	
	set ibox $::dApp::Priv(ibox)
	
	set fme [::ttk::frame $wpath]
	
	set lblType [::ttk::label $fme.lblType -text [::msgcat::mc "分類 : "] -justify left -anchor w]
	set Priv(txtType,var) ""
	set txtType [::ttk::entry $fme.txtType -textvariable ::bookmark::Priv(txtType,var)]
	set btnType [::ttk::button $fme.btnType \
		-style "Toolbutton" \
		-image [$ibox get category_add] \
		-command {
			set txt [string trim $::bookmark::Priv(txtType,var)]
			if {$txt != ""} {
				::bookmark::category_add "$txt"
				set ::bookmark::Priv(txtType,var) ""
			}
	}]
	
	::tooltip::tooltip $btnType [::msgcat::mc "增加"]
	
	set tree [::bookmark::tree_init $fme.tree]
	::bookmark::tree_refresh

	grid $lblType $txtType $btnType -sticky "we" -padx 2 -pady 2
	grid $tree - - -sticky "news" -padx 2 -pady 2
	grid rowconfigure $fme 1 -weight 1
	grid columnconfigure $fme 1 -weight 1

	bind $txtType <KeyRelease-Return> [list $btnType invoke]

	return $wpath
}

proc ::bookmark::category_add {name} {
	variable Priv
	
	set id [string trimleft [clock clicks] "-"]
	
	set tok [::ttrc::openrc 	$Priv(rcFile)]
	foreach sess [$tok session_list] {
		set attr [$tok attr_get $sess name]
		if {$attr == $name} {
			$tok close
			return
		}
	}
	
	set ca [$tok session_add "category_$id"]
	$tok attr_set $ca name $name
	$tok close
	::bookmark::tree_refresh	
}

proc ::bookmark::category_del {caId} {
	variable Priv
	
	set tok [::ttrc::openrc 	$Priv(rcFile)]
	foreach sess [$tok session_list] {
		if {[$sess nodeName] == $caId} {
			$tok session_del $sess
			$tok close
			::bookmark::tree_refresh
			return
		}
	}
	$tok close
	 ::bookmark::tree_refresh
}

proc ::bookmark::category_list {} {
	variable Priv
	
	
	set tok [::ttrc::openrc 	$Priv(rcFile)]
	set ret ""
	foreach sess [$tok session_list] {
		lappend ret [$sess nodeName] [$tok attr_get $sess name]
	}
	$tok close
	
	return $ret
}


proc ::bookmark::category_menu_post {item} {
	variable Priv
	
	set tree $Priv(tree)
	
	set ibox $::dApp::Priv(ibox)
		
	if {[winfo exists $tree.m]} {destroy $tree.m}
	set m [menu $tree.m -tearoff 0]
	set id [$tree item element cget $item 0 txt -data]

	$m add command \
		-compound left \
		-image [$ibox get empty] \
		-label  [::msgcat::mc "重新命名"] \
		-command [list ::TreeCtrl::FileListEdit $tree $item colStation txt]		

	$m add command \
		-compound left \
		-label  [::msgcat::mc "刪除分類"] \
		-image [$ibox get empty] \
		-command [format {
			set win ._dialog_2
			catch {destroy $win}
			set ret [::ttdialog::messageBox  $win -title [::msgcat::mc "刪除分類"] \
				-message [::msgcat::mc "確定要刪除這個分類嗎?"] \
				-buttons [list "確定" ok "取消" cancel] \
				-default cancel]
			
			if {$ret == "ok"} {::bookmark::category_del "%s"}
		} $id]
		
	return $m
}

proc ::bookmark::category_rename {caId name} {
	variable Priv
	
	set tok [::ttrc::openrc 	$Priv(rcFile)]
	foreach sess [$tok session_list] {
		if {[$sess nodeName] == $caId} {
			$tok attr_set $sess name $name
			break
		}
	}
	$tok close
}
