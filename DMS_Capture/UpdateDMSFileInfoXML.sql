/****** Object:  StoredProcedure [dbo].[UpdateDMSFileInfoXML] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateDMSFileInfoXML]
/****************************************************
**
**  Desc:   Calls synonym S_UpdateDatasetFileInfoXML for the specified DatasetID
**
**      S_UpdateDatasetFileInfoXML refers to UpdateDatasetFileInfoXML in DMS5
**      UpdateDatasetFileInfoXML uses data in T_Dataset_Info_XML in this database
**      to populate several dataset related tables
**      - T_Dataset: Acq_Time_Start, Acq_Time_End, Scan_Count, File_Size_Bytes, File_Info_Last_Modified
**      - T_Dataset_Info: ScanCountMS, ScanCountMSn, Elution_Time_Max, etc.
**      - T_Dataset_ScanTypes
**      - T_Dataset_Files
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   mem
**  Date:   09/01/2010 mem - Initial Version
**          06/13/2018 mem - Add comment regarding duplicate datasets
**          08/09/2018 mem - Set Ignore to 1 when the return code from S_UpdateDatasetFileInfoXML is 53600
**    
*****************************************************/
(
    @DatasetID INT,
    @DeleteFromTableOnSuccess tinyint = 1,
    @message varchar(512) = '' output,
    @infoOnly tinyint = 0
)
As
    Set nocount on

    declare @myError int = 0
    declare @myRowCount int = 0
        
    Declare @DatasetInfoXML xml

    --------------------------------------------
    -- Validate the inputs
    --------------------------------------------
    --
    Set @DeleteFromTableOnSuccess = IsNull(@DeleteFromTableOnSuccess, 1)
    Set @message = ''
    Set @infoOnly = IsNull(@infoOnly, 0)
    
    SELECT @DatasetInfoXML = DS_Info_XML
    FROM T_Dataset_Info_XML
    WHERE Dataset_ID = @DatasetID
    
    If Not @DatasetInfoXML Is Null
    Begin
        If @infoOnly > 0
            Print 'Call S_UpdateDatasetFileInfoXML for DatasetID ' + Cast(@DatasetID as varchar(12))

        -- Note that this procedure will return error code 53600 if this dataset is a duplicate to another dataset (based on T_Dataset_Files)

        EXEC @myError = S_UpdateDatasetFileInfoXML @DatasetID, @DatasetInfoXML, @message output, @infoOnly=@infoOnly
        
        If @myError = 0 And @infoOnly = 0 And @DeleteFromTableOnSuccess <> 0
        Begin
            DELETE FROM T_Dataset_Info_XML WHERE Dataset_ID = @DatasetID
        End

        If @myError = 53600 And @infoOnly = 0 And @DeleteFromTableOnSuccess <> 0
        Begin
            UPDATE T_Dataset_Info_XML Set Ignore = 1 WHERE Dataset_ID = @DatasetID
        End

    End

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDMSFileInfoXML] TO [DDL_Viewer] AS [dbo]
GO
