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

namespace eval ::frmSetting {
	variable nodeInfo
	array set nodeInfo ""

	variable wInfo 
	array set wInfo ""
}

proc ::frmSetting::show {path} {
	variable wInfo 
	Dialog $path -title  [::msgcat::mc "CrowTDE configuration"]  -modal local
	set fmeMain [$path getframe]
	set fmeFun [frame $fmeMain.fun -relief groove -bd 2 ]
	set tree [treectrl $fmeMain.tree \
		-font [::crowFont::get_font smaller] \
		-width 170 \
		-height 500 \
		-itemheight 25 \
		-showroot no \
		-linestyle dot \
		-selectmod browse \
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
		-bd 1]

	$tree column create -tag colName -expand yes -text "Tree" -font [::crowFont::get_font smaller]
	$tree element create txt text -fill [list black {selected focus}] -justify left
	$tree element create rect rect -showfocus yes -fill [list #e6e4e4 {selected}]
	
	$tree configure -treecolumn colName

	$tree style create styDefault
	$tree style elements styDefault {rect txt}
	$tree style layout styDefault txt -padx {0 4} -expand ns
	$tree style layout styDefault rect -union {txt} -iexpand ns -ipadx 2

	$tree notify bind $tree <Selection> [list ::frmSetting::::btn1_click %S]

	set btnExit [button $fmeMain.btnExit -text [::msgcat::mc "Exit"] -command {::frmSetting::btnExit_click}]

	pack $tree -fill y -side left
	pack $fmeFun -expand 1 -fill both -padx 1 -side top -padx 2
	pack $btnExit -fill both -padx 2 -pady 2
	
	set wInfo(tree) $tree
	set wInfo(frmSetting) $fmeMain
	set wInfo(dialog) $path
	set wInfo(currFrame) ""
	::frmSetting::load_frames $fmeFun
	wm resizable $path 1 1
	$path draw
	destroy $path
}

#######################################################
#                                                     #
#           Private Operations                        #
#                                                     #
#######################################################

proc ::frmSetting::btn1_click {item} {
	variable wInfo
	
	set tree $wInfo(tree)	
	set parent [$tree item parent $item]
	set idata [$tree item element cget $item 0 txt -data]
	if {$wInfo(currFrame)  ne $idata} {
		pack forget $wInfo(currFrame)
		pack $idata -expand 1 -fill both
		set wInfo(currFrame) $idata
	}
}

proc ::frmSetting::btnExit_click {} {
	variable wInfo
	$wInfo(dialog) enddialog ""
}

proc ::frmSetting::item_add {parent caption widget} {
	variable wInfo
	set tree $wInfo(tree)
	set item [$tree item create -button no]
	$tree item style set $item 0 styDefault
	$tree item lastchild $parent $item
	$tree item element configure $item 0 txt -text $caption -data $widget
	return $item
}

proc ::frmSetting::load_frames {parent} {
	variable wInfo
	
	::frmSetting::item_add 0 [::msgcat::mc "General"] [::fmeGenericSetting::get_frame $parent.gs]
	::frmSetting::item_add 0 [::msgcat::mc "Editor Settings"] [::crowEditor::get_frame $parent.es]
	::frmSetting::item_add 0 [::msgcat::mc "File Settings"] [::crowFileRelation::get_frame $parent.fr]
	::frmSetting::item_add 0 [::msgcat::mc "Fonts"] [::crowFont::get_frame $parent.fc]

	pack $parent.gs -expand 1 -fill both
	set wInfo(currFrame) $parent.gs	
}

