/****** Object:  StoredProcedure [dbo].[DuplicateFilterSetCriteria] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.DuplicateFilterSetCriteria
/****************************************************
**
**	Desc: 
**		Copies the filter set critera
**
**		Requires that the new filter set exist in T_Filter_Sets
**		However, do not make any entries in T_Filter_Set_Criteria_Groups or T_Filter_Set_Criteria
**
**		The following query is useful for editing filter sets:
**
			SELECT FS.Filter_Set_ID, FS.Filter_Set_Name, 
				FS.Filter_Set_Description, FSC.Filter_Criteria_Group_ID, 
				FSC.Filter_Set_Criteria_ID, FSC.Criterion_ID, 
				FSCN.Criterion_Name, FSC.Criterion_Comparison, 
				FSC.Criterion_Value
			FROM dbo.T_Filter_Sets FS INNER JOIN
				dbo.T_Filter_Set_Criteria_Groups FSCG ON 
				FS.Filter_Set_ID = FSCG.Filter_Set_ID INNER JOIN
				dbo.T_Filter_Set_Criteria FSC ON 
				FSCG.Filter_Criteria_Group_ID = FSC.Filter_Criteria_Group_ID INNER
				JOIN
				dbo.T_Filter_Set_Criteria_Names FSCN ON 
				FSC.Criterion_ID = FSCN.Criterion_ID
			WHERE (FS.Filter_Set_ID = 184)
			ORDER BY FSCN.Criterion_Name, FSC.Filter_Criteria_Group_ID
**
**
**	Auth:	mem
**	Date:	10/02/2009
**    
*****************************************************/
(
	@SourceFilterSetID int,
	@DestFilterSetID int,
	@AddMissingFilterCriteria tinyint = 1,
	@InfoOnly tinyint = 0,
	@message varchar(512)='' OUTPUT
)
AS
	Set NoCount On

	Declare @myRowCount int	
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	Declare @UniqueIDCurrent int
	Declare @GroupIDOld int
	Declare @Continue tinyint

	Declare @GroupCount int
	Declare @FilterCriteriaGroupIDNext int
						 
	-----------------------------------------
	-- Validate the input parameters
	-----------------------------------------
	
	Set @AddMissingFilterCriteria = IsNull(@AddMissingFilterCriteria, 1)
	Set @InfoOnly = IsNull(@InfoOnly, 0)
	Set @message = ''
	
	If @SourceFilterSetID Is Null Or @DestFilterSetID Is Null
	Begin
		Set @message = 'Both the source and target filter set ID must be defined; unable to continue'
		Set @myError = 53000
		Goto Done
	End

	-----------------------------------------
	-- Validate that @DestFilterSetID is defined in T_Filter_Sets
	-----------------------------------------
	--
	Set @myRowCount = 0
	Select @myRowCount = Count(*)
	FROM T_Filter_Sets
	WHERE (Filter_Set_ID = @DestFilterSetID)

	If @myRowCount = 0
	Begin
		Set @message = 'Filter Set ID ' + Convert(varchar(11), @DestFilterSetID) + ' was not found in T_Filter_Sets; make an entry in that table for this filter set before calling this procedure'
		Goto Done
	End

	-----------------------------------------
	-- Validate that no groups exist for @DestFilterSetID
	-----------------------------------------
	--
	Set @GroupCount = -1
	Select @GroupCount = Count(*)
	FROM T_Filter_Set_Criteria_Groups
	WHERE (Filter_Set_ID = @DestFilterSetID)

	If @GroupCount > 0
	Begin
		Set @message = 'Existing groups were found for Filter Set ID ' + Convert(varchar(11), @DestFilterSetID) + '; this is not allowed'
		Goto Done
	End

	--	if exists (select * from dbo.sysobjects where id = object_id(N'dbo.[#T_Tmp_FilterSetGroups]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
	--	drop table dbo.[#T_Tmp_FilterSetGroups]

	-- Populate a temporary table with the list of groups for @SourceFilterSetID
	CREATE TABLE #T_Tmp_FilterSetGroups (
		UniqueRowID int Identity(1,1) NOT NULL,
		Group_ID_Old int NULL
	)

	-----------------------------------------
	-- Populate #T_Tmp_FilterSetGroups with the groups defined for @SourceFilterSetID
	-----------------------------------------
	--
	INSERT INTO #T_Tmp_FilterSetGroups (Group_ID_Old)
	SELECT Filter_Criteria_Group_ID
	FROM T_Filter_Set_Criteria_Groups
	WHERE (Filter_Set_ID = @SourceFilterSetID)
	ORDER BY Filter_Criteria_Group_ID
	--
	SELECT @myRowCount = @@rowcount, @myError = @@error

	Set @GroupCount = @myRowCount

	-- Abort if number of groups is 0
	If @GroupCount <= 0
	Begin
		Set @message = 'No groups found for Filter Set ID ' + Convert(varchar(11), @SourceFilterSetID)
		Goto Done
	End

	If @InfoOnly <> 0
	Begin
		SELECT FSC.Filter_Criteria_Group_ID,
		       FSC.Criterion_ID,
		       FSCN.Criterion_Name,
		       FSC.Criterion_Comparison,
		       FSC.Criterion_Value
		FROM dbo.T_Filter_Set_Criteria FSC
		     INNER JOIN #T_Tmp_FilterSetGroups FSG
		       ON FSC.Filter_Criteria_Group_ID = FSG.Group_ID_Old
		     INNER JOIN T_Filter_Set_Criteria_Names FSCN
		       ON FSC.Criterion_ID = FSCN.Criterion_ID
		ORDER BY FSG.Group_ID_Old, Criterion_ID
		
		Goto Done
	End
	
		
	-----------------------------------------
	-- For each group in #T_Tmp_FilterSetGroups, make a new group in T_Filter_Set_Criteria_Groups
	--  and duplicate the entries in T_Filter_Set_Criteria
	-----------------------------------------
	
	Set @UniqueIDCurrent = -1
	Set @Continue = 1
	While @Continue = 1
	Begin -- <a>
		SELECT Top 1 @UniqueIDCurrent = UniqueRowID,
					@GroupIDOld = Group_ID_Old
		FROM #T_Tmp_FilterSetGroups
		WHERE UniqueRowID > @UniqueIDCurrent
		ORDER BY UniqueRowID
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error

		If @myRowCount < 1
			Set @Continue = 0
		Else
		Begin -- <b>
			-- Define the next Filter_Criteria_Group_ID to insert into T_Filter_Set_Criteria_Groups
			SELECT @FilterCriteriaGroupIDNext = MAX(Filter_Criteria_Group_ID) + 1
			FROM T_Filter_Set_Criteria_Groups

			INSERT INTO T_Filter_Set_Criteria_Groups (Filter_Set_ID, Filter_Criteria_Group_ID)
			VALUES (@DestFilterSetID, @FilterCriteriaGroupIDNext)
			--
			SELECT @myRowCount = @@rowcount, @myError = @@error

			If @myError <> 0
			Begin
				Set @message = 'Error inserting new filter criteria group ID values into T_Filter_Set_Criteria_Groups'
				Goto Done
			End

			-- Duplicate the criteria for group @GroupIDOld (from Filter Set @SourceFilterSetID)
			--
			INSERT INTO dbo.T_Filter_Set_Criteria
				(Filter_Criteria_Group_ID, Criterion_ID, Criterion_Comparison, Criterion_Value)
			SELECT @FilterCriteriaGroupIDNext AS NewGroupID, Criterion_ID, Criterion_Comparison, Criterion_Value
			FROM dbo.T_Filter_Set_Criteria
			WHERE Filter_Criteria_Group_ID = @GroupIDOld
			ORDER BY Criterion_ID
			--
			SELECT @myRowCount = @@rowcount, @myError = @@error


		End -- </b>
	End -- </a>

	drop table dbo.[#T_Tmp_FilterSetGroups]

		
	If @AddMissingFilterCriteria <> 0
	Begin
		-----------------------------------------
		-- Call AddMissingFilterCriteria to add any missing criteria
		-----------------------------------------
		--
		Exec AddMissingFilterCriteria @DestFilterSetID
	End

	Set @message = 'Duplicated criteria from Filter Set ID ' + Convert(varchar(11), @SourceFilterSetID) + ' to Filter Set ID ' + Convert(varchar(11), @DestFilterSetID)
	
Done:
	If Len(@message) > 0
		SELECT @message As Message
	
	--
	Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[DuplicateFilterSetCriteria] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DuplicateFilterSetCriteria] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DuplicateFilterSetCriteria] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DuplicateFilterSetCriteria] TO [PNL\D3M580] AS [dbo]
GO
