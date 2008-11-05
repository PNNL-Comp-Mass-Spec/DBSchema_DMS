/****** Object:  StoredProcedure [dbo].[AddMissingFilterCriteria] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.AddMissingFilterCriteria
/****************************************************
**
**	Desc: 
**		Examines @FilterSetID and makes sure all of its groups contain all of the criteria
**
**
**	Auth:	mem
**	Date:	02/01/2006
**			10/30/2008 mem - Added MQScore, TotalPRMScore, and FScore
**    
*****************************************************/
(
	@FilterSetID int,
	@ProcessGroupsWithNoCurrentCriteriaDefined tinyint = 0,
	@message varchar(255)='' OUTPUT
)
AS
	Set NoCount On

	declare @myRowCount int	
	declare @myError int
	set @myRowCount = 0
	set @myError = 0

	Set @message = ''
	
	Declare @GroupID int
	Declare @CriterionID int
	
	Declare @GroupsProcessed int
	Declare @CriteriaAdded int
	Declare @CriteriaAdditionErrors int
	
	Declare @Continue tinyint
	Declare @InnerContinue tinyint
	
	Declare @CriterionComparison char(2)
	Declare @CriterionValue float
	
	Set @GroupsProcessed = 0
	Set @CriteriaAdded = 0
	Set @CriteriaAdditionErrors = 0
	
	Set @GroupID = -1000000
	Set @Continue = 1
	While @Continue = 1
	Begin -- <a>
		-- Lookup the first @GroupID for @FilterSetID
		If @ProcessGroupsWithNoCurrentCriteriaDefined <> 0
			SELECT TOP 1 @GroupID = Filter_Criteria_Group_ID
			FROM T_Filter_Set_Criteria_Groups
			WHERE (Filter_Set_ID = @FilterSetID) AND Filter_Criteria_Group_ID > @GroupID
			GROUP BY Filter_Criteria_Group_ID
			ORDER BY Filter_Criteria_Group_ID
		Else
			SELECT TOP 1 @GroupID = FSCG.Filter_Criteria_Group_ID
			FROM T_Filter_Set_Criteria_Groups FSCG INNER JOIN
			    T_Filter_Set_Criteria FSC ON 
			    FSCG.Filter_Criteria_Group_ID = FSC.Filter_Criteria_Group_ID
			WHERE (FSCG.Filter_Set_ID = @FilterSetID) AND 
				  FSC.Filter_Criteria_Group_ID > @GroupID
			GROUP BY FSCG.Filter_Criteria_Group_ID
			ORDER BY FSCG.Filter_Criteria_Group_ID
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error
	
		If @myRowCount = 0
			Set @Continue = 0
		Else
		Begin -- <b>

			-- Make sure an entry is present for each Criterion_ID defined in T_Filter_Set_Criteria_Names
			Set @CriterionID = -1000000
			Set @InnerContinue = 1
			While @InnerContinue = 1
			Begin -- <c>
				SELECT TOP 1 @CriterionID = Criterion_ID
				FROM T_Filter_Set_Criteria_Names
				WHERE Criterion_ID > @CriterionID
				ORDER BY Criterion_ID
				--
				SELECT @myRowCount = @@rowcount, @myError = @@error

				If @myRowCount = 0
					Set @InnerContinue = 0
				Else
				Begin -- <d>
					Set @myRowCount = 0
					SELECT @myRowCount = COUNT(*)
					FROM T_Filter_Set_Criteria FSC INNER JOIN
						 T_Filter_Set_Criteria_Groups FSCG ON 
						 FSC.Filter_Criteria_Group_ID = FSCG.Filter_Criteria_Group_ID
					WHERE (FSCG.Filter_Set_ID = @FilterSetID) AND 
						  FSC.Filter_Criteria_Group_ID = @GroupID AND 
						  FSC.Criterion_ID = @CriterionID
					
					If @myRowCount = 0
					Begin
						-- Define the default comparison operator and criterion value
						Set @CriterionComparison = '>='
						Set @CriterionValue = 0
						
						-- Update the values for some of the criteria						
						If @CriterionID = 1
						Begin
							-- Spectrum Count
							Set @CriterionComparison = '>='
							Set @CriterionValue = 1
						End
						
						If @CriterionID = 7
						Begin
							-- DelCn
							Set @CriterionComparison = '<='	
							Set @CriterionValue = 1
						End
						
						If @CriterionID = 14
						Begin
							-- XTandem Hyperscore
							Set @CriterionComparison = '>='	
							Set @CriterionValue = 1
						End

						If @CriterionID = 15
						Begin
							-- XTandem Log_EValue
							Set @CriterionComparison = '<='	
							Set @CriterionValue = 0
						End

						If @CriterionID = 18
						Begin
							-- Inspect MQScore
							Set @CriterionComparison = '>='	
							Set @CriterionValue = -10000
						End

						If @CriterionID = 19
						Begin
							-- Inspect TotalPRMScore
							Set @CriterionComparison = '>='	
							Set @CriterionValue = -10000
						End

						If @CriterionID = 20
						Begin
							-- Inspect FScore
							Set @CriterionComparison = '>='	
							Set @CriterionValue = -10000
						End

												
						INSERT INTO T_Filter_Set_Criteria
							(Filter_Criteria_Group_ID, Criterion_ID, Criterion_Comparison, Criterion_Value)
						VALUES (@GroupID, @CriterionID, @CriterionComparison, @CriterionValue)
						--
						SELECT @myRowCount = @@rowcount, @myError = @@error
						
						If @myRowCount = 1
							Set @CriteriaAdded = @CriteriaAdded + 1
						Else
							Set @CriteriaAdditionErrors = @CriteriaAdditionErrors + 1
					End
				End -- </d>
			End -- </c>
	
			Set @GroupsProcessed = @GroupsProcessed + 1
		End -- </b>
	End -- </a>

	-- Abort if @myRowCount = 0
	If @GroupsProcessed = 0
	Begin
		Set @message = 'No groups found for Filter Set ID ' + Convert(varchar(11), @FilterSetID)
	End
	Else
	Begin
		Set @message = 'Finished processing Filter Set ID ' + Convert(varchar(11), @FilterSetID) + '; Processed ' + Convert(varchar(11), @GroupsProcessed) + ' groups and added ' + Convert(varchar(11), @CriteriaAdded) + ' criteria'
		If @CriteriaAdditionErrors > 0
			Set @message = @message + '; Error occurred for the addition of ' + Convert(varchar(11), @CriteriaAdditionErrors) + ' criteria'		
	End
	
Done:
	Select @message as Message
	--
	Return @myError

GO
GRANT EXECUTE ON [dbo].[AddMissingFilterCriteria] TO [DMS_ParamFile_Admin]
GO
