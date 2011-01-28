/****** Object:  StoredProcedure [dbo].[UpdateCachedStatistics] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.UpdateCachedStatistics
/****************************************************
**
**	Desc:	Updates various cached statistics
**			- Job_Usage_Count in T_Param_Files
**			- Job_Usage_Count in T_Settings_Files
**			- Job_Count in T_Analysis_Job_Request
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	11/04/2008 mem - Initial version (Ticket: #698)
**			12/21/2009 mem - Added parameter @UpdateJobRequestStatistics
**    
*****************************************************/
(
	@message varchar(512) = '' output,
	@PreviewSql tinyint = 0,
	@UpdateParamSettingsFileCounts tinyint = 1,
	@UpdateGeneralStatistics tinyint = 1,
	@UpdateJobRequestStatistics tinyint = 1
)
As
	Set nocount on
	
	Declare @myRowCount int
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	Declare @UniqueID int
	Declare @Category varchar(128)
	Declare @Label varchar(128)
	Declare @UseDecimal tinyint

	Declare @Sql nvarchar(2048)
	Declare @SqlParams nvarchar(128)
	Declare @SqlParamsDec nvarchar(128)
	
	Declare @Total int
	Declare @TotalDec decimal(18, 3)
	Declare @Value varchar(128)
	
	Declare @Continue int
	
	------------------------------------------------
	-- Validate the inputs
	------------------------------------------------
	Set @message = ''
	Set @PreviewSql = IsNull(@PreviewSql, 0)
	Set @UpdateParamSettingsFileCounts = IsNull(@UpdateParamSettingsFileCounts, 1)
	Set @UpdateGeneralStatistics = IsNull(@UpdateGeneralStatistics, 0)
	Set @UpdateJobRequestStatistics = IsNull(@UpdateJobRequestStatistics, 1)

	If @UpdateParamSettingsFileCounts <> 0
	Begin -- <a1>
		------------------------------------------------
		-- Update Usage Counts for Parameter Files
		------------------------------------------------
		--
		UPDATE T_Param_Files
		SET Job_Usage_Count = IsNull(StatsQ.JobCount, 0)
		FROM T_Param_Files PF
			LEFT OUTER JOIN ( SELECT AJ_parmFileName AS Param_File_Name,
									COUNT(*) AS JobCount
							FROM dbo.T_Analysis_Job
							GROUP BY AJ_parmFileName ) StatsQ
			ON PF.Param_File_Name = StatsQ.Param_File_Name
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		

		------------------------------------------------
		-- Update Usage Counts for Settings Files
		------------------------------------------------
		--
		UPDATE T_Settings_Files
		SET Job_Usage_Count = IsNull(StatsQ.JobCount, 0)
		FROM T_Settings_Files SF
			LEFT OUTER JOIN ( SELECT AJ_settingsFileName AS Settings_File_Name,
									COUNT(*) AS JobCount
							FROM dbo.T_Analysis_Job
							GROUP BY AJ_settingsFileName ) StatsQ
			ON SF.File_Name = StatsQ.Settings_File_Name
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
	End -- </a1>
	
	If @UpdateGeneralStatistics <> 0
	Begin -- <a2>
		------------------------------------------------
		-- Make sure T_General_Statistics contains the required categories and labels
		------------------------------------------------

		CREATE TABLE #TmpStatEntries (
			Category varchar(128) NOT NULL,
			Label varchar(128) NOT NULL,
			Sql varchar(1024) NOT NULL,
			UseDecimal tinyint NOT NULL Default 0,
			UniqueID int IDENTITY(1,1)
		)
		
		INSERT INTO #TmpStatEntries VALUES ('Job_Count', 'All',          'SELECT @Total = COUNT(*) FROM T_Analysis_Job', 0)
		INSERT INTO #TmpStatEntries VALUES ('Job_Count', 'Last 7 days',  'SELECT @Total = COUNT(*) FROM T_Analysis_Job WHERE AJ_created > DATEADD(day, -7, GetDate())', 0)
		INSERT INTO #TmpStatEntries VALUES ('Job_Count', 'Last 30 days', 'SELECT @Total = COUNT(*) FROM T_Analysis_Job WHERE AJ_created > DATEADD(DAY, -30, GetDate())', 0)
		INSERT INTO #TmpStatEntries VALUES ('Job_Count', 'New',          'SELECT @Total = COUNT(*) FROM T_Analysis_Job WHERE AJ_StateID = 1', 0)

		INSERT INTO #TmpStatEntries VALUES ('Campaign_Count', 'All',          'SELECT @Total = COUNT(*) FROM T_Campaign', 0)
		INSERT INTO #TmpStatEntries VALUES ('Campaign_Count', 'Last 7 days',  'SELECT @Total = COUNT(*) FROM T_Campaign WHERE CM_created > DATEADD(day, -7, GetDate())', 0)
		INSERT INTO #TmpStatEntries VALUES ('Campaign_Count', 'Last 30 days', 'SELECT @Total = COUNT(*) FROM T_Campaign WHERE CM_created > DATEADD(day, -30, GetDate())', 0)

		INSERT INTO #TmpStatEntries VALUES ('CellCulture_Count', 'All',          'SELECT @Total = COUNT(*) FROM T_Cell_Culture', 0)
		INSERT INTO #TmpStatEntries VALUES ('CellCulture_Count', 'Last 7 days',  'SELECT @Total = COUNT(*) FROM T_Cell_Culture WHERE CC_Created > DATEADD(day, -7, GetDate())', 0)
		INSERT INTO #TmpStatEntries VALUES ('CellCulture_Count', 'Last 30 days', 'SELECT @Total = COUNT(*) FROM T_Cell_Culture WHERE CC_Created > DATEADD(day, -30, GetDate())', 0)

		INSERT INTO #TmpStatEntries VALUES ('Dataset_Count', 'All',          'SELECT @Total = COUNT(*) FROM T_Dataset', 0)
		INSERT INTO #TmpStatEntries VALUES ('Dataset_Count', 'Last 7 days',  'SELECT @Total = COUNT(*) FROM T_Dataset WHERE DS_created > DATEADD(day, -7, GetDate())', 0)
		INSERT INTO #TmpStatEntries VALUES ('Dataset_Count', 'Last 30 days', 'SELECT @Total = COUNT(*) FROM T_Dataset WHERE DS_created > DATEADD(day, -30, GetDate())', 0)

		INSERT INTO #TmpStatEntries VALUES ('Experiment_Count', 'All',          'SELECT @Total = COUNT(*) FROM T_Experiments', 0)
		INSERT INTO #TmpStatEntries VALUES ('Experiment_Count', 'Last 7 days',  'SELECT @Total = COUNT(*) FROM T_Experiments WHERE EX_created > DATEADD(day, -7, GetDate())', 0)
		INSERT INTO #TmpStatEntries VALUES ('Experiment_Count', 'Last 30 days', 'SELECT @Total = COUNT(*) FROM T_Experiments WHERE EX_created > DATEADD(day, -30, GetDate())', 0)

		INSERT INTO #TmpStatEntries VALUES ('Organism_Count', 'All',          'SELECT @Total = COUNT(*) FROM T_Organisms', 0)
		INSERT INTO #TmpStatEntries VALUES ('Organism_Count', 'Last 7 days',  'SELECT @Total = COUNT(*) FROM T_Organisms WHERE OG_Created > DATEADD(day, -7, GetDate())', 0)
		INSERT INTO #TmpStatEntries VALUES ('Organism_Count', 'Last 30 days', 'SELECT @Total = COUNT(*) FROM T_Organisms WHERE OG_Created > DATEADD(day, -30, GetDate())', 0)

		INSERT INTO #TmpStatEntries VALUES ('RawDataTB', 'All',          'SELECT @TotalDec = Round(SUM(IsNull(File_Size_Bytes,0)) / 1024.0 / 1024.0 / 1024.0 / 1024.0, 2) FROM T_Dataset', 1)
		INSERT INTO #TmpStatEntries VALUES ('RawDataTB', 'Last 7 days',  'SELECT @TotalDec = Round(SUM(IsNull(File_Size_Bytes,0)) / 1024.0 / 1024.0 / 1024.0 / 1024.0, 2) FROM T_Dataset WHERE DS_Created > DATEADD(day, -7, GetDate())', 1)
		INSERT INTO #TmpStatEntries VALUES ('RawDataTB', 'Last 30 days', 'SELECT @TotalDec = Round(SUM(IsNull(File_Size_Bytes,0)) / 1024.0 / 1024.0 / 1024.0 / 1024.0, 2) FROM T_Dataset WHERE DS_Created > DATEADD(day, -30, GetDate())', 1)

		-- Initialize @SqlParams
		Set @SqlParams = '@Total int output'
		Set @SqlParamsDec = '@TotalDec decimal(18, 3) output'
		
		------------------------------------------------
		-- Use the queries in #TmpStatEntries to update T_General_Statistics
		------------------------------------------------
		
		Set @UniqueID = 0
		
		Set @Continue = 1
		While @Continue = 1
		Begin -- <b>
			SELECT TOP 1 @Category = Category,
			             @Label = Label,
			             @Sql = Sql,
			             @UseDecimal = UseDecimal,
			             @UniqueID = UniqueID
			FROM #TmpStatEntries
			WHERE UniqueID > @UniqueID
			ORDER BY UniqueID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			If @myRowCount = 0
				Set @Continue = 0
			Else -- <c>
			Begin
				If @PreviewSql <> 0
					Print @Sql
				Else
				Begin -- <d>
				
					------------------------------------------------
					-- Run the query in @Sql; store the value for @Total in T_General_Statistics
					------------------------------------------------

					If @UseDecimal = 0
					Begin			
						Set @Total = 0
						exec sp_executesql @Sql, @SqlParams, @Total = @Total Output
						Set @Value = Convert(varchar(12), IsNull(@Total, 0))
					End
					Else
					Begin
						Set @TotalDec = 0
						exec sp_executesql @Sql, @SqlParamsDec, @TotalDec = @TotalDec Output
						Set @Value = Convert(varchar(12), IsNull(@TotalDec, 0))
					End
					
					IF Exists ( SELECT * FROM T_General_Statistics WHERE Category = @Category AND Label = @Label )
						UPDATE T_General_Statistics
						SET Value = @Value, Last_Affected = GetDate()
						WHERE Category = @Category AND Label = @Label
					ELSE
						INSERT INTO T_General_Statistics( Category, Label, Value, Last_Affected)
						VALUES(@Category, @Label, @Value, GetDate())
				End -- </d>
								
			End -- </c>
		End -- </b>
		 
	End -- </a2>

	If @UpdateJobRequestStatistics <> 0
	Begin -- <a3>
		UPDATE T_Analysis_Job_Request
		SET AJR_jobCount = StatQ.JobCount
		FROM T_Analysis_Job_Request AJR
		     INNER JOIN ( SELECT AJR.AJR_requestID,
		                         SUM(CASE WHEN AJ.AJ_jobID IS NULL 
		                                  THEN 0
		                                  ELSE 1
		                             END) AS JobCount
		                  FROM T_Analysis_Job_Request AJR
		                       INNER JOIN T_Users U
		                         ON AJR.AJR_requestor = U.ID
		                       INNER JOIN T_Analysis_Job_Request_State AJRS
		                         ON AJR.AJR_state = AJRS.ID
		                       INNER JOIN T_Organisms Org
		                         ON AJR.AJR_organism_ID = Org.Organism_ID
		                       LEFT OUTER JOIN T_Analysis_Job AJ
		                         ON AJR.AJR_requestID = AJ.AJ_requestID
		                  GROUP BY AJR.AJR_requestID ) StatQ
		       ON AJR.AJR_requestID = StatQ.AJR_requestID AND
		          ISNULL(AJR.AJR_jobCount, - 1) <> StatQ.JobCount
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		          
	End -- </a3>



Done:
	return @myError


GO
GRANT EXECUTE ON [dbo].[UpdateCachedStatistics] TO [D3L243] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateCachedStatistics] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateCachedStatistics] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateCachedStatistics] TO [PNL\D3M580] AS [dbo]
GO
