##################################################################################
# Copyright (C) 2006-2007 Tai, Yuan-Liang                                        #
#                                                                                #
# This program is free software; you can redistribute it and/or modify           #
# it under the terms of the GNU General Public License as published by           #
# the Free Software Foundation; either version 2 of the License, or              #
# (at your option) any later version.                                            #
#                                                                                #
# This program is distributed in the hope that it will be useful,                #
# but WITHOUT ANY WARRANTY; without even the implied warranty of                 #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                  #
# GNU General Public License for more details.                                   #
#                                                                                #
# You should have received a copy of the GNU General Public License              #
# along with this program; if not, write to the Free Software                    #
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA   #
##################################################################################

package require Tkhtml
package require BWidget

namespace eval ::fmeDocView {
	variable vars
	array set vars ""
	variable wInfo
	array set wInfo ""
	
	variable bookmarks 
	array set bookmarks ""
	
	variable hisList
	array set hisList ""
	variable hisIdx
	array set hisIdx ""
}

#######################################################
#                                                     #
#                 Private Operations                  #
#                                                     #
#######################################################

proc ::fmeDocView::check_on_link {hv x y} {
	variable vars
	variable wInfo
	set node [$hv node $x $y]
	set win [winfo toplevel $hv]
	$win configure -cursor ""
	if {[llength $node] != 1} {return}
	if {[$node text] eq ""} {return}
	set pNode [::fmeDocView::find_a $hv $node]
	if {$pNode eq ""} {return}
	array set attrs [$pNode attr]
	if {[info exists attrs(href)] || [info exists attrs(HREF)]} {
		set vars($hv,oCursor) [$win cget -cursor]
		$win configure -cursor hand2
	}
}

proc ::fmeDocView::click_on_link {hv x y} {
	variable vars
	variable wInfo
	variable hisList
	variable hisIdx
		
	set node [$hv node $x $y]
	set win [winfo toplevel $hv]
	$win configure -cursor ""
	if {[llength $node] != 1} {return}
	if {[$node text] eq ""} {return}
	set pNode [::fmeDocView::find_a $hv $node]
	if {$pNode eq ""} {return}
	array set attrs [$pNode attr]
	set href ""
	if {[info exists attrs(href)]} {
		set href $attrs(href)
	}
	if {[info exists attrs(HREF)]} {
		set href $attrs(HREF)
	}
	if {$href eq ""} {return}
	::fmeDocView::his_put $hv [file join $vars($hv,pwd) $href]
	::fmeDocView::goto $hv [file join $vars($hv,pwd) $href]
	return
}

proc ::fmeDocView::cmd_a {hv node} {
	variable bookmarks
	if {$node eq "" || [string tolower [$node tag]] ne "a"} {return}
	array set attrs [$node attr]
	set bk ""
	if {[info exists attrs(name)]} {
		set bk $attrs(name)
	} elseif {[info exists attrs(NAME)]} {
		set bk $attrs(NAME)
	}
	if {$bk ne ""} {
		set bookmarks($hv,$bk) $node
	}
	return
}

proc ::fmeDocView::find_a {hv node} {
	if {[string tolower [$node tag]] eq "a"} {
		return $node
	} else {
		if {[$node parent] ne ""} {
			return [::fmeDocView::find_a $hv [$node parent]]
		}
	}
	return
}

proc ::fmeDocView::goto {hv fpath} {
	variable vars
	variable wInfo
	variable bookmarks
	foreach {page anchor} [split $fpath "#"] {}
	if {[string trim $page] ne "" && [file isfile $page]} {
		#bind $hv <Motion> {}
		#bind $hv <Button-1> {}
		$hv reset
		array unset bookmarks "$hv,*"
		set fd [open $page r]
		$hv parse -final [read $fd]
		close $fd
		#bind $hv <Motion> [list ::fmeDocView::motion %x %y]
		#bind $hv <Button-1> [list ::fmeDocView::btn1_click %x %y]
		set vars($hv,pwd) [file dirname $page]
		set vars($hv,curr) [file normalize $page]
	}
	if {$anchor ne "" && [info exists bookmarks($hv,$anchor)]} {
		after idle [list $hv yview $bookmarks($hv,$anchor)]
	}
	return
}

proc ::fmeDocView::his_pop {hv fpath} {
	variable hisList
	variable hisIdx
	set hisList($hv) [lrange $hisList($hv) 1 end]
	set hisIdx($hv) [llength $hisList($hv)]
	return
}

proc ::fmeDocView::his_put {hv fpath} {
	variable hisList
	variable hisIdx
	set hisList($hv) [lrange $hisList($hv) 0 $hisIdx($hv)]
	lappend hisList($hv) $fpath
	# history url * 30
	if {[llength $hisList($hv)] == 31} {
		set hisList($hv) [lrange $hisList($hv) 1 end]
	}
	set hisIdx($hv) [expr [llength $hisList($hv)] -1]
	return
}

proc ::fmeDocView::hv_copy {hv data} {
	clipboard clear
	clipboard append $data
	if {[namespace exists ::crowTde]} {
		::fmeStatusBar::put_msg [::msgcat::mc "Copy %d %s" [string length $data] [msgcat::mc "chars"]]
	}
	return
}
proc ::fmeDocView::hv_get_selection {path offset maxChars} {
	set span [$path select span]
	if {[llength $span] != 4} {return ""}
	foreach {n1 i1 n2 i2} $span {}

	set not_empty 0
	set T ""
	set N $n1
	while {1} {
		if {[$N tag] eq ""} {
			set index1 0
			set index2 end
			if {$N == $n1} {set index1 $i1}
			if {$N == $n2} {set index2 $i2}
			set text [string range [$N text] $index1 $index2]
			append T $text
			if {[string trim $text] ne ""} {set not_empty 1}
		} else {
			array set prop [$N prop]
			if {$prop(display) ne "inline" && $not_empty} {
				append T "\n"
				set not_empty 0
			}
		}

		if {$N eq $n2} break 

		if {[$N nChild] > 0} {
			set N [$N child 0]
		} else {
			while {[set next_node [$N right_sibling]] eq ""} {
				set N [$N parent]
			}
			set N $next_node
		}
		
		if {$N eq ""} {error "End of tree!"}
	}

	set T [string range $T $offset [expr $offset + $maxChars]]
	return $T
}

proc ::fmeDocView::item_scan {tree item} {
	set dpath [$tree item element cget $item 0 txt -data]

	set dlist [lsort -dictionary [glob -nocomplain -directory $dpath -types {d} -- *]]
	foreach d $dlist {
		::fmeDocView::tree_item_add $tree $item $d [::crowImg::get_image help_close]
	}	
	
	set flist [lsort -dictionary [glob -nocomplain -directory $dpath -types {f} -- *]]
	foreach f $flist {
		set ext [string range [file extension $f] 1 end]
		if {[string range [string tolower $ext] 0 2] ne "htm"} {continue}
		::fmeDocView::tree_item_add $tree $item $f [::crowImg::get_image "mime_$ext"]
	}
}

proc ::fmeDocView::tree_init {path} {
	variable wInfo
	
	set fmeMain [frame $path]
	set fmeBody [ScrolledWindow $fmeMain.fmeBody]
	set tree [treectrl $fmeBody.tree \
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
		-bd 1 \
		-bg white]
	$tree column create -tag colFileTree -expand yes
	$tree element create img image -height 24 -width 24 -image \
		[list [::crowImg::get_image help_open] {open} [::crowImg::get_image help_close] {}]
	$tree element create txt text -fill [list black {selected focus}] -justify left
	$tree element create rect rect -showfocus yes -fill [list #e6e4e4 {selected}]
	
	$tree configure -treecolumn colFileTree
	
	$tree style create style
	$tree style elements style {rect img txt}
	$tree style layout style img -padx {0 4} -expand ns
	$tree style layout style txt -padx {0 4} -expand ns
	$tree style layout style rect -union {txt} -iexpand ns -ipadx 2
		
	#bind $tree <Double-Button-1> {::fmeDocView::tree_btn1_dclick %x %y} 
	bind $tree <Button-1> [list ::fmeDocView::tree_btn1_click %W %x %y]
	bind $tree <ButtonRelease-3> {::fmeDocView::tree_btn3_click %W %x %y %X %Y} 
	
	$tree notify bind $tree <Expand-before> {
		::fmeDocView::item_scan %T %I
	}
	
	$tree notify bind $tree <Collapse-after> {
		foreach c [%T item children %I] {::fmeDocView::tree_item_del %T $c }
		
	}
	
	$fmeBody setwidget $tree
	
	pack $fmeBody -side top -fill both -expand 1
	
	set item [::fmeDocView::tree_item_add $tree 0 [file join $::crowTde::appPath "docs"] [::crowImg::get_image helps]]
	$tree item element configure $item 0 img -image [list [::crowImg::get_image helps] {open} [::crowImg::get_image helps] {}]
	$tree item expand $item
	return $fmeMain
}
proc ::fmeDocView::tree_item_add {tree parent fpath img} {
	set item [$tree item create -button no]
	if {[file isdirectory $fpath]} {$tree item configure $item -button yes}
	$tree item style set $item 0 style
	$tree item lastchild $parent $item
	$tree item element configure $item 0 img -image $img
	$tree item element configure $item 0 txt -text [file tail $fpath] -data $fpath
	$tree item collapse $item
	return $item
}

proc ::fmeDocView::tree_item_del {tree item} {
	foreach c [$tree item children $item] {::fmeDocView::tree_item_del $tree $c }
	$tree item delete $item
}

proc ::fmeDocView::tree_btn1_click {tree posx posy} {
	variable wInfo
	set ninfo [$tree identify $posx $posy]
	if {[llength $ninfo] != 6} {return}
	foreach {what itemId where columnId type name} $ninfo {}
	if {$what eq "item" && $where eq "column"} {
		set parent [$tree item parent $itemId]
		set idata [$tree item element cget $itemId 0 txt -data]
		
		if {[file isfile $idata]} {
			
			::fmeDocView::goto_doc $::crowTde::wInfo(fmeDocView) $idata
			::fmeDocView::doc_expand
		} 
		if {[file isdirectory $idata]} {
			$tree item toggle $itemId
		}
	}
	return
}

proc ::fmeDocView::tree_btn1_dclick {tree posx posy} {
	set ninfo [$tree identify $posx $posy]
	if {[llength $ninfo] != 6} {return}
	foreach {what itemId where columnId type name} $ninfo {}
	if {$what eq "item" && $where eq "column"} {
		set parent [$tree item parent $itemId]
		set idata [$tree item element cget $itemId 0 txt -data]
		if {[file isdirectory $idata]} {
			$tree item toggle $itemId
		}
	}
}

proc ::fmeDocView::tree_btn3_click {tree posx posy posX posY} {
	variable wInfo
	set ninfo [$tree identify $posx $posy]
	if {[llength $ninfo] != 6} {return}
	foreach {what itemId where columnId type name} $ninfo {}
	if {$what eq "item" && $where eq "column"} {
		set parent [$tree item parent $itemId]
		set idata [$tree item element cget $itemId 0 txt -data]
		if {[file isfile $idata]} {
			$tree selection clear
			$tree selection add $itemId			
			set m $tree.menu
			if {[winfo exists $m]} {destroy $m}
			menu $m
			$m add command -label [::msgcat::mc "View in new window"] \
				-command [list ::fmeDocView::toplevel_new $idata]
			tk_popup $m $posX $posY
		} 
	}
	return
}
#######################################################
#                                                     #
#                 Public Operations                   #
#                                                     #
#######################################################

proc ::fmeDocView::doc_collapse {} {
	set pw $::crowTde::wInfo(fmeTextArea)
	foreach {x y} [$pw sash coord 0] {}
	while {$y > 0} {
		incr y -50
		if {$y <0} {set y 0}
 		$pw sash place 0 $x $y
 		after 15
 		update
 	}
 	return	
}

proc ::fmeDocView::doc_expand {} {
	set pw $::crowTde::wInfo(fmeTextArea)
	foreach {x y} [$pw sash coord 0] {}
	if {$y > 30} {return}
	while {$y < 160} {
		incr y 20
		if {$y <0} {set y 160}
 		$pw sash place 0 $x $y
 		after 15
 		update
 	}
 	return	
}

proc ::fmeDocView::doc_init {path fpath} {
	variable vars
	variable wInfo
	variable hisList
	variable hisIdx
	variable bookmarks	
	
	set fmeMain [frame $path -bd 0 -relief raised -background "#3e747b"]
	set sw [ScrolledWindow $fmeMain.sw -bd 1 -relief ridge]
	set hv [html [$sw getframe].hv]
	$sw setwidget $hv
	
	set fmeBtn [frame $fmeMain.fmeBtn -bd 1 -relief raised]
	set btnPrev [button $fmeBtn.btnPrev -image [::crowImg::get_image prev] -relief flat \
		-command [list ::fmeDocView::goto_prev $fmeMain]]
	set btnNext [button $fmeBtn.btnNext -image [::crowImg::get_image next] -relief flat\
		-command [list ::fmeDocView::goto_next $fmeMain]]
	set btnTop [button $fmeBtn.btnTop -image [::crowImg::get_image top] -relief flat\
		-command [list $hv yview moveto 0]]		
	set btnHome [button $fmeBtn.btnHome -image [::crowImg::get_image home] -relief flat\
		-command [list ::fmeDocView::goto_home $fmeMain]]
	set txtUrl [entry $fmeBtn.txtUrl -textvariable ::fmeDocView::vars($hv,curr) \
		-state disabled -disabledbackground white -disabledforeground black]
	set btnCol [button $fmeBtn.btnCol -image [::crowImg::get_image collapse_fme] -relief flat\
		-command [list ::fmeDocView::doc_collapse]]
	
	pack $btnPrev $btnNext $btnTop $btnHome -side left -ipadx 3 -ipady 3
	pack $txtUrl -expand 1 -fill both -padx 5 -pady 3 -side left
	#pack $btnCol -ipadx 3 -ipady 3 -side left
	
	foreach btn [list $btnPrev $btnNext $btnTop $btnHome $btnCol] {
		bind $btn <Enter> {%W configure -relief raised}
		bind $btn <Leave> {%W configure -relief flat}
	}
	
	array set tbl [list \
		Prev [::msgcat::mc "Previous"] \
		Next [::msgcat::mc "Next"] \
		Top  [::msgcat::mc "Top"] \
		Home [::msgcat::mc "Home"] \
		Col  [::msgcat::mc "Collapse"]]
	foreach {key} [array names tbl] {
		set btn [set btn$key]
		bind $btn <Enter> {%W configure -relief raised}
		bind $btn <Enter> +[list puts sbar msg $tbl($key)]
		bind $btn <Leave> {%W configure -relief flat}
		DynamicHelp::add $btn -text $tbl($key)
	}	
	
	$hv handler node a [list ::fmeDocView::cmd_a $hv]
	set vars($hv,drag) 0
	bind $hv <Motion> {
		if {$::fmeDocView::vars(%W,drag) == 0} {
			::fmeDocView::check_on_link %W %x %y
		} else {
			set to [%W node -index %x %y]
			if {[llength $to]==2} {
			foreach {node index} $to {}
				%W select to $node $index
			}
			selection own %W
		}
	}
	bind $hv <ButtonRelease-1> {
		set ::fmeDocView::vars(%W,drag) 0
	}
	bind $hv <Leave> {
		. configure -cursor ""
	}
	bind $hv <ButtonPress-1> {
	    	set from [%W node -index %x %y]
	    	if {[llength $from]==2} {
			foreach {node index} $from {}
			%W select from $node $index
			%W select to $node $index
		}
		::fmeDocView::click_on_link %W %x %y
		set ::fmeDocView::vars(%W,drag) 1
	}
	bind $hv <ButtonRelease-3> {
		set sel [::fmeDocView::hv_get_selection %W 0 10000]
		set m %W.menu
		if {[winfo exists $m]} {destroy $m}
		menu $m
		$m add command -label [::msgcat::mc "View in new window"] \
			-command [list ::fmeDocView::toplevel_new $::fmeDocView::vars(%W,curr)]
		if {[string trim $sel] ne ""} {
			$m add separator
			$m add command -label [::msgcat::mc "Copy"] -command [list ::fmeDocView::hv_copy %W $sel]
		}
		tk_popup $m %X %Y
		
	}
	bind $hv <Control-c> {
		set sel [::fmeDocView::hv_get_selection %W 0 10000]
		if {$sel ne ""} {
			::fmeDocView::hv_copy %W $sel
		}
		
	}	
	selection handle $hv [list ::fmeDocView::hv_get_selection $hv]
	set wInfo($fmeMain,hv) $hv
	set wInfo($fmeMain,btnCol) $btnCol
	set vars($hv,home) $fpath
	set vars($hv,pwd) [file dirname $fpath]
	set hisList($hv) ""
	set hisIdx($hv) 0
	::fmeDocView::goto_doc $fmeMain $fpath

	pack $fmeBtn -fill x -padx 2 -pady 2
	pack $sw -expand 1 -fill both -padx 2 -pady 2	

	after idle [list $hv yview moveto 0.01]
	
	return $fmeMain
}

proc ::fmeDocView::goto_doc {widget fpath} {
	variable vars
	variable wInfo
	variable hisList
	variable hisIdx
	variable bookmarks
	set hv $wInfo($widget,hv)
	::fmeDocView::his_put $hv [file join $vars($hv,pwd) $fpath]
	::fmeDocView::goto $hv [file join $vars($hv,pwd) $fpath]
	return
}

proc ::fmeDocView::goto_home {widget} {
	variable vars
	variable wInfo
	set hv $wInfo($widget,hv)
	::fmeDocView::goto $hv $vars($hv,home)
	return
}

proc ::fmeDocView::goto_next {widget} {
	variable hisList
	variable hisIdx
	variable wInfo	
	set hv $wInfo($widget,hv)
	if {$hisIdx($hv) == [expr [llength $hisList($hv)] -1 ]} {return}
	incr hisIdx($hv)
	::fmeDocView::goto $hv [lindex $hisList($hv) $hisIdx($hv)]
	return	
}

proc ::fmeDocView::goto_prev {widget} {
	variable hisList
	variable hisIdx
	variable wInfo	
	set hv $wInfo($widget,hv)
	if {$hisIdx($hv) == 0} {return}
	incr hisIdx($hv) -1
	::fmeDocView::goto $hv [lindex $hisList($hv) $hisIdx($hv)]
	return
}

proc ::fmeDocView::btnCol_hide {widget} {
	variable wInfo
	pack forget $wInfo($widget,btnCol)
	update
}

proc ::fmeDocView::btnCol_show {widget} {
	variable wInfo
	pack $wInfo($widget,btnCol) -ipadx 3 -ipady 3 -side left
}

proc ::fmeDocView::toplevel_new {fpath} {
	variable vars
	variable wInfo		
	set winDoc .crowTde_docView
	for {set i 0} {$i<10000} {incr i} {
		if {![winfo exists $winDoc$i]} {
			set winDoc $winDoc$i
			break
		}
	}
	toplevel $winDoc
	set fmeHv [::fmeDocView::doc_init $winDoc.fmeHv $fpath]
	::fmeDocView::btnCol_hide $fmeHv
	wm title $winDoc [::msgcat::mc "Document Viewer(%s)" $fpath]
	pack $fmeHv -expand 1 -fill both
}


#lappend ::auto_path "./lib" "./lib_unix"
#package require crowImg
#::crowImg::init "./image"
#set bb [::fmeDocView::doc_init .sw "/home/CrowTDE/docs/index.htm"]
#::fmeDocView::btnCol_hide $bb
#pack $bb -expand 1 -fill both
