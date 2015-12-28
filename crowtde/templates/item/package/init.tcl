namespace eval ::itemTemplPackage {}
proc ::itemTemplPackage::init {fpath} {
	set name [file rootname [file tail $fpath]]
	set fd [open $fpath w]
	puts $fd 	"package provide $name 1.0"
	puts $fd "
namespace eval ::$name {
}

proc ::${name}::init {args} {
}
::${name}::init"

	close $fd
	return ""

}
