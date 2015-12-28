 proc transparent {image} {
    set data ""
    foreach row [$image data] {
       set tmp ""
       foreach col $row {
       	if {$col != "#000000"} {
       			set c [string range $col 1 end]
       			set col [string range [format "%06x" [expr 0x$c + 0x888888]] 0 5]
       			set col "#$col"
       	}
         lappend tmp $col
       }
       lappend data $tmp
    }
    return $data
 }
 
 package require img::png
 set img [image create photo -file c:/tmp/folder.png]
 set img2 [image create photo]
 $img2 put [transparent $img ]

#puts $img2
 button .btn -image $img
 button .btn2 -image $img2
pack .btn .btn2
