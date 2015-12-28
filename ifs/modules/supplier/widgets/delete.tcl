oo::class create ::dApp::supplier::delete {
	constructor {wpath args} {
		my variable Priv
		
		set Priv(opts,buttonCursor) "hand2"
		set Priv(win,frame) $wpath
		my Ui_Init
	}
	
	destructor {}
	
	method check_all {state} {
		my variable Priv
		set tv $Priv(obj,tv)	
		set db $::dApp::supplier::Obj(db)
		
		$db check "" $state
		
		$Priv(obj,tv) sbar_find
	}
	
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
		set Priv(obj,tv) [::dApp::supplier::tableview new $fme.tv \
			-showsbar 1 \
			-showctrl 1 \
			-showfilter 0 \
			-showedit 0 \
			]
		pack $tbar -fill x -side top
		pack [ttk::separator $fme.sep -orient horizontal] -fill x
		pack [$Priv(obj,tv) frame] -expand 1 -fill both
		
		set lblPos [ttk::label $tbar.lblPos \
			-text [::msgcat::mc "供應商模組 > 刪除供應商"] \
			-style Position.TLabel \
		]
		pack $lblPos -fill y -padx 6 -pady 2 -side left		
		pack [ttk::separator $tbar.sep1 -orient vertical] -fill y -padx 6 -pady 2 -side left
		
		set btnDel [ttk::button $tbar.btnDel \
			-text [::msgcat::mc "刪除選取的項目"] \
			-image [$ibox get delete] \
			-compound left \
			-command [list [self object] delete] \
			-style Toolbutton \
		]		
		pack $btnDel -side left -padx 6 -pady 2		
		
		set btnCheckAll [ttk::button $tbar.btnCheckAll \
			-text [::msgcat::mc "選擇所有的項目"] \
			-image [$ibox get check_all] \
			-compound left \
			-command [list [self object] check_all "CHECK"] \
			-style Toolbutton \
		]		
		pack $btnCheckAll -side left -padx 6 -pady 2		
		
		set btnClearAll [ttk::button $tbar.btnClearAll \
			-text [::msgcat::mc "取消選取的項目"] \
			-image [$ibox get uncheck_all] \
			-compound left \
			-command [list [self object] check_all "!CHECK"] \
			-style Toolbutton \
		]		
		pack $btnClearAll -side left -padx 6 -pady 2
		
		pack [$Priv(obj,tv) sbar_filter_init $tbar.filter] -side right -padx 6 -pady 2
		
		bind $wpath <Visibility> [list $Priv(obj,tv) sbar_find]		
	}
}
