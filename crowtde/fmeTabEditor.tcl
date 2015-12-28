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

namespace eval ::fmeTabEditor {
	variable eid 0		  
	variable wInfo 
	array set wInfo ""

	variable pageTbl
	array set pageTbl ""
	
	variable vars
	array set vars ""
}

proc ::fmeTabEditor::cb_chk_modified {page val} {
	variable wInfo
	set nb $wInfo(nb)
	set title [string trimleft [::crowNoteBook::page_get_title $nb $page] "*"]
	if {$val} {
		::crowNoteBook::page_set_title $nb $page "*$title"
	} else {
		::crowNoteBook::page_set_title $nb $page $title
	}
}

proc ::fmeTabEditor::cb_page_delete {nb page} {
	variable pageTbl
	set fpath [::crowEditor::get_file $page]
	if {[info exists pageTbl($fpath)]} {
		unset pageTbl($fpath)
	}
}

proc ::fmeTabEditor::close_all {} {
	variable wInfo 
	set nb $wInfo(nb)
	::crowNoteBook::page_close_all $nb
}

proc ::fmeTabEditor::close_curr {} {
	variable wInfo
	variable pageTbl	
	set nb $wInfo(nb)
	set page [::crowNoteBook::page_get $nb]
	if {$page ne ""} {
		set fpath [::crowEditor::get_file $page]
		::crowNoteBook::page_close $nb $page
	}
}

proc ::fmeTabEditor::curr_copy {} {
	set editor [::fmeTabEditor::get_curr_editor]
	if {$editor eq ""} {return}
	set ret [::crowEditor::copy $editor]
	if {$ret eq ""} {
		puts sbar msg [::msgcat::mc "No Copy Region"]
	} else {
		puts sbar msg [::msgcat::mc "Copy %s - %s" [lindex $ret 0] [lindex $ret 1]]
	}
}

proc ::fmeTabEditor::curr_cut {} {
	set editor [::fmeTabEditor::get_curr_editor]
	if {$editor eq ""} {return}
	set ret [::crowEditor::cut $editor]
	if {$ret eq ""} {
		puts sbar msg [::msgcat::mc "No Cut Region"]
	} else {
		puts sbar msg [::msgcat::mc "Cut %s - %s" [lindex $ret 0] [lindex $ret 1]]
	}
}

proc ::fmeTabEditor::curr_eval {} {
	set fpath [::fmeTabEditor::get_curr_file]
	if {$fpath eq ""} {return}
	set interp [::fmeProjectManager::get_project_interpreter]
	::crowExec::run_script $interp $fpath	
}

proc ::fmeTabEditor::curr_insert_comment {} {
	set editor [::fmeTabEditor::get_curr_editor]
	if {$editor eq ""} {return}
	::crowEditor::insert_comment $editor
}

proc ::fmeTabEditor::curr_insert_tab {} {
	set editor [::fmeTabEditor::get_curr_editor]
	if {$editor eq ""} {return}
	::crowEditor::insert_tab $editor
}

proc ::fmeTabEditor::curr_paste {} {
	set editor [::fmeTabEditor::get_curr_editor]
	if {$editor eq ""} {return}
	::crowEditor::paste $editor
	puts sbar msg [::msgcat::mc "Paste"]
}

proc ::fmeTabEditor::curr_redo {} {
	if {[set editor [::fmeTabEditor::get_curr_editor]] eq ""} {return}
	catch [list ::crowEditor::redo $editor]
}

proc ::fmeTabEditor::curr_remove_comment {} {
	set editor [::fmeTabEditor::get_curr_editor]
	if {$editor eq ""} {return}
	::crowEditor::remove_comment $editor
}

proc ::fmeTabEditor::curr_remove_tab {} {
	set editor [::fmeTabEditor::get_curr_editor]
	if {$editor eq ""} {return}
	::crowEditor::remove_tab $editor
}

proc ::fmeTabEditor::curr_show_print {} {
	if {[set editor [::fmeTabEditor::get_curr_editor]] eq ""} {return}
	switch $::tcl_platform(platform) {
		"windows" {
			set fpath [::crowEditor::get_file $editor]			
			Print [::crowEditor::get_text_widget $editor] \
				-title $fpath
			
		}
		"unix" -
		default {
			set fpath [::crowEditor::get_file $editor]
			if {[::crowEditor::get_ch_flag  $editor]} {
				set ans [tk_messageBox -type yesno \
					-title [::msgcat::mc "'%s' has not save. save it ?" $fpath]]
				if {$ans eq "yes"} {::crowEditor::save $editor}
			}
			set dlg [Dialog .crowPrint -modal local]
			wm title $dlg [::msgcat::mc "Print"]
			set ::fmeTabEditor::vars(lpr) "lpr %FILE%"
			set lblLpr [label $dlg.lblLpr -text [::msgcat::mc "Print Command:"] -anchor w -justify left]
			set txtLpr [entry $dlg.txtLpr -textvariable ::fmeTabEditor::vars(lpr) -width 50]
			set btnOk [button $dlg.btnOk -text [::msgcat::mc "Print"] -command [list $dlg enddialog "Ok"]]
			set btnCancel [button $dlg.btnCancel -text [::msgcat::mc "Cancal"] -command [list $dlg enddialog "Cancel"]]
			pack $lblLpr -side left -padx 1 -pady 1 -fill y
			pack $txtLpr -side left -padx 1 -pady 1 -expand 1 -fill both
			pack $btnOk -side left -padx 1 -pady 1 -fill y
			pack $btnCancel -side left -padx 1 -pady 1 -fill y
			set ret [$dlg draw]
			destroy $dlg
			if {$ret eq "Ok"} {
				regsub {\%FILE\%} $::fmeTabEditor::vars(lpr) $fpath lprcmd
				eval "exec $lprcmd"
			}
			array unset ::fmeTabEditor::vars lpr
		}
	}
}

proc ::fmeTabEditor::curr_undo {} {
	if {[set editor [::fmeTabEditor::get_curr_editor]] eq ""} {return}
	catch [list ::crowEditor::undo $editor]
}

proc ::fmeTabEditor::file_close {fpath} {
	variable wInfo 
	variable pageTbl	
	set nb $wInfo(nb)
	set page $pageTbl($fpath)
	::crowNoteBook::page_close $nb $page
}

proc ::fmeTabEditor::file_exists {fpath} {
	variable pageTbl
	return [info exists pageTbl($fpath)]
}

proc ::fmeTabEditor::file_open {fpath} {
	variable eid
	variable wInfo
	variable pageTbl
	if {[info exists pageTbl($fpath)]} {
		::fmeTabEditor::file_raise $fpath
		return
	}

	set nb $wInfo(nb)
	set editor [::crowEditor::crowEditor $nb.editor[incr eid]]
	
	set page [::crowNoteBook::page_add $nb [file tail $fpath] $editor]

	::crowEditor::load $editor $fpath
	pack $editor -expand 1 -fill both
	
	set pageTbl($fpath) $page

	::crowEditor::add_trace_modified $editor [list ::fmeTabEditor::cb_chk_modified $page]
	
	::crowNoteBook::page_raise $nb $page
	return  $page
}

proc ::fmeTabEditor::file_raise {fpath} {
	variable wInfo
	variable pageTbl	
	set nb $wInfo(nb)
	if {[info exists pageTbl($fpath)]} {
		::crowNoteBook::page_raise $nb $pageTbl($fpath)
	}
	return
}

proc ::fmeTabEditor::file_save {fpath} {
	variable wInfo 
	variable pageTbl
	::crowEditor::save $pageTbl($fpath)
}

proc ::fmeTabEditor::get_all_editor {} {
	variable wInfo 
	set nb $wInfo(nb) 
	return [::crowNoteBook::page_get_all $nb]
}

proc ::fmeTabEditor::get_all_file {} {
	variable pageTbl
	return [array names pageTbl]
}


proc ::fmeTabEditor::get_curr_editor {} {
	variable wInfo 
	set nb $wInfo(nb) 	
	set page [::crowNoteBook::page_get $nb] 
	return $page
}

proc ::fmeTabEditor::get_curr_file {} {
	variable wInfo 
	set nb $wInfo(nb)  
	set page [::crowNoteBook::page_get $nb]
	if {$page eq ""} {return ""}
	return [::crowEditor::get_file $page]
}

proc ::fmeTabEditor::init {path} {
	variable wInfo 
	set wInfo(nb) [::crowNoteBook::crowNoteBook $path]
	$path.tree configure -font [::crowFont::get_font smallest]
	::crowNoteBook::page_delete_event_add $wInfo(nb) ::fmeTabEditor::cb_page_delete
	return $wInfo(nb)
}

proc ::fmeTabEditor::raise_next {} {
	variable wInfo 
	::crowNoteBook::page_raise_next $wInfo(nb)
}

proc ::fmeTabEditor::raise_prev {} {
	variable wInfo 
	::crowNoteBook::page_raise_prev $wInfo(nb)	
}

proc ::fmeTabEditor::scroll_incr {} {
	variable wInfo 
	::crowNoteBook::page_scroll_incr $wInfo(nb)
}

proc ::fmeTabEditor::scroll_desc {} {
	variable wInfo 
	::crowNoteBook::page_scroll_desc $wInfo(nb)	
}

proc ::fmeTabEditor::save_all {} {
	variable pageTbl
	foreach {fpath page} [array get pageTbl] {
		::crowEditor::save $page
	}
}

proc ::fmeTabEditor::save_curr {} {
	variable wInfo 
	variable pageTbl
	set nb $wInfo(nb)		  
	set editor [::fmeTabEditor::get_curr_editor]
	if {$editor ne ""} {
		::crowEditor::save $editor
	}
	return
}

##################################################################################
# Copyright (C) 2006-2010 Tai, Yuan-Liang & Zheng, Shao-Huan                     #
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
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA        #
##################################################################################

