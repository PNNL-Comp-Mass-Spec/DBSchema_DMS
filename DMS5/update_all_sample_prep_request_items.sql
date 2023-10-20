/****** Object:  StoredProcedure [dbo].[update_all_sample_prep_request_items] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_all_sample_prep_request_items]
/****************************************************
**
**  Desc:
**      Calls update_sample_prep_request_items for all active sample prep requests, updating table T_Sample_Prep_Request_Items
**      It also updates items for closed sample prep requests where the state was changed within the last year
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   07/05/2013 grk - Initial release
**          02/23/2016 mem - Add Set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          06/15/2021 mem - Also update counts for prep requests whose state changed within the last year
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          10/19/2023 mem - Also update counts for prep requests with state 1 (New)
**
*****************************************************/
(
    @daysPriorToUpdateClosedRequests int = 365,
    @message varchar(512) = '' output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @daysPriorToUpdateClosedRequests = Abs(IsNull(@daysPriorToUpdateClosedRequests, 365))
    Set @message = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_all_sample_prep_request_items', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

        ---------------------------------------------------
        -- Create and populate table to hold prep request IDs to process
        ---------------------------------------------------

        CREATE TABLE #SPRS (
            ID INT
        )

        -- Update counts for new and active prep requests
        INSERT INTO #SPRS ( ID )
        SELECT ID
        FROM T_Sample_Prep_Request
        WHERE State IN (1, 2, 3, 4)

        -- Also update counts for closed prep requests where the state changed within the last year
        INSERT INTO #SPRS ( ID )
        SELECT ID
        FROM T_Sample_Prep_Request
        WHERE State = 5 And StateChanged >= DateAdd(Day, -@daysPriorToUpdateClosedRequests, GetDate())

        ---------------------------------------------------
        -- Process the sample prep requests in #SPRS
        ---------------------------------------------------

        Declare @itemType varchar(128) = ''
        Declare @mode varchar(12) = 'update'
        Declare @callingUser varchar(128) = suser_sname()

        Declare @currentId int = 0
        Declare @prevId int = 0
        Declare @continue int = 1

        While @continue = 1
        Begin
            Set @currentId = 0

            SELECT TOP 1 @currentId = ID
            FROM #SPRS
            WHERE ID > @prevId
            ORDER BY ID

            If @currentId = 0
            Begin
                Set @continue = 0
            End
            Else
            Begin
                Set @prevId = @currentId

                EXEC @myError = update_sample_prep_request_items
                        @currentId,
                        @mode,
                        @message OUTPUT,
                        @callingUser

            End
        End

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output
        -- rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @message, 'update_all_sample_prep_request_items'
    END CATCH

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_all_sample_prep_request_items] TO [DDL_Viewer] AS [dbo]
GO
