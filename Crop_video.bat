@echo off
setlocal enabledelayedexpansion

rem 设置片头曲时长，单位秒
set StartTime=95

rem 设置片尾曲时长，单位秒
set EndTime=126

rem ===如下参数用户无需修改===

rem 设置FFmpeg路径
set ffmpeg=.\ffmpeg.exe

rem 设置源文件夹和输出文件夹
set source_folder=.\Videos
set output_folder=.\Output
set Temp_folder=.\Temp

rem 创建输出文件夹
if not exist "%output_folder%" mkdir "%output_folder%"
if not exist "%Temp_folder%" mkdir "%Temp_folder%"

rem 循环处理每个视频文件
for %%i in ("%source_folder%\*.mp4") do (
    set source_file=%%i
    set Temp_file=!Temp_folder!\temp_%%~nxi
    set output_file="%output_folder%\%%~nxi"

    rem 裁剪片头存至temp文件夹
    %ffmpeg% -i "!source_file!" -ss %StartTime% -c copy "!Temp_file!"

    rem 使用FFmpeg获取视频时长
    for /f "tokens=*" %%d in ('%ffmpeg% -i "!Temp_file!" 2^>^&1 ^| find "Duration"') do (
        set duration_line=%%d
        set duration=!duration_line:Duration=!
        set duration=!duration:~,12!

        rem 将 hh:mm:ss 转换为秒数
        for /f "tokens=1-3 delims=:" %%a in ("!duration!") do (
            set /a total_seconds=%%a * 3600 + %%b * 60 + %%c
        )

        rem 裁剪片尾曲
        set /a EndTime=total_seconds-EndTime
        %ffmpeg% -i "!Temp_file!" -ss 0 -t !EndTime! -c copy "!output_file!"

        rem 清空temp目录
        del "!Temp_file!"
    )
)

echo 全部视频处理完成
pause
