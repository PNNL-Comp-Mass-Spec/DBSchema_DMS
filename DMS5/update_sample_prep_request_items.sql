/****** Object:  StoredProcedure [dbo].[update_sample_prep_request_items] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_sample_prep_request_items]
/****************************************************
**
**  Desc:
**      Automatically associates DMS entities with
**      specified sample prep request
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   07/05/2013 grk - initial release
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          07/08/2022 mem - Change Item_ID from text to integer
**                         - No longer clear the Created column for existing items
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/02/2023 mem - Use renamed table names
**
*****************************************************/
(
    @samplePrepRequestID int,
    @mode varchar(12) = 'update',           -- 'update' or 'debug'
    @message varchar(512) = '' output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    set @message = ''

    declare @wasModified tinyint
    set @wasModified = 0

    ---------------------------------------------------
    -- Test mode for debugging
    ---------------------------------------------------
    if @mode = 'test'
    begin
        set @message = 'Test Mode'
        return 1
    end

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_sample_prep_request_items', @raiseError = 1
    If @authorized = 0
    Begin;
        Throw 51000, 'Access denied', 1;
    End;

    BEGIN TRY

        ---------------------------------------------------
        -- staging table
        ---------------------------------------------------
        CREATE TABLE #ITM (
            ID int,
            Item_ID int,
            Item_Name varchar(512),
            Item_Type varchar(128),
            [Status] varchar(128),
            Created datetime,
            Marked char(1) NOT NULL
        )
        -- all items are marked as not in database by default
        ALTER TABLE #ITM ADD CONSTRAINT [DF_ITM]  DEFAULT ('N') FOR Marked

        ---------------------------------------------------
        -- get items associated with sample prep request
        -- into staging table
        ---------------------------------------------------
        -- biomaterial
        INSERT INTO #ITM (ID, Item_ID, Item_Name, Item_Type, [Status], Created)
        SELECT  SPR.ID ,
                B.CC_ID AS Item_ID,
                TL.Item AS Item_Name,
                'biomaterial' AS Item_Type,
                B.CC_Material_Active AS [Status],
                B.CC_Created AS Created
        FROM    dbo.T_Sample_Prep_Request SPR
                CROSS APPLY dbo.make_table_from_list_delim(SPR.Cell_Culture_List, ';') TL
                INNER JOIN dbo.T_Cell_Culture B ON B.CC_Name = TL.Item
        WHERE   SPR.ID = @samplePrepRequestID
                AND SPR.Cell_Culture_List <> '(none)'
                AND SPR.Cell_Culture_List <> ''

        -- experiments
        INSERT INTO #ITM (ID, Item_ID, Item_Name, Item_Type, [Status], Created)
        SELECT  SPR.ID ,
                E.Exp_ID AS Item_ID,
                E.Experiment_Num AS Item_Name,
                'experiment' AS Item_Type,
                E.Ex_Material_Active AS [Status],
                E.EX_created AS Created
        FROM    dbo.T_Sample_Prep_Request SPR
                INNER JOIN dbo.T_Experiments E ON SPR.ID = E.EX_sample_prep_request_ID
        WHERE SPR.ID = @samplePrepRequestID

        -- experiment groups
        INSERT INTO #ITM (ID, Item_ID, Item_Name, Item_Type, [Status], Created)
        SELECT DISTINCT
                SPR.ID ,
                GM.Group_ID AS Item_ID ,
                G.EG_Description AS Item_Name ,
                'experiment_group' AS Item_Type,
                G.EG_Group_Type AS [Status],
                G.EG_Created AS Created
        FROM    dbo.T_Sample_Prep_Request SPR
                INNER JOIN dbo.T_Experiments E ON SPR.ID = E.EX_sample_prep_request_ID
                INNER JOIN dbo.T_Experiment_Group_Members GM ON E.Exp_ID = GM.Exp_ID
                INNER JOIN dbo.T_Experiment_Groups G ON GM.Group_ID = G.Group_ID
        WHERE SPR.ID = @samplePrepRequestID


        -- material containers
        INSERT INTO #ITM (ID, Item_ID, Item_Name, Item_Type, [Status], Created)
        SELECT  DISTINCT SPR.ID ,
                MC.ID AS Item_ID ,
                MC.Tag AS Item_Name ,
                'material_container' AS Item_Type,
                MC.Status,
                MC.Created
        FROM    dbo.T_Sample_Prep_Request SPR
                INNER JOIN dbo.T_Experiments E ON SPR.ID = E.EX_sample_prep_request_ID
                INNER JOIN dbo.T_Material_Containers MC ON E.EX_Container_ID = MC.ID
        WHERE SPR.ID = @samplePrepRequestID AND MC.ID > 1

         -- requested run
        INSERT INTO #ITM (ID, Item_ID, Item_Name, Item_Type, [Status], Created)
        SELECT  SPR.ID ,
                RR.ID AS Item_ID ,
                RR.RDS_Name AS Item_Name ,
                'requested_run' AS Item_Type,
                RR.RDS_Status AS [Status],
                RR.RDS_created AS Created
        FROM    dbo.T_Sample_Prep_Request SPR
                INNER JOIN dbo.T_Experiments E ON SPR.ID = E.EX_sample_prep_request_ID
                INNER JOIN dbo.T_Requested_Run RR ON E.Exp_ID = RR.Exp_ID
        WHERE SPR.ID = @samplePrepRequestID

        -- dataset
        INSERT INTO #ITM (ID, Item_ID, Item_Name, Item_Type, [Status], Created)
        SELECT  SPR.ID ,
                DS.Dataset_ID AS Item_ID ,
                DS.Dataset_Num AS Item_Name ,
                'dataset' AS Item_Type,
                DSN.DSS_name AS [Status],
                DS.DS_created AS Created
        FROM    dbo.T_Sample_Prep_Request SPR
                INNER JOIN dbo.T_Experiments E ON SPR.ID = E.EX_sample_prep_request_ID
                INNER JOIN dbo.T_Dataset DS ON E.Exp_ID = DS.Exp_ID
                INNER JOIN T_Dataset_State_Name DSN ON DS.DS_state_ID = DSN.Dataset_state_ID
        WHERE SPR.ID = @samplePrepRequestID

        -- HPLC Runs - Reference to sample prep request IDs in comma delimited list in text field
        INSERT INTO #ITM (ID, Item_ID, Item_Name, Item_Type, [Status], Created)
        SELECT  @samplePrepRequestID AS ID ,
                Item_ID ,
                Item_Name,
                'prep_lc_run' AS Item_Type,
                '' AS [Status],
                Created
        FROM    ( SELECT    LCRun.ID AS Item_ID ,
                            LCRun.Comment as Item_Name,
                            CONVERT(INT, TL.Item) AS SPR_ID,
                            LCRun.Created
                  FROM      T_Prep_LC_Run LCRun
                            CROSS APPLY dbo.make_table_from_list(LCRun.SamplePrepRequest) TL
                  WHERE     SamplePrepRequest LIKE '%' + CONVERT(VARCHAR(12), @samplePrepRequestID)
                            + '%'
                ) TX
        WHERE   TX.SPR_ID = @samplePrepRequestID

        ---------------------------------------------------
        -- mark items for update that are already in database
        ---------------------------------------------------

        UPDATE #ITM
        SET Marked = 'Y'
        FROM #ITM
            INNER JOIN dbo.T_Sample_Prep_Request_Items I ON I.ID = #ITM.ID
            AND I.Item_ID = #ITM.Item_ID
            AND I.Item_Type = #ITM.Item_Type

        ---------------------------------------------------
        -- mark items for delete that are already in database
        -- but are not in staging table
        ---------------------------------------------------

        INSERT INTO #ITM (ID, Item_ID, Item_Type, Marked)
        SELECT  I.ID ,
                I.Item_ID ,
                I.Item_Type ,
                'D' AS Marked
        FROM    dbo.T_Sample_Prep_Request_Items I
        WHERE   ID = @samplePrepRequestID
                AND NOT EXISTS ( SELECT *
                                 FROM   #ITM
                                 WHERE  I.ID = #ITM.ID
                                        AND I.Item_ID = #ITM.Item_ID
                                        AND I.Item_Type = #ITM.Item_Type )

        ---------------------------------------------------
        -- update database
        ---------------------------------------------------
        if @mode = 'update'
        BEGIN --<update>

            DECLARE @transName VARCHAR(64) = 'update_sample_prep_request_items'

            BEGIN TRANSACTION @transName

            ---------------------------------------------------
            -- insert unmarked items into database
            ---------------------------------------------------

            INSERT INTO dbo.T_Sample_Prep_Request_Items (
                ID ,
                Item_ID ,
                Item_Name ,
                Item_Type ,
                Status ,
                Created
            )
            SELECT
                ID ,
                Item_ID ,
                Item_Name ,
                Item_Type ,
                Status ,
                Created
            FROM    #ITM
            WHERE   Marked = 'N'

            ---------------------------------------------------
            -- Clear the status of marked items
            ---------------------------------------------------

            UPDATE T_Sample_Prep_Request_Items
            SET [Status] = ''
            FROM T_Sample_Prep_Request_Items AS I
                INNER JOIN #ITM ON I.ID = #ITM.ID
                AND I.Item_ID = #ITM.Item_ID
                AND I.Item_Type = #ITM.Item_Type
            WHERE #ITM.Marked = 'Y' And Len(Coalesce(I.[Status], '')) > 0

            ---------------------------------------------------
            -- Update the Created date for marked items (if not correct)
            ---------------------------------------------------

            UPDATE T_Sample_Prep_Request_Items
            SET Created = #ITM.Created
            FROM T_Sample_Prep_Request_Items AS I
                INNER JOIN #ITM ON I.ID = #ITM.ID
                AND I.Item_ID = #ITM.Item_ID
                AND I.Item_Type = #ITM.Item_Type
            WHERE #ITM.Marked = 'Y' And (
                  I.Created Is Null And Not #ITM.Created Is Null Or
                  I.Created <> #ITM.Created)

            ---------------------------------------------------
            -- delete marked items from database
            ---------------------------------------------------

            DELETE FROM dbo.T_Sample_Prep_Request_Items
            WHERE EXISTS (
            SELECT  *
            FROM    #ITM
            WHERE   T_Sample_Prep_Request_Items.ID = #ITM.ID
                    AND T_Sample_Prep_Request_Items.Item_ID = #ITM.Item_ID
                    AND T_Sample_Prep_Request_Items.Item_Type = #ITM.Item_Type
                    AND #ITM.Marked = 'D'
            )

            ---------------------------------------------------
            -- update item counts
            ---------------------------------------------------

            EXEC update_sample_prep_request_item_count @samplePrepRequestID

            COMMIT TRANSACTION @transName

        END --<update>

        ---------------------------------------------------
        --
        ---------------------------------------------------
        if @mode = 'debug'
        BEGIN
            SELECT * FROM #ITM
            ORDER BY Marked

            RETURN 0
        END

    ---------------------------------------------------
    ---------------------------------------------------

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output
        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @message, 'update_sample_prep_request_items'
    END CATCH

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_sample_prep_request_items] TO [DDL_Viewer] AS [dbo]
GO
