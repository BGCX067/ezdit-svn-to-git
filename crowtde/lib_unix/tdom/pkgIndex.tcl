proc loadlib {dir package version} {
    load [file join $dir tdom.so]
    source [file join $dir tdom.tcl]
}
package ifneeded tdom 0.7.8 [list loadlib $dir tdom 0.7.8]
