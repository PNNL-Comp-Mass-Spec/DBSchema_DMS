/****** Object:  StoredProcedure [dbo].[UpdateDatasetRating] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure UpdateDatasetRating
/****************************************************
**
**	Desc:	Updates the rating for the given datasets by calling SP UpdateDatasets
**
**	Return values: 0: success, otherwise, error code
** 
**	Auth:	mem
**	Date:	10/07/2015 mem - Initial release
**			03/17/2017 mem - Pass this procedure's name to udfParseDelimitedList
**    
*****************************************************/
(
	@datasets varchar(6000),				-- Comma-separated list of datasets
	@rating varchar(32) = 'Unknown',		-- Typically "Released" or "Not Released"
	@message varchar(512) = '' output,
	@infoOnly tinyint = 0,
   	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	Set @rating = IsNull(@rating, '')
	Set @infoOnly = IsNull(@infoOnly, 0)
	
	---------------------------------------------------
	-- Resolve id for rating
	---------------------------------------------------

	Declare @ratingID int

	execute @ratingID = GetDatasetRatingID @rating
	if @ratingID = 0
	begin
		Set @message = 'Could not find entry in database for rating "' + @rating + '"'
		Print @message
		Goto Done
	end

	Declare @DatasetCount int = 0
	
	SELECT @DatasetCount= COUNT (DISTINCT Value)
	FROM udfParseDelimitedList(@datasets, ',', 'UpdateDatasetRating')
	
	If @DatasetCount = 0
	Begin
		Set @message = '@datasets cannot be empty'
		Set @myError = 10
		Goto Done
	End
	
	---------------------------------------------------
	-- Determine the mode based on @infoOnly
	---------------------------------------------------
	
	Declare @mode varchar(12) = 'update'
	If @infoOnly <> 0
		Set @mode = 'preview'
	
	---------------------------------------------------
	-- Call stored procedure UpdateDatasets
	---------------------------------------------------
	
	Exec @myError = UpdateDatasets @datasets, @rating=@rating, @mode=@mode, @message=@message output, @callingUser=@callingUser

	If @myError = 0 And @infoOnly = 0
	Begin
		If @DatasetCount = 1
			Set @message = 'Changed the rating to "' + @rating + '" for dataset ' + @datasets
		Else
			Set @message = 'Changed the rating to "' + @rating + '" for ' + Cast(@DatasetCount as varchar(12)) + ' datasets'
		
		SELECT @message as Message, @datasets as DatasetList
	End
	
Done:
	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDatasetRating] TO [DDL_Viewer] AS [dbo]
GO
