# Working with VSCode and GHDL in Windows

1) Install MSYS2: https://www.msys2.org/

2) Open the UCRT64 shell and install the following packages:

```shell
pacman -S mingw-w64-ucrt-x86_64-ghdl-llvm \
          mingw-w64-ucrt-x86_64-gtkwave
```

3) Add these directories to the environment variables:

 - **PATH** ← C:\msys64\ucrt64\bin

4) Reset your machine.

5) Install VSCode and look for this extension: `rjyoung.vscode-modern-vhdl-support`.

6) It's possible to embed the MSYS2/UCRT64 shell with bash in VSCode creating a file named `.vscode/settings.json` with this content:

```json
{
    "terminal.integrated.profiles.windows": {
        "MSYS2": {
            "path": "C:\\msys64\\usr\\bin\\bash.exe",
            "args": [
                "--login",
                "-i"
            ],
            "env": {
                "MSYSTEM": "UCRT64",
                "CHERE_INVOKING": "1"
            }
        }
    }
}
```
