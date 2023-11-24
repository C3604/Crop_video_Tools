@echo off
setlocal enabledelayedexpansion

set StartTime=95

rem ����FFmpeg·����ȷ����·��������������CUDA֧�ֵ�FFmpeg��ִ���ļ�
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
    set output_file="%output_folder%\cropped_%%~nxi"

    rem �ü�Ƭͷ����temp�ļ��У�����GPU����
    %ffmpeg% -hwaccel cuvid -c:v h264_cuvid -i "!source_file!" -ss %StartTime% -c copy "!Temp_file!"

    rem ʹ��FFmpeg��ȡ��Ƶʱ��������GPU����
    for /f "tokens=*" %%d in ('%ffmpeg% -hwaccel cuvid -c:v h264_cuvid -i "!Temp_file!" 2^>^&1 ^| find "Duration"') do (
        set duration_line=%%d
        set duration=!duration_line:Duration=!
        set duration=!duration:~,12!

        rem �� hh:mm:ss ת��Ϊ����
        for /f "tokens=1-3 delims=:" %%a in ("!duration!") do (
            set /a total_seconds=%%a * 3600 + %%b * 60 + %%c
        )

        rem echo Video: "!input_file!", Duration: !duration! (converted to seconds: !total_seconds!)

        rem �ڴ���������������������ü���Ƶ��
        set /a EndTime=total_seconds-126
        %ffmpeg% -hwaccel cuvid -c:v h264_cuvid -i "!Temp_file!" -ss 0 -t !EndTime! -c copy "!output_file!"

        rem ���tempĿ¼
        del "!Temp_file!"
    )
)

echo Batch processing completed.
pause
