console show
update
proc del_svn {dpath} {
	set flist [glob -nocomplain -directory $dpath -types {d hidden} ".svn" ".__meta__"]
	foreach item $flist {
		switch -exact -- [file tail $item] {
			".svn" {file delete -force $item}
			".__meta__" {file delete -force $item}
		}
	}
	set flist [glob -nocomplain -directory $dpath -types {d} "*"]
	foreach item $flist {del_svn $item}	
}
del_svn ../
