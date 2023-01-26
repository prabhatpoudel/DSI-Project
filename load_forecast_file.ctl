
OPTIONS (rows =1, ERRORS=50)
LOAD DATA 
INFILE 'forecast_list.txt' 
BADFILE 'forecast_list.bad'
DISCARDFILE 'forecast_list.dsc'

APPEND
INTO TABLE "ESI_FORECAST_FILES_TAB"
WHEN FILE_NAME <> ' '

FIELDS TERMINATED BY ',' optionally enclosed by '"'

(
  FILE_NAME          CHAR(100),
  CLOB_FILENAME     FILLER CHAR(100),
  FILE_DATA         LOBFILE(CLOB_FILENAME) TERMINATED BY EOF
)
