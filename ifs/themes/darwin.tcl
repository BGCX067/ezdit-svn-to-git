ttk::style configure Heading.TNotebook -tabposition nw -tabmargins {50 30 50 0}

ttk::style layout  Heading.Toolbutton {

		Toolbutton.padding -sticky nswe -children {
			Toolbutton.label -sticky nswe
		}

}
ttk::style configure Heading.Toolbutton -padding 0 -boder 0
	
ttk::style map Start.Heading.Toolbutton -image [list \
	{!hover !disabled !pressed} [$::dApp::Obj(ibox) get start1] \
	{hover !disabled !pressed} [$::dApp::Obj(ibox) get start2] \
	{pressed !disabled} [$::dApp::Obj(ibox) get start1] \
] -background [list \
	{hover !disabled} [. cget -background] \
	{!hover !disabled} [. cget -background] \
] -border [list \
	{hover !disabled} 0 \
	{!hover !disabled} 0 \
] -relief [list \
	{hover !disabled} flat \
	{!hover !disabled} flat \
]
	
ttk::style map Close.Heading.Toolbutton -image [list \
	{!hover !disabled !pressed} [$::dApp::Obj(ibox) get close1] \
	{hover !disabled !pressed} [$::dApp::Obj(ibox) get close1] \
	{pressed !disabled} [$::dApp::Obj(ibox) get close2] \
] -background [list \
	{hover !disabled} [. cget -background] \
	{!hover !disabled} [. cget -background] \
] -border [list \
	{hover !disabled} 0 \
	{!hover !disabled} 0 \
] -relief [list \
	{hover !disabled} flat \
	{!hover !disabled} flat \
]

#######################Flat Button#####################

ttk::style layout Flat.Toolbutton {
	Button.border -sticky nswe -children {
		Button.padding -sticky nswe -children {
			Button.label -sticky nswe
		}
	}
}

ttk::style configure  Flat.Toolbutton \
	-width 0 \
	-border 0 \
	-anchor center  \
	-padding {15 3 15 1} \
	-relief flat \
	-foreground "#505050" \
	-takefocus 0

ttk::style map Flat.Toolbutton -relief {
	{hover pressed !disabled} sunken
} -background {
	{hover !pressed !disabled} "#aeacc1"
} -foreground {
	{hover  !disabled} "black"
} -border {
	{hover pressed !disabled} 0
} 
