/****** Object:  StoredProcedure [dbo].[validate_instrument_group_for_requested_runs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[validate_instrument_group_for_requested_runs]
/****************************************************
**
**  Desc:
**      Validates that the specified instrument group is valid for the dataset types defined for the requested runs in @requestedRunIDList
**
**  Arguments:
**    @requestedRunIDList   Comma separated list of requested run IDs
**    @instrumentGroup      Instrument group name
**    @message              Output: Status message if the group is valid; warning message if the instrument group is not valid
**    @returnCode           Output: Empty string if the instrument group is valid, 'U5205' if the instrument group is not valid for the dataset types
**
**  Auth:   mem
**  Date:   01/13/2023 mem - Initial version (code refactored code from update_requested_run_assignments)
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/02/2023 mem - Use renamed table names
**
*****************************************************/

(
    @requestedRunIDList varchar(max),
    @instrumentGroup varchar(64),
    @message varchar(1024) = '' output,
    @returnCode varchar(64) = '' output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @msg varchar(1024)
    Declare @continue Int

    Declare @datasetTypeID int
    Declare @datasetTypeName varchar(64)

    Declare @requestIDCount int
    Declare @requestIDFirst int
    Declare @requestIDLast int

    Declare @allowedDatasetTypes varchar(255) = ''

    Set @message = ''
    Set @returnCode = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'validate_instrument_group_for_requested_runs', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN Try
        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        Set @requestedRunIDList = Ltrim(Rtrim(IsNull(@requestedRunIDList, '')))
        Set @instrumentGroup = Ltrim(Rtrim(IsNull(@instrumentGroup, '')))

        If @requestedRunIDList = ''
        Begin
            Set @message = 'Argument @requestedRunIDList is an empty string'
            Set @returnCode = 'U5201'

            Return 5201
        End

        If Not Exists (Select * From T_Instrument_Group Where IN_Group = @instrumentGroup)
        Begin
            Set @message = 'Invalid instrument group name: ' + @instrumentGroup
            Set @returnCode = 'U5202'

            Return 5202
        End

        ---------------------------------------------------
        -- Populate a temporary table with the dataset type associated with the requested run IDs in @requestedRunIDList
        ---------------------------------------------------

        CREATE TABLE #Tmp_DatasetTypeList (
            DatasetTypeName varchar(64),
            DatasetTypeID int,
            RequestIDCount int,
            RequestIDFirst Int,
            RequestIDLast int
        )

        INSERT INTO #Tmp_DatasetTypeList (
            DatasetTypeName,
            DatasetTypeID,
            RequestIDCount,
            RequestIDFirst,
            RequestIDLast
        )
        SELECT DST.DST_Name AS DatasetTypeName,
               DST.DST_Type_ID AS DatasetTypeID,
               COUNT(RR.ID) AS RequestIDCount,
               MIN(RequestQ.RequestID) AS RequestIDFirst,
               MAX(RequestQ.RequestID) AS RequestIDFirst
        FROM ( SELECT Distinct Convert(int, Item) AS RequestID
               FROM make_table_from_list ( @requestedRunIDList )
             ) AS RequestQ
             INNER JOIN T_Requested_Run RR
               ON RequestQ.RequestID = RR.ID
             INNER JOIN T_Dataset_Type_Name DST
               ON RR.RDS_type_ID = DST.DST_Type_ID
        GROUP BY DST.DST_Name, DST.DST_Type_ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
        Begin
            Set @message = 'Requested run IDs not found in T_Requested_Run: ' + @requestedRunIDList
            Set @returnCode = 'U5203'

            Return 5203
        End

        ---------------------------------------------------
        -- Make sure the dataset type defined for each of the requested runs
        -- is appropriate for instrument group @instrumentGroup
        ---------------------------------------------------

        SELECT @datasetTypeID = Min(DatasetTypeID) - 1
        FROM #Tmp_DatasetTypeList

        Set @continue = 1

        While @continue = 1
        Begin
            SELECT TOP 1 @datasetTypeID   = DatasetTypeID,
                         @datasetTypeName = DatasetTypeName,
                         @requestIDCount  = RequestIDCount,
                         @requestIDFirst  = RequestIDFirst,
                         @requestIDLast   = RequestIDLast
            FROM #Tmp_DatasetTypeList
            WHERE DatasetTypeID > @datasetTypeID
            ORDER BY DatasetTypeID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
                Set @continue = 0
            Else
            Begin
                ---------------------------------------------------
                -- Verify that dataset type is valid for given instrument group
                ---------------------------------------------------

                If Not Exists (SELECT * FROM T_Instrument_Group_Allowed_DS_Type WHERE IN_Group = @instrumentGroup AND Dataset_Type = @datasetTypeName)
                Begin
                    SELECT @allowedDatasetTypes = dbo.get_instrument_group_dataset_type_list(@instrumentGroup, ', ')

                    Set @message = 'Dataset Type "' + @datasetTypeName + '" is invalid for instrument group "' + @instrumentGroup + '"; valid types are "' + @allowedDatasetTypes + '"'

                    If @requestIDCount > 1
                    Begin
                        Set @message = @message + '; ' + Convert(varchar(12), @requestIDCount) + ' conflicting Request IDs, ranging from ID ' +
                                                 Convert(varchar(12), @requestIDFirst) + ' to ' +  + Convert(varchar(12), @requestIDLast)
                    End
                    Else
                    Begin
                        Set @message = @message + '; conflicting Request ID is ' + Convert(varchar(12), @requestIDFirst)
                    End

                    Set @returnCode = 'U5205'
                    Set @myError = 5205

                    Set @continue = 0
                End

            End
        End

        If @returnCode = ''
        Begin
            SELECT @requestIDCount = Sum(RequestIDCount),
                   @requestIDFirst = Min(RequestIDFirst),
                   @requestIDLast  = Min(RequestIDLast)
            FROM #Tmp_DatasetTypeList

            If @requestIDCount = 1
            Begin
                Set @message = 'Instrument group ' + @instrumentGroup + ' is valid for requested run ID ' + Cast(@requestIDFirst As Varchar(12))
            End
            Else
            Begin
                Set @message = 'Instrument group ' + @instrumentGroup + ' is valid for all ' + Cast(@requestIDCount As Varchar(12)) + ' requested runs ' +
                               '(' + Cast(@requestIDFirst As Varchar(12)) + ' - ' + Cast(@requestIDLast As Varchar(12)) + ')'
            End

        End

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Set @msg = @message + '; Requests '

        If Len(@requestedRunIDList) < 128
            Set @msg = @msg + @requestedRunIDList
        Else
            Set @msg = @msg + Substring(@requestedRunIDList, 1, 128) + ' ...'

        exec post_log_entry 'Error', @msg, 'validate_instrument_group_for_requested_runs'

        Set @returnCode = 'U5210'
        Set @myError = 5210

    END CATCH

    Return @myError

GO
