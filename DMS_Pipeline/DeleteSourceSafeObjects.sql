/****** Object:  StoredProcedure [dbo].[DeleteSourceSafeObjects] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.DeleteSourceSafeObjects
/****************************************************
**
**	Desc:
**		Deletes SourceSafe stored procedures from this database
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**			01/07/2009 mem - initial release
**
*****************************************************/
(
	@message varchar(512)='' output
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	Declare @Continue int
	Declare @EntryID int
	Declare @DeletionCount int
	Declare @Procedure varchar(128)
	Declare @S varchar(1024)
	
	Set @message = ''

	CREATE TABLE #TmpProceduresToDelete (
		EntryID int Identity(1,1) NOT NULL,
		ProcedureName varchar(128) NOT NULL
	)
	
	---------------------------------------------------
	-- Find the Stored Procedure matching "dt_" or "sp_%diagram%"
	---------------------------------------------------
	--
	INSERT INTO #TmpProceduresToDelete (ProcedureName)
	SELECT Name
	FROM sys.procedures
	WHERE Name LIKE 'dt[_]%' OR Name Like 'sp[_]%diagram%'
	--
	SELECT @myError = @@Error, @myRowCount = @@RowCount
	
	If @myRowCount > 0
		Set @continue = 1
	Else
		Set @continue = 0
	
	Set @EntryID = -1
	Set @DeletionCount = 0

	While @Continue = 1
	Begin
		SELECT TOP 1 @EntryID = EntryID,
		             @Procedure = ProcedureName
		FROM #TmpProceduresToDelete
		WHERE EntryID > @EntryID
		ORDER BY EntryID
		--
		SELECT @myError = @@Error, @myRowCount = @@RowCount

		If @myRowCount = 0
			Set @Continue = 0
		Else
		Begin
			Set @S = ' DROP PROCEDURE ' + @Procedure
			Exec (@S)
			
			Set @DeletionCount = @DeletionCount + 1
		End
	End

	If @DeletionCount > 0
		Set @message = 'Deleted ' + Convert(varchar(12), @DeletionCount) + ' SourceSafe procedures'
	Else
		Set @message = 'No SourceSafe procedures were found'

	If Exists (SELECT * FROM sys.tables WHERE Name = 'dtproperties')
	Begin
		DROP TABLE dtProperties
		Set @message = @message + '; also deleted the "dtproperties" table'
	End
	
	SELECT @Message as Message
		
 	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[DeleteSourceSafeObjects] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteSourceSafeObjects] TO [PNL\D3M578] AS [dbo]
GO
