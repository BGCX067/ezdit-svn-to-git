oo::class create ::dApp::supplier::find {
	constructor {wpath args} {
		my variable Priv Row Win
		
		array set Row [list]
		
		set Priv(win,frame) $wpath
		set Priv(opts,timerId) ""

		array set Row [list \
			id "" \
			name "" \
			principal "" \
			business_no "" \
			tel1 "" \
			tel2 "" \
			fax1 "" \
			fax2 "" \
			company_addr "" \
			invoice_addr "" \
			other_addr "" \
			email "" \
			contact_person "" \
			contact_position "" \
			contact_tel "" \
			contact_cellphone "" \
			contact_email "" \
			country "" \
			currency "" \
			credit_lines "" \
			payment "" \
			business_item "" \
			note "" \
			create_date "" \
		]
		
		set Row(currency) [::msgcat::mc "新台幣"]
		set Row(rank) "☆☆☆"
		set Row(payment) [::msgcat::mc "貨到付款"]
		set Row(credit_lines) 0
		set Row(country) [::msgcat::mc "台灣"]
		
		my Ui_Init
	}
	
	destructor {}
	
	method view {tv} {
		my variable Priv Row Win
		set db $::dApp::supplier::Obj(db)
		
		set item [$tv selection]
		if {$item == ""} {return}
		set id [$tv item $item -tags]
		
		foreach {key val} [$db get $id] {set Row($key) $val}
		
		$Win(note) configure -state normal
		$Win(business_item) configure -state normal
		$Win(note) replace 1.0 end $Row(note)
		$Win(business_item) replace  1.0 end $Row(business_item)					
		$Win(note) configure -state disabled
		$Win(business_item) configure -state disabled		
	}
	
	method find {} {
		my variable Priv Row
		
		set tv $Priv(win,tvFind)
		set db $::dApp::supplier::Obj(db)
		
		set keyword [string trim [string map {' ""} $Priv(var,txtFind)]]
		
		$tv delete [$tv children {}]

		if {$keyword == ""} {return}
		
		set filter "id LIKE '%$keyword%' OR name LIKE '%$keyword%' OR business_no LIKE '%$keyword%' "
		append filter " OR tel1 LIKE '%$keyword%' OR tel2 LIKE '%$keyword%' "
		append filter " OR business_item LIKE '%$keyword%' LIMIT 300 "
		set first ""
		foreach {id name} [$db query $filter -fields [list id name]] {
			$tv insert {} end -text $name -tags $id
			if {$first == ""} {set first $id}
		}
		if {$first != ""} {
			foreach {key val} [$db get $id] {set Row($key) $val}
		}
		
		
		
	}
	

	method refresh {} {
		my variable Priv Row Win
		
		set db $::dApp::supplier::Obj(db)
		set tv $Priv(win,tvRecent)
		
		$tv delete [$tv children {}]
		foreach {id name} [$db query "1==1 ORDER BY create_date DESC LIMIT 100" -fields [list id name]] {
			$tv insert {} end -text $name -tags $id	
		}
		
		set Priv(var,lblCount) [$db count]
		
		$Priv(win,txtFind) selection range 0 end
		after 250 [list focus $Priv(win,txtFind)]
		
		return
	}
	
	method Help_Put {msg} {
		my variable Priv
		
		set txt $Priv(win,txtHelp)
		$txt delete 1.0 end
		$txt insert end $msg
	}
	
	method Msg_Put {msg} {
		my variable Priv
		
		after cancel $Priv(opts,timerId)
		set Priv(var,lblMsg) $msg
		set Priv(opts,timerId) [after 5000 [list set [self namespace]::Priv(var,lblMsg) ""]]
	}
	
	method Ui_Body_Init {} {
		my variable Priv
		
		set ibox $::dApp::supplier::Obj(ibox)
		set body $Priv(win,body)
		
		set fmeL [ttk::frame $body.fmeL -style White.TFrame]
		set fmeR [ttk::frame $body.fmeR -style White.TFrame]
		
		$body add $fmeL -weight 1
		$body add $fmeR -weight 0
		
		set Priv(win,fmeL) $fmeL
		set Priv(win,fmeR) $fmeR
		
		
		my Ui_Body_fmeL_Init
		my Ui_Body_fmeR_Init		
	}
	
	method Ui_Body_fmeL_Init {} {
		my variable Priv Win
		
		set ibox $::dApp::supplier::Obj(ibox)
		
		set fmeL $Priv(win,fmeL)
		set ns [self namespace]
		
		###################基本資訊###################
		set fmeBasic [ttk::frame  $fmeL.fmeBasic -style White.TFrame]
		pack $fmeBasic -fill x -padx 5 -pady 5
		grid columnconfigure $fmeBasic 1 -weight 2
		grid columnconfigure $fmeBasic 3 -weight 2
		
		
		set lblTitle [ttk::label $fmeBasic.lblBasicTitle \
			-text [::msgcat::mc "基本資訊"] \
			-foreground "#0000db" \
			-relief solid \
			-anchor center]
		grid $lblTitle - - - -sticky we -padx 2 -pady 5 -ipady 3		

		set lblId [my Label_Create $fmeBasic.lblId -text [::msgcat::mc "供應商代號"]]
		set txtId [my Entry_Create $fmeBasic.txtId \
			-state readonly \
			-textvariable ${ns}::Row(id) \
			-help [::msgcat::mc "這是必要欄位，供應商代號必需是唯一的不能夠重複。"] \
		]
		set Win(id)	$txtId

		set lblPrincipal [my Label_Create $fmeBasic.lblPrincipal -text [::msgcat::mc "負責人"]]
		set txtPrincipal [my Entry_Create $fmeBasic.txtPrincipal \
			-textvariable ${ns}::Row(principal) \
			-help [::msgcat::mc "這是必要欄位，請輸入供應商負責人的姓名。"] \
		]	
		set Win(principal)	$txtPrincipal

		grid $lblId $txtId $lblPrincipal $txtPrincipal  -padx 2 -pady 2 -sticky we

		set lblName [my Label_Create $fmeBasic.lblName -text [::msgcat::mc "供應商名稱"]]
		set txtName [my Entry_Create $fmeBasic.txtName \
			-textvariable ${ns}::Row(name) \
			-help [::msgcat::mc "這是必要欄位，請輸入供應商名稱的名稱。"] \
		]
		set Win(name)	$txtName

		set lblBusinessNo [my Label_Create $fmeBasic.lblBusinessNo -text [::msgcat::mc "統一編號"]]
		set txtBusinessNo [my Entry_Create $fmeBasic.txtBusinessNo \
			-textvariable ${ns}::Row(business_no) \
			-help [::msgcat::mc "統一編號必需是空白，或是8碼的數字。"] \
		]
		set Win(business_no) $txtBusinessNo
		
		grid $lblName $txtName $lblBusinessNo $txtBusinessNo -sticky we -padx 2 -pady 2

		set lblTel1 [my Label_Create $fmeBasic.lblTel1 -text [::msgcat::mc "聯絡電話1"]]
		set txtTel1 [my Entry_Create $fmeBasic.txtTel1 \
			-textvariable ${ns}::Row(tel1) \
			-help [::msgcat::mc "這是必要欄位，請用以下符號組成電話號碼 ( ) 0-9 * # -。"] \
		]
		set Win(tel1) $txtTel1
		
		set lblTel2 [my Label_Create $fmeBasic.lblTel2 -text [::msgcat::mc "聯絡電話2"]]
		set txtTel2 [my Entry_Create $fmeBasic.txtTel2 \
			-textvariable ${ns}::Row(tel2) \
			-help [::msgcat::mc "請用以下符號組成電話號碼 ( ) 0-9 * # -。"] \
		]
		set Win(tel2) $txtTel2

		grid $lblTel1 $txtTel1 $lblTel2 $txtTel2 -sticky we -padx 2 -pady 2
		
		set lblFax1 [my Label_Create $fmeBasic.lblFax1 -text [::msgcat::mc "傳真號碼1"]]
		set txtFax1 [my Entry_Create $fmeBasic.txtFax1 \
			-textvariable ${ns}::Row(fax1) \
			-help [::msgcat::mc "請用以下符號組成傳真號碼 ( ) 0-9 * # -。"] \
		]
		set Win(fax1) $txtFax1

		set lblFax2 [my Label_Create $fmeBasic.lblFax2 -text [::msgcat::mc "傳真號碼2"]]
		set txtFax2 [my Entry_Create $fmeBasic.txtFax2 \
			-textvariable ${ns}::Row(fax2) \
			-help [::msgcat::mc "請用以下符號組成傳真號碼 ( ) 0-9 * # -。"] \
		]
		set Win(fax2) $txtFax2

		grid $lblFax1 $txtFax1 $lblFax2 $txtFax2 -sticky we -padx 2 -pady 2				

		set lblCompanyAddr [my Label_Create $fmeBasic.lblCompanyAddr -text [::msgcat::mc "公司地址"] ]
		set txtCompanyAddr [my Entry_Create $fmeBasic.txtCompanyAddr \
			-textvariable ${ns}::Row(company_addr) \
			-help [::msgcat::mc "請用中文、英文或是數字組成地址，且不要使用標點符號。"] \
		]
		set Win(company_addr) $txtCompanyAddr

		set lblInvoiceAddr [my Label_Create $fmeBasic.lblInvoiceAddr -text [::msgcat::mc "發票地址"]]
		set txtInvoiceAddr [my Entry_Create $fmeBasic.txtInvoiceAddr \
			-textvariable ${ns}::Row(invoice_addr) \
			-help [::msgcat::mc "請用中文、英文或是數字組成地址，且不要使用標點符號。"] \
		]
		set Win(invoice_addr) $txtInvoiceAddr

		grid $lblCompanyAddr $txtCompanyAddr $lblInvoiceAddr $txtInvoiceAddr - - -sticky we -padx 2 -pady 2
		
		set lblOtherAddr [my Label_Create $fmeBasic.lblOtherAddr -text [::msgcat::mc "其它地址"]]
		set txtOtherAddr [my Entry_Create $fmeBasic.txtOtherAddr \
			-textvariable ${ns}::Row(other_addr) \
			-help [::msgcat::mc "請用中文、英文或是數字組成地址，且不要使用標點符號。"] \
		]
		set Win(other_addr) $txtOtherAddr


		set lblEMail [my Label_Create $fmeBasic.lblEMail -text [::msgcat::mc "E-Mail"] ]
		set txtEMail [my Entry_Create $fmeBasic.txtEMail \
			-textvariable ${ns}::Row(email) \
			-help [::msgcat::mc "請輸入合法的電子郵件地址。"] \
		]
		set Win(email) $txtEMail
		
		grid $lblOtherAddr $txtOtherAddr $lblEMail $txtEMail - - -sticky we -padx 2 -pady 2


		################# 聯絡人資訊#########################
		set lblTitle [ttk::label $fmeBasic.lblContastTitle \
			-text [::msgcat::mc "聯絡人資訊"] \
			-foreground "#0000db" \
			-relief solid \
			-anchor center]
		grid $lblTitle - - - -sticky we -padx 2 -pady 5 -ipady 3
		
		set lblPerson [my Label_Create $fmeBasic.lblPerson -text [::msgcat::mc "聯絡人"] ]
		set txtPerson [my Entry_Create $fmeBasic.txtPerson \
			-textvariable ${ns}::Row(contact_person) \
			-help [::msgcat::mc "請輸入聯絡人的姓名或是稱呼。"] \
		]
		set Win(contact_person) $txtPerson
		
		set lblPosition [my Label_Create $fmeBasic.lblPosition \
			-text [::msgcat::mc "職稱"] \
		]
		set txtPosition [my Entry_Create $fmeBasic.txtPosition \
			-textvariable ${ns}::Row(contact_position) \
			-help [::msgcat::mc "請輸入聯絡人的職稱。輸入過的項目將會自動記憶在下拉選單。"] \
		]
		set Win(contact_position) $txtPosition

		grid $lblPerson $txtPerson $lblPosition $txtPosition -sticky we -padx 2 -pady 2
				
		set lblTel [my Label_Create $fmeBasic.lblTel -text [::msgcat::mc "一般電話"]]
		set txtTel [my Entry_Create $fmeBasic.txtTel \
			-textvariable ${ns}::Row(contact_tel) \
			-help [::msgcat::mc "請用以下符號組成電話號碼 ( ) 0-9 * # -。"] \
		]
		set Win(contact_tel) $txtTel
		
		set lblCellphone [my Label_Create $fmeBasic.lblCellphone -text [::msgcat::mc "行動電話"]]
		set txtCellphone [my Entry_Create $fmeBasic.txtCellphone \
			-textvariable ${ns}::Row(contact_cellphone) \
			-help [::msgcat::mc "請用數字0-9組成行動電話。"] \
		]
		set Win(contact_cellphone) $txtCellphone
		
		grid $lblTel $txtTel $lblCellphone $txtCellphone -sticky we -padx 2 -pady 2

		set lblEMail [my Label_Create $fmeBasic.lblContactEMail -text [::msgcat::mc "E-Mail"]]
		set txtEMail [my Entry_Create $fmeBasic.txtContactEMail \
			-textvariable ${ns}::Row(contact_email) \
			-help [::msgcat::mc "請輸入合法的電子郵件地址。"] \
		]
		set Win(contact_email) $txtEMail
		
		grid $lblEMail $txtEMail -sticky we -padx 2 -pady 2
		
		################# 其它資訊#########################
		set lblTitle [ttk::label $fmeBasic.lblOtherTitle \
			-text [::msgcat::mc "其它資訊"] \
			-foreground "#0000db" \
			-relief solid \
			-anchor center]
		grid $lblTitle - - - -sticky we -padx 2 -pady 5 -ipady 3		

		set lblCountry [my Label_Create $fmeBasic.lblCountry -text [::msgcat::mc "國家"]]
		set txtCountry [my Entry_Create $fmeBasic.txtCountry \
			-textvariable ${ns}::Row(country) \
			-help [::msgcat::mc "請輸入供應商的國家。輸入過的項目將會自動記憶在下拉選單。"] \
		]
		set Win(country) $txtCountry

		set lblCurrency [my Label_Create $fmeBasic.lblCurrency -text [::msgcat::mc "貨幣"]]
		set txtCurrency [my Entry_Create $fmeBasic.txtCurrency \
			-textvariable ${ns}::Row(currency) \
			-help [::msgcat::mc "請輸入供應商使用的貨幣。輸入過的項目將會自動記憶在下拉選單。"] \
		]		
		set Win(currency) $txtCurrency
		
		grid $lblCountry $txtCountry $lblCurrency $txtCurrency -sticky we -padx 2 -pady 2

		set lblPayment [my Label_Create $fmeBasic.lblPayment -text [::msgcat::mc "付款方式"]]
		set txtPayment [my Entry_Create $fmeBasic.txtPayment \
			-textvariable ${ns}::Row(payment) \
			-help [::msgcat::mc "請輸入付款方式。輸入過的項目將會自動記憶在下拉選單。"] \
		]
		set Win(payment) $txtPayment
	
		set lblRank [my Label_Create $fmeBasic.lblRank -text [::msgcat::mc "關係"]]
		set txtRank [my Entry_Create $fmeBasic.txtRank \
			-textvariable ${ns}::Row(rank) \
			-help [::msgcat::mc "請輸入與供應商的關係。"] \
		]
		set Win(rank) $txtRank
			
	
		grid $lblPayment $txtPayment  $lblRank $txtRank -sticky we -padx 2 -pady 2

		
		set lblCreditlines [my Label_Create $fmeBasic.lblCreditlines -text [::msgcat::mc "信用額度"]]
		set txtCreditlines [my Entry_Create $fmeBasic.txtCreditlines \
			-textvariable ${ns}::Row(credit_lines) \
			-help [::msgcat::mc "請用數字0-9輸入信用額度。"] \
		]
		set Win(credit_lines) $txtCreditlines		
		
		set lblCreateDate [my Label_Create $fmeBasic.lblCreateDate -text [::msgcat::mc "建檔時間"]]
		set txtCreateDate [my Entry_Create $fmeBasic.txtCreateDate \
			-state readonly \
			-textvariable ${ns}::Row(create_date) \
			-help [::msgcat::mc "這項資訊是自動產生的，不能夠修改。"] \
		]
		set Win(credit_lines) $txtCreditlines				
		
		grid $lblCreditlines $txtCreditlines $lblCreateDate $txtCreateDate -sticky we -padx 2 -pady 2		

		set lblBusinessItem [my Label_Create $fmeBasic.lblBusinessItem -text [::msgcat::mc "營業項目"]]
		
		set fmeBusinessItem [ttk::frame $fmeBasic.fmeBusinessItem]
		set txtBusinessItem [text $fmeBusinessItem.txtNote \
			-state disabled \
			-relief groove \
			-bd 2 \
			-height 5 \
			-width 1 \
			-wrap none]
		set vs [ttk::scrollbar $fmeBusinessItem.vs -command [list $txtBusinessItem yview] -orient vertical]
		set hs [ttk::scrollbar $fmeBusinessItem.hs -command [list $txtBusinessItem xview] -orient horizontal]
		$txtBusinessItem configure -xscrollcommand [list $hs set] -yscrollcommand [list $vs set]
		::autoscroll::autoscroll $vs
		::autoscroll::autoscroll $hs
		grid $txtBusinessItem $vs -sticky "news"
		grid $hs - -sticky "we"
		grid rowconfigure $fmeBusinessItem 0 -weight 1
		grid columnconfigure $fmeBusinessItem 0 -weight 1
		
		bind $txtBusinessItem <FocusIn> [list $txtBusinessItem configure -bg yellow]
		bind $txtBusinessItem <FocusOut> [list $txtBusinessItem configure -bg white]

		set Win(business_item) $txtBusinessItem

		set lblNote [my Label_Create $fmeBasic.lblNote -text [::msgcat::mc "備註"]]
		
		set fmeNote [ttk::frame $fmeBasic.fmeNote]
		set txtNote [text $fmeNote.txtNote \
			-state disabled \
			-relief groove \
			-bd 2 \
			-height 5 \
			-width 1 \
			-wrap none]
		set vs [ttk::scrollbar $fmeNote.vs -command [list $txtNote yview] -orient vertical]
		set hs [ttk::scrollbar $fmeNote.hs -command [list $txtNote xview] -orient horizontal]
		$txtNote configure -xscrollcommand [list $hs set] -yscrollcommand [list $vs set]
		::autoscroll::autoscroll $vs
		::autoscroll::autoscroll $hs
		grid $txtNote $vs -sticky "news"
		grid $hs - -sticky "we"
		grid rowconfigure $fmeNote 0 -weight 1
		grid columnconfigure $fmeNote 0 -weight 1
		
		bind $txtNote <FocusIn> [list $txtNote configure -bg yellow]
		bind $txtNote <FocusOut> [list $txtNote configure -bg white]

		grid $lblBusinessItem $fmeBusinessItem $lblNote $fmeNote -sticky new -padx 2 -pady 3

	
		set Win(note) $txtNote
	
	}
	
	method Ui_Body_fmeR_Init {} {
		my variable Priv
		
		set ibox $::dApp::supplier::Obj(ibox)
		
		set fmeR $Priv(win,fmeR)
		
		######################### 搜尋說明 ############################
		set fme [ttk::frame $fmeR.fmeHelp -borderwidth 2 -relief groove]
		set lblTitle [ttk::label $fme.lblTitle -text [::msgcat::mc "搜尋說明"] -anchor center]
		set txtHelp [text $fme.txtHelp -bd 2 -relief groove -height 6 -width 5]
		pack $lblTitle $txtHelp -fill x -pady 3 -padx 5
		pack $fme -fill both -padx 3 -pady 3	
		
		set Priv(win,txtHelp) $txtHelp				
		
		set msg [::msgcat::mc "您可以在快速搜尋欄位輸入供應商編號、供應商名稱、供應商電話、統一編號或是營業項目等欄位可能包含的內容。"]
		$txtHelp insert end $msg		
		
		######################### 搜尋結果 ############################
		set fme [ttk::frame $fmeR.fmeFind -borderwidth 2 -relief groove]
		set lblTitle [ttk::label $fme.lblTitle -text [::msgcat::mc "搜尋結果"] -anchor center -justify center]

		set fmeTv [ttk::frame $fme.fmeTv]
		set tvFind [ttk::treeview $fmeTv.tvFind -show "tree" -selectmode browse -height 6]
		set btnApply [ttk::button $fmeTv.btnApply \
			-image [$ibox get apply] \
			-text [::msgcat::mc "檢視"] \
			-compound left \
			-style Toolbutton \
			-command [list [self object] view $tvFind] \
		]
		set vs [ttk::scrollbar $fmeTv.vs -command [list $tvFind yview] -orient vertical]
		set hs [ttk::scrollbar $fmeTv.hs -command [list $tvFind xview] -orient horizontal]
		$tvFind configure -xscrollcommand [list $hs set] -yscrollcommand [list $vs set]
		::autoscroll::autoscroll $vs
		::autoscroll::autoscroll $hs
		grid $tvFind - $vs -sticky news -pady 3 -padx 3
		grid $hs - - -pady 3 -sticky we -padx 3		
		grid columnconfigure $fmeTv 0 -weight 1
		grid rowconfigure $fmeTv 0 -weight 1		
		
		grid $lblTitle - - -sticky we -pady 3 -padx 2
		grid $fmeTv - - -sticky news -pady 3 -padx 3
		grid $hs - - -pady 3 -sticky we -padx 3
		grid $btnApply - - -pady 3 -sticky e -padx 3
		
		grid columnconfigure $fme 0 -weight 1
		grid rowconfigure $fme 1 -weight 1
		
		pack $fme -fill both -padx 3 -pady 3 
		
		bind $tvFind <<ButtonL-DClick>> [list [self object] view $tvFind]
		set Priv(win,tvFind) $tvFind
		
		######################### 最近新增 ############################
		set fme [ttk::frame $fmeR.fmeRecent -borderwidth 2 -relief groove -padding 5]
		set lblTitle [ttk::label $fme.lblTitle -text [::msgcat::mc "最近新增"] -anchor center]
		set tvRecent [ttk::treeview $fme.tvRecent -show "tree" -selectmode browse -height 6]
		set btnApply [ttk::button $fme.btnApply \
			-image [$ibox get apply] \
			-text [::msgcat::mc "檢視"] \
			-compound left \
			-style Toolbutton \
			-command [list [self object] view $tvRecent] \
		]
			
		set vs [ttk::scrollbar $fme.vs -command [list $tvRecent yview] -orient vertical]
		set hs [ttk::scrollbar $fme.hs -command [list $tvRecent xview] -orient horizontal]
		$tvRecent configure -xscrollcommand [list $hs set] -yscrollcommand [list $vs set]
		::autoscroll::autoscroll $vs
		::autoscroll::autoscroll $hs
		
		grid $lblTitle - -sticky we -pady 3 -padx 5
		grid $tvRecent $vs -sticky "news"
		grid $hs - -sticky "we"
		grid $btnApply -  -pady 3 -padx 3 -sticky e
		grid rowconfigure $fme 1 -weight 1
		grid columnconfigure $fme 0 -weight 1			
			
		pack $fme -fill both -padx 3 -pady 3	
		
		bind $tvRecent <<ButtonL-DClick>> [list [self object] view $tvRecent]
		set Priv(win,tvRecent) $tvRecent
	}
	
	method Ui_Init {} {
		my variable Priv
		
		
		set wpath $Priv(win,frame)
		
		ttk::frame $wpath -style White.TFrame -borderwidth 2 -relief groove
		
		set tbar [ttk::frame $wpath.tbar]
		set body [ttk::panedwindow $wpath.body -orient horizontal]
		set sbar [ttk::frame $wpath.sbar]
		pack $tbar -fill x
		pack [ttk::separator $wpath.spe1 -orient horizontal] -fill x
		pack $body -expand 1 -fill both
		#pack [ttk::separator $wpath.spe2 -orient horizontal]
		pack $sbar -fill x
		
		set Priv(win,tbar) $tbar
		set Priv(win,body) $body
		set Priv(win,sbar) $sbar
		
		bind $wpath <Visibility> [list [self object] refresh]
		
		my Ui_Tbar_Init
		my Ui_Body_Init
		my Ui_Sbar_Init
	}
	
	method Ui_Sbar_Init {} {
		my variable Priv
		
		set sbar $Priv(win,sbar)
		
		set lblMsg [ttk::label $sbar.lblMsg \
			-anchor w \
			-justify right \
			-textvariable [self namespace]::Priv(var,lblMsg) \
		]
		pack $lblMsg -expand 1 -fill x -padx 3 -pady 3 -side left
		
		set Priv(var,lblTotal) 0
		ttk::label $sbar.lblCount -textvariable [self namespace]::Priv(var,lblCount)
		ttk::label $sbar.lblTotal -text [::msgcat::mc "資料總數 : "]
		
		pack  $sbar.lblTotal $sbar.lblCount -side left -padx 3 -pady 3
				
		
	}
	
	method Ui_Tbar_Init {} {
		my variable Priv
		
		set ibox $::dApp::supplier::Obj(ibox)
		set tbar $Priv(win,tbar)
		
		set lblPos [ttk::label $tbar.lblPos \
			-text [::msgcat::mc "供應商模組 > 搜尋供應商"] \
			-style Position.TLabel \
		]
		pack $lblPos -fill y -padx 6 -pady 2 -side left		
		pack [ttk::separator $tbar.sep1 -orient vertical] -fill y -padx 6 -pady 2 -side left				
		
		set Priv(var,txtFind) [::msgcat::mc "輸入關鍵字"]
		set lblFind [ttk::label $tbar.lblFind -text [::msgcat::mc "快速搜尋"]]
		set txtFind [ttk::entry $tbar.txtFind \
			-textvariable [self namespace]::Priv(var,txtFind)]
		set btnFind [ttk::button $tbar.btnFind \
			-image [$ibox get find] \
			-style Toolbutton \
			-command [list [self object] find] \
		]		
		
		
		bind $txtFind <Return> [list $btnFind invoke]
		set Priv(win,txtFind) $txtFind
		pack $btnFind $txtFind $lblFind   -padx 6 -pady 2 -side right
		
	}
	
	method Combobox_Create {wpath args} {
		
		array set opts [list \
			-style Field.TCombobox \
			-help "" \
		]
		array set opts $args
		
		set help $opts(-help)
		
		unset opts(-help)
		
		ttk::combobox $wpath {*}[array get opts]
		return $wpath
	}		
	
	method Entry_Create {wpath args} {
		
		array set opts [list \
			-style Field.TEntry \
			-help "" \
			-state "readonly" \
		]
		array set opts $args
		
		set help $opts(-help)
		
		unset opts(-help)
		ttk::entry $wpath {*}[array get opts]
		return $wpath
	}	
	
	method Label_Create {wpath args} {
		
		array set opts [list \
			-style Field.TLabel \
			-anchor e \
			-justify right \
		]
		array set opts $args
		
		return [ttk::label $wpath {*}[array get opts]]
	}
	
	export Help_Put

}
