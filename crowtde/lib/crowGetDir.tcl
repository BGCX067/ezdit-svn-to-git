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

package provide crowGetDir 1.0
package require msgcat
package require treectrl
package require BWidget
package require crowImg
package require inputDlg

namespace eval ::crowGetDir {
	variable wInfo
	array set wInfo ""
	variable sel
	array set sel ""
}

proc ::crowGetDir::btnNew_click {} {
	variable wInfo
	variable vars
	if {![file exists $vars(sel)]} {
		tk_messageBox -icon error -title [::msgcat::mc "Error"] -type ok \
			-message [::msgcat::mc "Choose Folder First!"]
		return
	}
	set dir [::inputDlg::show .crowTDE_inputDlg_ [::msgcat::mc "New Folder"] ""]
	foreach {btn dir} $dir {break}
	if {$btn eq "CANCEL" || $btn eq "-1" || [string trim $dir] eq ""} {return}
	set dir [file join $vars(sel) $dir]
	if {[file exists $dir]} {
		tk_messageBox -title [::msgcat::mc "Error"] -icon error -type ok \
			-message [::msgcat::mc "Folder Already Exists!"] 	
		return
	}
	file mkdir $dir
	set item [$wInfo(tree) selection get]
	if {$item eq ""} {set item $wInfo(rootNode)}
	::crowGetDir::item_scan $item
}

proc ::crowGetDir::item_scan {item} {
	variable wInfo
	set tree $wInfo(tree)
	set dpath [$tree item element cget $item 0 txt -data]
	foreach c [$tree item children $item] {$tree item delete $c}
	set dlist [lsort -dictionary [glob -nocomplain -directory $dpath -types {d} -- *]]

	foreach d $dlist {
		set subItem [::crowGetDir::tree_item_add $item $d [::crowImg::get_image "cfolder"]]
		::crowGetDir::item_scan $subItem
	}
}

proc ::crowGetDir::tree_btn1_dclick {posx posy} {
	variable wInfo
	set tree $wInfo(tree)	
	set ninfo [$tree identify $posx $posy]
	if {[llength $ninfo] != 6} {return}
	foreach {what itemId where columnId type name} $ninfo {}
	if {$what eq "item" && $where eq "column"} {
		set parent [$tree item parent $itemId]
		set idata [$tree item element cget $itemId 0 txt -data]
		if {![file exists $idata]} {
			tk_messageBox -type ok -title [::msgcat::mc "Error"] \
				-message [::msgcat::mc "'%s' has been deleted from the file system!" [file tail $idata]]
			after idle [list ::crowGetDir::tree_item_del $itemId]
			return
		}
		$tree item toggle $itemId
		set vars(sel) $idata
	}
}

proc ::crowGetDir::tree_item_add {parent fpath img} {
	variable wInfo
	set tree $wInfo(tree)
	set item [$tree item create -button no]
	$tree item configure $item -button yes
	$tree item style set $item 0 style
	$tree item lastchild $parent $item
	$tree item element configure $item 0 img -image $img
	set tail [file tail $fpath]
	if {$tail eq ""} {set tail $fpath}
	$tree item element configure $item 0 txt -text $tail -data $fpath
	$tree item collapse $item
	return $item
}

proc ::crowGetDir::show {path initDir} {
	variable wInfo
	variable vars
	
	Dialog $path -title [::msgcat::mc "Choose Direcotry"] -modal local
	set fmeMain [$path getframe]
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
		-bd 1]
	$tree column create -tag colFile -expand yes
	$tree element create img image -height 24 -width 24 -image \
		[list [::crowImg::get_image ofolder] {open} [::crowImg::get_image cfolder] {}]
	$tree element create txt text -fill [list black {selected focus}] -justify left
	$tree element create rect rect -showfocus yes -fill [list #e6e4e4 {selected}]
	
	$tree configure -treecolumn colFile
	
	$tree style create style
	$tree style elements style {rect img txt}
	$tree style layout style img -padx {0 4} -expand ns
	$tree style layout style txt -padx {0 4} -expand ns
	$tree style layout style rect -union {txt} -iexpand ns -ipadx 2

	$tree notify bind $tree <Selection> {
		if {%S ne ""} {
			set ::crowGetDir::vars(sel) [%W item element cget %S 0 txt -data]
		}
	}

	$fmeBody setwidget $tree
	
	set lblSel [label $fmeMain.lblSel -anchor w -justify left -textvariable ::crowGetDir::vars(sel)]
	set fmeBtn [frame $fmeMain.fmeBtn]
	set btnNew [button $fmeBtn.btnNew -width 10 -command {::crowGetDir::btnNew_click} -text [::msgcat::mc "New Folder"]]
	set btnOk [button $fmeBtn.btnOk -width 10 -command [list $path enddialog "Ok"] -text [::msgcat::mc "Ok"]]
	set btnCancel [button $fmeBtn.btnCancel -width 10 -command [list $path enddialog "Cancel"] -text [::msgcat::mc "Cancel"]]
	pack $btnNew $btnOk $btnCancel -padx 5 -pady 2 -side left
	
	pack $lblSel -fill x -side top
	pack $fmeBody -expand 1 -fill both -side top -pady 5
	pack $fmeBtn -fill x -side top 
	
	set wInfo(tree) $tree
	set wInfo(dialog) $path
	
	set item [::crowGetDir::tree_item_add 0 $initDir [::crowImg::get_image "cfolder"]]
	set wInfo(rootNode) $item
	$tree selection add $item
	::crowGetDir::item_scan $item
	set vars(sel) $initDir
	set ret [$path draw]
	set dir ""
	if {$ret eq "Ok"} {
		set dir $vars(sel)
	}
	destroy $path
	return $dir
}
