/****** Object:  StoredProcedure [dbo].[update_prep_lc_run_work_package_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_prep_lc_run_work_package_list]
/****************************************************
**
**  Desc:
**      Updates the work package list for a single prep LC run or for all prep LC runs
**
**  Auth:   mem
**  Date:   03/08/2023 mem - Initial version
**
*****************************************************/
(
    @prepLCRunID int,                 -- If 0, update all rows in T_Prep_LC_Run
    @message varchar(512) = '' output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @currentPrepRunID Int
    Declare @samplePrepRequestIDs Varchar(1024)

    Declare @continue tinyint
    Declare @wpList varchar(1024)

    set @message = ''

    BEGIN TRY

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    
    Set @prepLCRunID = Coalesce(@prepLCRunID, 0)

    CREATE TABLE #Tmp_SamplePrepRequests_for_WP_List (
        Prep_Request_ID Int Not Null
    )
    
    ---------------------------------------------------
    -- Update the work package list for each Prep LC Run
    ---------------------------------------------------

    Set @continue = 1

    If @prepLCRunID = 0
        Set @currentPrepRunID = -1
    Else
        Set @currentPrepRunID = @prepLCRunID - 1

    While @continue > 0
    Begin

        SELECT TOP 1 @currentPrepRunID = ID,
                     @samplePrepRequestIDs = Sample_Prep_Requests
        FROM T_Prep_LC_Run
        WHERE ID > @currentPrepRunID
        ORDER BY id
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
        Begin
            Set @continue = 0
        End
        Else
        Begin
            Set @wpList = Null

            If Coalesce(@samplePrepRequestIDs, '') <> ''
            Begin
                ---------------------------------------------------
                -- Populate the temporary table with the sample prep request ID(s)
                ---------------------------------------------------

                Delete From #Tmp_SamplePrepRequests_for_WP_List

                INSERT INTO #Tmp_SamplePrepRequests_for_WP_List (Prep_Request_ID)
                SELECT Distinct Value
                FROM dbo.parse_delimited_integer_list ( @samplePrepRequestIDs, ',' )
        
                ---------------------------------------------------
                -- Construct the list of work packages for the prep request IDs
                ---------------------------------------------------

                SELECT @wpList = Coalesce(@wpList + ', ' + DistinctQ.Work_Package_Number, DistinctQ.Work_Package_Number)
                FROM ( SELECT DISTINCT Work_Package_Number
                       FROM T_Sample_Prep_Request SPR
                            INNER JOIN #Tmp_SamplePrepRequests_for_WP_List NewIDs
                              ON SPR.ID = NewIDs.Prep_Request_ID) As DistinctQ
                ORDER BY DistinctQ.Work_Package_Number
            End

            -- Update the table if @wpList differs from the existing value
            --
            UPDATE T_Prep_LC_Run
            SET Sample_Prep_Work_Packages = @wpList
            WHERE ID = @currentPrepRunID And
                       Coalesce(NULLIF(T_Prep_LC_Run.Sample_Prep_Work_Packages, @wpList),
                                NULLIF(@wpList, T_Prep_LC_Run.Sample_Prep_Work_Packages)) IS NOT NULL 
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

        End

        If @prepLCRunID > 0
            Set @continue = 0
    End
    
    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;
    END Catch

    return @myError

GO
