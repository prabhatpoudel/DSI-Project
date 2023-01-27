CREATE OR REPLACE TRIGGER ESI_FORECAST_FILES_TRG 
   before insert ON ESI_FORECAST_FILES_TAB             
  for each row
begin  
  if :NEW.FILE_ID is null then
    select ESI_FORECAST_FILES_SEQ.nextval into :NEW.FILE_ID from dual;
  end if;
end;
/ 

CREATE OR REPLACE TRIGGER ESI_FORECAST_FILES_LOAD_TRG
AFTER INSERT ON ESI_FORECAST_FILES_TAB FOR EACH ROW
DECLARE
  length_ NUMBER :=0;
BEGIN
    ESI_FORECAST_API.SUBMIT_FORECAST_FILE(:NEW.FILE_ID); 
END;
/ 