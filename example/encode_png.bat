
@echo off
call :treeProcess
goto :eof

:treeProcess

FOR %%f IN (*.png) DO C:\Tools\libwebp\bin\cwebp.exe "%%f" -m 6 -q 100 -o "%%~nf.webp"

for /D %%d in (*) do (
    cd %%d
    call :treeProcess
    cd ..
)

exit /b