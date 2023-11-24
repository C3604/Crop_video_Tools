@echo off
setlocal enabledelayedexpansion

rem ����Ƭͷ��ʱ������λ��
set StartTime=95

rem ����Ƭβ��ʱ������λ��
set EndTime=126

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

rem ѭ������ÿ����Ƶ�ļ�
for %%i in ("%source_folder%\*.mp4") do (
    set source_file=%%i
    set Temp_file=!Temp_folder!\temp_%%~nxi
    set output_file="%output_folder%\%%~nxi"

    rem �ü�Ƭͷ����temp�ļ���
    %ffmpeg% -i "!source_file!" -ss %StartTime% -c copy "!Temp_file!"

    rem ʹ��FFmpeg��ȡ��Ƶʱ��
    for /f "tokens=*" %%d in ('%ffmpeg% -i "!Temp_file!" 2^>^&1 ^| find "Duration"') do (
        set duration_line=%%d
        set duration=!duration_line:Duration=!
        set duration=!duration:~,12!

        rem �� hh:mm:ss ת��Ϊ����
        for /f "tokens=1-3 delims=:" %%a in ("!duration!") do (
            set /a total_seconds=%%a * 3600 + %%b * 60 + %%c
        )

        rem �ü�Ƭβ��
        set /a EndTime=total_seconds-EndTime
        %ffmpeg% -i "!Temp_file!" -ss 0 -t !EndTime! -c copy "!output_file!"

        rem ���tempĿ¼
        del "!Temp_file!"
    )
)

echo ȫ����Ƶ�������
pause
