create or replace PROCEDURE test_email_log 
IS
    v_current_time VARCHAR2(20);
    v_cutoff_time NUMBER := 0;
    v_date VARCHAR2(10);
    v_hour NUMBER;
    v_minute NUMBER;

    lclb_FromEmails  VARCHAR2(64) := 'TLSEncryptedEMailTest@noaa.gov';
    lclb_ToEmails                CLOB := 'ilya.taytslin@noaa.gov';
    ls_EmailSubject              CLOB := null;
    lclb_CCEmails                CLOB := null;
    lclb_BCCEmails               CLOB := null;
    lclb_PlainTextEMailBody      CLOB := null;

    v_procedure_name VARCHAR2(64);

    CURSOR lcsr_GetErrors IS
        SELECT module_name, procedure_name, message, end_time FROM adm_fso_log
        WHERE substr(to_char(start_time),1,10) = v_date
        AND (TO_NUMBER(SUBSTR(start_time,12,2)) * 60 + TO_NUMBER(SUBSTR(start_time,15,2))) > v_cutoff_time
        AND execution_status = 'FAILED';

    lrec_Module adm_fso_log.module_name%TYPE;
    lrec_ProcName adm_fso_log.procedure_name%TYPE;
    lrec_Message adm_fso_log.message%TYPE;
    lrec_EndTime adm_fso_log.end_time%TYPE;
BEGIN
    select to_char(sysdate, 'MM/DD/YYYY HH24:MI:SS') INTO v_current_time FROM DUAL;

    v_date := substr(to_char(v_current_time),1,10);
    v_hour := TO_NUMBER(SUBSTR(v_current_time,12,2));
    v_minute := TO_NUMBER(SUBSTR(v_current_time,15,2));
    v_cutoff_time := (v_hour - 3) * 60 + v_minute;

    OPEN lcsr_GetErrors;
    --DBMS_OUTPUT.PUT_LINE('Cursor opened');
    LOOP
        FETCH lcsr_GetErrors INTO lrec_Module, lrec_ProcName, lrec_Message, lrec_EndTime;
        EXIT WHEN lcsr_GetErrors%NOTFOUND;

        --DBMS_OUTPUT.PUT_LINE('Fetched ' || lrec_Message);
        lclb_PlainTextEMailBody := lclb_PlainTextEMailBody || 
            'Procedure ' || lrec_ProcName || ' (Module ' || lrec_Module || ') failed on ' || lrec_EndTime ||
            ' with the following message:' ||chr(13)||chr(10)||chr(13)||chr(10);
        lclb_PlainTextEMailBody := lclb_PlainTextEMailBody || lrec_Message||chr(13)||chr(10)||chr(13)||chr(10);

    END LOOP;
    CLOSE lcsr_GetErrors;
    --DBMS_OUTPUT.PUT_LINE('Cursor closed');

    IF lclb_PlainTextEMailBody IS NOT NULL THEN
        ls_EmailSubject := 'FSO_ADMIN log test: ' || v_current_time;
        send_fso_mail(lclb_FromEmails, lclb_ToEmails, ls_EmailSubject, lclb_CCEmails, lclb_BCCEmails, lclb_PlainTextEMailBody);
    END IF;
END;