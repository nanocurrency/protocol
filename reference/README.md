# Nano Protocol Definition

This directory hosts a formal specification of the Nano network protocol.

The definition is written in [Kaitai](https://kaitai.io), from which parsers and diagrams can be generated.

### Generate code

The following example generate parsers for C++ and Javascript:

```
kaitai-struct-compiler protocol.ksy --outdir output/cpp -t cpp_stl
kaitai-struct-compiler protocol.ksy --outdir output/js -t javascript
```

See `kaitai-struct-compiler --help` for the full list of supported programming languages.

### Generate diagrams

Run the following commands to generate a PNG diagram:

```
kaitai-struct-compiler protocol.ksy --outdir diagram -t graphviz
dot output/graphviz/nano.dot -v -Tpng -o diagram/nano.png
```

# Protocol diagram

![Alt text](nano.png?raw=true "Nano")
