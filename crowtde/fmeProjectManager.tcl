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

namespace eval ::fmeProjectManager {
	variable prjInfo
	array set prjInfo ""

	variable nodeInfo
	array set nodeInfo ""

	variable wInfo
	array set wInfo ""
	
	variable cpBuf
	array set cpBuf [list file "" flag ""]
	
	variable vars
	array set vars ""
	
	variable hooks
	array set hooks [list TOP "" DEFAULT "" BOTTOM ""]

}

#######################################################
#                                                     #
#                 Private Operations                  #
#                                                     #
#######################################################

proc ::fmeProjectManager::item_scan {item} {
	variable wInfo
	set tree $wInfo(tree)
	set dpath [$tree item element cget $item 0 txt -data]
	set flist [lsort -dictionary [glob -nocomplain -directory $dpath -types {f} -- *]]
	foreach f $flist {
		if {[string range [file tail $f] 0 2] eq ".__"} {continue}
		set ext [string range [file extension $f] 1 end]
		::fmeProjectManager::tree_item_add $item $f [::crowImg::get_image "mime_$ext"]
	}
	set dlist [lsort -dictionary [glob -nocomplain -directory $dpath -types {d} -- *]]

	foreach d $dlist {
		if {[string range [file tail $d] 0 2] eq ".__"} {continue}
		set subItem [::fmeProjectManager::tree_item_add $item $d [::crowImg::get_image "cfolder"]]
		::fmeProjectManager::item_scan $subItem
	}
}

proc ::fmeProjectManager::mk_new_item_menu {parent} {
	variable wInfo
	set tree $wInfo(tree)
	
	set item [::fmeProjectManager::get_curr_item]
	set fpath [::fmeProjectManager::get_curr_file]
	if {$item eq ""} {return $parent}
	$parent add command -compound left -label [::msgcat::mc "Folder"] \
		-image [::crowImg::get_image new_folder] \
		-command [list ::fmeProjectManager::item_mkdir $item]
	$parent add separator
	
	set templs [::crowTemplate::item_ls]
	
	foreach t $templs {
		array set templ $t
		if {$templ(image) eq ""} {
			$parent add command -compound left -label $templ(name) \
				-command [list ::fmeProjectManager::item_add $item $templ(path)]		
		} else {
			$parent add command -compound left -label $templ(name) \
				-image [::crowImg::get_image $templ(image)] \
				-command [list ::fmeProjectManager::item_add $item $templ(path)]
		}
		array unset templ
	}
	
	$parent add separator
	$parent add command -compound left -label [::msgcat::mc "Others..."] \
		-command [list ::fmeProjectManager::item_import $item]
	return $parent	
}

proc ::fmeProjectManager::mk_folder_menu {parent} {
	variable wInfo
	variable cpBuf
	variable hooks
	set tree $wInfo(tree)
	
	set item [::fmeProjectManager::get_curr_item]
	set fpath [$tree item element cget $item 0 txt -data]
	
	foreach fun $hooks(TOP) {$fun $tree $item $fpath $parent}
	if {$hooks(TOP) ne ""} {$parent add separator}	
	
	set mNew [menu $parent.mNew -tearoff 0]
	::fmeProjectManager::mk_new_item_menu $mNew
	$parent add cascade -compound left -label [::msgcat::mc "New Item"] -menu $mNew
	$parent add separator
	$parent add command -compound left -label [::msgcat::mc "Build..."] \
		-command [list ::fmeProjectManager::wrap_dir $fpath]
	
	if {$hooks(DEFAULT) ne ""} {$parent add separator}
	foreach fun $hooks(DEFAULT) {$fun $tree $item $fpath $parent}
			
	if {$item ne $::fmeProjectManager::nodeInfo(root)} {
		$parent add separator
		$parent add command -compound left -label [::msgcat::mc "Cut"] \
			-command [list ::fmeProjectManager::item_cut $item]
			
		$parent add command -compound left -label [::msgcat::mc "Copy"] \
			-command [list ::fmeProjectManager::item_copy $item]
		if {$cpBuf(file) ne ""} {
			$parent add command -compound left -label [::msgcat::mc "Paste"] \
				-command [list ::fmeProjectManager::item_paste $item]
		} else {
			$parent add command -compound left -label [::msgcat::mc "Paste"] \
				-state disabled \
				-command [list ::fmeProjectManager::item_paste $item]		
		}					
		$parent add command -compound left -label [::msgcat::mc "Delete"] \
			-image [::crowImg::get_image del] \
			-command [list ::fmeProjectManager::item_del $item]
		$parent add separator
		$parent add command -compound left -label [::msgcat::mc "Rename"] \
			-accelerator "F2" \
			-command [list ::fmeProjectManager::item_rename $item ""]			
	} else {
		$parent add separator
		$parent add command -compound left -label [::msgcat::mc "Save Project.."] \
			-image [::crowImg::get_image save_all] \
			-command {::fmeProjectManager::project_save}
		$parent add command -compound left -label [::msgcat::mc "Close Project"] \
			-command {::fmeProjectManager::project_close}
		$parent add separator
	
		$parent add command -compound left -label [::msgcat::mc "Project Properties..."] \
			-image [::crowImg::get_image project_properties] \
			-command {::frmProjectProperty::show ".frmProjectProperty"}
	}
	$parent add separator
	if {$cpBuf(file) ne ""} {
		$parent add command -compound left -label [::msgcat::mc "Paste"] \
			-command [list ::fmeProjectManager::item_paste $item]
	} else {
		$parent add command -compound left -label [::msgcat::mc "Paste"] \
			-state disabled \
			-command [list ::fmeProjectManager::item_paste $item]		
	}
	$parent add separator
	$parent add command -compound left -label [::msgcat::mc "File Properties..."] \
		-command [list ::crowFileProperties::show ".crowFileProperties" $fpath]
	$parent add separator
	$parent add command -compound left -label [::msgcat::mc "refresh"] \
		-image [::crowImg::get_image refresh] \
		-command [list ::fmeProjectManager::item_refresh $item]
		
	if {$hooks(BOTTOM) ne ""} {$parent add separator}
	foreach fun $hooks(BOTTOM) {$fun $tree $item $fpath $parent}
			
	return $parent
}

proc ::fmeProjectManager::mk_file_menu {parent} {
	variable wInfo
	variable cpBuf
	variable hooks
	set tree $wInfo(tree)
	
	set item [::fmeProjectManager::get_curr_item]	
	set fpath [$tree item element cget $item 0 txt -data]
	set ext [string trimleft [file extension $fpath] "."]
	set extAps [::crowFileRelation::get_relation $ext]
	
	foreach fun $hooks(TOP) {$fun $tree $item $fpath $parent}
	if {$hooks(TOP) ne ""} {$parent add separator}
	
	$parent add command -compound left -label [::msgcat::mc "Edit"] \
		-command [list ::fmeProjectManager::file_open $fpath]
	if {$extAps ne ""} {
		set ap [lindex $extAps 0]
		$parent add command -compound left -label [::msgcat::mc "%s Open" [file tail $ap]] \
			-image [::crowImg::get_image edit] \
			-command [list ::crowExec::run_ap $ap $fpath]
	}
	
	# <-
	if {[winfo exists $parent.extMenu]} {destroy $parent.extMenu}
	set extMenu [menu $parent.extMenu -tearoff 0]
	$parent add separator
	$parent add cascade -compound left -label [::msgcat::mc "Open"] \
		-menu $extMenu
	if {$extAps ne "" && $extAps ne "crowEditor"} {
		foreach ap $extAps {
			if {$ap eq "crowEditor"} {
				$extMenu add command -compound left -label [file tail $ap] \
					-command [list ::fmeProjectManager::file_open $fpath]
			} else {
				$extMenu add command -compound left -label [file tail $ap] \
					-command [list ::crowExec::run_ap $ap $fpath]
			}
		}
		$extMenu add separator
	}
	$extMenu add command -compound left -label  [::msgcat::mc "Others..."] \
		-command [list ::fmeProjectManager::run_ap_with $fpath]
	# ->
	
	if {$hooks(DEFAULT) ne ""} {$parent add separator}
	foreach fun $hooks(DEFAULT) {$fun $tree $item $fpath $parent}	
	
	#puts ext=$ext
	switch -exact -- [string tolower $ext] {
		"tcl" {
			# copy paste delete
			$parent add separator
			set interp [::fmeProjectManager::get_project_interpreter]

			#$parent add command -compound left -label [::msgcat::mc "Check Syntax*"] \
			#	-image [::crowImg::get_image chk_syntax] \
			#	-command {} 
			$parent add command -compound left -label [::msgcat::mc "Run..."] \
				-image [::crowImg::get_image run] \
				-command [list ::crowExec::run_script $interp $fpath]
			$parent add command -compound left -label [::msgcat::mc "Debug..."] \
				-command [list ::fmeDebugger::start $fpath]		
			set prjPath [::fmeProjectManager::get_project_path]
			set mainScript [string range $fpath [expr [string length $prjPath]+1] end]
			#puts mainScript=$mainScript
			$parent add command -compound left -label [::msgcat::mc "Syntax Check..."] \
				-image [::crowImg::get_image syntax_check] \
				-command [list ::fmeNagelfar::check $fpath]			
			$parent add command -compound left -label [::msgcat::mc "Set As Default Script"] \
				-command [list ::fmeProjectManager::set_project_mainScript $mainScript]
				
#			$parent add separator
			$parent add command -compound left -label [::msgcat::mc "Build..."] \
				-command [list ::crowSdx::wrap_file $fpath]
	

		}
		default {}
	}
	
	$parent add separator
	$parent add command -compound left -label [::msgcat::mc "Cut"] \
		-command [list ::fmeProjectManager::item_cut $item]
		
	$parent add command -compound left -label [::msgcat::mc "Copy"] \
		-command [list ::fmeProjectManager::item_copy $item]
	if {$cpBuf(file) ne ""} {
		$parent add command -compound left -label [::msgcat::mc "Paste"] \
			-command [list ::fmeProjectManager::item_paste $item]
	} else {
		$parent add command -compound left -label [::msgcat::mc "Paste"] \
			-state disabled \
			-command [list ::fmeProjectManager::item_paste $item]		
	}
	$parent add command -compound left -label [::msgcat::mc "Delete"] \
		-image [::crowImg::get_image del] \
		-command [list ::fmeProjectManager::item_del $item]
	$parent add separator
	$parent add command -compound left -label [::msgcat::mc "Rename"] \
		-accelerator "F2" \
		-command [list ::fmeProjectManager::item_rename $item ""]			
		
	$parent add separator
	$parent add command -compound left -label [::msgcat::mc "File Properties..."] \
		-command [list ::crowFileProperties::show ".crowFileProperties" $fpath]
		
	if {$hooks(BOTTOM) ne ""} {$parent add separator}
	foreach fun $hooks(BOTTOM) {$fun $tree $item $fpath $parent}
	return $parent
}

proc ::fmeProjectManager::post_folder_menu {X Y} {
	variable wInfo
	set tree $wInfo(tree)	
	set item [::fmeProjectManager::get_curr_item]	

	if {[winfo exists $tree.folderMenu]} {destroy $tree.folderMenu}
	set mMain [menu $tree.folderMenu -tearoff 0]
	::fmeProjectManager::mk_folder_menu $mMain
	tk_popup $mMain $X $Y
}

proc ::fmeProjectManager::post_file_menu {X Y} {
	variable wInfo
	set tree $wInfo(tree)	
	set item [::fmeProjectManager::get_curr_item]	

	if {[winfo exists $tree.fileMenu]} {destroy $tree.fileMenu}
	set mMain [menu $tree.fileMenu -tearoff 0]
	::fmeProjectManager::mk_file_menu $mMain
	tk_popup $mMain $X $Y
}

proc ::fmeProjectManager::project_init {prjPath} {
	if {![file exists [file join $prjPath ".__meta__"]]} {file mkdir [file join $prjPath ".__meta__"]}
	set rc [file join $prjPath ".__meta__" "project.rc"]
	::crowRC::param_set $rc interpreter ""
	::crowRC::param_set $rc mainScript ""
	return
}

proc ::fmeProjectManager::property_load {prjPath} {
	variable prjInfo
	set rc [file join $prjPath ".__meta__" "project.rc"]
	::crowRC::param_get_all $rc prjInfo
	set prjInfo(workspace) [file dirname $prjPath]
	set prjInfo(name) [file tail $prjPath]
	set prjInfo(path) $prjPath
	return
}

proc ::fmeProjectManager::property_get {key} {
	variable prjInfo
	if {[info exists prjInfo($key)]} {return $prjInfo($key)}
	return ""
}

proc ::fmeProjectManager::property_set {key val} {
	variable prjInfo
	if {![info exists prjInfo(name)]} {return}
  	set prjPath [file join $prjInfo(workspace) $prjInfo(name)]
  	set rc [file join $prjPath ".__meta__" project.rc]
  	::crowRC::param_set $rc $key $val
  	set prjInfo($key) $val
	return
}

proc ::fmeProjectManager::run_ap_with {fname} {
	set ret [tk_getOpenFile -filetypes [list [list {All} {*}]] -title [::msgcat::mc "Open As..."]]
	if {$ret eq ""} {return}
	::crowExec::run_ap $ret [list $fname]
}

proc ::fmeProjectManager::tree_init {path} {
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
		[list [::crowImg::get_image ofolder] {open} [::crowImg::get_image cfolder] {}]
	$tree element create txt text -fill [list black {selected focus}] -justify left
	$tree element create rect rect -showfocus yes -fill [list #e6e4e4 {selected}]
	
	$tree configure -treecolumn colFileTree
	
	$tree style create style
	$tree style elements style {rect img txt}
	$tree style layout style img -padx {0 4} -expand ns
	$tree style layout style txt -padx {0 4} -expand ns
	$tree style layout style rect -union {txt} -iexpand ns -ipadx 2
	
	$tree notify install <Edit-begin>
	$tree notify install <Edit-accept>
	$tree notify install <Edit-end>
	
	TreeCtrl::SetEditable $tree {{colFileTree style txt}}
	#TreeCtrl::SetSensitive $tree {{colFileTree style rect img txt}}
	#TreeCtrl::SetDragImage $tree {{}}
	#TreeCtrl::SetDragImage $tree {{colFileTree style rect img}}
		
	$tree notify bind $tree <Edit-begin> {%T item element configure %I %C rect -draw no + txt -draw no}
	$tree notify bind $tree <Edit-accept> {
		set t1 [%T item element cget %I %C txt -text]
		set t2 %t
		if {$t1 ne $t2} {::fmeProjectManager::item_rename %I $t2}
	}
	$tree notify bind $tree <Edit-end> {
		if {[%T item id %I] ne ""} {
			%T item element configure %I %C rect -draw yes + txt -draw yes
		}
	}	
	#bindtags $tree [list $tree TreeCtrlFileList TreeCtrl]
	#set ::TreeCtrl::Priv(DirCnt,$tree) 1
		
	bind $tree <Double-Button-1> {::fmeProjectManager::tree_btn1_dclick %x %y} 
	bind $tree <Button-1> {::fmeProjectManager::tree_btn1_click %x %y} 
	bind $tree <ButtonRelease-3> {::fmeProjectManager::tree_btn3_click %x %y %X %Y} 
	
	bind $tree <F2> {
		set tree $::fmeProjectManager::wInfo(tree)
		set item [$tree selection get]
		if {$item ne ""} {::TreeCtrl::FileListEdit $tree $item colFileTree txt}
	}
	
	$fmeBody setwidget $tree
	
	pack $fmeBody -side top -fill both -expand 1
	
	set wInfo(tree) $tree

	return $fmeMain
}

#
# events
# 

proc ::fmeProjectManager::tree_btn1_click {posx posy} {
	variable wInfo
	set tree $wInfo(tree)
	set ninfo [$tree identify $posx $posy]
	if {[llength $ninfo] != 6} {return}
	foreach {what itemId where columnId type name} $ninfo {}
	if {$what eq "item" && $where eq "column"} {
		set parent [$tree item parent $itemId]
		set idata [$tree item element cget $itemId 0 txt -data]
		
		if {[file isfile $idata]} {
			set fname [$tree item element cget $itemId 0 txt -data]
			::fmeTabEditor::file_raise $fname
			after 100 [list focus $tree]
		} 
	}
}

proc ::fmeProjectManager::tree_btn1_dclick {posx posy} {
	variable wInfo
	set tree $wInfo(tree)
	#puts tree=$tree	
	set ninfo [$tree identify $posx $posy]
	if {[llength $ninfo] != 6} {return}
	foreach {what itemId where columnId type name} $ninfo {}
	if {$what eq "item" && $where eq "column"} {
		set parent [$tree item parent $itemId]
		set idata [$tree item element cget $itemId 0 txt -data]
		if {![file exists $idata]} {
			tk_messageBox -type ok -title [::msgcat::mc "Error"] \
				-message [::msgcat::mc "'%s' has been deleted from the file system!" [file tail $idata]]
			after idle [list ::fmeProjectManager::tree_item_del $itemId]
			return
		}
		if {[file isdirectory $idata]} {
			$tree item toggle $itemId
		} else {
			set fpath [$tree item element cget $itemId 0 txt -data]
			set ext [string trimleft [file extension $fpath] "."]
			set extAps [::crowFileRelation::get_relation $ext]
			#::fmeProjectManager::run_ap $fname
			if {$extAps eq "" || $extAps eq "crowEditor"} {
				::fmeProjectManager::file_open $fpath
			} else {
				set ap [lindex $extAps 0]
				if {$ap eq "crowEditor"} {
					::fmeProjectManager::file_open $fpath	
				} else {
					::crowExec::run_ap $ap $fpath
				}
			}
			after 100 [list focus $tree]
		} 
	}
}

proc ::fmeProjectManager::tree_btn3_click {posx posy posX posY} {
	variable wInfo
	set tree $wInfo(tree)
	set ninfo [$tree identify $posx $posy]
	if {[llength $ninfo] != 6} {return}
	foreach {what itemId where columnId type name} $ninfo {}
	if {$what eq "item"} {
		$tree selection modify $itemId all
	}
	if {$what eq "item" && $where eq "column"} {
		set item [lindex $ninfo 1]
		set parent [$tree item parent $itemId]
		set idata [$tree item element cget $item 0 txt -data]
		if {[file isdirectory $idata]} {
			::fmeProjectManager::post_folder_menu $posX $posY
		} else {
			::fmeProjectManager::post_file_menu $posX $posY
		}
	}
}

proc ::fmeProjectManager::tree_item_add {parent fpath img} {
	variable wInfo
	set tree $wInfo(tree)
	set item [$tree item create -button no]
	if {[file isdirectory $fpath]} {$tree item configure $item -button yes}
	$tree item style set $item 0 style
	$tree item lastchild $parent $item
	$tree item element configure $item 0 img -image $img
	$tree item element configure $item 0 txt -text [file tail $fpath] -data $fpath
	$tree item collapse $item
	return $item
}

proc ::fmeProjectManager::tree_item_del {item} {
	variable wInfo
	set tree $wInfo(tree)
	foreach c [$tree item children $item] {::fmeProjectManager::tree_item_del $c }
	set fpath [$tree item element cget $item 0 txt -data]
	file delete -force $fpath
	$tree item delete $item
}

#######################################################
#                                                     #
#                  Public Operations                  #
#                                                     #
#######################################################

#proc ::fmeProjectManager::syntax_check_nagelfar {fpath} {
#	set ipChkSyntax [interp create]
#	$ipChkSyntax eval source [file join $::crowTde::appPath "lib" "nagelfar.tcl"]
#	set ret [$ipChkSyntax eval synCheck $fpath [file join $::crowTde::appPath "lib" "syntaxdb.tcl"]]
#	::fmeTaskMgr::nagelfar_show
#	foreach item $ret {
#		if {[string range $item 0 3] eq "Line"} {
#			set line [string trim [lindex $item 1] ":"]
#			set type [lindex $item 2]
#			switch -- $type {
#				W {set color "blue"}
#				E {set color "red"}
#				default {set color ""}
#			}
#			::fmeNagelfar::put_lmsg $item $fpath $line 0 $color
#		}
#	}
#	interp delete $ipChkSyntax
#}

proc ::fmeProjectManager::file_open {fpath} {
	if {![file exists $fpath]} {
		tk_messageBox -title [::msgcat::mc "Error"] -message [::msgcat::mc "'%s' not exists!" $fpath] -icon error
		return
	}
	::crowRecently::push_file $fpath
	::fmeTabEditor::file_open $fpath
}

proc ::fmeProjectManager::get_curr_item {} {
	variable wInfo
	set tree $wInfo(tree)
	return [$tree selection get]
}

proc ::fmeProjectManager::get_curr_directory_item {} {
	variable wInfo
	set tree $wInfo(tree)
	set item [::fmeProjectManager::get_curr_item]
	if {$item eq ""} {set item [$tree item firstchild 0]}
	set dir [::fmeProjectManager::get_curr_file]
	if {[file isfile $dir]} {
		set dir [file dirname $dir]
		set item [$tree item parent $item]
	}
	return $item
}

proc ::fmeProjectManager::get_curr_file {} {
	variable wInfo
	set tree $wInfo(tree)	
	set item [::fmeProjectManager::get_curr_item]
	if {$item eq ""} {return ""}
	return [$tree item element cget $item 0 txt -data]
}

proc ::fmeProjectManager::get_project_path {} {
	variable prjInfo
	if {[info exists prjInfo(path)]} {return $prjInfo(path)}
	return ""	
}

proc ::fmeProjectManager::hook_insert {pos cb_fun} {
	variable hooks
	lappend hooks($pos) $cb_fun
}

proc ::fmeProjectManager::init {path} {
	interp alias {} ::fmeProjectManager::get_project_path {} ::fmeProjectManager::property_get path
	interp alias {} ::fmeProjectManager::get_project_interpreter {} ::fmeProjectManager::property_get interpreter
	interp alias {} ::fmeProjectManager::get_project_mainScript {} ::fmeProjectManager::property_get mainScript
	interp alias {} ::fmeProjectManager::set_project_path {} ::fmeProjectManager::property_set path
	interp alias {} ::fmeProjectManager::set_project_interpreter {} ::fmeProjectManager::property_set interpreter
	interp alias {} ::fmeProjectManager::set_project_mainScript {} ::fmeProjectManager::property_set mainScript
	return [::fmeProjectManager::tree_init $path]
}

proc ::fmeProjectManager::item_add {item templ} {
	variable wInfo
	set tree $wInfo(tree)
	
	set parentPath [$tree item element cget $item 0 txt -data]
	set width [expr [string length $parentPath] + 15]
	set fname [::inputDlg::show $tree.ibox [::msgcat::mc "Location : %s" $parentPath] "" -width $width]
	foreach {btn fname} $fname {break}
	if {$btn eq "CANCEL" || $btn eq "-1" || [string trim $fname] eq ""} {return}	
	set fpath [file join $parentPath $fname]
	if {[file exists $fpath]} {
		tk_messageBox -title [::msgcat::mc "Error"] -icon error -type ok \
			-message [::msgcat::mc "'%s' already exists!" [file tail $fpath]]
		return
	}

	::crowTemplate::item_eval $templ $fpath

	set ext [string range [file extension $fpath] 1 end]
	::fmeProjectManager::tree_item_add $item $fpath [::crowImg::get_image "mime_$ext"]
	::fmeProjectManager::item_refresh $item
	return $fpath
}

proc ::fmeProjectManager::item_copy {item} {
	variable wInfo
	variable cpBuf
	set tree $wInfo(tree)
	set cpBuf(item) $item
	set cpBuf(file) [$tree item element cget $item 0 txt -data]
	set cpBuf(flag) "COPY"
	puts sbar msg [::msgcat::mc "Copied %s" [file tail $cpBuf(file)]]
	return
}

proc ::fmeProjectManager::item_cut {item} {
	variable wInfo
	variable cpBuf
	set tree $wInfo(tree)
	set cpBuf(item) $item
	set cpBuf(file) [$tree item element cget $item 0 txt -data]
	set cpBuf(flag) "CUT"
	puts sbar msg [::msgcat::mc "Cut %s" [file tail $cpBuf(file)]]
	return
}

proc ::fmeProjectManager::item_del {item} {
	variable wInfo
	set tree $wInfo(tree)
	set fpath [$tree item element cget $item 0 txt -data]
	set msg [::msgcat::mc "Are you sure you want to delete '%s' from the file system ?" [file tail $fpath]]
	
	set ans [tk_messageBox -title [::msgcat::mc "Confirm"] -icon warning -type yesno -message $msg]
	if {$ans eq "yes"} {
		if {[::fmeTabEditor::file_exists $fpath]} {
			::fmeTabEditor::file_save $fpath
			::fmeTabEditor::file_close $fpath
		}
		::fmeProjectManager::tree_item_del $item
	}
}

proc ::fmeProjectManager::item_mkdir {item} {
	variable wInfo
	set tree $wInfo(tree)

	set dname [::inputDlg::show $tree.ibox [::msgcat::mc "New Folder"] ""]
	foreach {btn dname} $dname {break}
	if {$btn eq "CANCEL" || $btn eq "-1" || [string trim $dname] eq ""} {return}	
	set parentDir [$tree item element cget $item 0 txt -data]
	set dpath [file join $parentDir $dname]
	if {[file exists $dpath]} {
		tk_messageBox -title [::msgcat::mc "Error"] -icon error -type ok \
			-message [::msgcat::mc "Folder already exists!"] 
		return
	}
	file mkdir $dpath
	::fmeProjectManager::item_refresh $item
	return $dpath
}

proc ::fmeProjectManager::item_import {item} {
	variable wInfo
	variable nodeInfo
	set tree $wInfo(tree)
	if {$item eq ""} {
		set item [::fmeProjectManager::get_curr_item]
		if {$item eq ""} {set item $nodeInfo(root)}
	}
	set dpath [$tree item element cget $item 0 txt -data]
	if {[file isfile $dpath]} {
		set dpath [file dirname $dpath]
		set item [$tree item parent $item]
	}	
	set fpath [tk_getOpenFile -filetypes [list [list [::msgcat::mc "All"] "*"] ] \
			-initialdir $dpath -title [::msgcat::mc "Import to : (%s)" $dpath] ]
	if {$fpath eq "" || $fpath eq "-1" || ![file exists $fpath]} {return}
	if {[catch {file copy $fpath $dpath}]} {
		tk_messageBox -title [::msgcat::mc "Error"] -icon error -type ok \
			-message [::msgcat::mc "File copy fail!"]		
		return
	}
	::fmeProjectManager::item_refresh $item
}

proc ::fmeProjectManager::item_paste {item} {
	variable wInfo
	variable cpBuf
	variable vars
	set tree $wInfo(tree)
	if {$cpBuf(file) eq ""} {
		puts sbar msg [::msgcat::mc "No copy target"]
		return
	}
	set dir [$tree item element cget $item 0 txt -data]
	set targetName [file join $dir [file tail $cpBuf(file)]]
	set replaceFlag 0
	if {[file isfile $dir]} {
		set item [$tree item parent $item]
		set dir [$tree item element cget $item 0 txt -data]
	}
	
	if {[file exists $targetName]} {
		set win [Dialog .crowTde_dialog_tmp -modal local -title [::msgcat::mc "Error"]]
		set fmeMain [$win getframe]
		set lblMsg [label $fmeMain.lblMsg -text [::msgcat::mc "The folder already contains a file named %s" [file tail $cpBuf(file)]]] 
		set rdoReplace [radiobutton $fmeMain.rdoReplace -anchor w -text [::msgcat::mc "Replace"] \
			-value "Replace" \
			-variable ::fmeProjectManager::vars(rdoPaste)]
		set rdoRename [radiobutton $fmeMain.rdoRename -anchor w -text [::msgcat::mc "Rename"] \
			-value "Rename" \
			-variable ::fmeProjectManager::vars(rdoPaste)]
		set txtRename [entry $fmeMain.txtRename]
		$txtRename insert end [file tail $cpBuf(file)]
		
		set fmeBtn [frame $fmeMain.fmeBtn]
		set btnOk [button $fmeBtn.btnOk -text [::msgcat::mc "Ok"] -command [list $win enddialog "Ok"]]
		set btnCancel [button $fmeBtn.btnCancel -text [::msgcat::mc "Cancel"] -command [list $win enddialog "Cancel"]]
		pack $btnOk $btnCancel -side left -expand 1 -padx 5
		
		grid $lblMsg - -sticky "news" -pady 8
		grid $rdoReplace - -sticky "news" -pady 2
		grid $rdoRename $txtRename -sticky "news"
		grid $fmeBtn - -sticky "news" -pady 8
		
		grid rowconfigure $fmeMain 0 -weight 1
		grid columnconfigure $fmeMain 0 -weight 1
		
		set vars(rdoPaste) "Rename"
		
		set ret [$win draw]
		if {$ret eq "Ok"} {
			if {$vars(rdoPaste) eq "Rename"} {
				set nName [$txtRename get]
				if {[string trim $nName] eq ""} {
					tk_messageBox -title [::msgcat::mc "Error"] -type ok \
						-message [::msgcat::mc "File name invalid."]
					return			
				}
				if {[file exists $nName]} {
					tk_messageBox -title [::msgcat::mc "Error"] -type ok \
						-message [::msgcat::mc "'%s' already exists." [file tail $nName]]
					return
				}				
				set targetName [file join $dir $nName]
			} else {
				set replaceFlag 1
			}
		} else {
			unset vars(rdoPaste)
			destroy $win
			return
		}
		unset vars(rdoPaste)
		destroy $win
	}
	
	switch -exact -- $cpBuf(flag) {
		"CUT" {
			file copy -force $cpBuf(file) $targetName
			file delete -force $cpBuf(file)
			if {$replaceFlag == 0} {
				set newItem [::fmeProjectManager::tree_item_add $item $targetName [$tree item element cget $cpBuf(item) 0 img -image]]
			}
			::fmeProjectManager::tree_item_del $cpBuf(item)
			set cpBuf(file) ""
			set cpBuf(item) ""
		}
		"COPY" {
			file copy -force $cpBuf(file) $targetName
			if {$replaceFlag == 0} {
				set newItem [::fmeProjectManager::tree_item_add $item $targetName [$tree item element cget $cpBuf(item) 0 img -image]]
			}
		}
	}
	if {[file isdirectory $targetName]} {
		::fmeProjectManager::item_refresh $newItem
	}
	return
}

proc ::fmeProjectManager::item_refresh {item} {
	variable wInfo
	set tree $wInfo(tree)	
	set fpath [$tree item element cget $item 0 txt -data]
	if {![file exists $fpath]} {return}
	foreach c [$tree item children $item] {
		$tree item delete $c
	}
	::fmeProjectManager::item_scan $item
}

proc ::fmeProjectManager::item_rename {item name} {
	variable wInfo
	set tree $wInfo(tree)

	set opath [$tree item element cget $item 0 txt -data]
	if {$name eq ""} {
		set name [file tail [::inputDlg::show $tree.ibox [::msgcat::mc "Rename"] [file tail $opath]]]
		foreach {btn name} $name {break}
		if {$btn eq "CANCEL" || $btn eq "-1" || [string trim $name] eq ""} {return}			
	}
	set npath [file join [file dirname $opath] $name]
	if {[file exists $npath]} {
		tk_messageBox -title [::msgcat::mc "Error"] -type ok -icon info \
			-message [::msgcat::mc "'%s' already exists!" $name]
		return
	}
	if {$opath ne $npath} {
		if {[catch {file rename $opath $npath}]} {
			tk_messageBox -title [::msgcat::mc "Error"] -type ok -icon info -message [::msgcat::mc "Rename fail!"]
			return
		}
	}
	::fmeProjectManager::item_refresh [$tree item parent $item]
}

proc ::fmeProjectManager::project_close {} {
	variable wInfo
	variable prjInfo
	variable nodeInfo
	set tree $wInfo(tree)
	
	if {$prjInfo(name) eq ""} {return}
	::fmeTabEditor::close_all
	
	set prjInfo(name) ""
	set prjInfo(workspace) ""
	set prjInfo(mainScript) ""
	set prjInfo(path) ""
	set prjInfo(interpreter) ""
	
	array unset nodeInfo
	$tree item delete all
	::fmeTask::unset_db
	puts sbar maxline ""
	puts sbar currpos ""
}

proc ::fmeProjectManager::project_new {} {
	set ret [::frmNewProject::show ".frmNewProject"]
	if {$ret eq "" || $ret eq "-1"} {return}
	if {[::fmeProjectManager::get_project_path] ne ""} {
		set ans [tk_messageBox -title [::msgcat::mc "Confirm"] -type yesno -icon info \
				-message [::msgcat::mc "The operation need close current project. Close project ?"]]
		if {$ans eq "no"} {return}
		::fmeProjectManager::project_close
	}
	array set params $ret
	::fmeProjectManager::project_open [file join $params(workspace) $params(name)]
}

proc ::fmeProjectManager::project_open {prjPath} {
	variable prjInfo
	variable nodeInfo
	variable wInfo
	set tree $wInfo(tree)
	if {$prjPath eq ""} {
		set prjPath [tk_chooseDirectory -title [::msgcat::mc "Open Project"] -mustexist 1]
		if {$prjPath eq ""} {return}
	}		
	if {[::fmeProjectManager::get_project_path] ne ""} {
		set ans [tk_messageBox -title [::msgcat::mc "Confirm"] -type yesno -icon info \
				-message [::msgcat::mc "The operation need close current project. Close project ?"]]
		if {$ans eq "no"} {return}
		::fmeProjectManager::project_close
	}
	set prjInfo(workspace) [file dirname $prjPath]
	set prjInfo(name) [file tail $prjPath]
	set prjFile [file join $prjPath ".__meta__" "project.rc"]
	if {![file exists $prjFile]} {::fmeProjectManager::project_init $prjPath}
	::fmeProjectManager::property_load $prjPath
	
	set item [$tree item create -button yes]
	$tree item lastchild 0 $item
	$tree item style set $item 0 style
	$tree item element configure $item 0 img -image [::crowImg::get_image cfolder]
	$tree item element configure $item 0 txt -text [::msgcat::mc "Project - %s" $prjPath] -data $prjPath
	$tree item collapse $item	
	
	set nodeInfo(root) $item
	
	::crowRecently::push_project $prjPath 
	
	::fmeTask::set_db [file join $prjPath ".__meta__" "todos"]
	::fmeProjectManager::item_refresh $item
	
	wm title . "$::fmeProjectManager::prjInfo(name) - CrowTDE (Crow Tcl/Tk Development Environment)"
	return $prjPath
}

proc ::fmeProjectManager::project_save {} {	
	::fmeTabEditor::save_all
}

proc ::fmeProjectManager::project_run {} {
	set mainScript [::fmeProjectManager::get_project_mainScript]
	if {$mainScript eq ""} {
		::frmProjectProperty::show ".frmProjectProperty"
		set mainScript [::fmeProjectManager::get_project_mainScript]
	}
	if {$mainScript eq ""} {
		tk_messageBox -icon error -title [::msgcat::mc "Error"] -type ok \
			-message [::msgcat::mc "Default script not specify!"]
		return ""
	}

	set fpath [file join [::fmeProjectManager::get_project_path] $mainScript]
	if {![file exists $fpath]} {
		tk_messageBox -icon error -title [::msgcat::mc "Error"] -type ok \
			-message [::msgcat::mc "Default script not exists"]
		return ""		
	}

	set prjInterp [::fmeProjectManager::get_project_interpreter]	
	::crowExec::run_script $prjInterp $fpath
}

proc ::fmeProjectManager::wrap_dir {dpath} {
	set rc [file join $::env(HOME) ".CrowTDE" CrowTDE.rc]
	set shell [::crowRC::param_get $rc CrowTDE.TclInterpreter]
	if {$shell eq ""} {
		set tclInterp [::crowRC::param_get $rc CrowTDE.TkInterpreter]
	}
	if {$shell eq ""} {
		set tclInterp [::fmeProjectManager::get_project_interpreter]
	}
	if {$shell eq "" || ![file exists $shell]} {
		tk_messageBox -title [::msgcat::mc "Error"] -icon error -type ok \
			-message [::msgcat::mc "Please specify Tcl or Tk interpreter first!"]
		::frmSetting::show $dlg
		return
	}
	if {$shell eq ""} {
		set tclInterp [::crowRC::param_get $rc CrowTDE.TkInterpreter]
	}
	if {$shell eq ""} {
		set tclInterp [::fmeProjectManager::get_project_interpreter]
	}
	if {$shell eq "" || ![file exists $shell]} {return}
	::crowSdx::wrap_dir $shell $dpath
	return
}


