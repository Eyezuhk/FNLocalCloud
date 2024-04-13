Testing cpython to improve performance, working for linux, testing compiling with MinGW for windows.
Ferramenta de build do visual studio 2022.

```
python3 Cython_FNCloud.py build_ext --inplace
```
```
python3 Cython_FNLocal.py build_ext --inplace
```
FNCloud
```
pyinstaller --onefile --icon=FNLocalCloud.ico FNCloud.py
```
FNLocal
```
pyinstaller --onefile --icon=FNLocalCloud.ico FNLocal.py
```
Fix
```
pip install --upgrade pyinstaller
```

Path: 
```
C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64
```
```
C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.29.30133\bin\HostX64\x64
```
