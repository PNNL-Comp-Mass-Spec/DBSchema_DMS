/****** Object:  StoredProcedure [dbo].[SyncWithDMSShowStats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE SyncWithDMSShowStats
/****************************************************
**
**	Desc: 
**		Called from stored procedure SyncWithDMS5
**
**		Uses temporary table #Tmp_SummaryOfChanges
**
**	Parameters: 
**
**	Auth:	mem
**	Date:	10/26/2015 mem - Initial release
**
*****************************************************/
(
	@rowCountUpdated int,
	@ShowUpdateDetails tinyint
)
As
	set nocount on

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
	
	Print '  - Added ' + Cast(@MergeInsertCount as varchar(12)) + dbo.CheckPlural(@MergeInsertCount, ' row', ' rows') + ', ' +
		        ' Updated ' + Cast(@MergeUpdateCount as varchar(12)) + dbo.CheckPlural(@MergeUpdateCount, ' row', ' rows') + ', '  +
		        ' Deleted ' + Cast(@MergeDeleteCount as varchar(12)) + dbo.CheckPlural(@MergeDeleteCount, ' row', ' rows') + ', '

	If @ShowUpdateDetails <> 0
	Begin
		Select *
		FROM #Tmp_SummaryOfChanges
		ORDER BY UpdateAction, InsertedKey, DeletedKey
	End
	
	return 0

GO
