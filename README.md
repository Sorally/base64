# base64
A windows Base 64 encoder and decoder in pure assembly

## How to build
Simply run the `makeit.bat` file included, or run the following commands:

```
\MASM32\BIN\Ml.exe /c /coff b64.asm
\MASM32\BIN\PoLink.exe /SUBSYSTEM:WINDOWS /merge:.data=.text b64.obj > nul
```

## Build Environment
This can be built using masm32: https://www.masm32.com/
