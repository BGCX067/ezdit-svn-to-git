package provide crowImg 1.0

namespace eval ::crowImg {
	variable images
	array set images ""
}

proc ::crowImg::init {dpath} {
	set flist [lsort -dictionary [glob -nocomplain -directory $dpath -types {f} -- *.png]]
	foreach f $flist {
		set ::crowImg::images([file rootname [file tail $f]]) [image create photo -file $f]
	}
}

proc ::crowImg::get_image {imgName} {
	if {[info exists ::crowImg::images($imgName)]} {return $::crowImg::images($imgName)}
	return $::crowImg::images(unknow)
}

