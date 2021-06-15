/****** Object:  StoredProcedure [dbo].[UpdateAllSamplePrepRequestItems] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateAllSamplePrepRequestItems]
/****************************************************
**
**  Desc:
**      Calls update sample prep request items for all active sample prep requests
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   07/05/2013 grk - initial release
**          02/23/2016 mem - Add Set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**
*****************************************************/
As
    Set XACT_ABORT, nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    DECLARE @message varchar(512) = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------
        
    Declare @authorized tinyint = 0    
    Exec @authorized = VerifySPAuthorized 'UpdateAllSamplePrepRequestItems', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;
 
    BEGIN TRY 
    
        ---------------------------------------------------

        CREATE TABLE #SPRS (
            ID INT
            -- FUTURE: details about auto-update
        )

        INSERT INTO #SPRS
        ( ID )
        SELECT [ID]
        FROM [T_Sample_Prep_Request]
        WHERE [State] IN (2,3,4)

        ---------------------------------------------------
        -- Cycle through active packages and do auto import
        -- for each one
        ---------------------------------------------------
        DECLARE
                @itemType varchar(128) = '',
                @mode varchar(12) = 'update',
                @callingUser varchar(128) = USER

        DECLARE
            @currentId INT = 0,
            @prevId INT = 0,
            @done INT = 0

        WHILE @done = 0
        BEGIN --<d>
            SET @currentId = 0

            SELECT TOP 1 @currentId = ID
            FROM #SPRS
            WHERE ID > @prevId
            ORDER BY ID

            IF @currentId = 0
            BEGIN --<e>
                SET @done = 1
            END --<e>
            ELSE
            BEGIN  --<f>
                SET @prevId = @currentId

            EXEC @myError = UpdateSamplePrepRequestItems
                    @currentId,
                    @mode,
                    @message OUTPUT,
                    @callingUser

/*
                EXEC @myError = UpdateOSMPackageItems
                                    @currentId,
                                    @itemType,
                                    @itemList,
                                    @comment,
                                    @mode,
                                    @message output,
                                    @callingUser
*/
            End
        End

    END TRY     
    BEGIN CATCH 
        EXEC FormatErrorMessage @message output, @myError output
        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec PostLogEntry 'Error', @message, 'UpdateAllSamplePrepRequestItems'
    END CATCH
    
    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateAllSamplePrepRequestItems] TO [DDL_Viewer] AS [dbo]
GO
