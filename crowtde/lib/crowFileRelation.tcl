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

package provide crowFileRelation 1.0

package require msgcat
package require Tk
package require BWidget
package require crowImg
package require crowFont
package require crowRC
package require crowMacro

namespace eval ::crowFileRelation {
	variable rcPath ""
	
	variable wInfo
	array set wInfo ""

	variable wVars
	array set wVars ""
	
	variable tblItem
	array set tblItem ""
	
	variable eInfo
	array set eInfo [list currItem ""]
	
	variable sysRelations ""
}

proc ::crowFileRelation::init {} {
	variable rcPath
	set rcPath [file join $::env(HOME) ".CrowTDE" "FileRelation.rc"]
}

proc ::crowFileRelation::get_frame {path} {
	variable wInfo	
	variable tblItem 
	variable rcPath

	array unset tblItem 

	if {[winfo exists $path]} {destroy $path}	
	#set win [Dialog $path]
	
	#set fmeMain [$win getframe]
	set fmeMain [frame $path]

	set msg [::msgcat::mc "File Relation Setting"]
	
	set msgHelp [label $fmeMain.msgHelp -text $msg -bd 2 -relief groove]

	set fmeBody [ScrolledWindow $fmeMain.fmeBody]
	set tree [treectrl $fmeBody.tree \
		-showroot no \
		-linestyle dot \
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
		-bg white \
		-bd 1]

	$tree state define MOUSEOVER 
	
	$tree column create -tag colName -expand 1 -text [::msgcat::mc "File types"] -textpady 3
	$tree element create img image 	-height 24 -width 24 -image \
		[list [::crowImg::get_image file_relation_oitem] {open} [::crowImg::get_image fil_relation_citem] {}]
	$tree element create txt text -fill [list black {selected focus}] -justify left
	$tree element create rect rect -showfocus yes -fill [list #e6e4e4 {selected}]
	$tree element create rect2 rect -showfocus yes -outline black -outlinewidth 0 -fill #ffffcc
	
	$tree element create imgDel image -image [::crowImg::get_image del] -width 24 -height 24
	$tree element create imgSetDefault image -image [::crowImg::get_image file_relation_set_default] -width 24 -height 24
	$tree element create imgDel2 image -image [::crowImg::get_image del] -width 24 -height 24
	
	$tree configure -treecolumn colName
	
	$tree style create styleItem
	$tree style elements styleItem {rect img txt imgSetDefault imgDel}
	$tree style layout styleItem img -padx {0 4} -expand ns
	$tree style layout styleItem txt -padx {0 4} -expand ns
	$tree style layout styleItem imgSetDefault -padx {0 4} -expand nsw
	$tree style layout styleItem imgDel -padx {0 4} -expand ns -ipadx 6
	$tree style layout styleItem rect -union {txt} -iexpand ns -ipadx 2

	$tree style create styleParent
	$tree style elements styleParent {rect2 img txt imgDel2}
	$tree style layout styleParent img -padx {0 4} -expand ns
	$tree style layout styleParent txt -padx {0 4} -expand ns
	$tree style layout styleParent imgDel2 -padx {0 4} -expand nsw -ipadx 6
	$tree style layout styleParent rect2 -iexpand xy -detach yes -sticky news -pady 0
	
	bind $tree <ButtonRelease-3> {::crowFileRelation::btn3_click %x %y %X %Y} 
	bind $tree <ButtonRelease-1> {::crowFileRelation::btn1_click %x %y %X %Y} 
		
	
	$fmeBody setwidget $tree
	
	set fmeEdit [frame $fmeMain.fmeEdit]
	

	set lblExt [label $fmeEdit.lblExt -text [::msgcat::mc "File Extension:"] -anchor w -justify left]
	set txtExt [entry $fmeEdit.txtExt -textvariable ::crowFileRelation::wVar(txtExt) -width 10]
	set lblCmd [label $fmeEdit.lblCmd -text [::msgcat::mc "Application:"] -anchor w -justify left]
	set txtCmd [entry $fmeEdit.txtCmd -textvariable ::crowFileRelation::wVar(txtCmd) -width 30]
	set btnSel [button $fmeEdit.btnSel -text [::msgcat::mc "Browse..."] -command {::crowFileRelation::btnSel_click}]
	set btnAdd [button $fmeEdit.btnAdd -text [::msgcat::mc "Add"] -command {::crowFileRelation::btnAdd_click}]
	
	grid $lblExt -row 0 -column 0 -sticky "we"
	grid $txtExt -row 0 -column 1 -columnspan 3 -sticky "we"
	grid $lblCmd -row 1 -column 0 -sticky "we"
	grid $txtCmd -row 1 -column 1 -sticky "we"
	grid $btnSel -row 1 -column 2
	grid $btnAdd -row 1 -column 3
	
	grid rowconfigure $fmeEdit 0 -weight 1
	grid columnconfigure $fmeEdit 1 -weight 1

	bind $txtCmd <KeyRelease-Return> [list ::crowFileRelation::btnAdd_click]
	
	pack $msgHelp -side top -fill x	
	pack $fmeBody -side top -fill both -expand 1
	pack $fmeEdit -side top -fill x
	
	set tblItem(root) 0
	set wInfo(tree) $tree

	if {[file exists $rcPath]} {
		set fd [open $rcPath r]
		set data [split [string trim [read $fd]] "\n"]
		close $fd
		foreach record $data {
			set key [lindex $record 0]
			set val [lindex $record 1]
			foreach cmd $val {
				::crowFileRelation::add_item $key $cmd
			}
		}
	}

	return $fmeMain

	#$win draw

	
}

proc ::crowFileRelation::btnSel_click {} {
	set ans [tk_getOpenFile -title [::msgcat::mc "Application"] \
		-filetypes [list [list [::msgcat::mc "All"] "*.*"] ]]
	if {[file exists $ans]} {
		set ::crowFileRelation::wVar(txtCmd) $ans
	}
		  
}
proc ::crowFileRelation::btnAdd_click {} {
	set ::crowFileRelation::wVar(txtExt) [string trim [string trimleft $::crowFileRelation::wVar(txtExt)] " ."]
	set ::crowFileRelation::wVar(txtCmd) [string trim $::crowFileRelation::wVar(txtCmd)]
	if {$::crowFileRelation::wVar(txtExt) eq "" || $::crowFileRelation::wVar(txtCmd) eq ""} {return}
	
	::crowFileRelation::add_item $::crowFileRelation::wVar(txtExt) $::crowFileRelation::wVar(txtCmd)
	::crowFileRelation::save
}

proc ::crowFileRelation::add_item {fileExtName cmd} {
	variable wInfo
	variable tblItem
	
	if {[info exists tblItem($fileExtName)]} {
		set parent $tblItem($fileExtName)
	} else {
		set item [$wInfo(tree) item create -button no]
		$wInfo(tree) item style set $item 0 styleParent
		$wInfo(tree) item lastchild $tblItem(root) $item
		$wInfo(tree) item element configure $item 0 img -image [::crowImg::get_image file_relation_citem]
		$wInfo(tree) item element configure $item 0 txt -text $fileExtName -data $cmd
		$wInfo(tree) item element configure $item 0 imgDel2 -image [::crowImg::get_image del] -height 24 -width 24
		$wInfo(tree) item expand $item
		set tblItem($fileExtName) $item	
		set parent $item
		
	}
	set item [$wInfo(tree) item create]
	$wInfo(tree) item style set $item 0 styleItem
	$wInfo(tree) item lastchild $parent $item
	$wInfo(tree) item element configure $item 0 img -image [::crowImg::get_image file_relation_cmd]
	$wInfo(tree) item element configure $item 0 txt -text $cmd -data $cmd
	$wInfo(tree) item collapse $item
}

proc ::crowFileRelation::set_default {itemId} {
	variable wInfo
	variable tblItem
	
	set parent [$wInfo(tree) item parent $itemId]
	set cmd [$wInfo(tree) item element cget $itemId 0 txt -data ]
	
	$wInfo(tree) item element configure $parent  0 txt -data $cmd
	
	set item [$wInfo(tree) item create]
	$wInfo(tree) item style set $item 0 styleItem
	$wInfo(tree) item firstchild $parent $item
	$wInfo(tree) item element configure $item 0 img -image [::crowImg::get_image file_relation_cmd]
	$wInfo(tree) item element configure $item 0 txt -text $cmd -data $cmd
	$wInfo(tree) item collapse $item
	
	$wInfo(tree) item delete $itemId
	::crowFileRelation::save
}

proc ::crowFileRelation::del_item {itemId} {
	variable wInfo
	variable tblItem
	set parent [$wInfo(tree) item parent $itemId]
	if {$parent eq $tblItem(root)} {
		set fileExtName [$wInfo(tree) item element cget $itemId 0 txt -text]
		$wInfo(tree) item delete $itemId
		unset tblItem($fileExtName)
		
	} else {
		set cmd [$wInfo(tree) item element cget $itemId 0 txt -data]
		set firstchild  [$wInfo(tree) item firstchild $parent]
		$wInfo(tree) item delete $itemId
		if {$itemId eq $firstchild} {
			set firstchild  [$wInfo(tree) item firstchild $parent]
			#puts fchild=$firstchild
			if {$firstchild eq ""} {
				set fileExtName [$wInfo(tree) item element cget $parent 0 txt -text]
				$wInfo(tree) item delete $parent
				unset tblItem($fileExtName)
			} else {
				set default [$wInfo(tree) item element cget $firstchild 0 txt -data]
				$wInfo(tree) item element configure $parent 0 txt -data $default
			}
		}
	}
	::crowFileRelation::save
}

proc ::crowFileRelation::btn1_click {posx posy posX posY } {
	variable wInfo
	variable eInfo
	variable tblItem
	
	set ninfo [$wInfo(tree) identify $posx $posy]
	if {[llength $ninfo] != 6} {return}
	foreach {what itemId where columnId type name} $ninfo {}
	if {$what eq "item"} {
		$wInfo(tree) selection modify $itemId all
	}
	if {$what eq "item" && $where eq "column"} {
		set item [lindex $ninfo 1]
		set parent [$wInfo(tree) item parent $itemId]
		if {$parent == 0} {
			$wInfo(tree) toggle $itemId
			set eInfo(currItem) ""
		}
	}
	if {([llength $ninfo]==6) && $name ne ""} {
		if {$name eq "imgSetDefault"} {
			::crowFileRelation::set_default $itemId
		} elseif {$name eq "imgDel" || $name eq "imgDel2"} {
			after idle [list ::crowFileRelation::del_item $itemId]
		}
	}
}

proc ::crowFileRelation::btn3_click {posx posy posX posY } {
	variable wInfo
	variable tblItem
	
	set ninfo [$wInfo(tree) identify $posx $posy]
	if {[llength $ninfo] != 6} {return}
	foreach {what itemId where columnId type name} $ninfo {}
	if {$what eq "item"} {
		$wInfo(tree) selection modify $itemId all
	}
	if {$what eq "item" && $where eq "column"} {
		set item [lindex $ninfo 1]
		set parent [$wInfo(tree) item parent $itemId]
		::crowFileRelation::post_menu $posX $posY
	}
}

proc ::crowFileRelation::post_menu {X Y} {
	variable wInfo	
	variable tblItem
	
	set itemId [::crowFileRelation::get_curr_item]
	
	if {[winfo exists $wInfo(tree).itemMenu]} {destroy $wInfo(tree).itemMenu}
	set mMain [menu $wInfo(tree).itemMenu -tearoff 0]
	if {[$wInfo(tree) item parent $itemId] ne $tblItem(root)} {
		$mMain add command -compound left -label [::msgcat::mc "Setting default"] \
			-image [::crowImg::get_image file_relation_set_default] \
			-command  [list ::crowFileRelation::set_default $itemId]		
	}
	$mMain add command -compound left -label [::msgcat::mc "Remove"] \
		-image [::crowImg::get_image del] \
		-command  [list ::crowFileRelation::del_item $itemId]
	
	tk_popup $mMain $X $Y
	
}

proc ::crowFileRelation::get_curr_item {} {
	variable wInfo
	return [$wInfo(tree) selection get]
}  

proc ::crowFileRelation::get_relation {fileExtName} {
	variable rcPath
	
	if {![file exists $rcPath]} {return ""}
	
	set fd [open $rcPath r]
	set data [split [string trim [read $fd]] "\n"]
	close $fd
	
	foreach record $data {
		set key [lindex $record 0]
		set val [lindex $record 1]
		if {$key eq $fileExtName} {
			return $val
		}
	}
	return ""
}

proc ::crowFileRelation::set_relation {fileExtName cmdlist} {
	variable rcPath
	set tbl ""	
	if {![file exists $rcPath]} {return ""}
	
	set fd [open $rcPath r]
	set data [split [string trim [read $fd]] "\n"]
	close $fd
	foreach {key val} $data {
		set tbl($key) $val
	}
	set tbl($fileExtName) $cmdlist
	set fd [open $rcPath w]
	foreach key [array names $tbl] {
		puts $fd [list $key $tbl($key)]
	}	
	close $fd	
	return ""
}

proc ::crowFileRelation::save {} {
	variable wInfo
	variable tblItem
	variable rcPath
	set fd [open $rcPath w]
	foreach extName [$wInfo(tree) item children $tblItem(root)] {
		set cmds [$wInfo(tree) item children $extName]
		if {$cmds eq ""} {continue}
		set ext [$wInfo(tree) item element cget $extName 0 txt -text]
		set default [$wInfo(tree) item element cget $extName 0 txt -data]
		#puts default=$default
		set cmdlist [list $default]
		set cmds [lrange $cmds 1 end]
		foreach cmd $cmds {
			lappend cmdlist [$wInfo(tree) item element cget $cmd 0 txt -data]
		}
		if {[string trim $cmdlist] ne ""} {
			puts $fd [list $ext $cmdlist]
		}
	}
	close $fd
}
::crowFileRelation::init

