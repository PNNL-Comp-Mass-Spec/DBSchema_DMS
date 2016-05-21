/****** Object:  StoredProcedure [dbo].[UpdateDataPackageItemsUtility] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateDataPackageItemsUtility
/****************************************************
**
**	Desc:
**      Updates data package items in list according to command mode
**
**	Expects list of items to be in temp table #TPI
**
**		CREATE TABLE #TPI(
**				Package varchar(50) null,
**				Type varchar(50) null,
**				Identifier varchar(256) null
**			)
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	Date:	05/23/2010
**          06/10/2009 grk - changed size of item list to max
**          06/10/2009 mem - Now calling UpdateDataPackageItemCounts to update the data package item counts
**          10/01/2009 mem - Now populating Campaign in T_Data_Package_Biomaterial
**          12/31/2009 mem - Added DISTINCT keyword to the INSERT INTO queries in case the source views include some duplicate rows (in particular, S_V_Experiment_Detail_Report_Ex)
**          05/23/2010 grk - create this sproc from common function factored out of UpdateDataPackageItems and UpdateDataPackageItemsXML
**			12/31/2013 mem - Added support for EUS Proposals
**			09/02/2014 mem - Updated to remove non-numeric items when working with analysis jobs
**			10/28/2014 mem - Added support for adding datasets using dataset IDs; to delete datasets, you must use the dataset name (safety feature)
**			02/23/2016 mem - Add set XACT_ABORT on
**			04/06/2016 mem - Now using Try_Convert to convert from text to int
**			05/18/2016 mem - Fix bug removing duplicate analysis jobs
**						   - Add parameter @infoOnly
**
*****************************************************/
(
	@comment varchar(512),
	@mode varchar(12) = 'update',	-- 'add', 'comment', 'delete'
	@message varchar(512) = '' output,
	@callingUser varchar(128) = '',
	@infoOnly tinyint = 0
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @message = ''
	
	declare @itemCountChanged int
	set @itemCountChanged = 0

	CREATE TABLE #Tmp_DatasetIDsToAdd (
	    Package   varchar(50) NOT NULL,
	    DatasetID int NOT NULL
	)

 	---------------------------------------------------
 	---------------------------------------------------
	BEGIN TRY 

		-- If working with analysis jobs, remove any entries from #TPI that are not numeric
		If Exists ( SELECT * FROM #TPI WHERE TYPE = 'Job' )
		Begin
		    DELETE #TPI
		    WHERE IsNull(Identifier, '') = '' OR Try_Convert(int, Identifier) Is Null
		    
		    Set @myRowCount= @@RowCount
		    
		    If @infoOnly > 0 And @myRowCount > 0
		    Begin
				Print 'Warning: deleted ' + Cast(@myRowCount as varchar(12)) + ' job(s) that were not numeric'
		    End
		End
		

		-- Add parent items and associated items to list for items in the list
		-- This process cascades up the DMS hierarchy of tracking entities, but not down
		--
		IF @mode = 'add'
		BEGIN -- <add_associated_items>
			 
			-- Auto-convert dataset IDs to dataset names
			-- First look for dataset IDs
			INSERT INTO #Tmp_DatasetIDsToAdd( Package, DatasetID )
			SELECT Package,
			       DatasetID
			FROM ( SELECT Package,
			              Try_Convert(int, Identifier) as DatasetID
			       FROM #TPI
			       WHERE [Type] = 'Dataset' AND			             
			             Not Package Is Null) SourceQ
			WHERE Not DatasetID Is Null
			
			If Exists (select * from #Tmp_DatasetIDsToAdd)
			Begin
				-- Add the dataset names
				INSERT INTO #TPI( Package,
				                  [Type],
				                  Identifier )
				SELECT Source.Package,
				       'Dataset' AS [Type],
				       DL.Dataset
				FROM #Tmp_DatasetIDsToAdd Source
				     INNER JOIN S_V_Dataset_List_Report_2 DL
				       ON Source.DatasetID = DL.ID

			End
			 
			-- add datasets to list that are parents of jobs in list
			-- (and are not already in list)
 			INSERT INTO #TPI (Package, Type, Identifier)
			SELECT DISTINCT
				TP.Package, 
				'Dataset', 
				TX.Dataset
			FROM   
				#TPI TP
				INNER JOIN S_V_Analysis_Job_List_Report_2 TX
				ON TP.Identifier = TX.Job 
			WHERE
				TP.Type = 'Job' 
				AND NOT EXISTS (
					SELECT * 
					FROM #TPI 
					WHERE #TPI.Type = 'Dataset' AND #TPI.Identifier = TX.Dataset AND #TPI.Package = TP.Package
				)

			-- add experiments to list that are parents of datasets in list
			-- (and are not already in list)
 			INSERT INTO #TPI (Package, Type, Identifier)
			SELECT DISTINCT
				TP.Package, 
				'Experiment',
				TX.Experiment
			FROM
				#TPI TP
				INNER JOIN S_V_Dataset_List_Report_2 TX
				ON TP.Identifier = TX.Dataset 
			WHERE
				TP.Type = 'Dataset' 
				AND NOT EXISTS (
					SELECT * 
					FROM #TPI 
					WHERE #TPI.Type = 'Experiment' AND #TPI.Identifier = TX.Experiment AND #TPI.Package = TP.Package
				)

			-- add EUS Proposals to list that are parents of datasets in list
			-- (and are not already in list)
 			INSERT INTO #TPI (Package, Type, Identifier)
			SELECT DISTINCT
				TP.Package, 
				'EUSProposal',
				TX.[EMSL Proposal]
			FROM
				#TPI TP
				INNER JOIN S_V_Dataset_List_Report_2 TX
				ON TP.Identifier = TX.Dataset 
			WHERE
				TP.Type = 'Dataset' 
				AND NOT EXISTS (
					SELECT * 
					FROM #TPI 
					WHERE #TPI.Type = 'EUSProposal' AND #TPI.Identifier = TX.[EMSL Proposal] AND #TPI.Package = TP.Package
				)


			-- add biomaterial items to list that are associated with experiments in list
			-- (and are not already in list)
 			INSERT INTO #TPI (Package, Type, Identifier)
			SELECT DISTINCT
				TP.Package, 
				'Biomaterial',
				TX.Cell_Culture_Name
			FROM
				#TPI TP
				INNER JOIN S_V_Experiment_Cell_Culture TX
				ON TP.Identifier = TX.Experiment_Num 
			WHERE
				TP.Type = 'Experiment' 
				AND NOT EXISTS (
					SELECT * 
					FROM #TPI 
					WHERE #TPI.Type = 'Biomaterial' AND #TPI.Identifier = TX.Cell_Culture_Name AND #TPI.Package = TP.Package
				)
		END -- </add_associated_items>


		---------------------------------------------------
		-- Possibly preview the items
		---------------------------------------------------
		
		If @infoOnly <> 0
		Begin
			SELECT * 
			FROM #TPI
			ORDER BY Package, Type, Identifier
		End

		---------------------------------------------------
		-- biomaterial operations
		---------------------------------------------------
		
		IF @mode = 'delete'
		BEGIN --<delete biomaterial>
			If @infoOnly > 0
			Begin
				SELECT 'Biomaterial to delete' As Item_Type, *
				FROM T_Data_Package_Biomaterial 
				WHERE EXISTS (
					SELECT * 
					FROM #TPI
					WHERE 
					#TPI.Package = T_Data_Package_Biomaterial.Data_Package_ID AND
					#TPI.Identifier = T_Data_Package_Biomaterial.Name AND
					#TPI.Type = 'Biomaterial'
				)
			End
			Else
			Begin
				DELETE 
				FROM  T_Data_Package_Biomaterial 
				WHERE EXISTS (
					SELECT * 
					FROM #TPI
					WHERE 
					#TPI.Package = T_Data_Package_Biomaterial.Data_Package_ID AND
					#TPI.Identifier = T_Data_Package_Biomaterial.Name AND
					#TPI.Type = 'Biomaterial'
				)
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				set @itemCountChanged = @itemCountChanged + @myRowCount
			End
		END --<delete biomaterial>

		IF @mode = 'comment'
		BEGIN --<comment biomaterial>
			If @infoOnly > 0
			Begin
				SELECT 'Update Biomaterial comment' as Item_Type,
						@comment As New_Comment, *
				FROM  T_Data_Package_Biomaterial 
				WHERE EXISTS (
					SELECT * 
					FROM #TPI
					WHERE 
					#TPI.Package = T_Data_Package_Biomaterial.Data_Package_ID AND
					#TPI.Identifier = T_Data_Package_Biomaterial.Name AND
					#TPI.Type = 'Biomaterial'
				)
			End
			Else
			Begin
				UPDATE T_Data_Package_Biomaterial
				SET [Package Comment] = @comment
				WHERE EXISTS (
					SELECT * 
					FROM #TPI
					WHERE 
					#TPI.Package = T_Data_Package_Biomaterial.Data_Package_ID AND
					#TPI.Identifier = T_Data_Package_Biomaterial.Name AND
					#TPI.Type = 'Biomaterial'
				)
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				set @itemCountChanged = @itemCountChanged + @myRowCount
			End
		END --<comment biomaterial>
		
 		IF @mode = 'add'
		BEGIN --<add biomaterial>

			-- Delete extras
			DELETE FROM #TPI
			WHERE EXISTS (
				SELECT * 
				FROM T_Data_Package_Biomaterial TX
				WHERE #TPI.Package = TX.Data_Package_ID AND 
				      #TPI.Identifier = TX.Name AND #TPI.Type = 'Biomaterial'
			)

			If @infoOnly > 0
			Begin
				SELECT DISTINCT 
					#TPI.Package,
					'New Biomaterial' as Item_Type,
					TX.ID,
					@comment AS Comment,
					TX.Name,
					TX.Campaign,
					TX.Created,
					TX.Type
				FROM   
					#TPI
					INNER JOIN S_V_Cell_Culture_List_Report_2 TX
					ON #TPI.Identifier = Name
				WHERE #TPI.Type = 'Biomaterial'
			End
			Else
			Begin
				
				-- add new items
				INSERT INTO T_Data_Package_Biomaterial(
					Data_Package_ID,
					Biomaterial_ID,
					[Package Comment],
					Name,
					Campaign,
					Created,
					Type
				)
				SELECT DISTINCT
					#TPI.Package,
					TX.ID,
					@comment,
					TX.Name,
					TX.Campaign,
					TX.Created,
					TX.Type
				FROM   
					#TPI
					INNER JOIN S_V_Cell_Culture_List_Report_2 TX
					ON #TPI.Identifier = Name
				WHERE #TPI.Type = 'Biomaterial'
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				set @itemCountChanged = @itemCountChanged + @myRowCount
			End
		END --<add biomaterial>


		---------------------------------------------------
		-- EUS Proposal operations
		---------------------------------------------------

		IF @mode = 'delete'
		BEGIN --<delete EUS Proposals>
			If @infoOnly > 0
			Begin
				SELECT 'EUS Proposal to delete' As Item_Type, *
				FROM T_Data_Package_EUS_Proposals
				WHERE EXISTS (
					SELECT * 
					FROM #TPI
					WHERE 
					#TPI.Package = T_Data_Package_EUS_Proposals.Data_Package_ID AND
					#TPI.Identifier = T_Data_Package_EUS_Proposals.Proposal_ID AND
					#TPI.Type = 'EUSProposal'
				)
			End
			Else
			Begin
				DELETE FROM  T_Data_Package_EUS_Proposals
				WHERE EXISTS (
					SELECT * 
					FROM #TPI
					WHERE 
					#TPI.Package = T_Data_Package_EUS_Proposals.Data_Package_ID AND
					#TPI.Identifier = T_Data_Package_EUS_Proposals.Proposal_ID AND
					#TPI.Type = 'EUSProposal'
				)
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				set @itemCountChanged = @itemCountChanged + @myRowCount
			End
		END --<delete EUS Proposal>

		IF @mode = 'comment'
		BEGIN --<comment EUS Proposals>
			If @infoOnly > 0
			Begin
				SELECT 'Update EUS Proposal comment' as Item_Type,
						@comment As New_Comment, *
				FROM  T_Data_Package_EUS_Proposal 
				WHERE EXISTS (
					SELECT * 
					FROM #TPI
					WHERE 
					#TPI.Package = T_Data_Package_EUS_Proposals.Data_Package_ID AND
					#TPI.Identifier = T_Data_Package_EUS_Proposals.Proposal_ID AND
					#TPI.Type = 'EUSProposal'
				)
			End
			Else
			Begin
				UPDATE T_Data_Package_EUS_Proposals
				SET [Package Comment] = @comment
				WHERE EXISTS (
					SELECT * 
					FROM #TPI
					WHERE 
					#TPI.Package = T_Data_Package_EUS_Proposals.Data_Package_ID AND
					#TPI.Identifier = T_Data_Package_EUS_Proposals.Proposal_ID AND
					#TPI.Type = 'EUSProposal'
				)
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				set @itemCountChanged = @itemCountChanged + @myRowCount
			End
		END --<comment EUS Proposals>
		
		IF @mode = 'add'
		BEGIN --<add EUS Proposals>
		
			-- Delete extras 
			DELETE FROM #TPI
			WHERE EXISTS (
				SELECT * 
				FROM T_Data_Package_EUS_Proposals TX
				WHERE #TPI.Package = TX.Data_Package_ID AND 
				      #TPI.Identifier = TX.Proposal_ID AND #TPI.Type = 'EUSProposal'
			)
			
			If @infoOnly > 0
			Begin
				SELECT DISTINCT
					#TPI.Package,
					'New EUS Proposal' as Item_Type,
					TX.ID,
					@comment AS Comment
				FROM   
					#TPI
					INNER JOIN S_V_EUS_Proposals_List_Report TX
					ON #TPI.Identifier = TX.ID
				WHERE #TPI.Type = 'EUSProposal'
			End
			Else
			Begin
				-- add new items
				INSERT INTO T_Data_Package_EUS_Proposals(
					Data_Package_ID,
					Proposal_ID,
					[Package Comment]
				)
				SELECT DISTINCT
					#TPI.Package,
					TX.ID,
					@comment
				FROM   
					#TPI
					INNER JOIN S_V_EUS_Proposals_List_Report TX
					ON #TPI.Identifier = TX.ID
				WHERE #TPI.Type = 'EUSProposal'
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				set @itemCountChanged = @itemCountChanged + @myRowCount
			End
		END --<add EUS Proposals>
		
		
		---------------------------------------------------
		-- experiment operations
		---------------------------------------------------

		IF @mode = 'delete'
		BEGIN --<delete experiments>
			If @infoOnly > 0
			Begin
				SELECT 'Experiment to delete' As Item_Type, *
				FROM T_Data_Package_Experiments
				WHERE EXISTS (
					SELECT * 
					FROM #TPI
					WHERE 
					#TPI.Package = T_Data_Package_Experiments.Data_Package_ID AND
					#TPI.Identifier = T_Data_Package_Experiments.Experiment AND
					#TPI.Type = 'Experiment'
				)
			End
			Else
			Begin
				DELETE FROM  T_Data_Package_Experiments
				WHERE EXISTS (
					SELECT * 
					FROM #TPI
					WHERE 
					#TPI.Package = T_Data_Package_Experiments.Data_Package_ID AND
					#TPI.Identifier = T_Data_Package_Experiments.Experiment AND
					#TPI.Type = 'Experiment'
				)
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				set @itemCountChanged = @itemCountChanged + @myRowCount
			End
		END --<delete experiments>

		IF @mode = 'comment'
		BEGIN --<comment experiments>
			If @infoOnly > 0
			Begin
				SELECT 'Update Experiment comment' as Item_Type,
						@comment As New_Comment, *
				FROM  T_Data_Package_Experiments 
				WHERE EXISTS (
					SELECT * 
					FROM #TPI
					WHERE 
					#TPI.Package = T_Data_Package_Experiments.Data_Package_ID AND
					#TPI.Identifier = T_Data_Package_Experiments.Experiment AND
					#TPI.Type = 'Experiment'
				)
			End
			Else
			Begin
				UPDATE T_Data_Package_Experiments
				SET [Package Comment] = @comment
				WHERE EXISTS (
					SELECT * 
					FROM #TPI
					WHERE 
					#TPI.Package = T_Data_Package_Experiments.Data_Package_ID AND
					#TPI.Identifier = T_Data_Package_Experiments.Experiment AND
					#TPI.Type = 'Experiment'
				)
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				set @itemCountChanged = @itemCountChanged + @myRowCount
			End
		END --<comment experiments>
		
		IF @mode = 'add'
		BEGIN --<add experiments>
		
			-- Delete extras
			DELETE FROM #TPI
			WHERE EXISTS (
				SELECT * 
				FROM T_Data_Package_Experiments TX
				WHERE #TPI.Package = TX.Data_Package_ID AND 
				      #TPI.Identifier = TX.Experiment AND #TPI.Type = 'Experiment'
			)
			
			If @infoOnly > 0
			Begin
				SELECT DISTINCT
					#TPI.Package,
					'New Experiment ID' as Item_Type,
					TX.ID,
					@comment AS Comment,
					TX.Experiment,
					TX.Created
				FROM   
					#TPI
					INNER JOIN S_V_Experiment_Detail_Report_Ex TX
					ON #TPI.Identifier = TX.Experiment
				WHERE #TPI.Type = 'Experiment'
			End
			Else
			Begin
				-- add new items
				INSERT INTO T_Data_Package_Experiments(
					Data_Package_ID,
					Experiment_ID,
					[Package Comment],
					Experiment,
					Created
				)
				SELECT DISTINCT
					#TPI.Package,
					TX.ID,
					@comment,
					TX.Experiment,
					TX.Created
				FROM   
					#TPI
					INNER JOIN S_V_Experiment_Detail_Report_Ex TX
					ON #TPI.Identifier = TX.Experiment
				WHERE #TPI.Type = 'Experiment'
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				set @itemCountChanged = @itemCountChanged + @myRowCount
			End
		END --<add experiments>
		
		---------------------------------------------------
		-- dataset operations
		---------------------------------------------------

		IF @mode = 'delete'
		BEGIN --<delete datasets>
			If @infoOnly > 0
			Begin
				SELECT 'Dataset to delete' As Item_Type, *
				FROM T_Data_Package_Datasets
				WHERE EXISTS (
					SELECT * 
					FROM #TPI
					WHERE 
					#TPI.Package = T_Data_Package_Datasets.Data_Package_ID AND
					#TPI.Identifier = T_Data_Package_Datasets.Dataset AND
					#TPI.Type = 'Dataset'
				)
			End
			Else
			Begin			
				DELETE FROM  T_Data_Package_Datasets
				WHERE EXISTS (
					SELECT * 
					FROM #TPI
					WHERE 
					#TPI.Package = T_Data_Package_Datasets.Data_Package_ID AND
					#TPI.Identifier = T_Data_Package_Datasets.Dataset AND
					#TPI.Type = 'Dataset'
				)
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				set @itemCountChanged = @itemCountChanged + @myRowCount
			End
		END --<delete datasets>

		IF @mode = 'comment'
		BEGIN --<comment datasets>
			If @infoOnly > 0
			Begin
				SELECT 'Update Dataset comment' as Item_Type,
						@comment As New_Comment, *
				FROM  T_Data_Package_Datasets 
				WHERE EXISTS (
					SELECT * 
					FROM #TPI
					WHERE 
					#TPI.Package = T_Data_Package_Datasets.Data_Package_ID AND
					#TPI.Identifier = T_Data_Package_Datasets.Dataset AND
					#TPI.Type = 'Dataset'
				)
			End
			Else
			Begin
				UPDATE T_Data_Package_Datasets
				SET [Package Comment] = @comment
				WHERE EXISTS (
					SELECT * 
					FROM #TPI
					WHERE 
					#TPI.Package = T_Data_Package_Datasets.Data_Package_ID AND
					#TPI.Identifier = T_Data_Package_Datasets.Dataset AND
					#TPI.Type = 'Dataset'
				)
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				set @itemCountChanged = @itemCountChanged + @myRowCount
			End
		END --<comment datasets>

		IF @mode = 'add'
		BEGIN --<add datasets>
		
			-- Delete extras
			DELETE FROM #TPI
			WHERE EXISTS (
				SELECT * 
				FROM T_Data_Package_Datasets TX
				WHERE #TPI.Package = TX.Data_Package_ID AND 
				      #TPI.Identifier = TX.Dataset AND #TPI.Type = 'Dataset'
			)

			If @infoOnly > 0
			Begin
				SELECT DISTINCT
					#TPI.Package,
					'New Dataset ID' as Item_Type,
					TX.ID,
					@comment AS Comment,
					TX.Dataset,
					TX.Created,
					TX.Experiment,
					TX.Instrument
				FROM   
					#TPI
					INNER JOIN S_V_Dataset_List_Report_2 TX
					ON #TPI.Identifier = TX.Dataset
				WHERE #TPI.Type = 'Dataset'
			End
			Else
			Begin
				-- add new items
				INSERT INTO T_Data_Package_Datasets(
					Data_Package_ID,
					Dataset_ID,
					[Package Comment],
					Dataset,
					Created,
					Experiment,
					Instrument
				)
				SELECT DISTINCT
					#TPI.Package,
					TX.ID,
					@comment,
					TX.Dataset,
					TX.Created,
					TX.Experiment,
					TX.Instrument
				FROM   
					#TPI
					INNER JOIN S_V_Dataset_List_Report_2 TX
					ON #TPI.Identifier = TX.Dataset
				WHERE #TPI.Type = 'Dataset'
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				set @itemCountChanged = @itemCountChanged + @myRowCount
			End
		END --<add datasets>

		---------------------------------------------------
		-- analysis_job operations
		---------------------------------------------------

		IF @mode = 'delete'
		BEGIN --<delete analysis_jobs>
			If @infoOnly > 0
			Begin
				SELECT 'Job to delete' As Item_Type, *
				FROM T_Data_Package_Analysis_Jobs DPAJ
					INNER JOIN ( SELECT Package,
										Try_Convert(int, Identifier) as Job
								FROM #TPI
								WHERE #TPI.TYPE = 'Job') ItemsQ
					ON DPAJ.Data_Package_ID = ItemsQ.Package AND
						DPAJ.Job = ItemsQ.Job
			End
			Else
			Begin			
				DELETE DPAJ
				FROM T_Data_Package_Analysis_Jobs DPAJ
					INNER JOIN ( SELECT Package,
										Try_Convert(int, Identifier) as Job
								FROM #TPI
								WHERE #TPI.TYPE = 'Job') ItemsQ
					ON DPAJ.Data_Package_ID = ItemsQ.Package AND
						DPAJ.Job = ItemsQ.Job
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				set @itemCountChanged = @itemCountChanged + @myRowCount
			End
		END --<delete analysis_jobs>

		IF @mode = 'comment'
		BEGIN --<comment analysis_jobs>
			If @infoOnly > 0
			Begin
				SELECT 'Update Job comment' as Item_Type,
						@comment As New_Comment, *
				FROM T_Data_Package_Analysis_Jobs DPAJ
					INNER JOIN ( SELECT Package,
										Try_Convert(int, Identifier) as Job
								FROM #TPI
								WHERE #TPI.TYPE = 'Job') ItemsQ
					ON DPAJ.Data_Package_ID = ItemsQ.Package AND
						DPAJ.Job = ItemsQ.Job
			End
			Else
			Begin
				UPDATE DPAJ
				SET [Package Comment] = @comment
				FROM T_Data_Package_Analysis_Jobs DPAJ
					INNER JOIN ( SELECT Package,
										Try_Convert(int, Identifier) as Job
								FROM #TPI
								WHERE #TPI.TYPE = 'Job') ItemsQ
					ON DPAJ.Data_Package_ID = ItemsQ.Package AND
						DPAJ.Job = ItemsQ.Job
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				set @itemCountChanged = @itemCountChanged + @myRowCount
			End
		END --<comment analysis_jobs>

		IF @mode = 'add'
		BEGIN --<add analysis_jobs>

			-- Delete extras
			DELETE FROM #TPI
			WHERE EXISTS (
				SELECT * 
				FROM T_Data_Package_Analysis_Jobs TX
				WHERE #TPI.Package = TX.Data_Package_ID AND 
				      #TPI.Identifier = TX.Job AND #TPI.Type = 'Job'
			)

			If @infoOnly > 0
			Begin
				SELECT DISTINCT
					ItemsQ.Package,
					'New Job' as Item_Type,
					TX.Job,
					@comment AS Comment,
					TX.Created,
					TX.Dataset,
					TX.Tool
				FROM S_V_Analysis_Job_List_Report_2 TX
					INNER JOIN ( SELECT Package,
										Try_Convert(int, Identifier) as Job
								FROM #TPI
								WHERE #TPI.TYPE = 'Job') ItemsQ
					ON TX.Job = ItemsQ.Job		
			End
			Else
			Begin
				-- add new items
				INSERT INTO T_Data_Package_Analysis_Jobs(
					Data_Package_ID,
					Job,
					[Package Comment],
					Created,
					Dataset,
					Tool
				)
				SELECT DISTINCT
					ItemsQ.Package,
					TX.Job,
					@comment,
					TX.Created,
					TX.Dataset,
					TX.Tool
				FROM S_V_Analysis_Job_List_Report_2 TX
					INNER JOIN ( SELECT Package,
										Try_Convert(int, Identifier) as Job
								FROM #TPI
								WHERE #TPI.TYPE = 'Job') ItemsQ
					ON TX.Job = ItemsQ.Job		
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				set @itemCountChanged = @itemCountChanged + @myRowCount
			End
		END --<add analysis_jobs>

 		---------------------------------------------------
		-- update item counts for all data packages in list
		---------------------------------------------------

		if @itemCountChanged <> 0
		begin
			CREATE TABLE #TK (ID int)

			INSERT INTO #TK (ID) SELECT DISTINCT Package FROM #TPI

			DECLARE @indx int
			DECLARE @done tinyint
			SET @done = 0
			WHILE @done = 0
			BEGIN
				SET @indx = 0
				SELECT TOP 1 @indx = ID FROM #TK ORDER BY ID
				--
				IF @indx = 0
					SET @done = 1
				ELSE
					BEGIN
					exec UpdateDataPackageItemCounts @indx, @message output, @callingUser
					DELETE FROM #TK WHERE ID = @indx
					END
			END
		end

 		---------------------------------------------------
		-- change last modified date
		---------------------------------------------------
		if @itemCountChanged > 0
		begin
			UPDATE T_Data_Package
			SET Last_Modified = GETDATE()
			WHERE ID IN (
				SELECT DISTINCT Package FROM #TPI
			)
		end

 	---------------------------------------------------
 	---------------------------------------------------
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output

		Declare @msgForLog varchar(512) = ERROR_MESSAGE()
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
		
		Exec PostLogEntry 'Error', @msgForLog, 'UpdateDataPackageItemsUtility'		
	END CATCH
	
 	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	return @myError

GO
