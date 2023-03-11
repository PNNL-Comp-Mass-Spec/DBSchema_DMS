/****** Object:  StoredProcedure [dbo].[make_automatic_requested_run_factors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[make_automatic_requested_run_factors]
/****************************************************
**
**  Desc:
**      Adds/updates factors named Actual_Run_Order for the requested runs in the given batch
**      The values for the factors are 1, 2, 3, etc., ordered by the acquisition time values for the datasets associated with the requested runs
**      Requested runs without a dataset will not have an Actual_Run_Order factor added
**
**  Arguments:
**    @mode     Unused parameter (proposed to be 'all' or 'actual_run_order', but in reality this procedure always calls update_requested_run_factors with f="Actual_Run_Order" defined by dataset acquisition times)
**
**  Auth:   grk
**  Date:   03/23/2010 grk - initial release
**          11/08/2016 mem - Use get_user_login_without_domain to obtain the user's network login
**          11/10/2016 mem - Pass '' to get_user_login_without_domain
**          06/10/2022 mem - Exit the procedure if @batchID is 0 or null
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/10/2023 mem - Call update_cached_requested_run_batch_stats to update T_Cached_Requested_Run_Batch_Stats
**
*****************************************************/
(
    @batchID int,
    @mode varchar(32) = 'actual_run_order',     -- 'all', 'actual_run_order'
    @message varchar(512) OUTPUT,
    @callingUser varchar(128) = ''
)
AS
    SET NOCOUNT ON

    Declare @myError Int = 0
    Declare @myRowCount int = 0

    SET @message = ''

    If Coalesce(@batchID, 0) = 0
    Begin
        Set @message = 'Batch ID is zero; cannot create automatic factors'
        Return 0
    End

    DECLARE @factorList VARCHAR(MAX) = ''

    -----------------------------------------------------------
    -- Make factor list for actual run order
    -- FUTURE: support 'actual_run_order' or 'all' for @mode
    -----------------------------------------------------------

    CREATE TABLE #REQ (
        Request int,
        Actual_Run_Order int IDENTITY(1,1) NOT NULL
    )

    INSERT INTO #REQ ( Request )
    SELECT T_Requested_Run.ID
    FROM T_Requested_Run
         INNER JOIN T_Dataset
           ON T_Requested_Run.DatasetID = T_Dataset.Dataset_ID
    WHERE (T_Requested_Run.RDS_BatchID = @batchID) AND
          (NOT (T_Dataset.Acq_Time_Start IS NULL))
    ORDER BY T_Dataset.Acq_Time_Start
    --
    SELECT
        @factorList = @factorList +
        '<r ' +
        'i="' + CONVERT(VARCHAR(12), Request) + '" ' +
        'f="Actual_Run_Order" ' +
        'v="' + CONVERT(VARCHAR(12), Actual_Run_Order) + '" ' +
        '/>'
    FROM #REQ

    -----------------------------------------------------------
    -- Update factors
    -----------------------------------------------------------
    --
    If @factorList = ''
    Begin
        RETURN @myError
    End

    If @callingUser = ''
    BEGIN
        SET @callingUser = dbo.get_user_login_without_domain('')
    END

    EXEC @myError = update_requested_run_factors
                            @factorList,
                            @message OUTPUT,
                            @callingUser

    -- Update cached data in T_Cached_Requested_Run_Batch_Stats
    Exec update_cached_requested_run_batch_stats @batchID, @fullRefresh = 0
    
    RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[make_automatic_requested_run_factors] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[make_automatic_requested_run_factors] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[make_automatic_requested_run_factors] TO [Limited_Table_Write] AS [dbo]
GO
