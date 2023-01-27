CREATE OR REPLACE package body IFSAPP.ESI_FORECAST_API is

FUNCTION Get_Version RETURN NUMBER
IS
BEGIN
   RETURN ESI_K__VERSION;
END Get_Version;

FUNCTION Get_What RETURN VARCHAR2
IS
BEGIN
   RETURN 'This is a Forecast File Load API.';
END Get_What;

PROCEDURE esi_putline(
   str         IN   VARCHAR2
 , len         IN   INTEGER := 512
 , expand_in   IN   BOOLEAN := TRUE
)
IS
   v_len     PLS_INTEGER     := LEAST (len, 255);
   v_len2    PLS_INTEGER;
   v_chr10   PLS_INTEGER;
   v_str     VARCHAR2(2000);
BEGIN
   IF LENGTH (str) > v_len
   THEN
      v_chr10 := INSTR (str, CHR (10));

      IF v_chr10 > 0 AND v_len >= v_chr10
      THEN
         v_len  := v_chr10 - 1;
         v_len2 := v_chr10 + 1;
      ELSE
         v_len2 := v_len + 1;
      END IF;

      v_str := SUBSTR (str, 1, v_len);
      DBMS_OUTPUT.put_line (v_str);
      esi_putline (SUBSTR (str, v_len2), len, expand_in);
   ELSE
      -- Save the string in case we hit an error and need to recover.
      v_str := str;
      DBMS_OUTPUT.put_line (str);
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN

      IF expand_in
      THEN
         DBMS_OUTPUT.ENABLE (1000000);
         DBMS_OUTPUT.put_line (v_str);
      ELSE
         RAISE;
      END IF;
END esi_putline;

PROCEDURE esi_output(message_ IN VARCHAR2,
status_ IN VARCHAR2 DEFAULT 'INFO')
IS
BEGIN
   esi_putline(message_);

   if (status_ IN ('INFO','WARNING')) then
      Transaction_Sys.set_status_info(message_, status_);
   else
      Transaction_Sys.set_status_info(message_, 'INFO');
   end if;

   EXCEPTION
      WHEN OTHERS THEN
         NULL;

   return;
END esi_output;

PROCEDURE esi_ascii_output(message_ IN VARCHAR2,
status_ IN VARCHAR2 DEFAULT 'INFO')
IS
BEGIN
   esi_putline(REGEXP_REPLACE(ASCIISTR(message_), '[^[:print:]]', '|'), 250, ESI_K__EXPAND_OUTPUT);

   if (status_ IN ('INFO','WARNING')) then
      Transaction_Sys.set_status_info(REGEXP_REPLACE(ASCIISTR(message_), '[^[:print:]]', '|'), status_);
   else
      Transaction_Sys.set_status_info(REGEXP_REPLACE(ASCIISTR(message_), '[^[:print:]]', '|'), 'INFO');
   end if;

   EXCEPTION
      WHEN OTHERS THEN
         NULL;

   return;
END esi_ascii_output;

PROCEDURE Raise_Error
is
begin 
   Error_SYS.Record_General('TM1ForeCastLoad','Only Error Status allowed for Re-Run.');
   return;
end Raise_Error;
   
FUNCTION Get_Substring_At_Position(string_ IN VARCHAR2,
   position_ IN NUMBER,
   delimeter_ IN VARCHAR2 DEFAULT ',') RETURN VARCHAR2
IS
   sub_string_      VARCHAR(1000) := '';
   start_pos_       NUMBER        := 0;
   end_pos_         NUMBER        := 0;
   length_          NUMBER        := 0;
BEGIN
   if (position_ <= 0) then
     return '';
   end if;

   if (position_ = 1) then
      start_pos_ := 0;
   else
      start_pos_ := instr(string_, delimeter_, 1, position_ - 1);
   end if;

   end_pos_   := instr(string_, delimeter_, 1, position_);
   
   if end_pos_ <= 0 then
     end_pos_ := length(string_);
   end if;
   
   length_    := end_pos_ - start_pos_ - 1;

   sub_string_ := substr(string_, start_pos_ + 1, length_);
   
   sub_string_ := replace(sub_string_, '"','');
   sub_string_ := trim(sub_string_);
   return sub_string_;
END Get_Substring_At_Position;

PROCEDURE Delete_Previous_Data 
IS
BEGIN
  esi_output('Delete_Previous_Data Starting' );
  
  DELETE FROM ESI_FORECAST_DATA_CLT 
  WHERE TRUNC(ROWVERSION) < TRUNC(SYSDATE);
  
  COMMIT;
  esi_output('Delete_Previous_Data Ending' );
return;
END Delete_Previous_Data;

PROCEDURE Create_Level_1_Part(contract_ IN VARCHAR2, part_no_ IN VARCHAR2) 
IS
  info_       VARCHAR2(32000) := '';
  attr_       VARCHAR2(32000) := '';
  objversion_ VARCHAR2(32000) := '';
  objid_      VARCHAR2(32000) := '';
BEGIN
   Client_Sys.Clear_Attr(attr_);
   
   Level_1_Part_API.New__ (
                           info_       => info_      ,
                           objid_      => objid_     ,
                           objversion_ => objversion_,
                           attr_       => attr_      ,
                           action_     => 'PREPARE'    );
                           
   Client_Sys.Set_Item_Value('CONTRACT', contract_, attr_);
   Client_Sys.Set_Item_Value('PART_NO', part_no_, attr_);
   Client_Sys.Set_Item_Value('DEMAND_TIMEFENCE', 5, attr_);
   Client_Sys.Set_Item_Value('PLANNING_TIMEFENCE', 35, attr_);
   Client_Sys.Set_Item_Value('UNCONSUMED_FORECAST_DISP', 'Drop', attr_); 
   
   Level_1_Part_API.New__ (
                           info_       => info_      ,
                           objid_      => objid_     ,
                           objversion_ => objversion_,
                           attr_       => attr_      ,
                           action_     => 'DO'    );                           
return;
END Create_Level_1_Part;

PROCEDURE Create_Level_1_Part_Ms(contract_ IN VARCHAR2, part_no_ IN VARCHAR2, ms_set_ IN NUMBER) 
IS
  info_       VARCHAR2(32000) := '';
  attr_       VARCHAR2(32000) := '';
  objversion_ VARCHAR2(32000) := '';
  objid_      VARCHAR2(32000) := '';
BEGIN
   Client_Sys.Clear_Attr(attr_);
   
   Level_1_Part_BY_MS_Set_API.New__ (
                                     info_       => info_      ,
                                     objid_      => objid_     ,
                                     objversion_ => objversion_,
                                     attr_       => attr_      ,
                                     action_     => 'PREPARE'    );
                           
   Client_Sys.Set_Item_Value('CONTRACT', contract_, attr_);
   Client_Sys.Set_Item_Value('PART_NO', part_no_, attr_);
   Client_Sys.Set_Item_Value('MS_SET', ms_set_, attr_); 
   
   Level_1_Part_BY_MS_Set_API.New__ (
                           info_       => info_      ,
                           objid_      => objid_     ,
                           objversion_ => objversion_,
                           attr_       => attr_      ,
                           action_     => 'DO'    );                           
return;
END Create_Level_1_Part_Ms;

PROCEDURE Create_Forecast(contract_ IN VARCHAR2, part_no_ IN VARCHAR2, ms_set_ IN NUMBER, ms_date_ IN DATE, forecast_lev0_ IN NUMBER) 
IS
  info_       VARCHAR2(32000) := '';
  attr_       VARCHAR2(32000) := '';
  objversion_ VARCHAR2(32000) := '';
  objid_      VARCHAR2(32000) := '';
BEGIN
   Client_Sys.Clear_Attr(attr_);
   
   Level_1_ForeCast_API.New__ (
                                     info_       => info_      ,
                                     objid_      => objid_     ,
                                     objversion_ => objversion_,
                                     attr_       => attr_      ,
                                     action_     => 'PREPARE'    );
                           
   Client_Sys.Set_Item_Value('CONTRACT', contract_, attr_);
   Client_Sys.Set_Item_Value('PART_NO', part_no_, attr_);
   Client_Sys.Set_Item_Value('MS_SET', ms_set_, attr_);
   Client_Sys.Set_Item_Value('MS_DATE', ms_date_, attr_);
   Client_Sys.Set_Item_Value('FORECAST_LEV0', forecast_lev0_, attr_);  
   
   Level_1_ForeCast_API.New__ (
                           info_       => info_      ,
                           objid_      => objid_     ,
                           objversion_ => objversion_,
                           attr_       => attr_      ,
                           action_     => 'DO'    );                           
return;
END Create_Forecast;

PROCEDURE Modify_Forecast(contract_ IN VARCHAR2, part_no_ IN VARCHAR2, ms_set_ IN NUMBER, ms_date_ IN DATE, forecast_lev0_ IN NUMBER) 
IS
  
  cursor c1 is
  select *
  from level_1_forecast
  where contract = contract_ 
    and part_no = part_no_
    and ms_set = ms_set_
    and ms_date = ms_date_;

  info_       VARCHAR2(32000) := '';
  attr_       VARCHAR2(32000) := '';
  objversion_ VARCHAR2(32000) := '';
  objid_      VARCHAR2(32000) := '';
BEGIN

  for rec in c1 loop
    objversion_ := rec.objversion;
    objid_      := rec.objid;
  end loop;
   
   Client_Sys.Clear_Attr(attr_);
  
   Client_Sys.Set_Item_Value('FORECAST_LEV0', forecast_lev0_, attr_);  
   
   Level_1_ForeCast_API.Modify__ (
                           info_       => info_      ,
                           objid_      => objid_     ,
                           objversion_ => objversion_,
                           attr_       => attr_      ,
                           action_     => 'DO'    );  
return;
END Modify_Forecast;

PROCEDURE Remove_Forecast(contract_ IN VARCHAR2, part_no_ IN VARCHAR2, ms_set_ IN NUMBER, ms_date_ IN DATE) 
IS  
BEGIN

   Level_1_ForeCast_API.Remove (
                                contract_ => contract_,
                                part_no_  => part_no_ ,
                                ms_set_   => ms_set_  ,
                                ms_date_  => ms_date_ );  
return;
END Remove_Forecast;

PROCEDURE Parse_Line(line_no_ IN NUMBER, file_id_ IN NUMBER, line_string_ IN VARCHAR2, file_name_ IN VARCHAR2) 
IS
  contract_      ESI_FORECAST_DATA_CLT.CF$_CONTRACT%TYPE;
  part_no_       ESI_FORECAST_DATA_CLT.CF$_PART_NO%TYPE;
  ms_set_        ESI_FORECAST_DATA_CLT.CF$_MS_SET%TYPE;
  ms_date_       ESI_FORECAST_DATA_CLT.CF$_MS_DATE%TYPE;
  forecast_lev0_ ESI_FORECAST_DATA_CLT.CF$_FORECAST_LEV0%TYPE;
  status_        ESI_FORECAST_DATA_CLT.CF$_STATUS%TYPE;
  error_message_ ESI_FORECAST_DATA_CLT.CF$_ERROR_MESSAGE%TYPE;
  file_type_     ESI_FORECAST_DATA_CLT.CF$_FILE_TYPE%TYPE;
  
BEGIN
   
    contract_        := Get_Substring_At_Position(line_string_,1,',');
    part_no_         := Get_Substring_At_Position(line_string_,2,',');
    ms_set_          := 1;
    ms_date_         := TO_DATE(Get_Substring_At_Position(line_string_,3,','), 'MM/DD/YYYY');
    forecast_lev0_   := Get_Substring_At_Position(line_string_,4,',');
    if upper(file_name_) like 'ZERO%' then 
       file_type_ := 'DELETE';
    else
       file_type_ := 'NEW-UPDATE';
    end if; 

    insert into ESI_FORECAST_DATA_CLT(CF$_LINE_NO, CF$_FILE_ID, CF$_CONTRACT, CF$_PART_NO, CF$_MS_SET, CF$_MS_DATE, CF$_FORECAST_LEV0, CF$_STATUS, CF$_LINE_STRING, ROWVERSION, CF$_FILE_TYPE )
       VALUES(line_no_, file_id_, contract_, part_no_, ms_set_, ms_date_, forecast_lev0_, 'Posted', line_string_, SYSDATE, file_type_);
return;  
END Parse_Line;

PROCEDURE Forecast_Line_Data(file_id_ IN NUMBER, line_no_ IN NUMBER)
IS
  cursor c1 is
    SELECT 
           CF$_LINE_NO line_no,
           CF$_FILE_ID file_id,
           CF$_CONTRACT contract,
           CF$_PART_NO part_no,
           CF$_MS_SET  ms_set,
           CF$_MS_DATE ms_date,
           CF$_FORECAST_LEV0 forecast_lev0,
           CF$_FILE_TYPE file_type 
    FROM ESI_FORECAST_DATA_CLT
    WHERE CF$_FILE_ID = file_id_
    and NVL(CF$_STATUS,'UNKNOWN') != 'Ready'
    and cf$_line_no = line_no_;
    
    header_exist_      VARCHAR2(10) := 'FALSE';
    sub_header_exist_  VARCHAR2(10) := 'FALSE';
    forecast_exist_    VARCHAR2(10) := 'FALSE';
    err_msg_           VARCHAR2(2000) := '';
    
BEGIN    
   esi_output('Forecast_Line_Data Starting');
   
   for rec in c1 loop
      begin
      --Check file type, if delete remove forecast else create new or modify forecast value
      if rec.file_type ='DELETE' then 
        --Check forecast value, if forecast value not equal to 0 then not required to remove forecast value
        if rec.forecast_lev0 = 0 then
        Remove_Forecast(rec.contract, rec.part_no, rec.ms_set, rec.ms_date);
         
          update ESI_FORECAST_DATA_CLT 
           set CF$_STATUS ='Ready', ROWVERSION = SYSDATE , CF$_ERROR_MESSAGE = ''
          where CF$_LINE_NO = rec.line_no AND CF$_FILE_ID = rec.file_id ;
        else
          update ESI_FORECAST_DATA_CLT 
           set CF$_STATUS ='Error', ROWVERSION = SYSDATE , CF$_ERROR_MESSAGE = 'Forecast value is not equal to 0 for file type Delete.'
          where CF$_LINE_NO = rec.line_no AND CF$_FILE_ID = rec.file_id ;        
        end if;
      else    
        --check if header exists
       if LEVEL_1_PART_API.CHECK_EXIST(rec.contract, rec.part_no) then
        header_exist_ := 'TRUE'; 
       end if; 
       
       if header_exist_ ='FALSE' then
        esi_output('Creating header for File ID#: '||file_id_||' Line#: '||rec.line_no);
        Create_Level_1_Part(rec.contract, rec.part_no);
       end if;
       
       --check if sub header exist   
       if LEVEL_1_PART_BY_MS_SET_API.CHECK_EXIST(rec.contract, rec.part_no, rec.ms_set) then
        sub_header_exist_ := 'TRUE';
       end if;
       
       if sub_header_exist_ ='FALSE' THEN
        esi_output('Creating Sub header for File ID#: '||file_id_||' Line#: '||rec.line_no);
        Create_Level_1_Part_Ms(rec.contract, rec.part_no, rec.ms_set);
       end if;
       
       --insert or modify the forecast data
       if LEVEL_1_FORECAST_API.CHECK_EXIST(rec.contract, rec.part_no, rec.ms_set, rec.ms_date) then
         forecast_exist_ := 'TRUE';
       end if;
       
       if forecast_exist_ = 'FALSE' THEN
        esi_output('Creating Forecast for File ID#: '||file_id_||' Line#: '||rec.line_no); 
        Create_Forecast(rec.contract, rec.part_no, rec.ms_set, rec.ms_date, rec.forecast_lev0);
       else
        esi_output('Modifying Forecast for File ID#: '||file_id_||' Line#: '||rec.line_no);
        Modify_Forecast(rec.contract, rec.part_no, rec.ms_set, rec.ms_date, rec.forecast_lev0);
       end if;
       
       update ESI_FORECAST_DATA_CLT 
        set CF$_STATUS ='Ready', ROWVERSION = SYSDATE , CF$_ERROR_MESSAGE = ''
       where CF$_LINE_NO = rec.line_no AND CF$_FILE_ID = rec.file_id ;
      
     COMMIT;
     end if;
     exception when others then     
       err_msg_ := substr(SQLERRM, 1, 2000);
       
       esi_output(err_msg_);
       
       update ESI_FORECAST_DATA_CLT 
         set CF$_STATUS ='Error', CF$_ERROR_MESSAGE = err_msg_, ROWVERSION = SYSDATE 
       where CF$_LINE_NO = rec.line_no AND CF$_FILE_ID = rec.file_id ;
     end;    
   end loop;
   esi_output('Forecast_Line_Data Ending');
RETURN;            
END Forecast_Line_Data; 

PROCEDURE Forecast_Data(file_id_ IN NUMBER)
IS
  cursor c1 is
    SELECT 
           CF$_LINE_NO line_no,
           CF$_FILE_ID file_id,
           CF$_CONTRACT contract,
           CF$_PART_NO part_no,
           CF$_MS_SET  ms_set,
           CF$_MS_DATE ms_date,
           round(CF$_FORECAST_LEV0) forecast_lev0 
    FROM ESI_FORECAST_DATA_CLT
    WHERE CF$_FILE_ID = file_id_
    and NVL(CF$_STATUS,'UNKNOWN') != 'Ready';
    
    header_exist_      VARCHAR2(10) := 'FALSE';
    sub_header_exist_  VARCHAR2(10) := 'FALSE';
    forecast_exist_    VARCHAR2(10) := 'FALSE';
    err_msg_           VARCHAR2(2000) := '';
    
BEGIN    
   esi_output('Forecast_Data Starting');
   
   for rec in c1 loop
    header_exist_      := 'FALSE';
    sub_header_exist_  := 'FALSE';
    forecast_exist_    := 'FALSE';
    err_msg_           := '';
                
    --esi_output('Processing Line#: '||rec.line_no);
     
      begin
      -- Check if Forecast Lev0 value, if 0 then delete it
      
      if rec.forecast_lev0 = 0 then
        Remove_Forecast(rec.contract, rec.part_no, rec.ms_set, rec.ms_date);
         
        update ESI_FORECAST_DATA_CLT 
         set CF$_STATUS ='Deleted', ROWVERSION = SYSDATE , CF$_ERROR_MESSAGE = ''
        where CF$_LINE_NO = rec.line_no AND CF$_FILE_ID = rec.file_id ;
      else
          --check if header exists
         if LEVEL_1_PART_API.CHECK_EXIST(rec.contract, rec.part_no) then
          header_exist_ := 'TRUE'; 
         end if; 
         
         if header_exist_ ='FALSE' then
          --esi_output('Creating header for Line#: '||rec.line_no);
          Create_Level_1_Part(rec.contract, rec.part_no);
         end if;
         
         --check if sub header exist   
         if LEVEL_1_PART_BY_MS_SET_API.CHECK_EXIST(rec.contract, rec.part_no, rec.ms_set) then
          sub_header_exist_ := 'TRUE';
         end if;
         
         if sub_header_exist_ ='FALSE' THEN
          --esi_output('Creating Sub header for Line#: '||rec.line_no);
          Create_Level_1_Part_Ms(rec.contract, rec.part_no, rec.ms_set);
         end if;
         
         --insert or modify the forecast data
         if LEVEL_1_FORECAST_API.CHECK_EXIST(rec.contract, rec.part_no, rec.ms_set, rec.ms_date) then
           forecast_exist_ := 'TRUE';
         end if;
         
         if forecast_exist_ = 'FALSE' THEN
          --esi_output('Creating Forecast for Line#: '||rec.line_no); 
          Create_Forecast(rec.contract, rec.part_no, rec.ms_set, rec.ms_date, rec.forecast_lev0);          
         else
          --esi_output('Modifying Forecast for Line#: '||rec.line_no);
          Modify_Forecast(rec.contract, rec.part_no, rec.ms_set, rec.ms_date, rec.forecast_lev0);
         end if;
       
       update ESI_FORECAST_DATA_CLT 
        set CF$_STATUS ='Ready', ROWVERSION = SYSDATE , CF$_ERROR_MESSAGE = ''
       where CF$_LINE_NO = rec.line_no AND CF$_FILE_ID = rec.file_id ;
     end if;
     
     exception when others then     
       err_msg_ := substr(SQLERRM, 1, 2000);
       
       update ESI_FORECAST_DATA_CLT 
         set CF$_STATUS ='Error', CF$_ERROR_MESSAGE = err_msg_, ROWVERSION = SYSDATE 
       where CF$_LINE_NO = rec.line_no AND CF$_FILE_ID = rec.file_id ;
     end;
     commit;    
   end loop;
   esi_output('Forecast_Data Ending');
RETURN;            
END Forecast_Data;    

PROCEDURE Forecast_File(file_id_ IN NUMBER)
IS
  cursor c1 is
    SELECT *  
    FROM ESI_FORECAST_FILES_TAB
    WHERE FILE_ID = file_id_;

  offset NUMBER := 1;
  amount NUMBER := 32767;
  len    number;
  --lc_buffer varchar2(32767);
  i pls_integer := 1;
  string_ varchar2(32767) ;
  file_clob clob;


BEGIN
   esi_output('Forecast_File Starting');
   
   Delete_Previous_Data;
   
    for rec in c1 loop
       esi_output('File Name: '||rec.file_name);
       esi_output('Status: '||rec.status);
       
       file_clob := rec.file_data;
       len := dbms_lob.getlength(file_clob);
       
      if ( dbms_lob.isopen(file_clob) != 1 ) then
        dbms_lob.open(file_clob, 0);
      end if;
      while ( offset < len )
          loop
            -- If no more newlines are found, read till end of CLOB
            if (instr(file_clob, chr(10), offset) = 0) then
                amount := len - offset + 1;
            else
                amount := instr(file_clob, chr(10), offset) - offset;
            end if;

            -- This is to catch empty lines, otherwise we get a NULL error
            if ( amount = 0 ) then
                string_ := '';
            else
                dbms_lob.read(file_clob, amount, offset, string_);
            end if;
            esi_output('Line #'||i||':'||string_);
            
            Parse_Line(i, file_id_, string_, rec.file_name);
            -- This is to catch a newline on the last line with 0 characters behind it
            i := i + 1;
            if (instr(file_clob, chr(10), offset) = len) then
                string_ := '';
                esi_output('Line #'||i||':'||string_);
            end if;
            offset := offset + amount + 1;
          end loop; 
      if ( dbms_lob.isopen(file_clob) = 1 ) then
        dbms_lob.close(file_clob);
      end if; 
    end loop;
    esi_output('Forecast File Tab Updating');
    update ESI_FORECAST_FILES_TAB set STATUS ='Transferred' where file_id = file_id_;
    
    Submit_Forecast_Data(file_id_);        
    esi_output('Forecast_File Ending');
   return;
exception when others then
    Rollback;
    update ESI_FORECAST_FILES_TAB set STATUS ='Failed' where file_id = file_id_;
    commit;
    raise;    
END Forecast_File;

--PROCEDURE Forecast_File(file_id_ IN NUMBER)
--IS
--  cursor c1 is
--    SELECT *  
--    FROM ESI_FORECAST_FILES_TAB
--    WHERE FILE_ID = file_id_;
--
--  offset NUMBER := 1;
--  amount NUMBER := 32767;
--  buf    VARCHAR2(32767);
--  arr APEX_APPLICATION_GLOBAL.VC_ARR2;
--  string_ varchar2(32000) ;
--
--BEGIN
--   esi_output('Forecast_File Starting');
--   
--    for rec in c1 loop
--       esi_output('File Name: '||rec.file_name);
--       esi_output('Status: '||rec.status);
--       
--        DBMS_LOB.read(rec.file_data, amount, offset, buf);    
--        arr := APEX_UTIL.string_to_table(buf, CHR(10));
--        
--        dbms_output.put_line(arr.COUNT);
--        
--        FOR i IN 1..arr.COUNT LOOP
--          IF i < arr.COUNT THEN
--            string_ := arr(i);
--          ELSE
--            string_ := arr(i);
--          END IF;
--          
--          Parse_Line(i, file_id_, string_);
--          
--        END LOOP;
--    end loop;
--    esi_output('Forecast File Tab Updating');
--    update ESI_FORECAST_FILES_TAB set STATUS ='Transferred' where file_id = file_id_;
--    
--    --Submit_Forecast_Data(file_id_);        
--    esi_output('Forecast_File Ending');
--   return;
--exception when others then
--    Rollback;
--    update ESI_FORECAST_FILES_TAB set STATUS ='Failed' where file_id = file_id_;
--    commit;
--    raise;    
--END Forecast_File;

PROCEDURE Forecast_Data_Attr(attr_ IN VARCHAR2)
IS
   file_id_            NUMBER ;

BEGIN
   esi_output('Forecast_Data_Attr Starting');
       
   file_id_ := Client_Sys.Get_Item_Value('FILE_ID', attr_);
   
   Forecast_Data(file_id_);

   esi_output('Forecast_Data_Attr Ending');
   exception when others then
    esi_output('SQLERRM: '||SQLERRM );
   return;
END Forecast_Data_Attr;

PROCEDURE Forecast_File_Attr(attr_ IN VARCHAR2)
IS
   file_id_            NUMBER ;

BEGIN
   esi_output('Forecast_File_Attr Starting');
       
   file_id_ := Client_Sys.Get_Item_Value('FILE_ID', attr_);
   
   Forecast_File(file_id_);

   esi_output('Forecast_File_Attr Ending');
END Forecast_File_Attr;

PROCEDURE Forecast_Line_Data_Attr(attr_ IN VARCHAR2)
IS
   file_id_            NUMBER ;
   line_no_            NUMBER ;

BEGIN
   esi_output('Forecast_Line_Data_Attr Starting');
       
   file_id_ := Client_Sys.Get_Item_Value('FILE_ID', attr_);
   line_no_ := Client_Sys.Get_Item_Value('LINE_NO', attr_);
   
   Forecast_Line_Data(file_id_, line_no_);

   esi_output('Forecast_Line_Data_Attr Ending');
   exception when others then
    esi_output('SQLERRM: '||SQLERRM );
   return;
END Forecast_Line_Data_Attr;

PROCEDURE Submit_Forecast_File(file_id_ IN NUMBER)
IS
   attr_                     VARCHAR2(2000) := '';
   status_                   NUMBER         := 0;
BEGIN
   esi_putline('Submit_Forecast_File Starting');
   Client_Sys.Clear_Attr(attr_);
   Client_Sys.Add_To_Attr('FILE_ID', file_id_, attr_);
   
   
   --IFSAPP.FND_Session_API.Impersonate_Fnd_User('IFSAPP');  
   
   status_ := Transaction_Sys.Post_Local__(ESI_K__DEBUG_IDENTIFIER || '.' || 'Forecast_File_Attr',
                 attr_,
                 'ESI Parsing File From ESI_FORECAST_FILES_TAB  : ' || file_id_,
                 sysdate,
                 'TRUE');

   esi_putline('Job: ' || status_);
    --commit;
    
   esi_putline('Submit_Forecast_File Ending');
   return;
END Submit_Forecast_File;

PROCEDURE Submit_Forecast_Data(file_id_ IN NUMBER)
IS
   attr_                     VARCHAR2(2000) := '';
   status_                   NUMBER         := 0;
BEGIN
   esi_putline('Submit_Forecast_Data Starting');
   Client_Sys.Clear_Attr(attr_);
   Client_Sys.Add_To_Attr('FILE_ID', file_id_, attr_);
         
   status_ := Transaction_Sys.Post_Local__(ESI_K__DEBUG_IDENTIFIER || '.' || 'Forecast_Data_Attr',
                 attr_,
                 'ESI Process ESI_FORECAST_DATA_CLT  : ' || file_id_,
                 sysdate,
                 'TRUE');

   esi_putline('Job: ' || status_);
    --commit;
    
   esi_putline('Submit_Forecast_Data Ending');
   return;
END Submit_Forecast_Data;

PROCEDURE Submit_Forecast_Line_Data(file_id_ IN NUMBER, line_no_ IN NUMBER)
IS
   attr_                     VARCHAR2(2000) := '';
   status_                   NUMBER         := 0;
BEGIN
   esi_putline('Submit_Forecast_Line_Data Starting');
   Client_Sys.Clear_Attr(attr_);
   Client_Sys.Add_To_Attr('FILE_ID', file_id_, attr_);
   Client_Sys.Add_To_Attr('LINE_NO', line_no_, attr_);
         
   status_ := Transaction_Sys.Post_Local__(ESI_K__DEBUG_IDENTIFIER || '.' || 'Forecast_Line_Data_Attr',
                 attr_,
                 'ESI Process ESI_FORECAST_DATA_CLT  File ID: ' || file_id_||' Line no: '||line_no_,
                 sysdate,
                 'TRUE');

   esi_putline('Job: ' || status_);
    --commit;
    
   esi_putline('Submit_Forecast_Line_Data Ending');
   return;
END Submit_Forecast_Line_Data;

PROCEDURE Register
IS
   dict_count_      NUMBER := 0;

   cursor dict_(lu_name__ IN VARCHAR2, module__ IN VARCHAR2, lu_prompt__ IN VARCHAR2) is
   select count(*) my_count
   from DICTIONARY_SYS_TAB
   where lu_name = lu_name__
   and module = module__;

BEGIN
   esi_output('Register Starting');

   esi_output('-> Registering module ' || module_);
   Module_API.Pre_Register(module_, 'eNSYNC Solutions');

   esi_output('-> Setting ' || module_ || ' module version');
   Module_API.Set_Version(module_, '1.0.0', NULL, 'eNSYNC Solutions');

   for rec in dict_(lu_name_, module_, lu_prompt_) loop
      dict_count_ := rec.my_count;
   end loop;

   if (dict_count_ = 0) then
      esi_output('-> Inserting module into DICTIONARY_SYS_TAB');
      insert into DICTIONARY_SYS_TAB(LU_NAME, MODULE, LU_PROMPT, LU_TYPE, ROWVERSION)
         values (lu_name_, module_, lu_prompt_, 'L', sysdate);
   end if;

   esi_output('Register Ending');
   return;
END Register;

PROCEDURE Init
IS
BEGIN
   NULL;
END Init;

end ESI_FORECAST_API;
/
