-- The following includes creation code for both sp_WhereIsItUsed and sp_SearchForString

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE sp_WhereIsItUsed
/****************************************************
**
**	Desc: 
**		This procedure searches through the code in the database for
**		whatever string you care to specify and displays the name of
**		each routine that the string is in, and its context (up to 
**		255 characters around it) of EVERY occurence so you can see, 
**		for example, whereabouts an object is being called. It is not
**		not really the same as having the build script in the Query
**		Analyser. This procedure makes it a lot quicker to find a problem.
**
**		Obviously, the code can be hacked for a particular problem,
**		as you end up with a table of all the routines in the database
**		with the routine name and all the text.
**
**  	Note that this procedure was written for SQL Server 2000 though 
**		it runs on Sql Server 2005.  However, in Sql Server 2005 you can use 
**		SELECT * FROM Information_Schema.Routines WHERE Routine_Definition like '%SearchText%'
**		to search for text in Stored Procedures
**
**		Example usage:
**			spWhereIsItUsed  'raiserror'
**			spWhereIsItUsed  'textptr',100,100
**			spWhereIsItUsed  'blog[sg]',100,100 --find blogg or blogs
**			spWhereIsItUsed  'b_gg',100,100     --find begg, bigg, etc
**
**	Original version by Phil Factor (http://www.simple-talk.com/community/blogs/philfactor/archive/2006/06/03/854.aspx)
**
**	Auth:	mem
**	Date:	08/18/2006
**			01/06/2012 mem - Now reporting DB name in the results
**
*****************************************************/
(
	@SearchString VARCHAR(1024),	--the string you want to search for 
	@BackSpan INT=10,				--when you find a string, how many characters back you show
	@ForwardSpan INT=25,			--when you find a string, how many characters forward you show
	@DBName varchar(255) = ''
)
AS
	Declare @myRowCount int
	Declare @myError int
	Set @myError = 0
	Set @myRowCount = 0

	Declare @hitCount int

	Declare @ii INT
	Declare @iiMax INT
	Declare @ColID INT
	Declare @objectID INT
	Declare @currentProcedureID INT
	Declare @pointerValue varbinary(16)
	Declare @EndOfText INT
	Declare @Chunk NVARCHAR(4000)
	Declare @pos INT
	Declare @size INT
	Declare @WhereWeAre INT--index into string so far
	Declare @context INT
	Declare @S varchar(2048)

	SET nocount ON

	IF @BackSpan + @ForwardSpan > 255 
	BEGIN
		If @BackSpan > 100
			Set @BackSpan = 100
		Set @ForwardSpan = 255 - @BackSpan
	END

	Set @DBName = IsNull(@DBName, '')
	If Len(@DBName) = 0
	Begin
		Set @DBName = DB_Name()
		Set @hitCount = 1
	End
	Else
	Begin
		-- Confirm that @DBName exists
		SELECT @hitCount = Count(*)
		FROM master.dbo.sysdatabases
		WHERE [Name] = @DBName
	End
	
	If @hitCount = 0
	Begin
		Select 'Database not found: ' + @DBName AS Message
		Goto Done
	End


	--create a table so we can iterate through it
	--a row at a time in the correct order
	CREATE TABLE #Tmp_Raw_Text (
		UniqueID INT IDENTITY(1,1), --
		colid INT, 
		[ObjectID] INT, 
		chunk NVARCHAR(4000)
	)

	--now get all the code routines into the table
	-- for views, procedures, functions, or triggers

	Set @S = ''
	Set @S = @S + ' INSERT INTO #Tmp_Raw_Text (colid, ObjectID, Chunk)'
	Set @S = @S + ' SELECT colid, C.id, text'
	Set @S = @S + ' FROM [' + @DBName + '].dbo.syscomments AS C'
	Set @S = @S +    ' INNER JOIN [' + @DBName + '].dbo.sysobjects AS O'
	Set @S = @S +    ' ON C.id = O.id'
--	Set @S = @S + ' WHERE OBJECTPROPERTY(id, ''IsExecuted'') = 1 AND encrypted=0'
	Set @S = @S + ' WHERE encrypted=0'
	Set @S = @S + ' ORDER BY C.id, colid '

	Exec (@S)
	--
	Select @myRowCount = @@RowCount, @myError = @@Error

	--now we create the table of all the routines with their
	--text source in the correct order.
	CREATE TABLE #Tmp_Routine (
		UniqueID INT IDENTITY(1,1), 
		[ObjectID] INT, 
		Definition text
	)

	-- start the loop, adding all the nvarchar(4000) chunks 
	SELECT @ii=MIN(UniqueID), @iiMax=MAX(UniqueID)
	FROM #Tmp_Raw_Text

	WHILE @ii<=@iiMax 
	BEGIN 
		SELECT 
			@colid=colid, 
			@objectID=ObjectID, 
			@chunk=chunk 
		FROM #Tmp_Raw_Text 
		WHERE UniqueID=@ii
		
		IF @Colid=1
		BEGIN
			INSERT INTO #Tmp_Routine (ObjectID, Definition) 
			SELECT @objectID, @chunk     -- get the pointer for the current procedure name / colid 
			--
			SELECT @currentProcedureID=@@Identity 

			SELECT @pointerValue = TEXTPTR(Definition) 
			FROM #Tmp_Routine 
			WHERE UniqueID=@currentProcedureID
		END
		ELSE
		BEGIN
			-- find out where to append the #temp table's value 
			SELECT @EndOfText = DATALENGTH(Definition) 
			FROM #Tmp_Routine
			WHERE UniqueID=@currentProcedureID
		    
			--Take a deep breath. We are dealing with text here
			UPDATETEXT #Tmp_Routine.definition @pointerValue @EndOfText 0 @chunk 
		END
		
		SELECT @ii=@ii+1
	END 
	--select ObjectID,datalength(definition) from #Tmp_Routine

	CREATE TABLE #Tmp_Results (
		UniqueID INT IDENTITY(1,1), 
		[ObjectID] INT, 
		ObjectType varchar(64) NULL,
		ObjectName VARCHAR(128), 
		Offset INT,
		Context VARCHAR(255)
	)

	SELECT @ii=MIN(UniqueID), @iiMax=MAX(UniqueID) 
	FROM #Tmp_Routine

	WHILE @ii<=@iiMax--avoid cursors. Do we look like amateurs?
	BEGIN --for each routine...

		SELECT  @pos=1,
				@size=DATALENGTH(definition),
				@WhereWeAre=1  
		FROM #Tmp_Routine 
		WHERE UniqueID=@ii--find all occurences of the string in the current text
		
		WHILE @WhereWeAre<@size
		BEGIN
			SELECT	@pos=PATINDEX('%'+@SearchString+'%',
					SUBSTRING(definition,@whereWeAre,8000))
			FROM #Tmp_Routine
			WHERE UniqueID=@ii
			
			IF @pos>0 
			BEGIN
				SELECT @context=	CASE WHEN @whereWeAre+@pos-@backspan<=1              
									THEN 1              
									ELSE @whereWeAre+@pos-@backspan 
									END

				INSERT INTO #Tmp_Results (objectID, Offset, Context)
				SELECT ObjectID, @whereWeAre+@pos,
						SUBSTRING(definition,@context,@BackSpan+@ForwardSpan) 
				FROM #Tmp_Routine 
				WHERE UniqueID=@ii
				
				SELECT @WhereWeAre=@WhereWeAre+@pos
			END
			ELSE 
				SELECT @WhereWeAre=@WhereWeAre+6000
		END
		SELECT @ii=@ii+1
	END

	Set @S = ''
	Set @S = @S + ' UPDATE #Tmp_Results'
	Set @S = @S + ' SET ObjectName = O.[Name], '
	Set @S = @S +    ' ObjectType = CASE'
	Set @S = @S +    ' WHEN o.xtype = ''D'' THEN ''Default'''
	Set @S = @S +    ' WHEN o.xtype = ''F'' THEN ''Foreign Key'''
	Set @S = @S +    ' WHEN o.xtype = ''P'' THEN ''Stored Procedure'''
	Set @S = @S +    ' WHEN o.xtype = ''PK'' THEN ''Primary Key'''
	Set @S = @S +    ' WHEN o.xtype = ''S'' THEN ''System Table'''
	Set @S = @S +    ' WHEN o.xtype = ''TR'' THEN ''Trigger'''
	Set @S = @S +    ' WHEN o.xtype = ''U'' THEN ''User Table'''
	Set @S = @S +    ' WHEN o.xtype = ''V'' THEN ''View'''
	Set @S = @S +    ' WHEN o.xtype = ''C'' THEN ''Check Constraint'''
	Set @S = @S +    ' WHEN o.xtype = ''FN'' THEN ''User Function'''
	Set @S = @S +    ' ELSE o.xtype'
	Set @S = @S +    ' END'
	Set @S = @S + ' FROM #Tmp_Results INNER JOIN [' + @DBName + '].dbo.sysobjects O'
	Set @S = @S +    ' ON #Tmp_Results.ObjectID = O.id'

	Exec (@S)
	--
	Select @myRowCount = @@RowCount, @myError = @@Error

	SELECT	ObjectName, 
			Offset, '...'+ Context + '...' As Context, 
			RTrim(ObjectType) As ObjectType,
			@DBName as [DBName]
	FROM #Tmp_Results
	Order By ObjectType, ObjectName, Offset

Done:
	Return @myError

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.sp_SearchForString
/****************************************************
**
**	Desc: 
**      Searches for the given search text in the
**	given database.  If @DBName is '', then searches
**	this database.
**
**	Original version by Kenneth Cluff (http://www.databasejournal.com/scripts/article.php/1493151)
**
**	Auth:	mem
**	Date:	12/15/2004
**			07/25/2006 mem - Added brackets around @DBName as needed to allow for DBs with dashes in the name
**
*****************************************************/
(
	@SearchText varchar(1024) = 'Gigasax',
	@DBName varchar(255) = '',
	@IncludeContext tinyint=1,			-- If 1, then calls spWhereIsItUsed to do the work
	@BackSpan INT=10,					--when you find a string, how many characters back you show
	@ForwardSpan INT=25					--when you find a string, how many characters forward you show
)
AS
	set nocount on

	Declare @myRowCount int
	Declare @myError int
	Set @myError = 0
	Set @myRowCount = 0

	Declare @hitCount int
	
	Declare @S varchar(2048)
	
	Set @hitCount = 0

	Set @DBName = IsNull(@DBName, '')
	If Len(@DBName) = 0
	Begin
		Set @DBName = DB_Name()
		Set @hitCount = 1
	End
	Else
	Begin
		-- Confirm that @DBName exists
		SELECT @hitCount = Count(*)
		FROM master.dbo.sysdatabases
		WHERE [Name] = @DBName
	End
	
	If @hitCount = 0
	Begin
		Select 'Database not found: ' + @DBName AS Message
		Goto Done
	End

	If @IncludeContext <> 0
		exec sp_WhereIsItUsed @SearchText, @DBName = @DBName, @BackSpan = @BackSpan, @ForwardSpan = @ForwardSpan 
	Else
	Begin
		Set @S = ''
		Set @S = @S + ' SELECT ObjectName, Occurrences, RTrim(ObjectType) As ObjectType'
		Set @S = @S + ' FROM ('
		Set @S = @S +    ' SELECT SubString(o.name, 1, 35 ) as ObjectName,'
		Set @S = @S +    '   COUNT(*) as Occurrences,'
		Set @S = @S +    '   CASE '
		Set @S = @S +    '   WHEN o.xtype = ''D'' THEN ''Default'''
		Set @S = @S +    '   WHEN o.xtype = ''F'' THEN ''Foreign Key'''
		Set @S = @S +    '   WHEN o.xtype = ''P'' THEN ''Stored Procedure'''
		Set @S = @S +    '   WHEN o.xtype = ''PK'' THEN ''Primary Key'''
		Set @S = @S +    '   WHEN o.xtype = ''S'' THEN ''System Table'''
		Set @S = @S +    '   WHEN o.xtype = ''TR'' THEN ''Trigger'''
		Set @S = @S +    '   WHEN o.xtype = ''U'' THEN ''User Table'''
		Set @S = @S +    '   WHEN o.xtype = ''V'' THEN ''View'''
		Set @S = @S +    '   WHEN o.xtype = ''C'' THEN ''Check Constraint'''
		Set @S = @S +    '   WHEN o.xtype = ''FN'' THEN ''User Function'''
		Set @S = @S +    '   ELSE o.xtype'
		Set @S = @S +    '   END as ObjectType '
		Set @S = @S +    ' FROM [' + @DBName + '].dbo.syscomments AS C'
		Set @S = @S +    '   INNER JOIN [' + @DBName + '].dbo.sysobjects AS O'
		Set @S = @S +    '   ON C.id = O.id'
		Set @S = @S +    ' WHERE PatIndex(''%' + @SearchText + '%'', c.text) > 0'
		Set @S = @S +    ' GROUP BY o.name, o.xtype'
		Set @S = @S +    ' ) LookupQ'
		Set @S = @S + ' ORDER BY ObjectType, ObjectName'

		Exec (@S)
		--
		Select @myRowCount = @@RowCount, @myError = @@Error
	End

Done:		
	Return @myError


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

