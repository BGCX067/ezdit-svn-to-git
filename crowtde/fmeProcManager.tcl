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

namespace eval ::fmeProcManager {
#	variable tp ""
	
	variable nodeInfo
	array set nodeInfo ""

	variable wInfo 
	array set wInfo ""

	variable refreshInterval 1500
	variable currProjectPath ""
	
	variable procCache
	array set procCache ""
	
	variable currFile
	array set currFile [list file "" time ""]
	
}

#######################################################
#                                                     #
#                 Private Operations                  #
#                                                     #
#######################################################

proc ::fmeProcManager::btn1_dclick {posx posy posX posY } {
	variable wInfo
	set tree $wInfo(tree)	
	set ninfo [$tree identify $posx $posy]
	if {[llength $ninfo] != 6} {return}
	foreach {what itemId where columnId type name} $ninfo {}
	if {$what eq "item" && $where eq "column"} {
		set line [$tree item element cget $itemId 0 txt -data]
		if {$line ne "" } {
			$tree item toggle $itemId
			::fmeProcManager::goto_line $line
		}
	}
}

proc ::fmeProcManager::btn3_click {posx posy posX posY } {
	variable wInfo
	set tree $wInfo(tree)	
		
	set ninfo [$tree identify $posx $posy]
	if {[llength $ninfo] != 6} {return}
	foreach {what itemId where columnId type name} $ninfo {}
	if {$what eq "item"} {$tree selection modify $itemId all}
	if {$what eq "item" && $where eq "column"} {
		set line [$tree item element cget $itemId 0 txt -data]
		if {$line ne "" } {
			::fmeProcManager::post_menu $posX $posY
		}
	}
}

proc ::fmeProcManager::clear_item {} {
	variable wInfo
	set tree $wInfo(tree)
	set items [$tree item children 0]
	foreach item $items {$tree item delete $item}
	return
}

proc ::fmeProcManager::mk_menu {parent} {
	variable wInfo
	set tree $wInfo(tree)	
	set itemId [$tree selection get]
	set idata [$tree item element cget $itemId 0 txt -data]
	$parent add command -compound left -label [::msgcat::mc "View"] \
		-image [::crowImg::get_image view] \
		-command [list ::fmeProcManager::goto_line $idata]	
	return $parent
}

proc ::fmeProcManager::post_menu {X Y} {
	variable wInfo
	set tree $wInfo(tree)	
	set item [$tree selection get]
	if {[winfo exists $tree.procMenu]} {destroy $tree.procMenu}
	set mMain [menu $tree.procMenu -tearoff 0]
	::fmeProcManager::mk_menu $mMain
	tk_popup $mMain $X $Y
	return
}

proc ::fmeProcManager::proc_add {name arglist pos} {
	variable wInfo
	variable nodeInfo
	variable procCache
	
	set tree $wInfo(tree)
	set arglist [lindex $arglist 0]
	set lineNum [expr $pos+1]

	set parent $nodeInfo(root)
	set pInfo [split [regsub -all -- {\:\:} $name "\x7f"] "\x7f"]
	set pLen [llength $pInfo]
	set cut 0
	set pName ""
	foreach ns $pInfo {
		incr cut
		if {$ns eq ""} {
			set pName "${pName}::"
			continue
		}
		
		if {$cut != $pLen} {
			set ns "$pName$ns"
			if {![info exists procCache(ns,$ns)]} {
				set item [$tree item create -button yes]
				$tree item style set $item 0 style
				$tree item lastchild $parent $item
				$tree item element configure $item 0 img \
					-image [list [::crowImg::get_image proc_item_ons] {open} [::crowImg::get_image proc_item_cns] {}]
				$tree item element configure $item 0 txt -text $ns
				$tree item expand $item
				set procCache(ns,$ns) $item
			}
			set procCache(exists,ns,$ns) 1
			set parent $procCache(ns,$ns)
		} else {
			set procName $ns
			set ns "$pName$ns"
			if {![info exists procCache(proc,$ns)]} {
				set item [$tree item create -button no]
				$tree item style set $item 0 style
				$tree item lastchild $parent $item
				$tree item element configure $item 0 img \
					-image [list [::crowImg::get_image proc_item_oproc] {open} [::crowImg::get_image proc_item_cproc] {}]
				$tree item element configure $item 0 txt -text $procName -data $lineNum
				$tree item collapse $item
				set procCache(proc,$ns) $item
			} else {
				$tree item element configure $procCache(proc,$ns) 0 txt -data $lineNum
			}
			set procCache(exists,proc,$ns) 1
			set childs [$tree item children $procCache(proc,$ns)]
			foreach child $childs {	$tree item delete $child}
			if {[llength $arglist] > 0} {
				$tree item configure $procCache(proc,$ns) -button yes
				foreach arg $arglist {
					set item [$tree item create -button no]
					$tree item style set $item 0 style
					$tree item lastchild $procCache(proc,$ns) $item
					$tree item element configure $item 0 img -image [::crowImg::get_image proc_item_arg]
					$tree item element configure $item 0 txt -text $arg -data $lineNum
					$tree item collapse $item
				}
			}
		}
		set pName "${ns}::"
	}
	return
}

proc ::fmeProcManager::proc_scan_end {} {
	variable wInfo
	variable procCache	
	set tree $wInfo(tree)
	foreach key [array names procCache proc*] {
		if {$procCache(exists,$key) == 0} {
			$tree item delete $procCache($key)
			array unset procCache $key
			array unset procCache exists,$key
		}
	}
	foreach key [array names procCache ns,*] {
		if {$procCache(exists,$key) == 0} {
			$tree item delete $procCache($key)
			array unset procCache $key
			array unset procCache exists,$key
		}
	}
	return
}

proc ::fmeProcManager::proc_scan_start {} {
	variable procCache
	foreach key [array names procCache exists*] {
		set procCache($key) 0
	}
	return
}

proc ::fmeProcManager::recv {fd} {
	variable refreshInterval
	if {![eof $fd]} {
		set inBuf ""
		gets $fd inBuf
		if {$inBuf ne ""} {
			catch {
				switch -exact -- [lindex $inBuf 0] {
					::fmeProcManager::proc_add -
					::fmeProcManager::proc_scan_start -
					::fmeProcManager::proc_scan_end {eval $inBuf}
				}
			}
			update
		}
	} else {
		catch {close $fd}
		after $refreshInterval [list ::fmeProcManager::refresh]
	}
}

proc ::fmeProcManager::refresh {} {
	variable wInfo
	variable nodeInfo
	variable procCache
	variable refreshInterval
	variable currFile
#	variable tp
	
	set tree $wInfo(tree)
	set editor [::fmeTabEditor::get_curr_editor]
	if {$editor eq ""} {
		after idle [list after $refreshInterval ::fmeProcManager::refresh]
#		::fmeProcManager::proc_scan_start
#		::fmeProcManager::proc_scan_end
		$tree item delete all
		array unset procCache *
		set ::fmeProcManager::currFile(file) ""
		set ::fmeProcManager::currFile(time) ""
		return
	}
	
	#-----------------------------------------------------------------------------------------
#	$tp eval [list set ::refreshInterval $refreshInterval]
#	$tp eval [list ::parser_start [::crowEditor::dump_text $editor]]
#	after $::refreshInterval ::fmeProcManager::refresh
#	return	
	#-----------------------------------------------------------------------------------------

	set nextFile [::crowEditor::get_file $editor]
	set nextTime [::crowEditor::get_lastModify $editor]	
	if {$nextFile eq $::fmeProcManager::currFile(file) && $nextTime eq $::fmeProcManager::currFile(time)} {
		after idle [list after $refreshInterval ::fmeProcManager::refresh]
		return
	}

	set ::fmeProcManager::currFile(file) $nextFile
	set ::fmeProcManager::currFile(time) $nextTime
	
	set rc [file join $::env(HOME) ".CrowTDE" CrowTDE.rc]
	set shell [::crowRC::param_get $rc CrowTDE.TclInterpreter]
	if {$shell eq "" || ![file exists $shell]} {
		tk_messageBox -title [::msgcat::mc "Error"] -icon error -type ok \
			-message [::msgcat::mc "Please specify Tcl interpreter first!"]
		::frmSetting::show .crowtde_tmpdialog
		after idle [list after $refreshInterval ::fmeProcManager::refresh]
		return
	}	
	
	set fd [open [list | $shell] r+]
	puts $fd [list lappend ::auto_path [file join $::env(HOME) ".CrowTDE" "lib"]]
	puts $fd [list lappend ::auto_path [file join $::crowTde::appPath lib]]
	puts $fd [list package require Tclparser]
	flush $fd

	set tmpfile [file join $::env(HOME) .CrowTDE tmpfile.proc.[pid]]
	set fd2 [open $tmpfile w]
	puts $fd2 [::crowEditor::dump_text $editor]
	close $fd2	
	set code [format {
		proc ::parser_start {} {
			set ::currNS ""
			set ::EOF [geteof]
			set ::EOS [geteos]
			set tmpfile {%s}
			set fd [open $tmpfile r]
			set parseData [read -nonewline $fd]
			close $fd
			file delete $tmpfile
			puts ::fmeProcManager::proc_scan_start
			::parsing parseData 0
			puts ::fmeProcManager::proc_scan_end
		}
		
		proc ::parsing {buf baseLine} {
			upvar $buf code
			set tp [new_Tclparser $code 0]
#			catch {
			set currCmd ""
			while {[set tok [$tp gettok]] != $::EOF } {
				update
				if { $tok eq $::EOS } {
					set data ""
					foreach {line data} [lindex $currCmd 0] {break}
					switch -exact -- $data {
						"proc" {
							foreach {lname name} [lindex $currCmd 1] {break}
							foreach {larglist arglist} [lindex $currCmd 2] {break}
							set ns [lindex $::currNS end]
							if {$ns ne ""} {set data2 ${ns}::${name}}
							if {[info exists name] && [info exists arglist] } {
								puts [list ::fmeProcManager::proc_add $name $arglist $larglist]
								flush stdout
							}
							foreach {lbody body} [lindex $currCmd 3] {break}
							if {[info exists body] && [string index $body 0] eq "\x7b"} {::parsing body $lbody}	
						}
						"namespace" {
							foreach {line2 data2} [lindex $currCmd 1] {break}
							if {$data2 eq "eval"} {
								foreach {line3 data3} [lindex $currCmd 2] {break}
								lappend ::currNS $data3
								foreach parseData [lrange $currCmd 3 end] {
									foreach {line4 data4} $parseData {break}
									if {[info exists data4] && [string index $data4 0] eq "\x7b"} {::parsing data4 $line4}
								}
								set ::currNS [lrange $::currNS 0 end-1]
							}
						}							
					}
					set currCmd ""
					continue
				}
				lappend currCmd [list [expr [$tp getlineno]+$baseLine] $tok]				
			}
#			}
			delete_Tclparser $tp
		}
		::parser_start
		exit
	} $tmpfile]
	
	puts $fd $code
	fconfigure $fd -blocking 1 -buffering line
	fileevent $fd readable [list ::fmeProcManager::recv $fd]	
	flush $fd
	return
}

proc ::fmeProcManager::tree_init {path} {
	variable wInfo
	variable nodeInfo

	set fmeMain [frame $path]
	set fmeBody [ScrolledWindow $fmeMain.fmeBody]
	set tree [treectrl $fmeBody.tree \
		-showroot no \
		-linestyle dot \
		-selectmod single \
		-showrootbutton no \
		-showbuttons yes \
		-showheader no \
		-showlines no \
		-scrollmargin 16 \
		-xscrolldelay "500 50" \
		-yscrolldelay "500 50" \
		-highlightthickness 0 \
		-relief groove \
		-bg white \
		-bd 1] ;# -bg white -relief groove

	$tree column create -tag colName -expand yes -text "Tree"
	$tree element create img image \
		-height 24 -width 24
	$tree element create txt text -fill [list black {selected focus}] -justify left
	$tree element create rect rect -showfocus yes -fill [list #e6e4e4 {selected}]
	
	$tree configure -treecolumn colName
	
	$tree style create style
	$tree style elements style {rect img txt}
	$tree style layout style img -padx {0 4} -expand ns
	$tree style layout style txt -padx {0 4} -expand ns
	$tree style layout style rect -union {txt} -iexpand ns -ipadx 2
	
	bind $tree <Double-Button-1> {::fmeProcManager::btn1_dclick %x %y %X %Y} 
	bind $tree <ButtonRelease-3> {::fmeProcManager::btn3_click %x %y %X %Y} 
	
	$fmeBody setwidget $tree
	
	set wInfo(fmeMain) $fmeMain
	set wInfo(fmeBody) $fmeBody
	set wInfo(tree) $tree

	set nodeInfo(root) root

	pack $fmeBody -side top -fill both -expand 1
	
	
	return $fmeMain
}

#######################################################
#                                                     #
#                 Public Operations                   #
#                                                     #
#######################################################
proc ::fmeProcManager::get_interval {} {
	variable refreshInterval
	return $refreshInterval
}

proc ::fmeProcManager::get_procs {} {
	variable wInfo
	variable procCache	
	set tree $wInfo(tree)	
	set items [array names procCache proc*]
	set ret ""
	foreach item $items {
		lappend ret [string range $item 5 end] [$tree item element cget $procCache($item) 0 txt -data] 
	}
	return $ret
}

proc ::fmeProcManager::goto_line {line} {
	set editor [::fmeTabEditor::get_curr_editor]
	if {$editor eq ""} {return}
	::crowEditor::goto_line $editor $line
}

proc ::fmeProcManager::init {path} {
#	variable tp
	set fmeProc [::fmeProcManager::tree_init $path]
#	set code {
#		proc ::parser_start {parseData} {
#			set ::currNS ""
#			set ::EOF [geteof]
#			set ::EOS [geteos]
#			::fmeProcManager::proc_scan_start
#			puts "proc start"
##			if {[catch {::parsing parseData 0}]} {
##				puts $::errorInfo
##			}
#			::parsing parseData 0
#			puts "proc end"
#			::fmeProcManager::proc_scan_end
#			after $::refreshInterval ::fmeProcManager::refresh
#		}
#		
#		proc ::parsing {buf baseLine} {
#			upvar $buf code
#			set tp [new_Tclparser $code 0]
##			catch {
#				set currCmd ""
#				while {[set tok [$tp gettok]] != $::EOF } {
#					pupdate
#					update
#					if { $tok eq $::EOS } {
#						set data ""
#						foreach {line data} [lindex $currCmd 0] {break}
#						switch -exact -- $data {
#							"proc" {
#								foreach {lname name} [lindex $currCmd 1] {break}
#								foreach {larglist arglist} [lindex $currCmd 2] {break}
#								set ns [lindex $::currNS end]
#								if {$ns ne ""} {set data2 ${ns}::${name}}
##								puts [list  ::fmeProcManager::proc_add $name $arglist $larglist]
#								if {[info exists name] && [info exists arglist] && [info exists larglist]} {
#									::fmeProcManager::proc_add $name $arglist $larglist
#								}
##								foreach {lbody body} [lindex $currCmd 3] {break}
##								if {[string index $body 0] eq "\x7b"} {::parsing body $lbody}	
#							}
#							"namespace" {
#								foreach {line2 data2} [lindex $currCmd 1] {break}
#								if {$data2 eq "eval"} {
#									foreach {line3 data3} [lindex $currCmd 2] {break}
#									lappend ::currNS $data3
#									foreach parseData [lrange $currCmd 3 end] {
#										foreach {line4 data4} $parseData {break}
#										if {!([info exists line4] & [info exists data4])} {break}
#										if {[string index $data4 0] eq "\x7b"} {::parsing data4 $line4}
#									}
#									set ::currNS [lrange $::currNS 0 end-1]
#								}
#							}							
#						}
#						set currCmd ""
#						continue
#					}
#					lappend currCmd [list [expr [$tp getlineno]+$baseLine] $tok]				
#				}
##			}
#			delete_Tclparser $tp
#		}
#	}
#	
##	set tp [interp create]
##	$tp eval [list lappend ::auto_path [file join $::crowTde::appPath lib]]
##	$tp eval [list package require Tclparser]
##	$tp eval $code
##	interp alias $tp ::fmeProcManager::proc_add {} ::fmeProcManager::proc_add
##	interp alias $tp ::fmeProcManager::proc_scan_start {} ::fmeProcManager::proc_scan_start
##	interp alias $tp ::fmeProcManager::proc_scan_end {} ::fmeProcManager::proc_scan_end
##	interp alias $tp ::fmeProcManager::refresh {} ::fmeProcManager::refresh
##	interp alias $tp pupdate {} update
##	interp alias $tp puts {} puts
#	
	return $fmeProc
}

proc ::fmeProcManager::set_interval {val} {
	variable refreshInterval
	if {$val eq ""} {
		set ret [::inputDlg::show ".inputDlg" [::msgcat::mc "Interval"] $refreshInterval]
		foreach {btn ret} $ret {break}
		if {$btn eq "CANCEL" || $btn eq "-1" || ![string is integer $ret]} {return}
		set val $ret
	}
	set refreshInterval $val
#	::tsv::set ProcManager refreshInterval $refreshInterval
	return
}

