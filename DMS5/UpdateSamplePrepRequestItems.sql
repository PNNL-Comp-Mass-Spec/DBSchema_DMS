/****** Object:  StoredProcedure [dbo].[UpdateSamplePrepRequestItems] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.UpdateSamplePrepRequestItems
/****************************************************
**
**	Desc:
**      Automatically associates DMS entities with 
**      specified sample prep request
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	Date:	07/05/2013 grk - initial release
**			02/23/2016 mem - Add set XACT_ABORT on
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**
*****************************************************/
(
	@samplePrepRequestID int,
	@mode varchar(12) = 'update',
	@message varchar(512) = '' output,
	@callingUser varchar(128) = ''
)
As
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

	BEGIN TRY
	
		---------------------------------------------------
		-- Verify that the user can execute this procedure from the given client host
		---------------------------------------------------
			
		Declare @authorized tinyint = 0	
		Exec @authorized = VerifySPAuthorized 'UpdateSamplePrepRequestItems', @raiseError = 1
		If @authorized = 0
		Begin
			RAISERROR ('Access denied', 11, 3)
		End
		
		---------------------------------------------------	
		-- staging table			
		---------------------------------------------------	
		CREATE TABLE #ITM (
			ID int,
			Item_ID VARCHAR(128),
			Item_Name varchar(512),
			Item_Type varchar(128),
			[Status] VARCHAR(128),
			Created DATETIME,
			Marked CHAR(1) NOT NULL
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
				TBM.CC_ID AS Item_ID,
				TL.Item AS Item_Name,
				'biomaterial' AS Item_Type,
				TBM.CC_Material_Active AS [Status],
				TBM.CC_Created AS Created
		FROM    dbo.T_Sample_Prep_Request SPR
				CROSS APPLY dbo.MakeTableFromListDelim(SPR.Cell_Culture_List, ';') TL
				INNER JOIN dbo.T_Cell_Culture TBM ON TBM.CC_Name = TL.Item
		WHERE   SPR.ID = @samplePrepRequestID
				AND SPR.Cell_Culture_List <> '(none)'
				AND SPR.Cell_Culture_List <> ''

		-- experiments
		INSERT INTO #ITM (ID, Item_ID, Item_Name, Item_Type, [Status], Created) 
		SELECT  SPR.ID ,
				TEXP.Exp_ID AS Item_ID,
				TEXP.Experiment_Num AS Item_Name,
				'experiment' AS Item_Type,
				TEXP.Ex_Material_Active AS [Status],
				TEXP.EX_created AS Created
		FROM    dbo.T_Sample_Prep_Request SPR
				INNER JOIN dbo.T_Experiments TEXP ON SPR.ID = TEXP.EX_sample_prep_request_ID
		WHERE SPR.ID = @samplePrepRequestID
		        
		-- experiment groups 
		INSERT INTO #ITM (ID, Item_ID, Item_Name, Item_Type, [Status], Created) 
		SELECT DISTINCT
				SPR.ID ,
				TEGM.Group_ID AS Item_ID ,
				TEG.EG_Description AS Item_Name ,
				'experiment_group' AS Item_Type,
				TEG.EG_Group_Type AS [Status],
				TEG.EG_Created AS Created
		FROM    dbo.T_Sample_Prep_Request SPR
				INNER JOIN dbo.T_Experiments TEXP ON SPR.ID = TEXP.EX_sample_prep_request_ID
				INNER JOIN dbo.T_Experiment_Group_Members TEGM ON TEXP.Exp_ID = TEGM.Exp_ID
				INNER JOIN dbo.T_Experiment_Groups TEG ON TEGM.Group_ID = TEG.Group_ID
		WHERE SPR.ID = @samplePrepRequestID


		-- material containers
		INSERT INTO #ITM (ID, Item_ID, Item_Name, Item_Type, [Status], Created) 
		SELECT  DISTINCT SPR.ID ,
				TMC.ID AS Item_ID ,
				TMC.Tag AS Item_Name ,
				'material_container' AS Item_Type,
				TMC.Status,
				TMC.Created
		FROM    dbo.T_Sample_Prep_Request SPR
				INNER JOIN dbo.T_Experiments TEXP ON SPR.ID = TEXP.EX_sample_prep_request_ID
				INNER JOIN dbo.T_Material_Containers TMC ON TEXP.EX_Container_ID = TMC.ID
		WHERE SPR.ID = @samplePrepRequestID AND TMC.ID > 1
		  
		 -- requested run        
		INSERT INTO #ITM (ID, Item_ID, Item_Name, Item_Type, [Status], Created) 
		SELECT  SPR.ID ,
				TRR.ID AS Item_ID ,
				TRR.RDS_Name AS Item_Name ,
				'requested_run' AS Item_Type,
				TRR.RDS_Status AS [Status],
				TRR.RDS_created AS Created
		FROM    dbo.T_Sample_Prep_Request SPR
				INNER JOIN dbo.T_Experiments TEXP ON SPR.ID = TEXP.EX_sample_prep_request_ID
				INNER JOIN dbo.T_Requested_Run TRR ON TEXP.Exp_ID = TRR.Exp_ID
		WHERE SPR.ID = @samplePrepRequestID

		-- dataset
		INSERT INTO #ITM (ID, Item_ID, Item_Name, Item_Type, [Status], Created) 
		SELECT  SPR.ID ,
				TDS.Dataset_ID AS Item_ID ,
				TDS.Dataset_Num AS Item_Name ,
				'dataset' AS Item_Type,
				TDSN.DSS_name AS [Status],
				TDS.DS_created AS Created
		FROM    dbo.T_Sample_Prep_Request SPR
				INNER JOIN dbo.T_Experiments TEXP ON SPR.ID = TEXP.EX_sample_prep_request_ID
				INNER JOIN dbo.T_Dataset TDS ON TEXP.Exp_ID = TDS.Exp_ID
				INNER JOIN T_DatasetStateName TDSN ON TDS.DS_state_ID = TDSN.Dataset_state_ID
		WHERE SPR.ID = @samplePrepRequestID

		-- HPLC Runs - Reference to sample prep request IDs in comma delimited list in text field
		INSERT INTO #ITM (ID, Item_ID, Item_Name, Item_Type, [Status], Created) 
		SELECT  @samplePrepRequestID AS ID ,
				Item_ID ,
				Item_Name,
				'prep_lc_run' AS Item_Type,
				'' AS [Status],
				Created
		FROM    ( SELECT    TPLCR.ID AS Item_ID ,
							TPLCR.Comment as Item_Name,
							CONVERT(INT, TL.Item) AS SPR_ID,
							TPLCR.Created
				  FROM      T_Prep_LC_Run TPLCR
							CROSS APPLY dbo.MakeTableFromList(TPLCR.SamplePrepRequest) TL
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
			INNER JOIN dbo.T_Sample_Prep_Request_Items TI ON TI.ID = #ITM.ID
			AND TI.Item_ID = #ITM.Item_ID
			AND TI.Item_Type = #ITM.Item_Type

		---------------------------------------------------
		-- mark items for delete that are already in database
		-- but are not in staging table
		---------------------------------------------------

		INSERT INTO #ITM (ID, Item_ID, Item_Type, Marked) 
		SELECT  TI.ID ,
				TI.Item_ID ,
				TI.Item_Type ,
				'D' AS Marked
		FROM    dbo.T_Sample_Prep_Request_Items TI
		WHERE   ID = @samplePrepRequestID
				AND NOT EXISTS ( SELECT *
								 FROM   #ITM
								 WHERE  TI.ID = #ITM.ID
										AND TI.Item_ID = #ITM.Item_ID
										AND TI.Item_Type = #ITM.Item_Type )

		---------------------------------------------------
		-- update database
		---------------------------------------------------
		if @mode = 'update'
		BEGIN --<update>

			DECLARE @transName VARCHAR(32)
			SET @transName = 'AddBatchExperimentEntry'
			BEGIN  TRANSACTION @transName

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
			-- update marked items
			---------------------------------------------------

			UPDATE T_Sample_Prep_Request_Items
			SET T_Sample_Prep_Request_Items.[Status] = '' ,
				T_Sample_Prep_Request_Items.Created = ''
			FROM T_Sample_Prep_Request_Items AS TI
				INNER JOIN #ITM ON TI.ID = #ITM.ID
				AND TI.Item_ID = #ITM.Item_ID
				AND TI.Item_Type = #ITM.Item_Type
			WHERE   Marked = 'Y'

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
			
			EXEC UpdateSamplePrepRequestItemCount @samplePrepRequestID

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
		EXEC FormatErrorMessage @message output, @myError output
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
			
		Exec PostLogEntry 'Error', @message, 'UpdateSamplePrepRequestItems'
	END CATCH
	
 	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateSamplePrepRequestItems] TO [DDL_Viewer] AS [dbo]
GO
