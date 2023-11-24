@echo off
setlocal enabledelayedexpansion

set StartTime=95

rem 设置FFmpeg路径，确保该路径包含有启用了CUDA支持的FFmpeg可执行文件
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
    set output_file="%output_folder%\cropped_%%~nxi"

    rem 裁剪片头存至temp文件夹，启用GPU加速
    %ffmpeg% -hwaccel cuvid -c:v h264_cuvid -i "!source_file!" -ss %StartTime% -c copy "!Temp_file!"

    rem 使用FFmpeg获取视频时长，启用GPU加速
    for /f "tokens=*" %%d in ('%ffmpeg% -hwaccel cuvid -c:v h264_cuvid -i "!Temp_file!" 2^>^&1 ^| find "Duration"') do (
        set duration_line=%%d
        set duration=!duration_line:Duration=!
        set duration=!duration:~,12!

        rem 将 hh:mm:ss 转换为秒数
        for /f "tokens=1-3 delims=:" %%a in ("!duration!") do (
            set /a total_seconds=%%a * 3600 + %%b * 60 + %%c
        )

        rem echo Video: "!input_file!", Duration: !duration! (converted to seconds: !total_seconds!)

        rem 在此添加你的其他操作，例如裁剪视频等
        set /a EndTime=total_seconds-126
        %ffmpeg% -hwaccel cuvid -c:v h264_cuvid -i "!Temp_file!" -ss 0 -t !EndTime! -c copy "!output_file!"

        rem 清空temp目录
        del "!Temp_file!"
    )
)

echo Batch processing completed.
pause
