ttk::style configure Home.TFrame -background white
ttk::style configure Heading.TNotebook -tabposition nw -tabmargins {50 42 50 0}
ttk::style configure Heading.Toolbutton -padding 0 -boder 0
ttk::style configure Tab -padding {6 2 6 2}

ttk::style layout Start.Heading.Toolbutton {
		Toolbutton.padding -sticky nswe -children {
			Toolbutton.label -sticky nswe
		}
}
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
	Toolbutton.padding -sticky nswe -children {
		Toolbutton.label -sticky nswe
	}
}

ttk::style configure  Flat.Toolbutton \
	-width 0 \
	-border 0 \
	-anchor center  \
	-padding 3 \
	-relief flat \
	-foreground "#353535" \
	-takefocus 0

ttk::style map Flat.Toolbutton -foreground {
	{hover pressed !disabled} "#0066cc"
	{hover !pressed !disabled} "#004080"
}



