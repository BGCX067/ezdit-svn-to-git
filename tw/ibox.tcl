# 功能 : 影像管理
# ibox 以圖檔的檔名 來識別一個image resource


# 使用範例
# set ibox [::tw::ibox new]
# $ibox add a.png b.png c.jpg 
# button .btn -image [$ibox get a.png]   ;# a.png
# button .btn -image [$ibox get d.gif]  ;# 不存在所以回傳1x1 px的空白圖片
# 

package provide ::tw::ibox $::tw::OPTS(version)
::oo::class create ::tw::ibox {
	constructor {args} {
		# SYNOPSIS : ibox new
		my variable PRIV

		set PRIV(__unknow__) [image create photo -format png -data {
			iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAAZiS0dEAP8A
			/wD/oL2nkwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB9kBEA4WLl5MDHoAAAAZdEVYdENv
			bW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBXgQ4XAAAAEklEQVQ4y2NgGAWjYBSMAggAAAQQAAGFP6py
			AAAAAElFTkSuQmCC
		}]
	}

	destructor {
		my variable PRIV
		foreach name [array names PRIV] {my delete $name}
	}

	method add {args} {
		# SYNOPSIS : iboxobj add filepath ?filepath? ...
		# RETURN : count
		my variable PRIV

		set cut 0
		foreach fpath $args {
			if {![file exists $fpath]} {continue}
			set name [file tail $fpath]
			if {[info exists PRIV($name)]} {
				$PRIV($name) configure -file $fpath
			} else {
				set PRIV($name) [image create photo -file $fpath]
			}
			incr cut
		}
	}

	method delete {args} {
		# SYNOPSIS : iboxobj delete name ?name? ?name?
		my variable PRIV
		foreach name $args {
			if {[info exists PRIV($name)]} {catch {image delete $PRIV($name)}}
			array unset PRIV $name
		}
	}

	method exists {name} {
		# SYNOPSIS : iboxobj exists name
		# RETURN : 1 -> exists , 0 -> not exists
		my variable PRIV
		if {[info exists PRIV($name)]} {return 1}
		return 0
	}

	method get {name} {
		# SYNOPSIS : iboxobj get name
		# RETURN : named image or unknow image
		my variable PRIV

		if {![info exists PRIV($name)] } {return $PRIV(__unknow__)}
		return $PRIV($name)
	}

	method names {} {
		# SYNOPSIS : iboxobj names
		# RETURN : all image name
		my variable PRIV

		return [array names PRIV]
	}

	method set {args} {
		# SYNOPSIS : iboxobj set name image name image ...
		# RETURN : count
		my variable PRIV

		set cut 0
		foreach {name img} $args {
			if {[info exists PRIV($name)]} {
				$PRIV($name) copy $img
			} else {
				set PRIV($name) $img
			}
			incr cut
		}

		return $cut
	}

	method unknow {{fpath ""}} {
		# SYNOPSIS : iboxobj unknow ?filepath?
		my variable PRIV

		if {![file exists $fpath]} {return $PRIV(__unknow__)}
		$PRIV(__unknow__) configure -file $fpath

		return $PRIV(__unknow__)
	}

}

if {![info exists ::tw::OBJ(ibox)]} {
	set ::tw::OBJ(ibox) [::tw::ibox new]
	foreach f [glob -nocomplain -types {f} -directory [file join $::tw::OPTS(pkgDir) images] *.png] {
		$::tw::OBJ(ibox) add $f
	}
}

