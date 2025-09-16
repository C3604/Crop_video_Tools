@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

rem 片头裁剪开始时间（秒）
set StartTime=95

rem FFmpeg 路径（确保为支持 CUDA 的版本）
set ffmpeg=.\ffmpeg.exe

rem 源、输出、临时 目录
set source_folder=.\Videos
set output_folder=.\Output
set Temp_folder=.\Temp

rem 创建输出与临时目录
if not exist "%output_folder%" mkdir "%output_folder%"
if not exist "%Temp_folder%" mkdir "%Temp_folder%"

rem 校验 FFmpeg 可用
set "FFMPEG_BIN="
if exist "%ffmpeg%" (
    set "FFMPEG_BIN=%ffmpeg%"
) else (
    where ffmpeg >nul 2>&1 && set "FFMPEG_BIN=ffmpeg"
)
if not defined FFMPEG_BIN (
    echo [ERROR] 未找到 FFmpeg；请配置 ffmpeg.exe 路径或加入 PATH
    goto :end
)

rem 校验源目录与 MP4 文件
if not exist "%source_folder%" (
    echo [ERROR] 源目录不存在: %source_folder%
    goto :end
)
dir /b "%source_folder%\*.mp4" >nul 2>&1
if errorlevel 1 (
    echo [WARN] 未找到 MP4 文件: %source_folder%
    goto :end
)

rem 遍历处理每个视频文件
for %%i in ("%source_folder%\*.mp4") do (
    set source_file=%%i
    set Temp_file=!Temp_folder!\temp_%%~nxi
    set output_file="%output_folder%\cropped_%%~nxi"
    set "skip_current="

    rem 裁剪片头到临时文件，使用 GPU 加速
    "%FFMPEG_BIN%" -v error -hide_banner -y -hwaccel cuvid -c:v h264_cuvid -i "!source_file!" -ss %StartTime% -c copy "!Temp_file!"
    if errorlevel 1 (
        echo [ERROR] 片头裁剪失败: "!source_file!"
        if exist "!Temp_file!" del /q "!Temp_file!" >nul 2>&1
        set "skip_current=1"
    )

    if not defined skip_current (
        rem 读取视频时长
        set "duration_line="
        for /f "tokens=*" %%d in ('"%FFMPEG_BIN%" -hwaccel cuvid -c:v h264_cuvid -i "!Temp_file!" 2^>^&1 ^| find "Duration"') do (
            set duration_line=%%d
        )
        if not defined duration_line (
            echo [ERROR] 无法获取视频时长: "!Temp_file!"
            set "skip_current=1"
        )
    )

    if not defined skip_current (
        set duration=!duration_line:Duration=!
        set duration=!duration:~,12!
        rem 将 hh:mm:ss 转为秒
        for /f "tokens=1-3 delims=:" %%a in ("!duration!") do (
            set /a total_seconds=%%a * 3600 + %%b * 60 + %%c
        )

        rem 尾部裁剪并生成输出
        set /a ClipDuration=total_seconds-126
        if !ClipDuration! LEQ 0 (
            echo [WARN] 尾部裁剪时长不合理，直接复制输出: "!output_file!"
            copy /y "!Temp_file!" !output_file! >nul
            if errorlevel 1 (
                echo [ERROR] 复制文件失败: "!output_file!"
            ) else (
                echo [OK] 已输出: "!output_file!"
            )
        ) else (
            "%FFMPEG_BIN%" -v error -hide_banner -y -hwaccel cuvid -c:v h264_cuvid -i "!Temp_file!" -ss 0 -t !ClipDuration! -c copy !output_file!
            if errorlevel 1 (
                echo [ERROR] 尾部裁剪失败: "!source_file!"
            ) else (
                echo [OK] 已输出: "!output_file!"
            )
        )

        rem 清理临时文件
        if exist "!Temp_file!" del /q "!Temp_file!" >nul 2>&1
    )
)

echo 全部处理完成。
pause
