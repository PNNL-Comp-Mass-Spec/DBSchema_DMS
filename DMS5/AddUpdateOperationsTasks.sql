/****** Object:  StoredProcedure [dbo].[AddUpdateOperationsTasks] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddUpdateOperationsTasks]
/****************************************************
**
**  Desc: 
**      Adds new or edits existing item in T_Operations_Tasks 
**
**  Auth:   grk
**  Date:   09/01/2012 
**          11/19/2012 grk - Added work package and closed date
**          11/04/2013 grk - Added @hoursSpent
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          03/16/2022 mem - Rename parameters
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
    @id int output,
    @tab varchar(64),
    @requester varchar(64),
    @requestedPersonnel varchar(256),
    @assignedPersonnel varchar(256),
    @description varchar(5132),
    @comments varchar(MAX),
    @workPackage VARCHAR(32),
    @hoursSpent VARCHAR(12),
    @status varchar(32),
    @priority varchar(32),
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
As
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    SET @message = ''
    
    Declare @closed datetime = null

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------
        
    Declare @authorized tinyint = 0    
    Exec @authorized = VerifySPAuthorized 'AddUpdateOperationsTasks', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    Begin TRY 

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    If @status IN ('Completed', 'Not Implemented')
    Begin 
        SET @closed = GETDATE() 
    End 
    
    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    If @mode = 'update'
    Begin
        -- Cannot update a non-existent entry
        --
        Declare @tmp int = 0
        Declare @curStatus varchar(32) = ''
        Declare @curClosed datetime = null
        --
        SELECT @tmp = ID,
               @curStatus = Status,
               @curClosed = Closed
        FROM T_Operations_Tasks
        WHERE ID = @id
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0 OR @tmp = 0
            RAISERROR ('No entry could be found in database for update', 11, 16)
            
        If @curStatus IN ('Completed', 'Not Implemented')
        Begin 
            SET @closed = @curClosed
        End 
        
    End

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    If @mode = 'add'
    Begin

        INSERT INTO T_Operations_Tasks (
            Tab,
            Requester,
            Requested_Personnel,
            Assigned_Personnel,
            Description,
            Comments,
            Status,
            Priority,
            Work_Package,
            Closed,
            Hours_Spent 
        ) VALUES(
            @tab, 
            @requester, 
            @requestedPersonnel, 
            @assignedPersonnel, 
            @description, 
            @comments, 
            @status,
            @priority,
            @workPackage,
            @closed,
            @hoursSpent
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Insert operation failed', 11, 7)

        -- Return ID of newly created entry
        --
        Set @id = SCOPE_IDENTITY()

    End

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------
    --
    If @mode = 'update' 
    Begin
        Set @myError = 0
        --
        UPDATE T_Operations_Tasks
        SET Tab = @tab,
            Requester = @requester,
            Requested_Personnel = @requestedPersonnel,
            Assigned_Personnel = @assignedPersonnel,
            Description = @description,
            Comments = @comments,
            Status = @status,
            Priority = @priority,
            Work_Package = @workPackage,
            Closed = @closed,
            Hours_Spent = @hoursSpent
        WHERE ID = @id
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Update operation failed: "%s"', 11, 4, @id)

    End

    ---------------------------------------------------
    ---------------------------------------------------
    End TRY
    Begin CATCH 
        EXEC FormatErrorMessage @message output, @myError output
        
        -- rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;
            
        Exec PostLogEntry 'Error', @message, 'AddUpdateOperationsTasks'
    End CATCH
    
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateOperationsTasks] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateOperationsTasks] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateOperationsTasks] TO [DMS2_SP_User] AS [dbo]
GO
