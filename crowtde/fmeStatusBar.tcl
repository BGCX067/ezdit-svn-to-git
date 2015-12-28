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

namespace eval ::fmeStatusBar {
	variable wInfo
	variable appPath ""
	array set wInfo ""
	
	variable maxline 0
	variable currpos 0.0

	variable vars
	array set vars ""

	variable msgid 0
	variable afterId ""
}

proc ::fmeStatusBar::cls_msg {mid} {
	variable msgid
	if {$msgid == $mid} {set ::fmeStatusBar::vars(msg) ""}
}

proc ::fmeStatusBar::init {path appPath} {
	variable wInfo
	set ::fmeStatusBar::appPath $appPath

	set wInfo(statusBar) [frame $path -bd 2 -relief raised]
	set ::fmeStatusBar::vars(msg) ""
	label $wInfo(statusBar).msg -textvariable ::fmeStatusBar::vars(msg) \
		-anchor w \
		-relief sunken \
		-bd 1 \
		-wraplength 0
	label $wInfo(statusBar).lblMaxline -text [::msgcat::mc "Lines"]
	label $wInfo(statusBar).maxline -textvariable ::fmeStatusBar::vars(maxline) \
		-anchor center \
		-relief sunken \
		-bd 1 \
		-wraplength 0 \
		-width 8
	label $wInfo(statusBar).lblCurrpos -text [::msgcat::mc "Pos"]	
	label $wInfo(statusBar).currpos -textvariable ::fmeStatusBar::vars(currpos) \
		-anchor center \
		-relief sunken \
		-bd 1 \
		-wraplength 0 \
		-width 12
	
	pack $wInfo(statusBar).msg -expand 1 -fill both -side left
	pack $wInfo(statusBar).lblMaxline -side left
	pack $wInfo(statusBar).maxline -side left
	pack $wInfo(statusBar).lblCurrpos -side left
	pack $wInfo(statusBar).currpos -side left
	
	::crowIO::register sbar ::fmeStatusBar::msg_dispatcher
	
	return $path
}

proc ::fmeStatusBar::msg_dispatcher {type msg} {
	switch -exact -- $type {
		"msg" {::fmeStatusBar::put_msg $msg}
		"maxline" {set ::fmeStatusBar::vars(maxline) $msg}
		"currpos" {set ::fmeStatusBar::vars(currpos) $msg}
	}
}

proc ::fmeStatusBar::put_msg {msg} {
	variable msgid
	variable afterId
	incr msgid
	catch {after cancel $afterId}
	set ::fmeStatusBar::vars(msg) $msg
	set afterId [after idle [list after 3000 ::fmeStatusBar::cls_msg $msgid]]
}


