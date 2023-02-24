/****** Object:  StoredProcedure [dbo].[validate_instrument_group_and_dataset_type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[validate_instrument_group_and_dataset_type]
/****************************************************
**
**  Desc:   Validates the dataset type for the given instrument group
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   mem
**  Date:   08/27/2010 mem - Initial version
**          09/09/2010 mem - Removed print statements
**          07/04/2012 grk - Added handling for 'Tracking' type
**          11/12/2013 mem - Changed @instrumentName to be an input/output parameter
**          03/25/2014 mem - Now auto-updating dataset type from HMS-HMSn to HMS-HCD-HMSn for group QExactive
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @datasetType varchar(20),
    @instrumentGroup varchar(64) output,            -- Input/output parameter
    @datasetTypeID int output,
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    declare @allowedDatasetTypes varchar(255)

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @DatasetType = IsNull(@DatasetType, '')
    Set @instrumentGroup = IsNull(@instrumentGroup, '')
    Set @datasetTypeID = 0
    set @message = ''

    ---------------------------------------------------
    -- verify that dataset type is valid
    -- and get its id number
    ---------------------------------------------------

    execute @datasetTypeID = get_dataset_type_id @DatasetType

    -- No further validation required for certain dataset types
    -- In particular, dataset type 100 (Tracking)
    If @datasetTypeID IN (100)
    Begin
        Goto Done
    End

    if @datasetTypeID = 0
    begin
        set @message = 'Could not find entry in database for dataset type "' + @DatasetType + '"'
        return 51118
    end

    -- Possibly auto-update the dataset type
    If @instrumentGroup = 'QExactive' AND @DatasetType IN ('HMS-HMSn')
        Set @DatasetType = 'HMS-HCD-HMSn'

    ---------------------------------------------------
    -- Verify that dataset type is valid for given instrument group
    ---------------------------------------------------

    If @instrumentGroup <> ''
    Begin
        SELECT @instrumentGroup = IN_Group
        FROM T_Instrument_Group
        WHERE IN_Group = @instrumentGroup
        --
        SELECT @myRowCount = @@RowCount, @myError = @@Error

        If @myRowCount = 0
        Begin
            set @message = 'Invalid instrument group: ' + @instrumentGroup
            return 51013
        End

        If Not Exists (SELECT * FROM T_Instrument_Group_Allowed_DS_Type WHERE IN_Group = @instrumentGroup AND Dataset_Type = @DatasetType)
        begin
            Set @allowedDatasetTypes = ''

            SELECT @allowedDatasetTypes = @allowedDatasetTypes + ', ' + Dataset_Type
            FROM T_Instrument_Group_Allowed_DS_Type
            WHERE IN_Group = @instrumentGroup
            ORDER BY Dataset_Type

            -- Remove the leading two characters
            If Len(@allowedDatasetTypes) > 0
                Set @allowedDatasetTypes = Substring(@allowedDatasetTypes, 3, Len(@allowedDatasetTypes))

            set @message = 'Dataset Type "' + @DatasetType + '" is invalid for instrument group "' + @instrumentGroup + '"; valid types are "' + @allowedDatasetTypes + '"'
            return 51014
        end

    End

Done:
    ---------------------------------------------------
    -- Done
    ---------------------------------------------------

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[validate_instrument_group_and_dataset_type] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[validate_instrument_group_and_dataset_type] TO [Limited_Table_Write] AS [dbo]
GO
