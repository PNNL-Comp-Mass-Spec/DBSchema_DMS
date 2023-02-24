/****** Object:  StoredProcedure [dbo].[DoAnalysisRequestOperation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DoAnalysisRequestOperation]
/****************************************************
**
**  Desc:
**      Perform analysis request operation defined by 'mode'
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   10/13/2004
**          05/05/2005 grk - removed default mode value
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**
*****************************************************/
(
    @request varchar(32),
    @mode varchar(12),  -- 'delete', ??
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    set @message = ''

    declare @result int

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'DoAnalysisRequestOperation', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    ---------------------------------------------------
    -- Delete analysis job request if it is unused
    ---------------------------------------------------

    if @mode = 'delete'
    begin

        declare @requestID int
        set @requestID = cast(@request as int)
        --
        execute @result = DeleteAnalysisRequest @requestID, @message output
        --
        if @result <> 0
        begin
            RAISERROR (@message, 10, 1)
            return 51142
        end

        return 0
    end -- mode 'deleteNew'


    ---------------------------------------------------
    -- Mode was unrecognized
    ---------------------------------------------------

    set @message = 'Mode "' + @mode +  '" was unrecognized'
    RAISERROR (@message, 10, 1)
    return 51222

GO
GRANT VIEW DEFINITION ON [dbo].[DoAnalysisRequestOperation] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DoAnalysisRequestOperation] TO [DMS_Analysis] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DoAnalysisRequestOperation] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoAnalysisRequestOperation] TO [Limited_Table_Write] AS [dbo]
GO
