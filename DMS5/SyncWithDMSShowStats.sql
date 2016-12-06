/****** Object:  StoredProcedure [dbo].[SyncWithDMSShowStats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE SyncWithDMSShowStats
/****************************************************
**
**	Desc: 
**		Called from stored procedure SyncWithDMS5
**
**		The calling procedure must create temporary table #Tmp_SummaryOfChanges
**
**			Create Table #Tmp_SummaryOfChanges (
**				TableName varchar(128), 
**				UpdateAction varchar(20), 
**				InsertedKey varchar(128), 
**				DeletedKey varchar(128)
**			)
**
**	Parameters: 
**
**	Auth:	mem
**	Date:	10/27/2015 mem - Initial release
**			10/29/2015 mem - Added parameter @tableName
**
*****************************************************/
(
	@tableName varchar(128),
	@rowCountUpdated int,
	@ShowUpdateDetails tinyint
)
As
	set nocount on

	Declare @message varchar(512) = ''
	Declare @updateStats varchar(512)
	
	Declare @MergeUpdateCount int = 0
	Declare @MergeInsertCount int = 0
	Declare @MergeDeleteCount int = 0

	SELECT @MergeInsertCount = COUNT(*)
	FROM #Tmp_SummaryOfChanges
	WHERE UpdateAction = 'INSERT'

	SELECT @MergeUpdateCount = COUNT(*)
	FROM #Tmp_SummaryOfChanges
	WHERE UpdateAction = 'UPDATE'

	SELECT @MergeDeleteCount = COUNT(*)
	FROM #Tmp_SummaryOfChanges
	WHERE UpdateAction = 'DELETE'
	
	Set @updateStats = 'Added ' + Cast(@MergeInsertCount as varchar(12)) + dbo.CheckPlural(@MergeInsertCount, ' row', ' rows')   + ', ' +
		               'Updated ' + Cast(@MergeUpdateCount as varchar(12)) + dbo.CheckPlural(@MergeUpdateCount, ' row', ' rows') + ', '  +
		               'Deleted ' + Cast(@MergeDeleteCount as varchar(12)) + dbo.CheckPlural(@MergeDeleteCount, ' row', ' rows')

	Print ' - ' + @updateStats

	-- Make sure @message is at least 30 characters wide
	-- Padding with dollar signs because Sql Server will not allow the addition of a single space to the end of a string
	-- The $ characters are replaced with spaces below
	
	Set @message = @tableName + ': '
	While Len(@message) < 30
	Begin
		Set @message = @message + '$'
	End
	 
	Set @message = Replace(@message, '$', ' ') + @updateStats
	
	If @MergeInsertCount + @MergeUpdateCount + @MergeDeleteCount > 0
	Begin
		Exec PostLogEntry 'Normal', @message, 'SyncWithDMS5'
	End

	If @ShowUpdateDetails <> 0
	Begin
		Select *
		FROM #Tmp_SummaryOfChanges
		ORDER BY UpdateAction, InsertedKey, DeletedKey
	End
	
	return 0

GO
GRANT VIEW DEFINITION ON [dbo].[SyncWithDMSShowStats] TO [DDL_Viewer] AS [dbo]
GO
