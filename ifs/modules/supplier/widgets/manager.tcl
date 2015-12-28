oo::class create ::dApp::supplier::manager {
	constructor {wpath args} {
		my variable Priv
		
		set Priv(opts,buttonCursor) "hand2"
		set Priv(win,frame) $wpath
		my Ui_Init
	}
	
	destructor {}
	
	method add {} {
	}
	method export {} {}
	method fetch_email {} {}
	
	method delete {} {
		my variable Priv
		
		set db $::dApp::supplier::Obj(db)
		set tv $Priv(obj,tv)
		
		set ids [$db checks]
		
		if {[llength $ids] == 0} {
			tk_messageBox \
				-title [::msgcat::mc "提示"] \
				-message [::msgcat::mc "請先選取想要刪除的記錄。"] \
				-icon info \
				-type ok
			return
		}
		
		set ans [tk_messageBox \
			-title [::msgcat::mc "刪除"] \
			-message [::msgcat::mc "確定要刪除 %s 筆記錄嗎?" [llength $ids]] \
			-icon question \
			-type yesno \
		]
		if {$ans != "yes"} {return}
		
		$db delete $ids
		
		$Priv(obj,tv) sbar_find
	}
	
	method tv {args} {
		my variable Priv
		$Priv(obj,tv) {*}$args
	}
	
	method Ui_Init {} {
		my variable Priv
		
		set ibox $::dApp::supplier::Obj(ibox)
		set wpath $Priv(win,frame)
		
		set fme [ttk::frame $wpath -borderwidth 2 -relief groove]
		set tbar [ttk::frame $fme.tbar]
		set Priv(obj,tv) [::dApp::supplier::tableview new $fme.tv -showsbar 1 -showctrl 1 -showfilter 0]
		pack $tbar -fill x -side top 
		pack [ttk::separator $fme.sep -orient horizontal] -fill x
		pack [$Priv(obj,tv) frame] -expand 1 -fill both
		
		set btnAdd [ttk::button $tbar.btnAdd \
			-text [::msgcat::mc "新增"] \
			-image [$ibox get add] \
			-compound left \
			-command [list [self object] add] \
			-style Toolbutton \
			-cursor 	$Priv(opts,buttonCursor) \
		]
		pack $btnAdd -side left -padx 6 -pady 2
		
		set btnDel [ttk::button $tbar.btnDel \
			-text [::msgcat::mc "刪除"] \
			-image [$ibox get delete] \
			-compound left \
			-command [list [self object] delete] \
			-style Toolbutton \
		]		
		pack $btnDel -side left -padx 6 -pady 2
		
		set btnFetchMail [ttk::button $tbar.btnFetchMail \
			-text [::msgcat::mc "提取E-Mail"] \
			-image [$ibox get mail] \
			-compound left \
			-command [list [self object] fetch_email] \
			-style Toolbutton \
		]
		pack $btnFetchMail -side left -padx 6 -pady 2
		
		set btnExport [ttk::button $tbar.btnExport \
			-text [::msgcat::mc "輸出報表"] \
			-image [$ibox get export] \
			-compound left \
			-command [list [self object] export] \
			-style Toolbutton \
		]
		pack $btnExport -side left -padx 6 -pady 2
		
		pack [$Priv(obj,tv) sbar_filter_init $tbar.ctrl] -side right
		
#		set btnRefresh [ttk::button $tbar.btnRefresh \
#			-text [::msgcat::mc "Refresh"] \
#			-image [$ibox get refresh] \
#			-compound left \
#			-command [list $Priv(obj,tv) sbar_find] \
#			-style Toolbutton \
#		]
#		pack $btnRefresh -side right -padx 10		
		
	}
}
