oo::class create ::dApp::supplier {
	constructor {dir} {
		my variable Priv Columns
		
		array set Priv [list \
			pwd $dir \
		]

		source -encoding utf-8 [file join $dir style $::dApp::Env(os).tcl]		
		source -encoding utf-8 [file join $dir db.tcl]
		source -encoding utf-8 [file join $dir tableview.tcl]
		foreach f [glob -nocomplain -directory [file join $dir widgets] -types {f} -- *.tcl] {
			source -encoding utf-8 $f
		}
		
		set Priv(db) [::dApp::supplier::db new]
		set ::dApp::supplier::Obj(db) $Priv(db)
		
		set ::dApp::supplier::Obj(ibox)	[::twidget::ibox new]
		
		# <-- load images
		if {[file exists $::dApp::Env(imgPath)]} {
			foreach {f} [glob -nocomplain -directory [file join $dir images] -- *.png] {
				if {[string index [file tail $f] 0] == "."} {continue}
				$::dApp::supplier::Obj(ibox) add $f
			}
		}
		#-->
		
		set Columns(delete) [list id name tel1 fax1 email company_addr]
		set Columns(manager) [list id name tel1 company_addr contact_person contact_position contact_tel]
		set Columns(fetch) [list id name tel1 email company_addr]
		
		my Home_Init
	}
	
	destructor {
		my variable Priv
	}
	
	method add_close {} {
		return 1
	}
	
	method add_show {args} {
		set wpath ".nb.supplier_add"
		set ibox $::dApp::supplier::Obj(ibox)
		
		if {![winfo exists $wpath]} {
			set obj [::dApp::supplier::add new $wpath {*}$args]
		}

		$::dApp::Obj(uimgr) tab add $wpath \
			-text [::msgcat::mc "新增供應商"] \
			-image [$ibox get add_tab_icon]	\
			-closecmd [list [self object] add_close]
		return 		
	}

	method delete_close {} {
		my variable Priv
		return 1
	}

	method delete_show {args} {
		my variable Priv Columns
		
		set ibox $::dApp::supplier::Obj(ibox)
		
		set wpath ".nb.supplier_delete"
		if {![winfo exists $wpath]} {
			set obj [::dApp::supplier::delete new $wpath {*}$args]
			
			foreach {col title} [$Priv(db) columns] {
				if {$col == "id"} {set title "#"}
				$obj tv column_add $col -text $title -itemstyle text -visible 0
			}
			
			foreach {col} $Columns(delete) {
				$obj tv column_configure $col -visible 1
				$obj tv column_move $col
			}
			$obj tv column configure company_addr -expand 1
			
			$obj tv refresh_start
		}

		$::dApp::Obj(uimgr) tab add $wpath \
			-text [::msgcat::mc "刪除供應商"] \
			-image [$ibox get delete_tab_icon]	\
			-closecmd [list [self object] delete_close]
		return 
	}
	
	method edit_close {} {
		return 1
	}
	
	method edit_show {args} {
		my variable Priv Columns
		
		set wpath ".nb.supplier_edit"
		set ibox $::dApp::supplier::Obj(ibox)
		
		if {![winfo exists $wpath]} {
			set obj [::dApp::supplier::edit new $wpath {*}$args]	
		}

		$::dApp::Obj(uimgr) tab add $wpath \
			-text [::msgcat::mc "修改供應商"] \
			-image [$ibox get edit_tab_icon]	\
			-closecmd [list [self object] edit_close]
		return 		
	}
	
	method find_close {} {
		return 1
	}
	
	method find_show {args} {
		my variable Priv Columns
		
		set wpath ".nb.supplier_find"
		set ibox $::dApp::supplier::Obj(ibox)
		
		if {![winfo exists $wpath]} {
			set obj [::dApp::supplier::find new $wpath {*}$args]	
		}

		$::dApp::Obj(uimgr) tab add $wpath \
			-text [::msgcat::mc "搜尋供應商"] \
			-image [$ibox get search]	\
			-closecmd [list [self object] edit_close]
		return 		
	}	
	
	method fetch_close {} {
		return 1
	}
	
	method fetch_show {args} {
		my variable Priv Columns
		
		set wpath ".nb.supplier_fetch"
		set ibox $::dApp::supplier::Obj(ibox)
		
		if {![winfo exists $wpath]} {
			set obj [::dApp::supplier::fetch new $wpath {*}$args]
			foreach {col title} [$Priv(db) columns] {
				if {$col == "id"} {set title "#"}
				$obj tv column_add $col -text $title -itemstyle text -visible 0
			}
			
			foreach {col} $Columns(fetch) {
				$obj tv column_configure $col -visible 1
				$obj tv column_move $col
			}
			$obj tv column configure company_addr -expand 1
			$obj tv column_configure _OPERATION_ -visible 0
			
			$obj tv refresh_start			
		}

		$::dApp::Obj(uimgr) tab add $wpath \
			-text [::msgcat::mc "提取供應商郵件"] \
			-image [$ibox get fetch_tab_icon]	\
			-closecmd [list [self object] fetch_close]
		return 		
	}

	method manager {wpath args} {
		my variable Priv Columns
		
		set mgr [::dApp::supplier::manager new $wpath {*}$args]
		
		foreach {col title} [$Priv(db) columns] {
			if {$col == "id"} {set title "#"}
			$mgr tv column_add $col -text $title -itemstyle text -visible 0
		}
		
		foreach {col} $Columns(manager) {
			$mgr tv column_configure $col -visible 1
			$mgr tv column_move $col
		}
		$mgr tv column configure company_addr -expand 1
		$mgr tv column_move company_addr
		
		$mgr tv refresh_start		
		
		return $mgr
	}
	
	method tableview {wpath args} {
		my variable Priv
		
		set tv [::dApp::supplier::tableview new $wpath {*}$args]
		
		foreach {col title} [$Priv(db) columns] {
			if {$col == "id"} {set title "#"}
			$tv column_add $col -text $title -itemstyle text -visible 0
		}
		
		foreach {col} [list id name company_addr] {$tv column_configure $col -visible 1}
		$tv column configure company_addr -expand 1
		
		$tv refresh_start
		
		return $tv
	}
	
	method manager_close {} {
		variable Priv
		return 1
	}
	
	method manager_show {} {
		variable Priv
		
		set ibox $::dApp::supplier::Obj(ibox)
		set wpath ".nb.supplier_mgr"
		if {![winfo exists $wpath]} {set mgr [my manager $wpath]}

		$::dApp::Obj(uimgr) tab add $wpath \
			-text [::msgcat::mc "供應商管理"] \
			-image [$ibox get manager_tab_icon]	\
			-closecmd [list [self object] manager_close]
	}
	
	method Home_Init {} {
		
		set ibox $::dApp::supplier::Obj(ibox)
		
		set fmeMain [$::dApp::Obj(uimgr) widget_create]
		set fmeBody [ttk::frame $fmeMain.fme]
		set fmeR [ttk::frame $fmeMain.fmeR]
		set sbar [ttk::frame $fmeMain.sbar]
		
		grid $fmeBody $fmeR -sticky news -padx 2 -pady 2
		grid  $sbar -  -sticky news
		grid rowconfigure $fmeMain 0 -weight 1
		grid columnconfigure $fmeMain 0 -weight 1
		
		set lblTotal [ttk::label $sbar.lblTotal -text [::msgcat::mc "資料總數:"]]
		set lblCut [ttk::label $sbar.lblCut]
		set lblMsg [ttk::label $sbar.lblMsg -text [::msgcat::mc " 筆記錄"]]
		pack $lblTotal $lblCut $lblMsg -side left -padx 2 -pady 2
		
		bind $lblTotal <Visibility> [format {	
			%s configure -text [$::dApp::supplier::Obj(db) count]
		} $lblCut]
		
		set fmeIcon [ttk::frame $fmeBody.fmeIcon ]
		set fmeFun [ttk::frame $fmeBody.fmeFun ]
		place $fmeIcon -width 120 -height 120 
		place $fmeFun -relwidth 1 -width -120 -x 120 -relheight 1  -anchor nw
		
		set lblIcon [ttk::button $fmeIcon.lblIcon \
			-image [$ibox get supplier] \
			-text [::msgcat::mc "供應商管理模組"] \
			-command [list [self object] find_show] \
			-compound top]
		
		pack $lblIcon -expand 1 -fill both -padx 7 -pady 7 -anchor center

		ttk::button $fmeFun.btn1 \
			-image [$ibox get add] \
			-compound left \
			-text [::msgcat::mc "增加一筆新的記錄"] \
			-command [list [self object] add_show] \
			-style Toolbutton
		ttk::button $fmeFun.btn2 \
			-compound left \
			-image [$ibox get delete] \
			-text [::msgcat::mc "刪除已經建立記錄"] \
			-command [list [self object] delete_show] \
			-style Toolbutton

		ttk::button $fmeFun.btn3 \
			-compound left \
			-image [$ibox get edit] \
			-text [::msgcat::mc "修改已存在的記錄"] \
			-command [list [self object] edit_show] \
			-style Toolbutton

		ttk::button $fmeFun.btn4 \
			-compound left \
			-image [$ibox get search] \
			-text [::msgcat::mc "搜尋已存在的記錄"] \
			-command [list [self object] find_show] \
			-style Toolbutton

		ttk::button $fmeFun.btn5 \
			-compound left \
			-image [$ibox get mail] \
			-text [::msgcat::mc "提取供應商E-Mail"] \
			-command [list [self object] fetch_show] \
			-style Toolbutton

#		ttk::button $fmeFun.btn6 \
#			-compound left \
#			-image [$ibox get export] \
#			-text [::msgcat::mc "產生報表輸出"] \
#			-style Toolbutton			
	
	
		grid $fmeFun.btn1 $fmeFun.btn4 -padx 10 -pady 5  -sticky nw
		grid $fmeFun.btn2 $fmeFun.btn5 -padx 10 -pady 5 -sticky nw
		grid $fmeFun.btn3  -padx 10 -pady 5 -sticky nw
	
	}	
}







