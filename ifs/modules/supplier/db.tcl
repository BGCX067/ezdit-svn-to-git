oo::class create ::dApp::supplier::db {
	constructor {} {
		my variable Priv Schema
		
		set Priv(obj,validator) [::ddb::validator new]
		set v $Priv(obj,validator)
		set Schema(*) [list supplier]
		set Schema(supplier) [list \
			[list \
				name "_CHECK_" \
				modifier "text" \
				validator "" \
				text [::msgcat::mc ""]] \
			[list \
				name "id" \
				modifier "text" \
				validator [list my validate_id] \
				text [::msgcat::mc "編號"]] \
			[list \
				name "name" \
				modifier "text" \
				validator [list my validate_name] \
				text [::msgcat::mc "供應商"]] \
			[list \
				name "principal" \
				modifier "text" \
				validator [list $v string 1 30 ""] \
				text [::msgcat::mc "負責人"]] \
			[list \
				name "business_no" \
				modifier "text" \
				validator [list my validate_business_no] \
				text [::msgcat::mc "統一編號"]] \
			[list \
				name "tel1" \
				modifier "text" \
				validator [list $v string 1 20 "0123456789()-#*"] \
				text [::msgcat::mc "聯絡電話1"]] \
			[list \
				name "tel2" \
				modifier "text" \
				validator [list $v string 0 20 "0123456789()-#*"] \
				text [::msgcat::mc "聯絡電話2"]] \
			[list \
				name "fax1" \
				modifier "text" \
				validator [list $v string 0 20 "0123456789#*-"] \
				text [::msgcat::mc "傳真號碼1"]] \
			[list \
				name "fax2" \
				modifier "text" \
				validator [list $v string 0 20 "0123456789#*-"] \
				text [::msgcat::mc "傳真號碼2"]] \
			[list \
				name "company_addr" \
				modifier "text" \
				text [::msgcat::mc "公司地址"]] \
			[list \
				name "invoice_addr" \
				modifier "text" \
				text [::msgcat::mc "發票地址"]] \
			[list \
				name "other_addr" \
				modifier "text" \
				text [::msgcat::mc "其它地址"]] \
			[list \
				name "email" \
				modifier "text" \
				text [::msgcat::mc "E-Mail"]] \
			[list \
				name "contact_person" \
				modifier "text" \
				text [::msgcat::mc "聯絡人"]] \
			[list \
				name "contact_position" \
				modifier "text" \
				text [::msgcat::mc "聯絡人職稱"]] \
			[list \
				name "contact_tel" \
				modifier "text" \
				validator [list $v string 0 20 "0123456789()-#*"] \
				text [::msgcat::mc "聯絡人電話"]] \
			[list \
				name "contact_cellphone" \
				modifier "text" \
				validator [list $v string 0 20 "0123456789"] \
				text [::msgcat::mc "聯絡人手機"]] \
			[list \
				name "contact_email" \
				modifier "text" \
				text [::msgcat::mc "聯絡人E-Mail"]] \
			[list \
				name "country" \
				modifier "text" \
				text [::msgcat::mc "國家"]] \
			[list \
				name "currency" \
				modifier "text" \
				text [::msgcat::mc "貨幣"]] \
			[list \
				name "credit_lines" \
				modifier "text" \
				validator [list $v int 0 100000000] \
				text [::msgcat::mc "信用額度"]] \
			[list \
				name "payment" \
				modifier "text" \
				text [::msgcat::mc "付款方式"]] \
			[list \
				name "rank" \
				modifier "text" \
				text [::msgcat::mc "關係"]] \
			[list \
				name "business_item" \
				modifier "text" \
				text [::msgcat::mc "營業項目"]] \
			[list \
				name "note" \
				modifier "text" \
				text [::msgcat::mc "備註"]] \
			[list \
				name "create_date" \
				modifier "text" \
				text [::msgcat::mc "建立日期"]] \
		]
		
		set Schema(*,columns) [list]
		foreach {tbl} $Schema(*) {
			foreach {item} $Schema($tbl) {
				array set opts [list validator ""]
				array set opts $item
				lappend Schema(*,columns) $opts(name)
				set Schema($tbl,$opts(name),modifier) $opts(modifier)
				set Schema($tbl,$opts(name),text) $opts(text)
				set Schema($tbl,$opts(name),validator) $opts(validator)
				array unset opts
			}
		}
		my DB_Init
	}
	
	destructor {
		my variable Priv
		$Priv(obj,validator) destroy
	}
	
	method add {args} {
		my variable Priv Schema

		set invalid [list]
		set data [list]
		foreach {key val} $args {
			if {$Schema(supplier,$key,validator) != ""} {
				if {[eval [linsert $Schema(supplier,$key,validator) end $val]] != "1"} {
					lappend invalid $key
				}
			}
		}

		if {[llength $invalid] > 0} {return $invalid}
		
		set ret [$::dApp::Obj(db) insert supplier {*}$args]
		if {$ret == 1} {my sn_incr}
		
		return $ret
	}
	
	method begin {} {
		my variable Priv Schema
		return [$::dApp::Obj(db) transaction_begin]
	}
	
	method check {ids state} {
		my variable Priv Schema
		

		if {$Schema(supplier,_CHECK_,validator) != ""} {
			if {[eval [linsert $Schema(supplier,_CHECK_,validator) end $state]] != "1"} {return 0}
		}
		
		if {$ids == ""} {
			set filter " 1 == 1 "
		} else {
			foreach id $ids {append filter " id == '$id' OR"}
			set filter [string range $filter 0 end-2]
		}
		return [$::dApp::Obj(db) update supplier $filter _CHECK_ $state]
	}
	
	method checks {} {
		my variable Priv Schema

		set filter "_CHECK_ == 'CHECK'"		
		return [$::dApp::Obj(db) query supplier $filter -fields "id"]
	}	
	
	method columns {} {
		my variable Priv Schema
		
		set ret [list]
		foreach {key} $Schema(*,columns) {
			lappend ret $key $Schema(supplier,$key,text)
		}
		
		return $ret			
	}
	
	method count {{filter "1==1"}} {		
		return [$::dApp::Obj(db) count supplier $filter]
	}
	
	method delete {ids} {
		my variable Priv Schema
		
		foreach id $ids {append filter " id == '$id' OR"}
		set filter [string range $filter 0 end-2]
		
		return [$::dApp::Obj(db) delete supplier $filter]
	}
	
	method end {} {
		my variable Priv Schema
		return [$::dApp::Obj(db) transaction_end]
	}	
	
	method get {id} {
		my variable Priv Schema
		append filter " id == '$id'"

		set data [$::dApp::Obj(db) query supplier $filter]

		set ret [list]
		set columns $Schema(*,columns)
		set idx 0
		foreach {val} $data {
			lappend ret [lindex $columns $idx] $val
			incr idx
		}
		puts ret=$ret
		return $ret
	}
	
	method sn_get {} {
		set sn [$::dApp::Obj(db) param_get "supplier.sn"]
		
		return S[string range "00000000$sn" end-6 end]
	}
	
	method sn_incr {} {
		set sn [$::dApp::Obj(db) param_get "supplier.sn"]
		$::dApp::Obj(db) param_set "supplier.sn" [incr sn]
	}
	
	method query {filter args} {
		my variable Priv Schema
		return [$::dApp::Obj(db) query supplier $filter {*}$args]
	}
	
	method set {ids args} {
		my variable Priv Schema
		
		set data [list]
		set invalid [list]
		foreach {key val} $args {
			if {$Schema(supplier,$key,validator) != ""} {
				if {$key == "id"} {continue}
				if {$key == "name" && [string trim $val] == ""} {lappend invalid $key}
				if {$key == "name"} {continue}
				if {[eval [linsert $Schema(supplier,$key,validator) end $val]] != "1"} {
					lappend invalid $key
				}
			}
		}
		
		if {[llength $invalid] > 0} {return $invalid}
		
		foreach id $ids {append filter " id == '$id' OR"}
		set filter [string range $filter 0 end-2]

		return [$::dApp::Obj(db) update supplier $filter {*}$args]
	}
	
	method validate_business_no {val} {
		my variable Priv
		
		if {$val == ""} {return 1}
		return [$Priv(obj,validator) string 8 8 "0123456789" $val]
	}
	
	method validate_id {id} {
		if {[string trim $id] == ""} {return 0}
		if {[my get $id] != ""} {return 0}
		return 1
	}
	
	method validate_name {name} {
		if {[string trim $name] == ""} {return 0}
		set filter "name == '$name'"
		if {[my query $filter -fields id] != ""} {return}
		return 1
	}	
	
	method DB_Init {} {
		my variable Priv Schema
		
		set val [$::dApp::Obj(db) param_get "supplier.init"]
		
		if {$val != ""} {return}

		foreach {tbl} $Schema(*) {
			set desc [list]
			foreach {item} $Schema($tbl) {
				array set opts $item
				lappend desc "$opts(name) $opts(modifier)"
				array unset opts
			}
			$::dApp::Obj(db) create $tbl [join $desc ","]
		}
		
		$::dApp::Obj(db) param_add "supplier.init" 1
		$::dApp::Obj(db) param_add "supplier.sn" 1
		#my Create_Test_Data
		
	}

	method Create_Test_Data {} {
		my variable Priv

		my begin
		for {set i 0} {$i <300} {incr i} {
			my add \
				id $i \
				name "V$i" \
				company_addr "addr fjsdlfkjsdkfjskdfjklsdjflksadjfsldjfda $i" \
				create_date $i
		}
		my end
	}
	
}



