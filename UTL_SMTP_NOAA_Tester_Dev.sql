set serveroutput on

DECLARE

    FROM_ADDRESS CONSTANT VARCHAR2(64) := 'TLSEncryptedEMailTest@noaa.gov';
    
    lclb_ToEmails                CLOB := 'ilya.taytslin@noaa.gov';
    lclb_CCEmails                CLOB := 'joseph.upshaw@noaa.gov';
    lclb_BCCEmails               CLOB := 'david.weekley@noaa.gov';
    lclb_PlainTextEMailBody      CLOB := 'This is a Test of sending TLS ' ||
                                         'Encrypted Emails from the database ' || 
                                         '(' ||
                                         SYS_CONTEXT( 'USERENV', 'DB_NAME' ) || 
                                         ') via the Google Relay server.' || 
                                         Chr(10) || Chr(10) || 'It was ' ||
                                         'constructed using an encapsulated ' ||
                                         'package with no direct calls to ' ||
                                         'UTL_SMTP or UTL_MAIL.';
                                         
    lclb_HTMLEMailBody           CLOB := '<html>
    <head>
      <title>Test of TLS Encrypted Email</title>
    </head>
    <body>
        <p>This is a <b>HTML version</b> of the test message <b>with MULTIPLE attachments</b>.</p>
        <p><img src="https://www.fisheries.noaa.gov/themes/custom/noaa_components/images/noaa-50th-logo.png" alt="NOAA 50 Year Anniversary" /></p>
        <p>This is a Test of sending TLS Encrypted Emails from the ' ||
           'database (' || SYS_CONTEXT( 'USERENV', 'DB_NAME' ) || ') via ' || 
           'the Google Relay server.<br><br>It was ' || 
           'constructed using an encapsulated package with no direct calls to ' ||
           'either the UTL_SMTP or UTL_MAIL packages.</p>
    </body>
</html>';    
    
    ltb_Attachments              UTL_SMTP_NOAA.TAB_ATTACHMENTS;
    
    ls_EmailSubject              VARCHAR2(64) := 'Test of TLS Encrypted Email - ' || SYS_CONTEXT( 'USERENV', 'INSTANCE_NAME' );
    
    CURSOR lcsr_GetSampleBLOB IS
        SELECT FILE_NAME, MIME_TYPE, DOCUMENT
        FROM
        ( SELECT FILENAME AS FILE_NAME, 'image/gif' AS MIME_TYPE, PRODUCT_IMAGE AS DOCUMENT, 
                 ROW_NUMBER() OVER ( PARTITION BY FILENAME ORDER BY IMAGE_LAST_UPDATE ) AS ROW_NUM_WITHIN_GROUP
          FROM JOPS.DEMO_PRODUCT_INFO
          WHERE ROWNUM < 7 )
        WHERE ROW_NUM_WITHIN_GROUP = 1;
        
    lrec_SampleBlob lcsr_GetSampleBLOB%ROWTYPE;
    
BEGIN

    -- Plain Text EMail, no Attachments
    
    UTL_SMTP_NOAA.SEND_ENCRYPTED_EMAIL( as_EMailFromAddress          => FROM_ADDRESS,
                                        aclb_ToEMailAddresses        => lclb_ToEmails,
                                        aclb_CCEMailAddresses        => lclb_CCEmails,
                                        aclb_BCCEMailAddresses       => lclb_BCCEmails,
                                        as_EMailAddressDelimiter     => ';',
                                        as_EMailSubject              => ls_EmailSubject,
                                        aclb_PlainTextMessageBody    => lclb_PlainTextEMailBody,
                                        aclb_HTMLMessageBody         => NULL,
                                        as_AttachmentFriendlyName    => NULL,
                                        as_AttachmentMimeType        => NULL,
                                        ablb_AttachmentPayload       => NULL );
                                        
    -- HTML Email (Not enforced but, Best Practice is that a Plain Text Version  
    --             Should ALWAYS also be Provided as a Fall Through!)
    
    UTL_SMTP_NOAA.SEND_ENCRYPTED_EMAIL( as_EMailFromAddress          => FROM_ADDRESS,
                                        aclb_ToEMailAddresses        => lclb_ToEmails,
                                        aclb_CCEMailAddresses        => lclb_CCEmails,
                                        aclb_BCCEMailAddresses       => lclb_BCCEmails,
                                        as_EMailAddressDelimiter     => ';',
                                        as_EMailSubject              => ls_EmailSubject,
                                        aclb_PlainTextMessageBody    => lclb_PlainTextEMailBody,
                                        aclb_HTMLMessageBody         => Replace( lclb_HTMLEMailBody,
                                                                                 ' <b>with MULTIPLE attachments</b>' ),
                                        as_AttachmentFriendlyName    => NULL,
                                        as_AttachmentMimeType        => NULL,
                                        ablb_AttachmentPayload       => NULL );
    
    -- HTML Email with Single Attachment
    
    OPEN lcsr_GetSampleBLOB;
    FETCH lcsr_GetSampleBLOB INTO lrec_SampleBlob;
    CLOSE lcsr_GetSampleBLOB;
   
    UTL_SMTP_NOAA.SEND_ENCRYPTED_EMAIL( as_EMailFromAddress          => FROM_ADDRESS,
                                        aclb_ToEMailAddresses        => lclb_ToEmails,
                                        aclb_CCEMailAddresses        => lclb_CCEmails,
                                        aclb_BCCEMailAddresses       => lclb_BCCEmails,
                                        as_EMailAddressDelimiter     => ';',
                                        as_EMailSubject              => ls_EmailSubject,
                                        aclb_PlainTextMessageBody    => lclb_PlainTextEMailBody,
                                        aclb_HTMLMessageBody         => Replace( Replace( lclb_HTMLEMailBody,
                                                                                          'MULTIPLE',
                                                                                          'A SINGLE' ),
                                                                                 'attachments',
                                                                                 'attachment' ),
                                        as_AttachmentFriendlyName    => lrec_SampleBlob.FILE_NAME,
                                        as_AttachmentMimeType        => lrec_SampleBlob.MIME_TYPE,
                                        ablb_AttachmentPayload       => lrec_SampleBlob.DOCUMENT ); 
                                        
    -- HTML Email with Multiple Attachments
    
    OPEN lcsr_GetSampleBLOB;
    
    LOOP
        FETCH lcsr_GetSampleBLOB INTO lrec_SampleBlob;
        EXIT WHEN lcsr_GetSampleBLOB%NOTFOUND;
        
        ltb_Attachments(ltb_Attachments.COUNT + 1 ) := lrec_SampleBlob;
    END LOOP;
    
    CLOSE lcsr_GetSampleBLOB;
    
    UTL_SMTP_NOAA.SEND_ENCRYPTED_EMAIL( as_EMailFromAddress          => FROM_ADDRESS,
                                        aclb_ToEMailAddresses        => lclb_ToEmails,
                                        aclb_CCEMailAddresses        => lclb_CCEmails,
                                        aclb_BCCEMailAddresses       => lclb_BCCEmails,
                                        as_EMailAddressDelimiter     => ';',
                                        as_EMailSubject              => ls_EmailSubject,
                                        aclb_PlainTextMessageBody    => lclb_PlainTextEMailBody,
                                        aclb_HTMLMessageBody         => lclb_HTMLEMailBody,
                                        atb_Attachments              => ltb_Attachments );
END;
/
