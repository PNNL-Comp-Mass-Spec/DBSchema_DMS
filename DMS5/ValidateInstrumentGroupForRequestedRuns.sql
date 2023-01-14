/****** Object:  StoredProcedure [dbo].[ValidateInstrumentGroupForRequestedRuns] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ValidateInstrumentGroupForRequestedRuns]
/****************************************************
**
**  Desc:
**      Validates that the specified instrument group is valid for the dataset types defined for the requested runs in @reqRunIDList
**
**  Arguments:
**    @reqRunIDList         Comma separated list of requested run IDs
**    @instrumentGroup      Instrument group name
**    @message              Output: Status message if the group is valid; warning message if the instrument group is not valid
**    @returnCode           Output: Empty string if the instrument group is valid, 'U5205' if the instrument group is not valid for the dataset types
**
**  Auth:   mem
**  Date:   01/13/2023 mem - Initial version (code refactored code from UpdateRequestedRunAssignments)
**
*****************************************************/
(
    @reqRunIDList varchar(max),
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
    Exec @authorized = VerifySPAuthorized 'ValidateInstrumentGroupForRequestedRuns', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN Try
        ---------------------------------------------------
        -- Validate the inputs
        ---------------------------------------------------

        Set @reqRunIDList = Ltrim(Rtrim(IsNull(@reqRunIDList, '')))
        Set @instrumentGroup = Ltrim(Rtrim(IsNull(@instrumentGroup, '')))

        If @reqRunIDList = ''
        Begin
            Set @message = 'Argument @reqRunIDList is an empty string'
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
        -- Populate a temporary table with the dataset type associated with the requested run IDs in @reqRunIDList
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
               FROM MakeTableFromList ( @reqRunIDList )
             ) AS RequestQ
             INNER JOIN T_Requested_Run RR
               ON RequestQ.RequestID = RR.ID
             INNER JOIN T_DatasetTypeName DST
               ON RR.RDS_type_ID = DST.DST_Type_ID
        GROUP BY DST.DST_Name, DST.DST_Type_ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
        Begin
            Set @message = 'Requested run IDs not found in T_Requested_Run: ' + @reqRunIDList
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
                    SELECT @allowedDatasetTypes = dbo.GetInstrumentGroupDatasetTypeList(@instrumentGroup, ', ')

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
        EXEC FormatErrorMessage @message output, @myError output

        -- rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Set @msg = @message + '; Requests '

        If Len(@reqRunIDList) < 128
            Set @msg = @msg + @reqRunIDList
        Else
            Set @msg = @msg + Substring(@reqRunIDList, 1, 128) + ' ...'

        exec PostLogEntry 'Error', @msg, 'ValidateInstrumentGroupForRequestedRuns'

        Set @returnCode = 'U5210'
        Set @myError = 5210

    END CATCH

    Return @myError


GO
