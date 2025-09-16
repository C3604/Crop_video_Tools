@echo off
setlocal enabledelayedexpansion

rem ����Ƭͷ��ʱ������λ��
set StartTime=95

rem ����Ƭβ��ʱ������λ��
set TailTrimSeconds=126

rem ===���²����û������޸�===

rem ����FFmpeg·��
set ffmpeg=.\ffmpeg.exe

rem ����Դ�ļ��к�����ļ���
set source_folder=.\Videos
set output_folder=.\Output
set Temp_folder=.\Temp

rem ��������ļ���
if not exist "%output_folder%" mkdir "%output_folder%"
if not exist "%Temp_folder%" mkdir "%Temp_folder%"

rem ��֤FFmpeg����
set "FFMPEG_BIN="
if exist "%ffmpeg%" (
    set "FFMPEG_BIN=%ffmpeg%"
) else (
    where ffmpeg >nul 2>&1 && set "FFMPEG_BIN=ffmpeg"
)
if not defined FFMPEG_BIN (
    echo [ERROR] FFmpeg δ�ҵ��� ��ȷ����ffmpeg.exe·��������PATH��
    goto :end
)

rem ��֤ԴĿ¼�����ڣ�����MP4�ļ�
if not exist "%source_folder%" (
    echo [ERROR] ԴĿ¼�����ڣ� %source_folder%
    goto :end
)
dir /b "%source_folder%\*.mp4" >nul 2>&1
if errorlevel 1 (
    echo [WARN] �����ҵ�MP4�ļ��� %source_folder%
    goto :end
)

set /a processed=0

rem ѭ������ÿ����Ƶ�ļ�
for %%i in ("%source_folder%\*.mp4") do (
    set source_file=%%i
    set Temp_file=!Temp_folder!\temp_%%~nxi
    set output_file="%output_folder%\%%~nxi"
    set "skip_current="

    if exist "!Temp_file!" del /q "!Temp_file!" >nul 2>&1

    rem �ü�Ƭͷ����temp�ļ���
    "%FFMPEG_BIN%" -v error -hide_banner -y -i "!source_file!" -ss %StartTime% -c copy "!Temp_file!"
    if errorlevel 1 (
        echo [ERROR] ǰ�ü�ʧ��: "!source_file!"
        if exist "!Temp_file!" del /q "!Temp_file!" >nul 2>&1
        set "skip_current=1"
    )

    if not defined skip_current (
        rem ʹ��FFmpeg��ȡ��Ƶʱ��
        set "duration_line="
        for /f "tokens=*" %%d in ('"%FFMPEG_BIN%" -i "!Temp_file!" 2^>^&1 ^| find "Duration"') do (
            set duration_line=%%d
        )
        if not defined duration_line (
            echo [ERROR] �޷���ȡ��Ƶʱ��: "!Temp_file!"
            set "skip_current=1"
        )
    )

    if not defined skip_current (
        set duration=!duration_line:Duration=!
        set duration=!duration:~,12!
        rem �� hh:mm:ss ת��Ϊ����
        for /f "tokens=1-3 delims=:" %%a in ("!duration!") do (
            set /a total_seconds=%%a * 3600 + %%b * 60 + %%c
        )
        set /a ClipDuration=total_seconds-TailTrimSeconds

        if !ClipDuration! LEQ 0 (
            echo [WARN] β�ü����ȳ�������, ֱ�Ӹ��Ƴ����ļ�: "!output_file!"
            copy /y "!Temp_file!" !output_file! >nul
            if errorlevel 1 (
                echo [ERROR] �����ļ�ʧ��: "!output_file!"
            ) else (
                echo [OK] �������: "!output_file!"
            )
        ) else (
            "%FFMPEG_BIN%" -v error -hide_banner -y -i "!Temp_file!" -ss 0 -t !ClipDuration! -c copy !output_file!
            if errorlevel 1 (
                echo [ERROR] β�ü�ʧ��: "!source_file!"
            ) else (
                echo [OK] �������: "!output_file!"
            )
        )
    )

    rem ���tempĿ¼
    if exist "!Temp_file!" del /q "!Temp_file!" >nul 2>&1
    set /a processed+=1
)

if %processed% EQU 0 (
    echo û�н��κ��ļ���
) else (
    echo ȫ����Ƶ������� �� �ܹ������ %processed% ���ļ�
)
pause
