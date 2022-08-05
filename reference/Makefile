default: nano.png

nano.dot: protocol.ksy
	kaitai-struct-compiler protocol.ksy -t graphviz

nano.png: nano.dot
	dot nano.dot -v -Tpng -o nano.png
