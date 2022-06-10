/****** Object:  StoredProcedure [dbo].[MakeAutomaticRequestedRunFactors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[MakeAutomaticRequestedRunFactors]
/****************************************************
**
**  Desc: 
**      Create reqeusted run factors from metadata values
**
**  Auth:   grk
**  Date:   03/23/2010 grk - initial release
**          11/08/2016 mem - Use GetUserLoginWithoutDomain to obtain the user's network login
**          11/10/2016 mem - Pass '' to GetUserLoginWithoutDomain
**          06/10/2022 mem - Exit the procedure if @batchID is 0 or null
**    
*****************************************************/
(
    @batchID int,
    @mode varchar(32) = 'all', -- 'all', 'actual_run_order'
    @message varchar(512) OUTPUT,
    @callingUser varchar(128) = ''
)
As
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
    -- FUTURE: mode = 'actual_run_order' or 'all'
    -----------------------------------------------------------

    CREATE TABLE #REQ (
        Request INT,
        Seq INT IDENTITY(1,1) NOT NULL
    )

    INSERT INTO #REQ( Request )
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
        'v="' + CONVERT(VARCHAR(12), Seq) + '" ' +
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
        SET @callingUser = dbo.GetUserLoginWithoutDomain('')
    END

    EXEC @myError = UpdateRequestedRunFactors
                            @factorList,
                            @message OUTPUT,
                            @callingUser
                            
    RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[MakeAutomaticRequestedRunFactors] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[MakeAutomaticRequestedRunFactors] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[MakeAutomaticRequestedRunFactors] TO [Limited_Table_Write] AS [dbo]
GO
