/************************************************************
project : N3C DI&H
Date: 5/16/2020
Authors: 
Stephanie Hong, Sandeep Naredla, Richard Zhu, Tanner Zhang
Stored Procedure : SP_DM_PCORNET_LAB_RESULT_CM

Description : insert to N3CDS_DOMAIN_MAP

*************************************************************/
CREATE PROCEDURE CDMH_STAGING.SP_DM_PCORNET_LAB_RESULT_CM 
(
  DATAPARTNERID IN NUMBER 
, MANIFESTID IN NUMBER 
, RECORDCOUNT OUT NUMBER
) 
AS
/******************************************************
*  CONSTANTs
******************************************************/
COMMIT_LIMIT CONSTANT NUMBER := 10000;
loop_count NUMBER;
insert_rec_count NUMBER;
/**************************************************************
*  Cursor for selecting table
**************************************************************/
CURSOR Lab_Cursor IS
SELECT distinct 
DATAPARTNERID AS DATA_PARTNER_ID,
'LAB_RESULT_CM' AS DOMAIN_NAME,
LAB_RESULT_CM_ID AS SOURCE_ID, 
SYSDATE AS CREATE_DATE,
x.target_domain_id, 
x.target_concept_id
FROM "NATIVE_PCORNET51_CDM"."LAB_RESULT_CM"  
JOIN CDMH_STAGING.PERSON_CLEAN ON LAB_RESULT_CM.PATID=PERSON_CLEAN.PERSON_ID AND PERSON_CLEAN.DATA_PARTNER_ID=DATAPARTNERID  
JOIN CDMH_STAGING.P2o_Code_Xwalk_Standard x ON x.src_code=LAB_RESULT_CM.lab_loinc AND X.Cdm_Tbl='LAB_RESULT_CM'  
LEFT JOIN CDMH_STAGING.N3CDS_DOMAIN_MAP mp on LAB_RESULT_CM.LAB_RESULT_CM_ID=Mp.Source_Id AND mp.DOMAIN_NAME='LAB_RESULT_CM'  
AND Mp.target_domain_id=x.target_domain_id AND mp.target_concept_id=x.target_concept_id AND mp.DATA_PARTNER_ID=DATAPARTNERID
WHERE mp.N3CDS_DOMAIN_MAP_ID IS NULL                                
;
TYPE l_val_cur IS TABLE OF Lab_Cursor%ROWTYPE;
values_rec l_val_cur;

BEGIN

/**************************************************************
_  VARIABLES:
*  loop_count - counts loop iterations for COMMIT_LIMIT
**************************************************************/
   loop_count := 0;
   insert_rec_count := 0;
/******************************************************
* Beginning of loop on each record in cursor.
******************************************************/
open Lab_Cursor;
  LOOP
    FETCH Lab_Cursor bulk collect into values_rec limit 10000;
    EXIT WHEN values_rec.COUNT=0;
BEGIN
   FORALL i IN 1..values_rec.COUNT
	   INSERT INTO CDMH_STAGING.N3CDS_DOMAIN_MAP (DATA_PARTNER_ID,DOMAIN_NAME,SOURCE_ID,CREATE_DATE,TARGET_DOMAIN_ID,TARGET_CONCEPT_ID)
     VALUES (values_rec(i).DATA_PARTNER_ID,values_rec(i).DOMAIN_NAME,values_rec(i).SOURCE_ID,values_rec(i).CREATE_DATE,values_rec(i).TARGET_DOMAIN_ID,values_rec(i).TARGET_CONCEPT_ID);
        COMMIT;
	END;
         insert_rec_count := insert_rec_count+ values_rec.COUNT;
--         dbms_output.put_line('Number of records inserted during loop = '||insert_rec_count);
END LOOP;
RECORDCOUNT :=insert_rec_count;
COMMIT;
Close Lab_Cursor;
dbms_output.put_line('Number of records inserted are = '||RECORDCOUNT);
END SP_DM_PCORNET_LAB_RESULT_CM;
