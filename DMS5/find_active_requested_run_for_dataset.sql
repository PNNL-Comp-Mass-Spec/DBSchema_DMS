/****** Object:  StoredProcedure [dbo].[find_active_requested_run_for_dataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[find_active_requested_run_for_dataset]
/****************************************************
**
**  Desc:
**      Looks for an active requested run for the specified dataset name
**
**      Steps backward through the name looking for dashes and underscores, looking
**      for active requested runs that match the dataset name portion
**
**      If one and only one match is found, returns that requested run's id via the output parameter
**      If multiple matches are found, @requestedID will be 0
**
**  Return values: 0 if no error; otherwise error code
**
**  Auth:   mem
**  Date:   06/10/2016 mem - Initial version
**          10/19/2020 mem - Rename the instrument group column to RDS_instrument_group
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          09/07/2023 mem - Update warning messages
**          09/11/2023 mem - Stop searching for matches once one or more requested runs are matched
**
*****************************************************/
(
    @datasetName varchar(128),                      -- Dataset name
    @experimentID int = 0,                          -- Optional; include to limit by experiment ID,
    @requestID int = 0 output,                      -- Matched request ID; 0 if no match
    @requestInstGroup varchar(128) = '' output,     -- Instrument group for the matched request; empty if no match
    @requestMatchCount int = 0 output,              -- Number of matching candidate run requests
    @showDebugMessages tinyint = 0
)
AS
    Set XACT_ABORT, nocount on
    Set NOCOUNT ON

    Declare @myRowCount int
    Declare @myError int
    Set @myRowCount = 0
    Set @myError = 0

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @datasetName = IsNull(@datasetName, '')
    Set @experimentID = IsNull(@experimentID, 0)
    Set @showDebugMessages = IsNull(@showDebugMessages, 0)

    If @datasetName = ''
        RAISERROR ('Dataset name must be specified', 11, 10)

    ---------------------------------------------------
    -- Initialize some variables
    ---------------------------------------------------

    Declare @startPos int = 1

    Declare @datasetReversed varchar(128) = Reverse(@datasetName)
    Declare @datasetNameLength int = Len(@datasetName)
    Declare @underscorePos int
    Declare @dashPos int
    Declare @DatasetPrefix varchar(128)

    Declare @requestName varchar(128) = ''

    Set @requestID = 0
    Set @requestInstGroup = ''
    Set @requestMatchCount = 0

    ---------------------------------------------------
    -- Search for active requested runs
    ---------------------------------------------------

    While @startPos > 0
    Begin -- <a>

        Set @underscorePos = CharIndex('_', @datasetReversed, @startPos)
        Set @dashPos = CharIndex('-', @datasetReversed, @startPos)

        If @underscorePos > 0
        Begin
            If @dashPos > 0 AND @dashPos < @underscorePos
                Set @startPos = @dashPos
            Else
                Set @startPos = @underscorePos
        End
        Else
        Begin
            Set @startPos = @dashPos
        End

        If @startPos > 0
        Begin -- <b>
            Set @DatasetPrefix = Substring(@datasetName, 1, @datasetNameLength - @startPos)

            If @showDebugMessages > 0
                Print Substring(@datasetName, 1, @datasetNameLength - @startPos)

            If @experimentID <= 0
                SELECT @requestMatchCount = Count(*),
                       @requestID = Min(ID)
                FROM T_Requested_Run
                WHERE RDS_Name LIKE @DatasetPrefix + '%' AND
                      RDS_Status = 'Active'
            Else
                SELECT @requestMatchCount = Count(*),
                       @requestID = Min(ID)
                FROM T_Requested_Run
                WHERE RDS_Name LIKE @DatasetPrefix + '%' AND
                      RDS_Status = 'Active' AND
                      Exp_ID = @experimentID

            If @requestMatchCount > 0
            Begin
                If @requestMatchCount = 1
                Begin
                    -- Single match found; lookup the requested run's instrument group
                    SELECT @requestInstGroup = RDS_instrument_group,
                           @requestName = RDS_Name
                    FROM T_Requested_Run
                    WHERE ID = @requestID
                End
                Else
                Begin
                    -- Multiple matches were found; set @requestID to 0
                    Set @requestID = 0
                End

                Set @startPos = 0
            End
            Else
            Begin
                Set @requestID = 0
                Set @startPos = @startPos + 1
            End
        End -- </b>

    End -- </a>

    If @showDebugMessages > 0
    Begin
        If @requestID > 1
            SELECT 'Match found ' AS Status,
                   @datasetName As Dataset,
                   @requestID AS Request_ID,
                   @requestName AS Request,
                   @requestInstGroup AS Instrument_Group
        Else
        Begin
            If @requestMatchCount > 1
                SELECT 'Multiple matches found' AS Status,
                       @datasetName As Dataset,
                       @requestMatchCount as Candidate_Count
            Else
                SELECT 'Match not found' AS Status,
                       @datasetName As Dataset,
                       @requestMatchCount as Candidate_Count
        End
    End

Done:
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[find_active_requested_run_for_dataset] TO [DDL_Viewer] AS [dbo]
GO
