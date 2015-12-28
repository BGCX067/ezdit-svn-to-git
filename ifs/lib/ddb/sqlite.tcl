package require sqlite3
package require TclOO

package provide ::ddb::sqlite 1.0

oo::class create ::ddb::sqlite {
	constructor {dbfile} {
		my variable Priv
		
		set Priv(dbfile) $dbfile
		set Priv(dbCmd) [self namespace]::dbCmd
		
		sqlite3  $Priv(dbCmd) $dbfile
		
	}
	
	destructor {
		my variable Priv
		
		$Priv(dbCmd) close
	}
	
	method reset {} {
		# 清空所有資料庫的表格
		my variable Priv
		
		$Priv(dbCmd) close
		file delete $Priv(dbfile)
		sqlite3  $Priv(dbCmd) $Priv(dbfile)
	}
	
	method transaction_begin {} {
		# 
		my variable Priv
		
		$Priv(dbCmd) eval "BEGIN TRANSACTION;"
	}
	
	method transaction_end {} {
		my variable Priv
		
		$Priv(dbCmd) eval "END TRANSACTION;"
	}	
	
	method count {table {filter "1==1"}} {
		my variable Priv
		
		set cut [$Priv(dbCmd) eval "SELECT count(*) FROM $table WHERE $filter ;"	]
		
		return $cut	
	}
	
	method create {table spec} {
		my variable Priv
		
		$Priv(dbCmd) eval "CREATE TABLE $table ($spec);"
		
		return 1
	}	
	
	method delete {table filter args} {
		my variable Priv
	
		array set opts [list \
			-filter $filter \
		]
		array set opts $args
		
		append qs "DELETE FROM " $table
		if {$opts(-filter) != ""} {append qs " WHERE " $opts(-filter)}		
		
		append qs " ; "
		
		$Priv(dbCmd) eval $qs
		
		array unset opts
		return [$Priv(dbCmd) changes]
	}
	
	method drop {table} {
		my variable Priv
		
		set ret [catch {$Priv(dbCmd) eval "DROP TABLE $table ;"	}]
		
		return [expr !$ret]
	}	
	
	method insert {table args} {
		my variable Priv
		
		set qs "INSERT INTO $table"
		array set data $args
		
		append qs "(" [join [array names data] ","] ")"
		
		set values [list]
		foreach key [array names data] {
			lappend values "\$data($key)"
		}
		append qs " VALUES (" [join  $values ","] ");"

		$Priv(dbCmd) eval $qs

		array unset data
		
		return [$Priv(dbCmd) changes]
	}
	
	method query {tables filter args} {
		my variable Priv
	
		array set opts [list \
			-command "" \
			-filter $filter \
			-fields * \
		]
		
		array set opts $args
		
		set tables [join $tables ","]
		
		if {$opts(-fields) != "*"} {set opts(-fields) [join $opts(-fields) ","]} 
	
		append qs "SELECT " $opts(-fields) " FROM " $tables
		if {$opts(-filter) != ""} {append qs " WHERE " $opts(-filter)}

		if {$opts(-command) == ""} {
			array unset opts
			return [$Priv(dbCmd) eval $qs]
		}
		set cut 0
		array set result [list]
		$Priv(dbCmd) eval $qs result {
			incr cut
			if {[info exists result(*)]} {unset result(*)}
			eval [linsert $opts(-command) end {*}[array get result]]
		}
		array unset opts
		
		return $cut
	}
	
	method update {table filter args} {
		my variable Priv
		
		set qs "UPDATE $table SET "

		array set data [list \
			-filter $filter \
		]
		array set data $args
		
		set values [list]
		foreach {key val} $args {
			set tmp ""
			append tmp $key "=" \$data($key) " "
			lappend values $tmp 
		}
		
		append qs [join $values ","]
		
		if {$data(-filter) != ""} {append qs " WHERE " $data(-filter)}

		$Priv(dbCmd) eval $qs
		
		return [$Priv(dbCmd) changes]
	}
}
