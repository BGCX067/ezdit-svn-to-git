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


package provide crowNoteBook 1.0
package require treectrl

namespace eval ::crowNoteBook {
	variable wInfo
	array set wInfo [list CrowNoteBook,pages 0]
	variable pageCounter 0
}

proc ::crowNoteBook::crowNoteBook {path args} {
	variable wInfo
	set nb [frame $path -relief ridge -padx 3 -pady 3 -bd 0]
	
	set tree [treectrl $nb.tree \
		-orient horizontal \
		-showroot no \
		-showline no \
		-selectmod single \
		-showrootbutton no \
		-showbuttons no \
		-showheader no \
		-highlightthickness 0 \
		-relief groove \
		-borderwidth 0 \
		-background [. cget -background] \
		-height 24 ]

	$tree column create -tag colHead
	set fNormal [::crowFont::get_font smaller]
	set fBold [font create \
		-family [font configure $fNormal -family] \
		-size [font configure $fNormal -size] \
		-weight bold]
	$tree element create eIcon image \
		-image [list [::crowImg::get_image page_raise] {selected} [::crowImg::get_image page_ridge] {}]
	$tree element create eTitle text -justify center -lines 1 -fill [list #000000 {selected} #646566 {}] -font [list $fBold {selected} $fNormal {}]
	$tree element create eRect rect -outlinewidth 1  -open ns -outline [list #888888 {selected} #cccccc {}]
	
	$tree style create styPage
	$tree style elements styPage {eIcon eTitle eRect}
	$tree style layout styPage eIcon -expand news -padx {5 5} -pady 0
	$tree style layout styPage eTitle -expand news -iexpand news -padx {0 10} -pady 0
	$tree style layout styPage eRect -iexpand news  -union {eIcon eTitle} -padx 0 -ipady 2
	
	$tree notify bind $tree <Selection> [list ::crowNoteBook::page_change $nb %S]

	set lblPrev [label $nb.prev -image [::crowImg::get_image page_prev] -bd 1 -state disabled]
	set lblCurr [label $nb.curr -textvariable ::crowNoteBook::wInfo($tree,curr) -state disabled]
	set lblNext [label $nb.next -image [::crowImg::get_image page_next] -bd 1 -state disabled]
	set lblCancel [label $nb.cancel -image [::crowImg::get_image page_close] -bd 1 -state disabled]
	
	bind $lblNext <ButtonRelease-1> [list ::crowNoteBook::page_raise_next $nb]
	bind $lblNext <ButtonRelease-1> +[list ::crowNoteBook::btn_release $nb %W]
	bind $lblNext <ButtonPress-1> [list ::crowNoteBook::btn_press $nb %W]
	bind $lblNext <Enter> [list ::crowNoteBook::btn_enter $nb %W]
	bind $lblNext <Leave> [list ::crowNoteBook::btn_leave $nb %W]
	
	bind $lblPrev <ButtonRelease-1> [list ::crowNoteBook::page_raise_prev $nb]
	bind $lblPrev <ButtonRelease-1> +[list ::crowNoteBook::btn_release $nb %W]
	bind $lblPrev <ButtonPress-1> [list ::crowNoteBook::btn_press $nb %W]
	bind $lblPrev <Enter> [list ::crowNoteBook::btn_enter $nb %W]
	bind $lblPrev <Leave> [list ::crowNoteBook::btn_leave $nb %W]	
	
	bind $lblCancel <ButtonRelease-1> [list ::crowNoteBook::btnDel_click $nb]
	bind $lblCancel <ButtonRelease-1> +[list ::crowNoteBook::btn_release $nb %W]
	bind $lblCancel <ButtonPress-1> [list ::crowNoteBook::btn_press $nb %W]
	bind $lblCancel <Enter> [list ::crowNoteBook::btn_enter $nb %W]
	bind $lblCancel <Leave> [list ::crowNoteBook::btn_leave $nb %W]
	
	set body [frame $nb.body -bd 0 -relief groove -height 100]
	
	grid $tree -row 0 -column 0 -sticky "news"
	grid $lblPrev -row 0 -column 1 -sticky "news"
	grid $lblCurr -row 0 -column 2 -sticky "news"
	grid $lblNext -row 0 -column 3 -sticky "news"
	grid $lblCancel -row 0 -column 4 -sticky "news"
	grid $body -row 1 -column 0 -columnspan 5 -sticky "news"
	grid rowconfigure $nb 1 -weight 1 
	grid columnconfigure $nb 0 -weight 1 
	
	set wInfo($tree,body) $body
	set wInfo($tree,deleteEvent) ""
	set wInfo($tree,curr) "0/0"
	set wInfo(lblNext) $lblNext
	set wInfo(lblPrev) $lblPrev
	set wInfo(lblCancel) $lblCancel
	set wInfo(lblCurr) $lblCurr
	return $nb
}

proc ::crowNoteBook::btn_enter {nb btn} {
	set tree $nb.tree
	set currItem [$tree selection get]
	if {$currItem eq ""} {
		$btn configure -relief flat -fg #999999
	} else {
		$btn configure -relief raised -fg #222244
	}
	return	
}

proc ::crowNoteBook::btn_leave {nb btn} {
	set tree $nb.tree
	$btn configure -relief flat -fg #999999
}

proc ::crowNoteBook::btn_press {nb btn} {
	set tree $nb.tree
	set relief [$btn cget -relief]
	if {$relief eq "raised"} {
		$btn configure -relief sunken -fg #999999
	}
}

proc ::crowNoteBook::btn_release {nb btn} {
	set tree $nb.tree
	set relief [$btn cget -relief]
	if {$relief eq "sunken"} {
		$btn configure -relief raised -fg #999999
	}
}

proc ::crowNoteBook::btnDel_click {nb} {
	set tree $nb.tree
	set currItem [$tree selection get]
	if {$currItem eq ""} {return}
	set win [$tree item element cget $currItem 0 eTitle -data]
	::crowNoteBook::page_close $nb $win	
	return
}

proc ::crowNoteBook::page_change {nb item} {
	variable wInfo
	if {$item eq ""} {return}
	set tree $nb.tree
	$tree notify bind $tree <Selection> {}
	set body $wInfo($tree,body)
	set win [pack slaves $body]
	if {[winfo exists $win]} {pack forget $win}
	set win [$tree item element cget $item 0 eTitle -data]
	if {[winfo exists $win]} {pack $win -expand 1 -fill both -in $body}
	$tree selection clear
	$tree selection add $item
	$tree see $item
	::crowNoteBook::page_pos_update $nb
	focus $body
	$tree notify bind $tree <Selection> [list ::crowNoteBook::page_change $nb %S]
	return
}

proc ::crowNoteBook::page_scroll_incr {nb} {
	set tree $nb.tree
	$tree xview scroll 1 pages
	return
}

proc ::crowNoteBook::page_scroll_desc {nb} {
	set tree $nb.tree
	$tree xview scroll -1 pages
	return
}

proc ::crowNoteBook::page_pos_update {nb} {
	variable wInfo
	set tree $nb.tree	
	set body $wInfo($tree,body)
	set pages [$tree item children 0]
	if {$pages eq ""} {
		$wInfo(lblNext) configure -state disabled
		$wInfo(lblCurr) configure -state disabled
		$wInfo(lblPrev) configure -state disabled
		$wInfo(lblCancel) configure -state disabled
		set wInfo($tree,curr) "0/0"
		set wInfo(CrowNoteBook,pages) 0
		return
	}
	$wInfo(lblNext) configure -state normal
	$wInfo(lblCurr) configure -state normal
	$wInfo(lblPrev) configure -state normal
	$wInfo(lblCancel) configure -state normal	
	
	set currPage [$tree selection get]
	if {$currPage eq ""} {
		set wInfo($tree,curr) 0/[llength $pages]
		set wInfo(CrowNoteBook,pages) [llength $pages]
		return
	}
	set idx [expr [lsearch $pages $currPage] +1]
	set wInfo($tree,curr) $idx/[llength $pages]
	set wInfo(CrowNoteBook,pages) [llength $pages]
	return
}

############################# 
# 
#############################

proc ::crowNoteBook::page_add {nb title win} {
	variable pageCounter
	set tree $nb.tree
	set item [$tree item create -button no -parent 0]
	$tree item style set $item 0 styPage
	$tree item lastchild 0 $item
	$tree item element configure $item 0 eTitle -text $title -data $win
	incr pageCounter
	::crowNoteBook::page_pos_update $nb
	return $win
}

proc ::crowNoteBook::page_close {nb win} {
	set tree $nb.tree
	set item [::crowNoteBook::page_find $nb $win]
	if {$item eq ""} {return}

	set nextItem [$tree item nextsibling $item]
	if {$nextItem eq ""} {set nextItem [$tree item prevsibling $item]}
	::crowNoteBook::page_delete_event_trigger $nb $win
	destroy $win	
	$tree item delete $item
	if {$nextItem ne ""} {
		::crowNoteBook::page_raise $nb [$tree item element cget $nextItem 0 eTitle -data]
	}
	::crowNoteBook::page_pos_update $nb
	return
}

proc ::crowNoteBook::page_close_all {nb} {
	set tree $nb.tree
	set items [$tree item children 0]
	foreach item $items {
		set win [$tree item element cget $item 0 eTitle -data]
		::crowNoteBook::page_delete_event_trigger $nb $win
		if {[winfo exists $win]} {destroy $win}
		$tree item delete $item
	}
	::crowNoteBook::page_pos_update $nb
	return
}

proc ::crowNoteBook::page_close_curr {nb} {
	set tree $nb.tree
	set currItem [$tree selection get]
	if {$currItem eq ""} {return}
	set win [$tree item element cget $currItem 0 eTitle -data]
	::crowNoteBook::page_close $nb $win
	return		  
}

proc ::crowNoteBook::page_delete_event_add {nb cb} {
	variable wInfo
	set tree $nb.tree
	lappend wInfo($tree,deleteEvent) $cb
}

proc ::crowNoteBook::page_delete_event_trigger {nb win} {
	variable wInfo
	set tree $nb.tree
	foreach cb $wInfo($tree,deleteEvent) {
		eval [concat $cb $nb $win]
	}
}

proc ::crowNoteBook::page_find {nb win} {
	set tree $nb.tree
	set items [$tree item children 0]
	foreach item $items {
		if {[$tree item element cget $item 0 eTitle -data] eq $win} {
			return $item
		}
	}
	return	""
}

proc ::crowNoteBook::page_get {nb} {
	set tree $nb.tree
	set item [$tree selection get]
	if {$item eq ""} {return ""}
	return 	[$tree item element cget $item 0 eTitle -data]
}

proc ::crowNoteBook::page_get_all {nb} {
	set tree $nb.tree
	set items [$tree item children 0]
	set ret ""
	foreach item $items {
		lappend ret [$tree item element cget $item 0 eTitle -data]
	}
	return $ret
}

proc ::crowNoteBook::page_get_title {nb win} {
	set tree $nb.tree
	set item [::crowNoteBook::page_find $nb $win]
	if {$item eq ""} {return}
	return [$tree item element cget $item 0 eTitle -text]	
}

proc ::crowNoteBook::page_raise {nb win} {
	set tree $nb.tree
	set item [::crowNoteBook::page_find $nb $win]
	if {$item eq ""} {return}
	set prevItem [$tree selection get]
	::crowNoteBook::page_change $nb $item	
	return $win
}

proc ::crowNoteBook::page_raise_next {nb} {
	set tree $nb.tree
	set item [$tree selection get]
	if {$item ne ""} {
		set nextItem [$tree item nextsibling $item]
		if {$nextItem eq ""} {
			set nextItem [$tree item firstchild 0]
		}
		::crowNoteBook::page_change $nb $nextItem
		return
	}
	set nextItem [$tree item firstchild 0]
	if {$nextItem ne ""} {::crowNoteBook::page_change $nb $nextItem}
	return
}

proc ::crowNoteBook::page_raise_prev {nb} {
	set tree $nb.tree
	set item [$tree selection get]
	if {$item ne ""} {
		set prevItem [$tree item prevsibling $item]
		if {$prevItem eq ""} {
			set prevItem [$tree item lastchild 0]
		}
		::crowNoteBook::page_change $nb $prevItem
		return
	}
	set prevItem [$tree item firstchild 0]
	if {$prevItem ne ""} {::crowNoteBook::page_change $nb $prevItem}
	return	
}

proc ::crowNoteBook::page_set_title {nb win title} {
	set tree $nb.tree
	set item [::crowNoteBook::page_find $nb $win]
	if {$item eq ""} {return}
	$tree item element configure $item 0 eTitle -text $title
	return $win
}


if {![namespace exists ::crowTde]} {
	namespace eval ::crowTde {}
	lappend ::auto_path "../lib"

	package require crowImg
	package require treectrl
	package require msgcat
	
	::crowImg::init "../image"
	set nb [::crowNoteBook::crowNoteBook ".t" ""]
	for {set i 0} {$i<10} {incr i} {
		::crowNoteBook::page_add $nb "page$i" [button .btn$i -text "button $i"]
	}
	pack $nb -expand 1 -fill x
}


