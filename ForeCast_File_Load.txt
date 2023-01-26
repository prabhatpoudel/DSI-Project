@echo ------------------------------------------------------------------------------ >> process.log
@echo Batch Load Started at %date% %time% >> process.log
@echo. >> process.log
@echo removing existing file list >> process.log
break > forecast_list.txt 
@echo Copying IM and WNA file from wna-ch3-pptm01\TM1_Import\IFS EXPORT to Forecast Directory >> process.log
@echo xcopy /y /f "\\wna-ch3-pptm01\TM1_Import\IFS EXPORT\IM.csv" "Forecast\" >> process.log
xcopy /y /f "\\wna-ch3-pptm01\TM1_Import\IFS EXPORT\IM.csv" "Forecast\"
@echo xcopy /y /f "\\wna-ch3-pptm01\TM1_Import\IFS EXPORT\WNA.csv" "Forecast\" >> process.log
xcopy /y /f "\\wna-ch3-pptm01\TM1_Import\IFS EXPORT\WNA.csv" "Forecast\"
@echo xcopy /y /f "\\wna-ch3-pptm01\TM1_Import\IFS EXPORT\Zero.csv" "Forecast\" >> process.log
xcopy /y /f "\\wna-ch3-pptm01\TM1_Import\IFS EXPORT\Zero.csv" "Forecast\"
@echo Renaming IM and WNA file on Forecast directory to todays timestamp >> process.log >> process.log
@echo ren Forecast\IM.csv IM-%date:~4,2%%date:~7,2%%date:~10,4%%time:~0,2%%time:~3,2%%time:~6,2%%.csv >> process.log
ren Forecast\IM.csv IM-%date:~4,2%%date:~7,2%%date:~10,4%%time:~0,2%%time:~3,2%%time:~6,2%%.csv
@echo ren Forecast\WNA.csv WNA-%date:~4,2%%date:~7,2%%date:~10,4%%time:~0,2%%time:~3,2%%time:~6,2%%.csv >> process.log
ren Forecast\WNA.csv WNA-%date:~4,2%%date:~7,2%%date:~10,4%%time:~0,2%%time:~3,2%%time:~6,2%%.csv
@echo ren Forecast\Zero.csv Zero-%date:~4,2%%date:~7,2%%date:~10,4%%time:~0,2%%time:~3,2%%time:~6,2%%.csv >> process.log
ren Forecast\Zero.csv Zero-%date:~4,2%%date:~7,2%%date:~10,4%%time:~0,2%%time:~3,2%%time:~6,2%%.csv

@echo Removing files readonly attribute >> process.log
attrib -r Forecast\*.* /s
@echo generating forecast_list.txt file >> process.log
for /r %%F in (Forecast\*.csv) do (
	@echo "%%~nxF","%%~dpF%%~nxF"
) >> "forecast_list.txt"

@echo Loading File: forecast_list.txt ... >> process.log
@echo Running: sqlldr ifsapp/ifsapp@dev83 ifsapp8sp1_race.ctl >> process.log

sqlldr ifsapp/ifsapp@dev83 load_forecast_file.ctl

@echo Appending SQL Loader file to Process log>> process.log
@echo         -----------------SQL LOADER LOG STARTED----------------- >> process.log
type load_forecast_file.log >> process.log
del  load_forecast_file.log
@echo         -----------------SQL LOADER LOG ENDS----------------- >> process.log
@echo Moving all the file listed on forecast_list.txt to Backup Folder >> process.log
FOR /F "tokens=1,2 delims=," %%G IN (forecast_list.txt) DO (
move /Y .\Forecast\%%G .\Processed\%%G 
@echo %%G >> process.log
@echo Forecast File %%G Moved to Processed. >> process.log
ENDLOCAL
)




