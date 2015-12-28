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

package require BWidget

namespace eval ::fmeTabMgr {
	variable wInfo
	array set wInfo ""
}
 
proc ::fmeTabMgr::init {path} {
	variable wInfo
	
	set fmeMain [NoteBook $path -side bottom -tabbevelsize 0 -arcradius 0]
	$fmeMain insert end pagePrjMgr -text [::msgcat::mc "File"]
	$fmeMain insert end pageProcMgr -text [::msgcat::mc "Proc"]
	$fmeMain insert end pageDocView -text [::msgcat::mc "Help"]
	$fmeMain insert end pageDebugger -text [::msgcat::mc "Debug"]
	
	set fmePrjMgr [$fmeMain getframe pagePrjMgr]
	set fmeProcMgr [$fmeMain getframe pageProcMgr]
	set fmeDocView [$fmeMain getframe pageDocView]
	set fmeDebugger [$fmeMain getframe pageDebugger]
	
	::fmeProcManager::init $fmeProcMgr.body
	::fmeProjectManager::init $fmePrjMgr.body
	::fmeDocView::tree_init $fmeDocView.body
	::fmeDebugger::init $fmeDebugger.body
	
	pack $fmeProcMgr.body -expand 1 -fill both
	pack $fmePrjMgr.body -expand 1 -fill both
	pack $fmeDocView.body -expand 1 -fill both
	pack $fmeDebugger.body -expand 1 -fill both
	
	#puts $fmeProcMgr
	$fmeMain raise pagePrjMgr
	set wInfo(nb) $fmeMain
	return $fmeMain
}

proc ::fmeTabMgr::page_raise {name} {
	variable wInfo
	set nb $wInfo(nb)
	foreach page [$nb pages] {
		if {[$nb itemcget $page -text] eq $name} {
			$nb raise $page
			break
		}
	}
	return
}

proc ::fmeTabMgr::page_raise2 {page} {
	variable wInfo
	set nb $wInfo(nb)	
	$nb raise $page
}

