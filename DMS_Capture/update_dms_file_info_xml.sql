/****** Object:  StoredProcedure [dbo].[update_dms_file_info_xml] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_dms_file_info_xml]
/****************************************************
**
**  Desc:   
**      Calls synonym s_update_dataset_file_info_xml for the specified DatasetID
**
**      The synonym refers to update_dataset_file_info_xml in DMS5
**
**      update_dataset_file_info_xml uses data in T_Dataset_Info_XML in this database
**      to populate several dataset info tables
**
**      Table                Columns / Description
**      -----                ---------------------
**      T_Dataset            Acq_Time_Start, Acq_Time_End, Scan_Count, File_Size_Bytes, File_Info_Last_Modified
**      T_Dataset_Info       ScanCountMS, ScanCountMSn, Elution_Time_Max, ScanTypes, Scan_Count_DIA, etc.
**      T_Dataset_ScanTypes  ScanType, ScanCount, ScanFilter
**      T_Dataset_Files      File_Path, File_Size_Bytes, File_Hash, File_Size_Rank
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   09/01/2010 mem - Initial Version
**          06/13/2018 mem - Add comment regarding duplicate datasets
**          08/09/2018 mem - Set Ignore to 1 when the return code from s_update_dataset_file_info_xml is 53600
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @datasetID int,
    @deleteFromTableOnSuccess tinyint = 1,
    @message varchar(512) = '' output,
    @infoOnly tinyint = 0
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

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
            Print 'Call s_update_dataset_file_info_xml for DatasetID ' + Cast(@DatasetID as varchar(12))

        -- Note that this procedure will return error code 53600 if this dataset is a duplicate to another dataset (based on T_Dataset_Files)

        EXEC @myError = s_update_dataset_file_info_xml @DatasetID, @DatasetInfoXML, @message output, @infoOnly=@infoOnly

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
GRANT VIEW DEFINITION ON [dbo].[update_dms_file_info_xml] TO [DDL_Viewer] AS [dbo]
GO
