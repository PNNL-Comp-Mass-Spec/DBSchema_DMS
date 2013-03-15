/****** Object:  StoredProcedure [dbo].[ValidateAnalysisJobRequestDatasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure ValidateAnalysisJobRequestDatasets
/****************************************************
**
**	Desc:
**			Validates datasets in temporary table #TD 
**			The calling procedure must create #TD and populate it with the dataset names; 
**			 the remaining columns in the table will be populated by this procedure
**
**	Return values: 
**			0 if no problems
**			Error code if a problem; @message will contain the error message
**
**	Auth:	mem
**			11/12/2012 mem - Initial version (extracted code from AddUpdateAnalysisJobRequest and ValidateAnalysisJobParameters)
**			03/05/2013 mem - Added parameter @AutoRemoveNotReleasedDatasets
**
*****************************************************/
(
	@message varchar(512) output,
	@AutoRemoveNotReleasedDatasets tinyint = 0			-- When 1, then automatically removes datasets from #TD if they have an invalid rating
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	set @message = ''
	
	Set @AutoRemoveNotReleasedDatasets = IsNull(@AutoRemoveNotReleasedDatasets, 0)
	
	---------------------------------------------------
	-- Auto-delete 'Dataset' and 'Dataset_Num' from #TD
	---------------------------------------------------
	--
	DELETE FROM #TD
	WHERE Dataset_Num IN ('Dataset', 'Dataset_Num')

	---------------------------------------------------
	-- Update the additional info in #TD
	---------------------------------------------------
	--
	UPDATE T
	SET
		T.Dataset_ID = T_Dataset.Dataset_ID, 
		T.IN_class = T_Instrument_Class.IN_class, 
		T.DS_state_ID = T_Dataset.DS_state_ID, 
		T.AS_state_ID = isnull(T_Dataset_Archive.AS_state_ID, 0),
		T.Dataset_Type = T_DatasetTypeName.DST_name,
		T.DS_rating = T_Dataset.DS_Rating
	FROM
		#TD T INNER JOIN
		T_Dataset ON T.Dataset_Num = T_Dataset.Dataset_Num INNER JOIN
		T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID INNER JOIN
		T_Instrument_Class ON T_Instrument_Name.IN_class = T_Instrument_Class.IN_class INNER JOIN
		T_DatasetTypeName ON T_DatasetTypeName.DST_Type_ID = T_Dataset.DS_type_ID LEFT OUTER JOIN
		T_Dataset_Archive ON T_Dataset.Dataset_ID = T_Dataset_Archive.AS_Dataset_ID	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
		
	---------------------------------------------------
	-- Make sure none of the datasets has a rating of -5 (Not Released)
	---------------------------------------------------
	--
	Declare @list varchar(4000)
	Declare @NotReleasedCount int
	--
	Set @NotReleasedCount = 0
	
	SELECT @NotReleasedCount = COUNT(*)
	FROM #TD
	WHERE DS_Rating = -5
	
	If @NotReleasedCount > 0
	Begin
		Set @list = ''
		
		SELECT @list = @list + Dataset_Num + ', '
		FROM #TD
		WHERE DS_Rating = -5
		ORDER BY Dataset_Num
		
		-- Remove the trailing comma If the length is less than 400 characters, otherwise truncate
		If Len(@list) < 400
			Set @list = Left(@list, Len(@list)-1)
		Else
			Set @list = Left(@list, 397) + '...'
		
		If @AutoRemoveNotReleasedDatasets = 0
		Begin
			set @message = Convert(varchar(12), @NotReleasedCount) + ' ' + dbo.CheckPlural(@NotReleasedCount, 'dataset', 'datasets') + ' are "Not Released": ' + @list
			return 50101
		End
		Else
		Begin
			set @message = 'Skipped ' + Convert(varchar(12), @NotReleasedCount) + ' "Not Released" ' + dbo.CheckPlural(@NotReleasedCount, 'dataset', 'datasets') + ': ' + @list
			
			DELETE FROM #TD
			WHERE DS_Rating = -5
			
		End
	End
	
	---------------------------------------------------
	-- Verify that datasets in list all exist
	---------------------------------------------------
	--
	set @list = ''
	--
	SELECT 
		@list = @list + CASE 
		WHEN @list = '' THEN Dataset_Num
		ELSE ', ' + Dataset_Num
		END
	FROM
		#TD
	WHERE 
		Dataset_ID IS NULL
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error checking dataset Existence'
		return 51007
	end
	--
	if @list <> ''
	begin
		set @message = 'The following datasets from list were not in database: ' + @list
		return 51007
	end	

	---------------------------------------------------
	-- Verify state of datasets
	---------------------------------------------------
	--
	set @list = ''
	--
	SELECT 
		@list = @list + CASE 
		WHEN @list = '' THEN Dataset_Num
		ELSE ', ' + Dataset_Num
		END
	FROM
		#TD
	WHERE 
		(DS_state_ID <> 3)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error checking dataset state'
		return 51007
	end
	--
	if @list <> ''
	begin
		set @message = 'The following datasets were not in correct state: ' + @list
		return 51007
	end	

	---------------------------------------------------
	-- Verify rating of datasets
	---------------------------------------------------
	--
	set @list = ''
	--
	SELECT 
		@list = @list + CASE 
		WHEN @list = '' THEN Dataset_Num
		ELSE ', ' + Dataset_Num
		END
	FROM
		#TD
	WHERE (DS_rating IN (-1, -2))
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error checking dataset rating'
		return 51007
	end
	--
	if @list <> ''
	begin
		set @message = 'The following datasets have a rating of -1 (No Data) or -2 (Data Files Missing): ' + @list
		return 51007
	end	

	---------------------------------------------------
	-- Do not allow high res datasets to be mixed with low res datasets
	---------------------------------------------------
	--
	Declare @HMSCount int = 0
	Declare @MSCount int = 0
	
	SELECT @HMSCount = COUNT(*)
	FROM #TD
	WHERE Dataset_Type LIKE 'hms%' OR
	      Dataset_Type LIKE 'ims-hms%'


	SELECT @MSCount = COUNT(*)
	FROM #TD
	WHERE Dataset_Type LIKE 'MS%' OR
	      Dataset_Type LIKE 'IMS-MS%'
	
	If @HMSCount > 0 And @MSCount > 0
	Begin		
		Set @message = 'You cannot mix high-res MS datasets with low-res datasets; create separate analysis job requests.  You currently have ' + Convert(varchar(12), @HMSCount) + ' high res (HMS) and ' + Convert(varchar(12), @MSCount) + ' low res (MS)'
		return 51009
	End	
		
	return 0


GO
