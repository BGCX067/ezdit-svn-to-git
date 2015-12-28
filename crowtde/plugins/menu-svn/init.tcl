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

#package require msgcat
#package require BWidget
#package require tdom

namespace eval ::svnWrapper {
	variable svnInfo
	array set svnInfo [list CMD svn USER "" PASSWORD "" FD ""]
	
	variable wInfo
	array set wInfo ""
}

proc ::svnWrapper::init {appPath pluginPath} {
	::fmeProjectManager::hook_insert DEFAULT ::svnWrapper::mk_menu
	foreach src [glob -nocomplain -directory $pluginPath -type {f} "svn-*.tcl"] {
		source $src
	}
	foreach img [glob -nocomplain -directory [file join $pluginPath images] -type {f} "*.png"] {
		::crowImg::load_image $img
	}
	return
}

proc ::svnWrapper::mk_menu {tree item itemPath menuParent} {
	variable svnInfo
	
	set parent $menuParent
	if {[catch [list exec $svnInfo(CMD) --help]]} {
		$parent add cascade -compound left -label [::msgcat::mc "Svn"] \
			-state disabled
			return
	}
	
	if {[winfo exists $parent.svnHookMenu]} {destroy $parent.svnHookMenu}
	
	if {[file isdirectory $itemPath] && \
			(![file exists [file join [file dirname $itemPath] ".svn"]]) && \
			(![file exists [file join $itemPath ".svn"]]) && \
			[$tree item parent $item] == 0} {
		$parent add command -compound left -label [::msgcat::mc "Import"] \
			-command [list ::svnWrapper::svn_import_init $itemPath]		
		return
	}
	
	if {[file isfile $itemPath] && (![file exists [file join [file dirname $itemPath] ".svn"]])} {				
		$parent add cascade -compound left -label [::msgcat::mc "Subversion"] -state disabled
		return
	}
	
	set menuSvn [menu $parent.svnHookMenu -tearoff 0]	
	$menuSvn add command -compound left -label [::msgcat::mc "Check for modifications"] \
		-command [list ::svnWrapper::svn_status_init $itemPath]
	$menuSvn add separator
	$menuSvn add command -compound left -label [::msgcat::mc "update"] \
		-command [list ::svnWrapper::svn_update_init $itemPath]
	$menuSvn add command -compound left -label [::msgcat::mc "Commit"] \
		-command [list ::svnWrapper::svn_commit_init $itemPath]
	$menuSvn add separator
	
	$menuSvn add command -compound left -label [::msgcat::mc "Clean up"] \
		-command [list ::svnWrapper::svn_cleanup_init $itemPath]	
	$menuSvn add separator
	
	$menuSvn add command -compound left -label [::msgcat::mc "Export"] \
		-command [list ::svnWrapper::svn_export_init $itemPath]
	$menuSvn add separator

	$menuSvn add command -compound left -label [::msgcat::mc "Add"] \
		-command [list ::svnWrapper::svn_add_init $itemPath]
	$menuSvn add command -compound left -label [::msgcat::mc "Delete"] \
		-command [list ::svnWrapper::svn_del_init $itemPath]		
	$menuSvn add command -compound left -label [::msgcat::mc "Move"] \
		-command [list ::svnWrapper::svn_move_init $itemPath]
	$menuSvn add command -compound left -label [::msgcat::mc "Rename"] \
		-command [list ::svnWrapper::svn_rename_init $itemPath]
	$menuSvn add command -compound left -label [::msgcat::mc "Revert"] \
		-command [list ::svnWrapper::svn_revert_init $itemPath]			
	$menuSvn add command -compound left -label [::msgcat::mc "Resolved"] \
		-command [list ::svnWrapper::svn_resolved_init $itemPath]
	$menuSvn add separator
	
	$menuSvn add command -compound left -label [::msgcat::mc "Properties"] \
		-command [list ::svnWrapper::svn_properties_init $itemPath]
		
	$parent add cascade -compound left -label [::msgcat::mc "Svn"] \
		-menu $menuSvn
	return
}
