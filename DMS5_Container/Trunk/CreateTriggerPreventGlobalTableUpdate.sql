/****** Object:  StoredProcedure [dbo].[CreateTriggerPreventGlobalTableUpdate] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.CreateTriggerPreventGlobalTableUpdate
/****************************************************
**
**	Desc: 
**		Creates a trigger on the specified table to prevent updating or deleting all rows in the table
**		Original code posted to http://www.sqlservercentral.com/articles/delete/71468/
**		by Rahul Kr. Ghosh, MCITP-DBA 2009, posted 2010-Sep-20
**
**	Return values: 0 if no error; otherwise error code
**
**	Auth:	mem
**	Date:	02/08/2011
**    
*****************************************************/
(
	@TableName varchar(50),					-- Table name to create the trigger on
	@TriggerType varchar(20) = 'Both'		-- 'Update' if to create only update trigger, 'Delete' if to create only delete trigger, 'Both' if to create both (combine) delete & update trigger
)
AS 
Begin
	
	--getting my tools
	Declare @TriggerName nvarchar(100)
	Declare @Sql Varchar(max)
	Declare @SqlTrigType varchar(50)
	Declare @errUpdate varchar(50)
	Declare @errDelete varchar(60)
	Declare @errBoth varchar(60)
	Declare @errMsg varchar(120)
	Declare @severity nvarchar(5)
	Declare @state nvarchar (5)
	
	-- Initialize the settings
	Set @TableName = SubString(@TableName,CharIndex('.',@TableName)+1, Len(@TableName))
	Set	@Sql = ''
	Set @errUpdate = 'Cannot update all rows. Use a WHERE clause'
	Set @errDelete = 'Cannot delete all rows. Use a WHERE clause'
	Set @errBoth = 'Cannot update or delete all rows. Use a WHERE clause'
	Set @severity = '16'
	Set @state = '1'
	
	Set @TriggerName = ''

	-- Make sure @TableName exists
	If Not Exists (select * from sys.tables where name = @TableName)
	Begin
		Set @errMsg = 'Table not found: ' + @TableName + '; unable to create the trigger'
		Print @errMsg
		SELECT @errMsg AS Error
	End
	Else
	Begin
		-- Make sure @TableName is capitalized
		SELECT @TableName = Name
		FROM sys.tables 
		WHERE Name = @TableName
	End

	--if update trigger
	if @TriggerType = 'Update'
	begin 
		Set	@TriggerName = 'trig_u_'+ @TableName
		Set @SqlTrigType = 'UPDATE'
		Set @errMsg = @errUpdate
	end
		
	
	if @TriggerType = 'Delete'
	begin
		Set	@TriggerName = 'trig_d_'+ @TableName
		Set @SqlTrigType = 'DELETE'
		Set @errMsg = @errDelete
	end
		
	if @TriggerType = 'Both'
	begin
		--- BOTH THE TRIGGER DELETE & UPDATE 
		Set	@TriggerName = 'trig_ud_'+ @TableName
		Set @SqlTrigType = 'UPDATE, DELETE'
		Set @errMsg = @errBoth
	end

	If @TriggerName <> ''
	Begin
		IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(@TriggerName))
		begin
			-- trigger already there
			Print @TriggerName + ' already exists in the database; unable to continue'
		end
		Else
		Begin
	
			Set @errMsg = @errMsg + ' (see trigger ' + @TriggerName + ')'
	 
			Set @Sql = @Sql +  CHAR(13) + 'CREATE TRIGGER [dbo].[' + @TriggerName + ']'
			Set @Sql = @Sql +  CHAR(13) + 'ON ' + @TableName
			Set @Sql = @Sql +  CHAR(13) + 'FOR ' + @SqlTrigType + ' AS'
			Set @Sql = @Sql +  CHAR(13) + '/****************************************************'
			Set @Sql = @Sql +  CHAR(13) + '**'
			Set @Sql = @Sql +  CHAR(13) + '**	Desc: '
			Set @Sql = @Sql +  CHAR(13) + '**		Prevents updating or deleting all rows in the table'
			Set @Sql = @Sql +  CHAR(13) + '**'
			Set @Sql = @Sql +  CHAR(13) + '**	Auth:	mem'
			Set @Sql = @Sql +  CHAR(13) + '**	Date:	02/08/2011'
			Set @Sql = @Sql +  CHAR(13) + '**'
			Set @Sql = @Sql +  CHAR(13) + '*****************************************************/'
			Set @Sql = @Sql +  CHAR(13) + 'BEGIN' 
			Set @Sql = @Sql +  CHAR(13) + ''
			Set @Sql = @Sql +  CHAR(13) + '    DECLARE @Count int'
			
			-- Alternative to using @@RowCount is:  SELECT @Count = COUNT(*) FROM inserted'
			Set @Sql = @Sql +  CHAR(13) + '    SET @Count = @@ROWCOUNT;'
			Set @Sql = @Sql +  CHAR(13) + ''
			Set @Sql = @Sql +  CHAR(13) + '    IF @Count >= (	SELECT i.rowcnt AS TableRowCount'
			Set @Sql = @Sql +  CHAR(13) + '                     FROM dbo.sysobjects o INNER JOIN dbo.sysindexes i ON o.id = i.id'
			Set @Sql = @Sql +  CHAR(13) + '                     WHERE o.name = ''' + @TableName + ''' AND o.type = ''u'' AND i.indid < 2'
			Set @Sql = @Sql +  CHAR(13) + '                 )'
			
			-- The following works on small tables, but doesn't work on tables with lots of columns or lots of long, text columns
			-- Set @Sql = @Sql +  CHAR(13) + '    IF @Count >= (	SELECT SUM(row_count)' 
			-- Set @Sql = @Sql +  CHAR(13) + '                  FROM sys.dm_db_partition_stats'
			-- Set @Sql = @Sql +  CHAR(13) + '                  WHERE OBJECT_ID = OBJECT_ID(''' + @TableName + ''')'
			-- Set @Sql = @Sql +  CHAR(13) + '                 )'
			
			Set @Sql = @Sql +  CHAR(13) + '    BEGIN'
			Set @Sql = @Sql +  CHAR(13) + ''
			Set @Sql = @Sql +  CHAR(13) + '        RAISERROR('''+ @errMsg + ''',' + @severity +',' + @state +')'
			Set @Sql = @Sql +  CHAR(13) + '        ROLLBACK TRANSACTION' 
			Set @Sql = @Sql +  CHAR(13) + '        RETURN;'
			Set @Sql = @Sql +  CHAR(13) + ''
			Set @Sql = @Sql +  CHAR(13) + '    END'
			Set @Sql = @Sql +  CHAR(13) + ''
			Set @Sql = @Sql +  CHAR(13) + 'END'
			Set @Sql = @Sql +  CHAR(13) + ''
			Set @Sql = @Sql +  CHAR(13) + ''

			Exec(@Sql);
			
			print 'Trigger created (' + @SqlTrigType + ')'
		
			if (@@ERROR=0) 
				Print 'Trigger ' + @TriggerName + ' Created Successfully '
		End
	End

end


GO
