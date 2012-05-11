/****** Object:  StoredProcedure [dbo].[AddAnnotationInfoForExperiments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.AddAnnotationInfoForExperiments
/****************************************************
**
**	Desc: 
**		Examines T_Experiment_Annotations for the given
**		list of experiments (or for all experiments matching
**		the filter criteria) and makes sure they include the
**		given annotation key names
**
**	Auth:	mem
**	Date:	05/04/2007 (Ticket:431)
**    
*****************************************************/
(
	@AnnotationKeyList varchar(2048) = 'Acceptability',
	@DefaultValue varchar(256) = '',
	@ExperimentIDList varchar(8000) = '',		-- If a list of experiment IDs is provided, then the various filter fields are ignored (@CampaignFilter, @ExpNameFilter, etc.)
	@CampaignFilter varchar(128) = '',			-- If a list of experiment IDs is not provided, then campaign _must_ be provided; this filter can optionally contain the % sign as a wildcard
	@ExpNameFilter varchar(128) = '',
	@ExpDateMinimum varchar(32) = '',
	@ExpDateMaximum varchar(32) = '',
	@InfoOnly tinyint = 0,
	@message varchar(512)='' OUTPUT
)
AS
	Set NoCount On

	Declare @myRowCount int	
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	Set @message = ''

	Declare @Sql varchar(2048)
	Declare @SqlWhere varchar(2048)
	Declare @CampaignNameOperator varchar(32)
	Declare @ExperimentNameOperator varchar(32)

	Declare @InvalidKeyList varchar(1024)
	Declare @AnnotationKeyListClean varchar(1024)
	Set @AnnotationKeyListClean = ''
	
	Declare @CurrentKey varchar(128)
	Declare @Continue int
	Declare @NewAnnotationCount int
	Set @NewAnnotationCount = 0
	
	-----------------------------------------
	-- Validate the input parameters
	-----------------------------------------
	
	Set @AnnotationKeyList = LTrim(RTrim(IsNull(@AnnotationKeyList, '')))
	Set @DefaultValue = IsNull(@DefaultValue, '')
	Set @ExperimentIDList = LTrim(RTrim(IsNull(@ExperimentIDList, '')))
	Set @CampaignFilter = LTrim(RTrim(IsNull(@CampaignFilter, '')))
	Set @ExpNameFilter = LTrim(RTrim(IsNull(@ExpNameFilter, '')))
	Set @ExpDateMinimum = IsNull(@ExpDateMinimum, '')
	Set @ExpDateMaximum = IsNull(@ExpDateMaximum, '')

	If Len(@AnnotationKeyList) = 0
	Begin
		Set @Message = 'No keys were defined in @AnnotationKeyList; unable to continue'
		Set @myError = 40000
		Goto Done
	End
	
	If Len(@ExperimentIDList) = 0
	Begin
		-- Make sure @CampaignFilter is defined
		If Len(@CampaignFilter) = 0
		Begin
			Set @Message = 'Either a list of experiments must be provided, or a campaign name must be defined in @CampaignFilter; unable to continue'
			Set @myError = 40001
			Goto Done
		End
	End
	
	-----------------------------------------
	-- Create some temporary tables
	-----------------------------------------
	
	CREATE TABLE #Tmp_Experiments (
		Exp_ID int NOT NULL
	)
	CREATE CLUSTERED INDEX #IX_Tmp_Experiments ON #Tmp_Experiments (Exp_ID)

	CREATE TABLE #Tmp_AnnotationKeys (
		Key_Name varchar(128) NOT NULL
	)
	CREATE CLUSTERED INDEX #IX_Tmp_AnnotationKeys ON #Tmp_AnnotationKeys (Key_Name)
	
	CREATE TABLE #Tmp_NewAnnotationItems (
		Exp_ID int NOT NULL,
		Key_Name varchar(128) NOT NULL,
		Value varchar(512) NOT NULL,
	)

	CREATE CLUSTERED INDEX #IX_Tmp_NewAnnotationItems ON #Tmp_NewAnnotationItems (Exp_ID, Key_Name)
	
	-----------------------------------------
	-- Populate #Tmp_Experiments
	-----------------------------------------
	If Len(@ExperimentIDList) > 0
	Begin
		INSERT INTO #Tmp_Experiments (Exp_ID)
		SELECT Convert(int, Item)
		FROM dbo.MakeTableFromList(@ExperimentIDList)
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error

		If @myRowCount = 0
		Begin
			Set @message = 'Unable to parse the list of experiment IDs provided in @ExperimentIDList'
			Set @myError = 40002
			Goto Done			
		End
		
		-- Delete any items in #Tmp_Experiments that are not in T_Experiments
		DELETE #Tmp_Experiments
		FROM #Tmp_Experiments LEFT OUTER JOIN 
			 T_Experiments ON #Tmp_Experiments.Exp_ID = T_Experiments.Exp_ID
		WHERE T_Experiments.Exp_ID IS NULL
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error
		
		If @myRowCount <> 0
		Begin
			Set @message = 'Warning: Found ' + Convert(varchar(19), @myRowCount) + ' experiments in @ExperimentIDList that are not present in T_Experiments'
			SELECT @message as Warning_Message
		End
	End
	Else
	Begin
		If CharIndex('%', @CampaignFilter) > 0
			Set @CampaignNameOperator = 'LIKE'
		Else
			Set @CampaignNameOperator = '='

		If CharIndex('%', @ExpNameFilter) > 0
			Set @ExperimentNameOperator = 'LIKE'
		Else
			Set @ExperimentNameOperator = '='
			
		Set @Sql = ''
		Set @Sql = @Sql + ' INSERT INTO #Tmp_Experiments (Exp_ID)'
		Set @Sql = @Sql + ' SELECT E.Exp_ID'
		Set @Sql = @Sql + ' FROM T_Experiments E INNER JOIN'
		Set @Sql = @Sql +      ' T_Campaign C ON E.EX_campaign_ID = C.Campaign_ID'
		
		Set @SqlWhere = 'C.Campaign_Num ' + @CampaignNameOperator + ' ''' + @CampaignFilter + ''''
		
		If Len(@ExpNameFilter) > 0
			Set @SqlWhere = @SqlWhere +  ' AND E.Experiment_Num ' + @ExperimentNameOperator + ' ''' + @ExpNameFilter + ''''
			
		If Len(@ExpDateMinimum) > 0
			Set @SqlWhere = @SqlWhere +  ' AND E.EX_Created >= ''' + @ExpDateMinimum + ''''
		
		If Len(@ExpDateMaximum) > 0
			Set @SqlWhere = @SqlWhere +  ' AND E.EX_Created < ''' + @ExpDateMaximum + ''''

		Set @Sql = @Sql + ' WHERE ' + @SqlWhere
		
		Exec (@Sql)		    
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error
	
		If @myRowCount = 0
		Begin
			Set @message = 'Did not match any experiments using the filters provided: ' + @SqlWhere
			Set @myError = 40003
			Goto Done
		End
	End

	-----------------------------------------
	-- Populate #Tmp_AnnotationKeys
	-----------------------------------------

	INSERT INTO #Tmp_AnnotationKeys (Key_Name)
	SELECT DISTINCT Item
	FROM (	SELECT LTrim(RTrim(Item)) AS Item
			FROM dbo.MakeTableFromList(@AnnotationKeyList)
		 ) KeyListQ
	ORDER BY Item
	--
	SELECT @myRowCount = @@rowcount, @myError = @@error

	If @myRowCount = 0
	Begin
		Set @message = 'Unable to parse the list of annotation key names provided in @AnnotationKeyList'
		Set @myError = 40004
		Goto Done			
	End

	-- Make sure there are no blank keys in #Tmp_AnnotationKeys
	DELETE FROM #Tmp_AnnotationKeys
	WHERE Len(Key_Name) = 0
	
	-----------------------------------------
	-- Look for invalid keys in #Tmp_AnnotationKeys
	-----------------------------------------
	Set @InvalidKeyList = ''
	SELECT @InvalidKeyList = @InvalidKeyList + TAK.Key_Name + ','
	FROM #Tmp_AnnotationKeys TAK LEFT OUTER JOIN 
		 T_Annotation_Keys AK ON AK.Key_Name = TAK.Key_Name
	WHERE AK.Key_Name Is Null
	--
	SELECT @myRowCount = @@rowcount, @myError = @@error

	If @myRowCount > 0
	Begin
		Set @InvalidKeyList = Left(@InvalidKeyList, Len(@InvalidKeyList)-1)
		Set @message = 'Invalid annotation key(s) specified: ' + @InvalidKeyList
		Set @myError = 40005
		Goto Done
	End

	-----------------------------------------
	-- Make sure the key names are capitalized properly
	-----------------------------------------
	UPDATE #Tmp_AnnotationKeys
	SET Key_Name = AK.Key_Name
	FROM #Tmp_AnnotationKeys TAK INNER JOIN
		 T_Annotation_Keys AK ON AK.Key_Name = TAK.Key_Name
	--
	SELECT @myRowCount = @@rowcount, @myError = @@error


	-----------------------------------------
	-- Parse each item in #Tmp_AnnotationKeys
	-- to make sure the experiments have this item defined in T_Experiment_Annotations
	-----------------------------------------
	
	Set @CurrentKey = ''
	Set @Continue = 1
	
	While @Continue <> 0
	Begin
		SELECT TOP 1 @CurrentKey = Key_Name
		FROM #Tmp_AnnotationKeys
		WHERE Key_Name > @CurrentKey
		ORDER BY Key_Name
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error
		
		If @myRowCount = 0
			Set @continue = 0
		Else
		Begin
			If Len(@AnnotationKeyListClean) > 0
				Set @AnnotationKeyListClean = @AnnotationKeyListClean + ', '
			Set @AnnotationKeyListClean = @AnnotationKeyListClean + @CurrentKey
			
			INSERT INTO #Tmp_NewAnnotationItems (Exp_ID, Key_Name, Value)
			SELECT Exp_ID, @CurrentKey, @DefaultValue
			FROM #Tmp_Experiments E LEFT OUTER JOIN 
				 T_Experiment_Annotations A ON E.Exp_ID = A.Experiment_ID AND A.Key_Name = @CurrentKey
			WHERE A.Experiment_ID IS NULL
			ORDER BY E.Exp_ID
			--
			SELECT @myRowCount = @@rowcount, @myError = @@error
			
			Set @NewAnnotationCount = @NewAnnotationCount + @myRowCount
		End
	End


	If @NewAnnotationCount = 0
	Begin
		Set @Message = 'Nothing to do: Each of the experiments specified already has entries for the specified annotation key names'
	End
	Else
	Begin
		If @InfoOnly = 0
		Begin
			INSERT INTO T_Experiment_Annotations (Experiment_ID, Key_Name, Value)
			SELECT DISTINCT Exp_ID, Key_Name, Value
			FROM #Tmp_NewAnnotationItems
			ORDER BY Exp_ID, Key_Name, Value
			--
			SELECT @myRowCount = @@rowcount, @myError = @@error
			
			Set @message = 'Added ' + Convert(varchar(19), @myRowCount) + ' row(s) to T_Experiment_Annotations for annotation key(s) "' + @AnnotationKeyListClean + '"'
		End
		Else
		Begin
			SELECT E.Experiment_Num, C.Campaign_Num, E.Exp_ID, A.Key_Name, A.Value
			FROM T_Experiments E INNER JOIN
				T_Campaign C ON E.EX_campaign_ID = C.Campaign_ID INNER JOIN
				#Tmp_NewAnnotationItems A ON E.Exp_ID = A.Exp_ID
			ORDER BY A.Exp_ID, A.Key_Name
		End			
	End

Done:
	If Len(@message) > 0
		SELECT @message As Message
	
	--
	Return @myError


GO
GRANT EXECUTE ON [dbo].[AddAnnotationInfoForExperiments] TO [DMS_Analysis] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddAnnotationInfoForExperiments] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddAnnotationInfoForExperiments] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddAnnotationInfoForExperiments] TO [PNL\D3M580] AS [dbo]
GO
