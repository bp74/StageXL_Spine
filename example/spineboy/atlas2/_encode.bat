FOR %%G IN (*.png) DO cwebp.exe "%%G" -m 6 -q 100 -lossless -o "%%~nG.webp"

