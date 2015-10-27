/****** Object:  StoredProcedure [dbo].[GenerateMergeStatement] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create Procedure GenerateMergeStatement
/****************************************************
**
**	Desc: Creates a Merge statement for the specified table
**        Does not actually perform the merge, just generates the code required to do so
**        Intended for use when you need to add a merge statement to a stored procedure
**
**        Modeled after code from http://weblogs.sqlteam.com/billg/archive/2011/02/15/generate-merge-statements-FROM-a-table.aspx
**
**	Auth:	mem
**	Date:	10/26/2015 mem - Initial version
**    
*****************************************************/
(
	@tableName varchar(128),
	@sourceDatabase varchar(128) = 'SourceDBName',
	@includeDelete tinyint = 1
)
As
	
	set nocount on

	Declare @myError int
	Declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Declare @return int
	Declare @newLine varchar(2) = Char(13) + Char(10)
	
	Set @tableName = IsNull(@tableName, '')
	Set @sourceDatabase = IsNull(@sourceDatabase, '')
	Set @includeDelete = IsNull(@includeDelete, 1)

	If @tableName = ''
	Begin
		PRINT '@tableName cannot be empty'
		Goto Done
	End

	If @sourceDatabase = ''
	Begin
		PRINT '@sourceDatabase cannot be empty'
		Goto Done
	End
	
	---------------------------------------------------
	-- Validate the table name
	---------------------------------------------------

	If Not Exists (Select * FROM sys.columns WHERE object_id = object_id(@tableName))
	Begin
		PRINT 'Cannot generate a merge statement for ' + @tableName + ': Table not found'
		Goto Done
	End

	---------------------------------------------------
	-- Populate a table with list of data types that we can compare
	---------------------------------------------------
	
	Declare @UpdatableColumns TABLE (ColumnName varchar(255) NOT NULL, user_type_id int not NULL, is_nullable tinyint NOT NULL)
	
	Declare @Types TABLE (user_type_id int not NULL, IsNumber tinyint NOT null)

	INSERT Into @Types Values (36, 0) -- uniqueidentifier; compatible with IsNull(ColumnName, '')
	INSERT Into @Types Values (167, 0) -- varchar
	INSERT Into @Types Values (175, 0) -- char
	INSERT Into @Types Values (231, 0) -- nvarchar
	INSERT Into @Types Values (239, 0) -- nchar
	INSERT Into @Types Values (241, 0) -- XML; Note: cannot be compared using the ISNULL(NULLIF()) test used below

	INSERT Into @Types VALUES(40, 0) -- date
	INSERT Into @Types VALUES(41, 0) -- time
	INSERT Into @Types VALUES(42, 0) -- datetime2
	INSERT Into @Types VALUES(58, 0) -- smalldatetime
	INSERT Into @Types VALUES(61, 0) -- datetime

	INSERT Into @Types Values (48, 1) -- tinyint
	INSERT Into @Types Values (52, 1) -- smallint
	INSERT Into @Types Values (56, 1) -- int
	INSERT Into @Types Values (59, 1) -- real
	INSERT Into @Types Values (60, 1) -- money
	INSERT Into @Types Values (62, 1) -- float
	INSERT Into @Types Values (104, 1) -- bit
	INSERT Into @Types Values (106, 1) -- decimal
	INSERT Into @Types Values (108, 1) -- numeric
	INSERT Into @Types Values (122, 1) -- smallmoney
	INSERT Into @Types Values (127, 1) -- bigint

	---------------------------------------------------
	-- Turn identity insert off for tables with identities
	---------------------------------------------------
	
	SELECT @return = objectproperty(object_id(@tableName), 'TableHasIdentity')
	If @return = 1 
		PRINT 'SET IDENTITY_INSERT [dbo].[' + @tableName + '] ON;' + @newLine

	---------------------------------------------------
	-- Lookup the column names
	---------------------------------------------------

	Declare @sql varchar(max) = ''
	Declare @list varchar(max) = '';


	SELECT @list = @list + [name] +', '
	FROM sys.columns
	WHERE object_id = object_id(@tableName)

	---------------------------------------------------
	-- Construct the merge statment
	---------------------------------------------------

	PRINT 'MERGE [dbo].[' + @tableName + '] AS t'
	PRINT 'USING (SELECT * FROM [' + @sourceDatabase + '].[dbo].[' + @tableName + ']) as s'

	-- Determine the columns to join on by looking up the primary key(s)
	--
	SET @list = ''
	
	SELECT @list = @list + 't.[' + c.COLUMN_NAME + '] = s.[' + c.COLUMN_NAME + '] AND '
	FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS pk,
	     INFORMATION_SCHEMA.KEY_COLUMN_USAGE c
	WHERE pk.TABLE_NAME = @tableName AND
	      CONSTRAINT_TYPE = 'PRIMARY KEY' AND
	      c.TABLE_NAME = pk.TABLE_NAME AND
	      c.CONSTRAINT_NAME = pk.CONSTRAINT_NAME

	If @list = ''
	Begin
		PRINT 'Cannot generate a merge statement for ' + @tableName + ' because it does not have a primary key'
		Goto Done
	End

	-- Remove the trailing "AND"
	--
	SELECT @list =  LEFT(@list, LEN(@list) - 4)
	PRINT 'ON ( ' + @list + ')'


	-- Find the updatable columns (those that are not primary keys or identity columns)
	
	INSERT INTO @UpdatableColumns (ColumnName, user_type_id, is_nullable)
	SELECT [name], user_type_id, is_nullable
	FROM sys.columns
	WHERE object_id = object_id(@tableName) AND
	      [name] NOT IN 
	      ( SELECT [column_name]
	        FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS pk,
	                           INFORMATION_SCHEMA.KEY_COLUMN_USAGE c
	        WHERE pk.TABLE_NAME = @tableName AND
	              CONSTRAINT_TYPE = 'PRIMARY KEY' AND
	              c.TABLE_NAME = pk.TABLE_NAME AND
	              c.CONSTRAINT_NAME = pk.CONSTRAINT_NAME ) AND
	      columnproperty(object_id(@tableName), [name], 'IsIdentity ') = 0

	If Not Exists (Select * from @UpdatableColumns)
	Begin
		PRINT 'Cannot generate a merge statement for ' + @tableName + ': all of the columns are primary keys or identity columns'
		Goto Done
	End
	      
	---------------------------------------------------
	-- Sql for updating when rows match
	-- Do not update primary keys or identity columns
	---------------------------------------------------
	--
	PRINT 'WHEN MATCHED AND ('
		
	---------------------------------------------------
	-- Sql to determine if matched rows have different values
	--
	-- Comparison option #1 (misses edge cases where either value is null and the other is 0)
	--  WHERE ((IsNull(Source.ColumnA, 0) <> IsNull(Target.ColumnA, 1))) OR
	--        ((IsNull(Source.ColumnA, 'BogusNonWordValue12345') <> IsNull(Target.ColumnA, 'BogusNonWordValue67890')))
	--
	-- Comparison option #2 (contributed by WileCau at http://stackoverflow.com/questions/1075142/how-to-compare-values-which-may-both-be-null-is-t-sql )
	--  NullIf returns Null if the two values are equal, or returns the first value if the fields are not equal
	--  This expression is a bit hard to follow, but it's a compact way to compare two fields to see if they are equal
	--
	--  WHERE ISNULL(NULLIF(Target.Field1, Source.Field1),
    --               NULLIF(Source.Field1, Target.Field1)
    --         ) IS NOT NULL
	---------------------------------------------------
	
	Declare @WhereListA varchar(max) = ''
	Declare @WhereListB varchar(max) = ''

	-- Compare the non-nullable columns
	--
	SELECT @WhereListA = @WhereListA + '    t.[' + [ColumnName] +  '] <> s.[' + [ColumnName] +'] OR' + @newLine
	FROM @UpdatableColumns
	WHERE is_nullable = 0 AND
	      user_type_id <> 241   -- Exclude XML columns
	

	-- Compare the nullable columns
	--	
	SELECT @WhereListB = @WhereListB + '    ISNULL( NULLIF(t.[' + [ColumnName] +  '], s.[' + [ColumnName] +']),' + @newLine
	                                 + '            NULLIF(s.[' + [ColumnName] +'], t.[' + [ColumnName] +  '])) IS NOT NULL OR' + @newLine
	FROM @UpdatableColumns C
	     INNER JOIN @Types T
	       ON C.user_type_id = T.user_type_id
	WHERE C.is_nullable <> 0 AND
	      C.user_type_id <> 241   -- Exclude XML columns

	-- Compare XML columns
	--
	SELECT @WhereListB = @WhereListB + '    ISNULL(Cast(t.[' + [ColumnName] + '] AS varchar(max)), '''') <>' + 
	                                   '    ISNULL(Cast(s.[' + [ColumnName] + '] AS varchar(max)), '''') OR' + @newLine
	FROM @UpdatableColumns C
	     INNER JOIN @Types T
	       ON C.user_type_id = T.user_type_id
	WHERE C.user_type_id = 241
	
	-- Remove the trailing OR's
	If @WhereListA <> ''
		Set @WhereListA = Left(@WhereListA, Len(@WhereListA) - 5)
	
	If @WhereListB <> ''
		Set @WhereListB = Left(@WhereListB, Len(@WhereListB) - 5)

	If @WhereListA <> '' And @WhereListB <> ''
	Begin
		PRINT @WhereListA + ' OR' + @newline + @WhereListB
	End
	Else
	Begin
		If @WhereListA <> ''
			PRINT @WhereListA + @newline
		Else
			PRINT @WhereListB + @newline
	End

	PRINT '    )'


	---------------------------------------------------
	-- Sql that actually updates the data
	---------------------------------------------------	

	SELECT @list = '';
	SELECT @list = @list + '    [' + [ColumnName] +  '] = s.[' + [ColumnName] +'],' + @newLine
	FROM @UpdatableColumns	

	-- Remove the trailing comma
	PRINT 'THEN UPDATE SET ' + @newLine + left(@list, len(@list) - 3)

	---------------------------------------------------
	-- Sql for inserting new rows
	---------------------------------------------------
	--
	PRINT 'WHEN NOT MATCHED BY TARGET THEN';

	SET @list = ''

	SELECT @list = @list + '[' + [name] +'], '
	FROM sys.columns
	WHERE object_id = object_id(@tableName)

	-- Remove the trailing comma
	SELECT @list = LEFT(@list, LEN(@list) - 1)

	PRINT '    INSERT(' + @list + ')'

	SET @list = ''

	SELECT @list = @list + 's.[' +[name] +'], '
	FROM sys.columns
	WHERE object_id = object_id(@tableName)

	-- Remove the trailing comma
	SELECT @list = LEFT(@list, LEN(@list) - 1)

	PRINT '    VALUES(' + @list + ')'

	---------------------------------------------------
	-- Sql for deleting extra rows
	---------------------------------------------------
	--
	If @includeDelete <> 0
		print 'WHEN NOT MATCHED BY SOURCE THEN DELETE; '
	Else
		PRINT ';'

	---------------------------------------------------
	-- Turn identity insert back on for tables with identities
	---------------------------------------------------
	
	SELECT @return = objectproperty(object_id(@tableName), 'TableHasIdentity')
	If @return = 1 
		PRINT 'SET IDENTITY_INSERT [dbo].[' + @tableName + '] OFF;' + @newLine

	
Done:			
	return 0

GO
