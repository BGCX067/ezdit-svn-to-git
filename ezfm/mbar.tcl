namespace eval ::mbar {
}

proc ::mbar::init {path} {
	set m [menu $path -bd 0 -relief groove -type menubar]
	$m add cascade  -label [::msgcat::mc "File"] -menu [menu $m.file -postcommand [list ::mbar::menu_file $m.file] -tearoff 0]
	$m add cascade  -label [::msgcat::mc "Edit"] -menu [menu $m.edit -postcommand [list ::mbar::menu_edit $m.edit] -tearoff 0]
	$m add cascade  -label [::msgcat::mc "View"] -menu [menu $m.view -postcommand [list ::mbar::menu_view $m.view] -tearoff 0]
	$m add cascade  -label [::msgcat::mc "Go"]  -menu [menu $m.go -postcommand [list ::mbar::menu_go $m.go] -tearoff 0]
	$m add cascade  -label [::msgcat::mc "Bookmarks"]  -menu [menu $m.bookmarks -postcommand [list ::mbar::menu_bookmarks $m.bookmarks] -tearoff 0]
	$m add cascade  -label [::msgcat::mc "Help"] -menu [menu $m.help -postcommand [list ::mbar::menu_help $m.help] -tearoff 0]

	return $path
}

proc ::mbar::menu_bookmarks {m} {
	$m delete 0 end
	$m add command -compound left -label [::msgcat::mc "Add Bookmark"] \
		-state normal  \
		-command {
			::libCrowFM::bookmark_add $::rframe::Priv(pwd)
			::lframe::tree_item_add 0 $::rframe::Priv(pwd) lframe.bookmark
	}
	$m add command -compound left -label [::msgcat::mc "Edit Bookmarks"] \
		-state normal  \
		-command {}
	$m add separator
	#load bookmarks
	return $m
}

proc ::mbar::menu_edit {m} {
	$m delete 0 end
	set state normal
	if {[::rframe::selection_get] == ""} {set state disabled}
	$m add command -compound left -label [::msgcat::mc "Cut"] \
		-state $state  \
		-command {::rframe::cut}
	$m add command -compound left -label [::msgcat::mc "Copy"] \
		-state $state  \
		-command {::rframe::copy}
	set state normal
	if {![info exists ::rframe::Priv(cp,source)] || 
			$::rframe::Priv(cp,source) == "" ||
			![file exists $::rframe::Priv(pwd)]} {
		set state disabled
	}
	$m add command -compound left -label [::msgcat::mc "Paste"] \
		-state $state  \
		-command {::rframe::paste}		
	$m add separator
	$m add command -compound left -label [::msgcat::mc "Select All"] \
		-accelerator "Ctrl-a" \
		-state normal  \
		-command {::rframe::select_all}
	$m add separator
	
	set state normal
	if {[llength [::rframe::selection_get]] == 0 ||
		![file exists $::rframe::Priv(pwd)]} {
			set state disabled
	}
	
	$m add command -compound left -label [::msgcat::mc "Duplicate"] \
		-state $state  -command {}			
	$m add command -compound left -label [::msgcat::mc "Make Link"] \
		-state $state  -command {::rframe::mklink}
		
	set state normal
	if {[llength [::rframe::selection_get]] != 1} {set state disabled}
	$m add command -compound left -label [::msgcat::mc "Rename"] \
		-state $state  -command {::rframe::rename}		
	$m add separator
	$m add command -compound left -label [::msgcat::mc "Preferences"] \
		-state normal  \
		-command {}
	
	return $m
}

proc ::mbar::menu_file {m} {
	$m delete 0 end
	
	set state normal
	if {![file exists $::rframe::Priv(pwd)]} {set state disabled}	
	$m add command -compound left -label [::msgcat::mc "Create Folder"] \
		-state $state  \
		-command {::rframe::mkdir}
	
	catch {destroy $m.new}
	set mNew [menu $m.new]
		
	$m add cascade -label [::msgcat::mc "Create Document"] -menu $mNew -state $state
	$m add separator
	set state normal
	if {![file exists $::rframe::Priv(pwd)] &&  [llength [::rframe::selection_get]] == 0} {set state disable}
	$m add command -compound left -label [::msgcat::mc "Properties"] \
		-state $state  \
		-command {::rframe::properties}		
	$m add separator	
	$m add command -compound left -label [::msgcat::mc "Close"] \
		-accelerator "Ctrl-W" \
		-state normal  \
		-command {exit}
	return $m
}

proc ::mbar::menu_go {m} {
	$m delete 0 end
	
	$m add command -compound left -label [::msgcat::mc "Back"] \
		-state [$::tbar::Priv(btnPrev) cget -state]  \
		-command {::rframe::cd_prev}
	$m add command -compound left -label [::msgcat::mc "Forword"] \
		-state [$::tbar::Priv(btnNext) cget -state]  \
		-command {::rframe::cd_next}
	$m add separator
	$m add command -compound left -label [::msgcat::mc "Home"] \
		-state normal  \
		-command {::rframe::chdir [file normalize $::env(HOME)]}
		
	foreach v [file volumes] {
		set type [::libCrowFM::get_volume_type $v]
		$m add command -compound left -label $v \
			-state normal  \
			-command [list ::rframe::chdir [file normalize $v]]		
	}
	$m add separator
	$m add command -compound left -label [::msgcat::mc "Clear History"] \
		-state normal  -command {}		
	$m add separator	
	# load history
	foreach item $::rframe::Priv(historyList) {
		$m add command -compound left -label $item \
			-state normal  -command {}		
	}
	
	return $m
}

proc ::mbar::menu_help {m} {
	$m delete 0 end
	$m add command -compound left -label [::msgcat::mc "Check New Version"] \
		-state normal  \
		-command {}
	$m add separator
	$m add command -compound left -label [::msgcat::mc "About"] \
		-state normal  \
		-command {}
	
	return $m
}

proc ::mbar::menu_view {m} {
	$m delete 0 end
	$m add command -compound left -label [::msgcat::mc "Reload"] \
		-state normal  \
		-command {::rframe::refresh}
	$m add checkbutton -compound left -label [::msgcat::mc "Show Hidden Files"] \
		-onvalue 1 \
		-offvalue 0 \
		-state normal  \
		-variable ::rframe::Priv(showHidden) \
		-command {::rframe::refresh}
	return $m
}

# example
#	set mfile [menu $m.file  -postcommand ::mbar::mfile_post]
#	$mfile add command -compound left -label [::msgcat::mc "Exit"] \
#		-accelerator "Ctrl-q" \
#		-state normal  \
#		-command {exit}
#
#	$m add cascade  -label [::msgcat::mc "File"] -menu $mfile
