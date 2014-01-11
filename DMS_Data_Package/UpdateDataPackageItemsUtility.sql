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
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**    Auth: grk
**    Date: 05/23/2010
**          06/10/2009 grk - changed size of item list to max
**          06/10/2009 mem - Now calling UpdateDataPackageItemCounts to update the data package item counts
**          10/01/2009 mem - Now populating Campaign in T_Data_Package_Biomaterial
**          12/31/2009 mem - Added DISTINCT keyword to the INSERT INTO queries in case the source views include some duplicate rows (in particular, S_V_Experiment_Detail_Report_Ex)
**          05/23/2010 grk - create this sproc from common function factored out of UpdateDataPackageItems and UpdateDataPackageItemsXML
**			12/31/2013 mem - Added support for EUS Proposals
**
*****************************************************/
(
	@comment varchar(512),
	@mode varchar(12) = 'update', -- 'add', 'comment', 'delete'
	@message varchar(512) = '' output,
	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @message = ''
	
	declare @itemCountChanged int
	set @itemCountChanged = 0

 	---------------------------------------------------
 	---------------------------------------------------
	BEGIN TRY 

		-- add parent items and associated items to list
		-- for items in the list - this process cascades
		-- up the DMS hierarchy of tracking entities, but
		-- not down
		--
		IF @mode = 'add'
		BEGIN -- <add_associated_items>
	 
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
		-- biomaterial operations
		---------------------------------------------------

		IF  @mode = 'delete'
		BEGIN --<delete biomaterial>

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
		END --<delete biomaterial>

		IF @mode = 'comment'
		BEGIN --<comment biomaterial>
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
		END --<comment biomaterial>
		
 		IF @mode = 'add'
		BEGIN --<add biomaterial>
			-- get rid of any duplicates
			DELETE FROM #TPI
			WHERE EXISTS (
				SELECT * 
				FROM T_Data_Package_Biomaterial TX
				WHERE 
				#TPI.Package = TX.Data_Package_ID AND #TPI.Identifier = TX.Name AND #TPI.Type = 'Biomaterial'
			)

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
		END --<add biomaterial>


		---------------------------------------------------
		-- EUS Proposal operations
		---------------------------------------------------

		IF @mode = 'delete'
		BEGIN --<delete EUS Proposals>
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
		END --<delete EUS Proposal>


		IF @mode = 'comment'
		BEGIN --<comment EUS Proposals>
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
		END --<comment EUS Proposals>
		
		IF @mode = 'add'
		BEGIN --<add EUS Proposals>
		
			-- get rid of any duplicates  
			DELETE FROM #TPI
			WHERE EXISTS (
				SELECT * 
				FROM T_Data_Package_EUS_Proposals TX
				WHERE 
				#TPI.Package = TX.Data_Package_ID AND #TPI.Identifier = TX.Proposal_ID AND #TPI.Type = 'EUSProposal'
			)
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
		END --<add EUS Proposals>
		
		
		---------------------------------------------------
		-- experiment operations
		---------------------------------------------------

		IF @mode = 'delete'
		BEGIN --<delete experiments>
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
		END --<delete experiments>


		IF @mode = 'comment'
		BEGIN --<comment experiments>
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
		END --<comment experiments>
		
		IF @mode = 'add'
		BEGIN --<add experiments>
		
			-- get rid of any duplicates  
			DELETE FROM #TPI
			WHERE EXISTS (
				SELECT * 
				FROM T_Data_Package_Experiments TX
				WHERE 
				#TPI.Package = TX.Data_Package_ID AND #TPI.Identifier = TX.Experiment AND #TPI.Type = 'Experiment'
			)
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
		END --<add experiments>
		
		---------------------------------------------------
		-- dataset operations
		---------------------------------------------------

		IF @mode = 'delete'
		BEGIN --<delete datasets>
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
		END --<delete datasets>

		IF @mode = 'comment'
		BEGIN --<comment datasets>
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
		END --<comment datasets>

		IF @mode = 'add'
		BEGIN --<add datasets>
			-- get rid of any duplicates
			DELETE FROM #TPI
			WHERE EXISTS (
				SELECT * 
				FROM T_Data_Package_Datasets TX
				WHERE 
				#TPI.Package = TX.Data_Package_ID AND #TPI.Identifier = TX.Dataset AND #TPI.Type = 'Dataset'
			)

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
		END --<add datasets>

		---------------------------------------------------
		-- analysis_job operations
		---------------------------------------------------

		IF @mode = 'delete'
		BEGIN --<delete analysis_jobs>

			DELETE FROM  T_Data_Package_Analysis_Jobs
			WHERE EXISTS (
				SELECT * 
				FROM #TPI
				WHERE 
				#TPI.Package = T_Data_Package_Analysis_Jobs.Data_Package_ID AND
				#TPI.Identifier = T_Data_Package_Analysis_Jobs.Job AND
				#TPI.Type = 'Job'
			)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			set @itemCountChanged = @itemCountChanged + @myRowCount
		END --<delete analysis_jobs>


		IF @mode = 'comment'
		BEGIN --<comment analysis_jobs>

			UPDATE T_Data_Package_Analysis_Jobs
			SET [Package Comment] = @comment
			WHERE EXISTS (
				SELECT * 
				FROM #TPI
				WHERE 
				#TPI.Package = T_Data_Package_Analysis_Jobs.Data_Package_ID AND
				#TPI.Identifier = T_Data_Package_Analysis_Jobs.Job AND
				#TPI.Type = 'Job'
			)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			set @itemCountChanged = @itemCountChanged + @myRowCount
		END --<comment analysis_jobs>

		IF @mode = 'add'
		BEGIN --<add analysis_jobs>

			-- get rid of any jobs already in data package
			DELETE FROM #TPI
			WHERE EXISTS (
				SELECT * 
				FROM T_Data_Package_Analysis_Jobs TX
				WHERE 
				#TPI.Package = TX.Data_Package_ID AND
				#TPI.Identifier = TX.Job AND
				#TPI.Type = 'Job'
			)

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
				#TPI.Package,
				TX.Job,
				@comment,
				TX.Created,
				TX.Dataset,
				TX.Tool
			FROM
				#TPI
				INNER JOIN S_V_Analysis_Job_List_Report_2 TX
				ON #TPI.Identifier = TX.Job
			WHERE #TPI.Type = 'Job'
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			set @itemCountChanged = @itemCountChanged + @myRowCount
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
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	
 	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	return @myError

GO
