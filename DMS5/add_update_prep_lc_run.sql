/****** Object:  StoredProcedure [dbo].[add_update_prep_lc_run] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_prep_lc_run]
/****************************************************
**
**  Desc:
**      Adds new or edits existing item in T_Prep_LC_Run
**
**  Auth:   grk
**  Date:   08/04/2009
**          04/24/2010 grk - replaced @project with @samplePrepRequest
**          04/26/2010 grk - @samplePrepRequest can be multiple
**          05/06/2010 grk - added storage path
**          08/25/2011 grk - added QC field
**          09/30/2011 grk - added datasets field
**          02/23/2016 mem - Add set XACT_ABORT on
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          05/27/2022 mem - Update @samplePrepRequest to replace semicolons with commas, then assure that the list only contains integers
**          06/06/2022 mem - Only validate @id if updating an existing item
**          11/18/2022 mem - Rename parameter to @prepRunName
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/08/2023 mem - Rename parameter to @samplePrepRequests
**                         - Use new column name Sample_Prep_Requests in T_Prep_LC_Run
**                         - Update work package(s) in column Sample_Prep_Work_Packages
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
    @id int output,
    @prepRunName varchar(128),
    @instrument varchar(128),
    @type varchar(64),
    @lcColumn varchar(128),
    @lcColumn2 varchar(128),
    @comment varchar(1024),
    @guardColumn varchar(12),
    @operatorUsername varchar(50),
    @digestionMethod varchar(128),
    @sampleType varchar(64),
    @samplePrepRequests varchar(1024),    -- Typically a single sample prep request ID, but can also be a comma separated list (or blank)
    @numberOfRuns varchar(12),
    @instrumentPressure varchar(32),
    @qualityControl varchar(2048),
    @datasets varchar(MAX),
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @itemCount Int
    Declare @existingId int = 0

    Declare @invalidIDs varchar(1024)
    
    set @message = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_prep_lc_run', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @id = IsNull(@ID, 0)
    Set @samplePrepRequests = Ltrim(Rtrim(IsNull(@samplePrepRequests, '')))

    If @mode = 'update' And @id <= 0
    Begin
        RAISERROR ('Prep LC run ID must be a positive integer', 11, 7)
    End

    -- Assure that @samplePrepRequests is a comma separated list of integers (or an empty string)
    If @samplePrepRequests Like '%;%'
    Begin
        Set @samplePrepRequests = Replace(@samplePrepRequests, ';', ',')
    End

    CREATE TABLE #Tmp_SamplePrepRequests (
        Prep_Request_ID Int Not Null
    )

    If Len(@samplePrepRequests) > 0
    Begin
        SELECT @itemCount = Count(Distinct Item)
        FROM dbo.make_table_from_list ( @samplePrepRequests )

        INSERT INTO #Tmp_SamplePrepRequests (Prep_Request_ID)
        SELECT Distinct Value
        FROM dbo.parse_delimited_integer_list ( @samplePrepRequests, ',' )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @itemCount = 0 Or @itemCount <> @myRowCount
        Begin
            Set @message = 'The sample prep request list should be one or more sample prep request IDs (integers), separated by commas'
            RAISERROR (@message, 11, 7)
        End

        Set @invalidIDs = Null

        SELECT @invalidIDs = Coalesce(@invalidIDs + ', ' + Cast(Prep_Request_ID AS varchar(12)), 
                                      Cast(Prep_Request_ID AS varchar(12)))
        FROM #Tmp_SamplePrepRequests NewIDs
             LEFT OUTER JOIN T_Sample_Prep_Request SPR
               ON NewIDs.Prep_Request_ID = SPR.ID
        WHERE SPR.ID IS NULL

        If Coalesce(@invalidIDs, '') <> ''
        Begin
            Set @message = 'Invalid sample prep request ID(s): ' + @invalidIDs
            RAISERROR (@message, 11, 7)
        End
    End

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    If @mode = 'update'
    Begin
        SELECT @existingId = ID
        FROM  T_Prep_LC_Run
        WHERE ID = @id
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0 OR @existingId = 0
            RAISERROR ('No entry could be found in database for update', 11, 7)
    End

    ---------------------------------------------------
    -- Resolve dataset list
    ---------------------------------------------------

    CREATE TABLE #DSL (
      Dataset VARCHAR(128) ,
      Dataset_ID INT NULL
    )

    INSERT INTO #DSL( Dataset )
    SELECT Item AS Dataset
    FROM dbo.make_table_from_list ( @datasets )

    UPDATE #DSL
    SET Dataset_ID = dbo.T_Dataset.Dataset_ID
    FROM #DSL
         INNER JOIN dbo.T_Dataset
           ON #DSL.Dataset = dbo.T_Dataset.Dataset_Num

    Declare @transName varchar(32) = 'add_update_prep_lc_run'

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    If @mode = 'add'
    Begin
        Begin transaction @transName

        INSERT INTO T_Prep_LC_Run (
            Prep_Run_Name,
            Instrument,
            Type,
            LC_Column,
            LC_Column_2,
            Comment,
            Guard_Column,
            OperatorPRN,
            Digestion_Method,
            Sample_Type,
            Sample_Prep_Requests,
            Number_Of_Runs,
            Instrument_Pressure,
            Quality_Control
        ) VALUES (
            @prepRunName,
            @instrument,
            @type,
            @lcColumn,
            @lcColumn2,
            @comment,
            @guardColumn,
            @operatorUsername,
            @digestionMethod,
            @sampleType,
            @samplePrepRequests,
            @numberOfRuns,
            @instrumentPressure,
            @qualityControl
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Insert operation failed', 11, 8)

        -- Return ID of newly created entry
        --
        Set @id = SCOPE_IDENTITY()

        INSERT INTO dbo.T_Prep_LC_Run_Dataset
                ( Prep_LC_Run_ID, Dataset_ID )
        SELECT @id AS Prep_LC_Run_ID, Dataset_ID
        FROM #DSL

        Commit transaction @transName
    End -- add mode

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
    --
    If @mode = 'update'
    Begin
        Begin transaction @transName

        UPDATE T_Prep_LC_Run
        SET Prep_Run_Name = @prepRunName,
            Instrument = @instrument,
            Type = @type,
            LC_Column = @lcColumn,
            LC_Column_2 = @lcColumn2,
            Comment = @comment,
            Guard_Column = @guardColumn,
            OperatorPRN = @operatorUsername,
            Digestion_Method = @digestionMethod,
            Sample_Type = @sampleType,
            Sample_Prep_Requests = @samplePrepRequests,
            Number_Of_Runs = @numberOfRuns,
            Instrument_Pressure = @instrumentPressure,
            Quality_Control = @qualityControl
        WHERE ID = @id
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Update operation failed: "%s"', 11, 4, @id)

        -- add new datasets
        INSERT INTO dbo.T_Prep_LC_Run_Dataset
                ( Prep_LC_Run_ID, Dataset_ID )
        SELECT @id AS Prep_LC_Run_ID, Dataset_ID
        FROM #DSL
        WHERE NOT #DSL.Dataset_ID IN (SELECT Dataset_ID FROM T_Prep_LC_Run_Dataset WHERE Prep_LC_Run_ID = @id)

        -- Delete removed datasets
        DELETE FROM T_Prep_LC_Run_Dataset
        WHERE Prep_LC_Run_ID = @id AND
              NOT T_Prep_LC_Run_Dataset.Dataset_ID IN (SELECT Dataset_ID FROM #DSL)

        Commit transaction @transName
    End -- update mode

    -- Update the work package list
    Exec update_prep_lc_run_work_package_list @id

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;
    END Catch

    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[add_update_prep_lc_run] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_prep_lc_run] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_prep_lc_run] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_update_prep_lc_run] TO [Limited_Table_Write] AS [dbo]
GO
