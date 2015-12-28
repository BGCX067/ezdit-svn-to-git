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

namespace eval ::fmeTaskMgr {
	variable wInfo
	array set wInfo ""
}

proc ::fmeTaskMgr::init {path} {
	variable wInfo
	set appPath $::crowTde::appPath
		
	set fmeNoteBook [NoteBook $path -side bottom -tabbevelsize 0 -arcradius 0]
	$fmeNoteBook insert end fmeTask \
		-image [::crowImg::get_image note] \
		-text [::msgcat::mc "Tasks"]

	$fmeNoteBook insert end fmeNagelfar \
		-image [::crowImg::get_image syntax_check] \
		-text [::msgcat::mc "Nagelfar"]
	
	$fmeNoteBook insert end fmeTkcon \
		-image [::crowImg::get_image console] \
		-text [::msgcat::mc "TkCon"]
		
#	$fmeNoteBook insert end fmeDebugger \
#		-image [::crowImg::get_image debugger] \
#		-text [::msgcat::mc "Debug"]		
									
	source [file join $appPath "fmeTask.tcl"]
	set fd [open [file join $appPath lib tkcon.tcl] r]
	namespace eval :: [read -nonewline $fd]
	close $fd
#	namespace eval :: [list source [file join $appPath lib tkcon.tcl]]
	source [file join $appPath "fmeNagelfar.tcl"]
		

	set wInfo(fmeTask) [::fmeTask::init [$fmeNoteBook getframe fmeTask].fmeTask]
	set wInfo(fmeNagelfar) [::fmeNagelfar::init [$fmeNoteBook getframe fmeNagelfar].fmeNagelfar]
	set wInfo(fmeTkcon) [::tkcon::AtCrow [$fmeNoteBook getframe fmeTkcon].fmeTkcon [file join $appPath lib tkcon.tcl]]
#	set wInfo(fmeDebugger) [::fmeDebugger::init [$fmeNoteBook getframe fmeDebugger].fmeDebugger]
	pack $wInfo(fmeTask) -expand 1 -fill both
	pack $wInfo(fmeNagelfar) -expand 1 -fill both
	pack $wInfo(fmeTkcon) -expand 1 -fill both
#	pack $wInfo(fmeDebugger) -expand 1 -fill both
	
	 set wInfo(nb) $fmeNoteBook
	
	$fmeNoteBook raise fmeTkcon
	
	return $path
}

proc ::fmeTaskMgr::raise {name} {
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


