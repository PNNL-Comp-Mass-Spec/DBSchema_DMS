/****** Object:  StoredProcedure [dbo].[get_dataset_details_from_dataset_info_xml] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_dataset_details_from_dataset_info_xml]
/****************************************************
**
**  Desc:   Extracts the dataset name from @datasetInfoXML
**          If @datasetID is non-zero, validates the dataset ID vs. the dataset name
**          Otherwise, updates @datasetID based on the dataset name defined in the XML
**
**          This procedure is used by procedures UpdateDatasetFileInfoXML and UpdateDatasetDeviceInfoXML
**
**      Typical XML file contents:
**
**      <DatasetInfo>
**        <Dataset>QC_Shew_17_01_Run_2_7Jun18_Oak_18-03-08</Dataset>
**        ...
**      </DatasetInfo>
**
**  Auth:   mem
**  Date:   02/29/2020 mem - Initial version
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @datasetInfoXML xml,                            -- Dataset info, in XML format
    @datasetID int = 0 Output,                      -- Input/output parameter
    @datasetName varchar(128) = '' Output,          -- Input/output parameter
    @message varchar(512) = '' Output,              -- Error message, or an empty string if no error
    @returnCode int = 0 Output                      -- 0 if no error, otherwise an integer
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @datasetIDText varchar(12) = Cast(@datasetID as varchar(12))
    Declare @datasetIDCheck Int = 0

    Set @datasetName  = ''
    Set @message = ''
    Set @returnCode = 0

    ---------------------------------------------------
    -- Parse out the dataset name from @datasetInfoXML
    -- If this parse fails, there is no point in continuing
    ---------------------------------------------------

    SELECT @datasetName = DSName
    FROM (SELECT @datasetInfoXML.value('(/DatasetInfo/Dataset)[1]', 'varchar(128)') AS DSName
         ) LookupQ
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error extracting the dataset name from @datasetInfoXML for DatasetID ' + @datasetIDText + ' in SP get_dataset_details_from_dataset_info_xml'
        Goto Done
    End

    If @myRowCount = 0 or IsNull(@datasetName, '') = ''
    Begin
        set @message = 'XML in @datasetInfoXML is not in the expected form for DatasetID ' + @datasetIDText + ' in SP get_dataset_details_from_dataset_info_xml; Could not match /DatasetInfo/Dataset'
        Set @myError = 50000
        Goto Done
    End

    ---------------------------------------------------
    -- Update or Validate Dataset_ID in @DSInfoTable
    ---------------------------------------------------
    --
    If @datasetID = 0
    Begin
        SELECT @datasetID = DS.Dataset_ID
        FROM T_Dataset DS
        WHERE DS.Dataset_Num = @datasetName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
        Begin
            Set @message = 'Dataset "' + @datasetName + '" not found in table T_Dataset by SP get_dataset_details_from_dataset_info_xml'
            Set @myError = 50001
            Goto Done
        End
    End
    Else
    Begin
        -- @datasetID is non-zero

        -- Validate that @datasetID exists in T_Dataset
        If Not Exists (SELECT * FROM T_Dataset WHERE Dataset_ID = @datasetID)
        Begin
            Set @message = 'Dataset ID "' + @datasetIDText + '" not found in table T_Dataset by SP get_dataset_details_from_dataset_info_xml'
            Set @myError = 50002
            Goto Done
        End

        SELECT @datasetIDCheck = DS.Dataset_ID
        FROM T_Dataset DS
        WHERE DS.Dataset_Num = @datasetName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
        Begin
            Set @message = 'Dataset "' + @datasetName + '" not found in table T_Dataset by SP get_dataset_details_from_dataset_info_xml'
            Set @myError = 50003
            Goto Done
        End

        If @datasetIDCheck <> @datasetID
        Begin
            Set @message = 'Dataset ID values for ' + @datasetName + ' do not match; ' +
                           'expecting ' + Cast(@datasetIDCheck As varchar(12)) + ' but stored procedure param ' +
                           '@datasetID is ' + @datasetIDText
            Set @myError = 50004
            Goto Done
        End
    End

Done:

    Set @returnCode = @myError
    Return @myError

GO
