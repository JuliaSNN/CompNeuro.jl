using Interact, Blink

el1 =button("Hello world!")
el2 = button("Goodbye world!")

el3 = hbox(el1, el2) # aligns horizontally
el4 = Interact.hline() # draws horizontal line
el5 = vbox(el1, el2) # aligns vertically


body!(Window(), el4)