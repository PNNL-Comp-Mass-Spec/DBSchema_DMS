/****** Object:  StoredProcedure [dbo].[CondenseIntegerListToRanges] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.CondenseIntegerListToRanges
/****************************************************
** 
**	Desc:	
**		Given a list of integers in a temporary table, condenses
**		the list into a comma and dash separted list
**
**		Leverages code from Dwain Camps
**		https://www.simple-talk.com/sql/database-administration/condensing-a-delimited-list-of-integers-in-sql-server/
**
**		The calling procedure must create two temporary tables
**		The #Tmp_ValuesByCategory table must be populated with the integers
**
**		Create Table #Tmp_ValuesByCategory (
**			Category varchar(512),
**			Value int Not null
**		)
**
**		Create Table #Tmp_Condensed_Data (
**			Category varchar(512),
**			ValueList varchar(max)
**		)
**
**		Example data:
**
**			Populate #Tmp_ValuesByCategory with:
**			Category  Value
**			Job       100
**			Job       101
**			Job       102
**			Job       114
**			Job       115
**			Job       118
**
**		After calling this procedure, #Tmp_Condensed_Data will have:
**			Category  ValueList
**			Job       100-102, 114-115, 118
**
**
**	Auth:	mem
**	Date:	07/01/2014 mem - Initial version
**    
*****************************************************/
(
	@debugMode tinyint = 0
)
As
	set nocount on

	----------------------------------------------------
	-- Validate the inputs
	----------------------------------------------------

	Set @debugMode = IsNull(@debugMode, 0)
	
	----------------------------------------------------
	-- Validate the temporary tables
	----------------------------------------------------
	--
	UPDATE #Tmp_ValuesByCategory
	SET Category = ''
	WHERE Category IS NULL

	TRUNCATE TABLE #Tmp_Condensed_Data

	----------------------------------------------------
	-- Process the data
	----------------------------------------------------
	--
	INSERT INTO #Tmp_Condensed_Data (Category, ValueList)
	Select Category, ''
	From #Tmp_ValuesByCategory
	Group By Category ;

	WITH Islands AS (
		SELECT Category, MIN(Value) AS StartValue, MAX(Value) AS EndValue
		FROM (
			SELECT Category, Value
				-- This rn represents the "staggered rows"
				,rn=Value-ROW_NUMBER() OVER (PARTITION BY Category ORDER BY Value)
			FROM #Tmp_ValuesByCategory) a
		GROUP BY Category, rn
	)
	UPDATE a
	SET ValueList=STUFF(( 
		SELECT ', ' + 
			CASE -- Include either a single Item or the range (hyphenated)
				WHEN StartValue = EndValue THEN CAST(StartValue AS VARCHAR(12))
				ELSE CAST(StartValue AS VARCHAR(12)) + '-' + CAST(EndValue AS VARCHAR(12))
				END
		FROM Islands b
		WHERE a.Category = b.Category
		ORDER BY StartValue
		FOR XML PATH('')), 1, 2, '')
	FROM #Tmp_Condensed_Data a ;

	If @debugMode <> 0
	Begin
		SELECT Category, MIN(Value) AS StartValue, MAX(Value) AS EndValue
		FROM (
			SELECT Category, Value,
				   rn=Value-ROW_NUMBER() OVER (PARTITION BY Category ORDER BY Value)
			FROM #Tmp_ValuesByCategory) a
		GROUP BY Category, rn
		ORDER BY Category, rn
		
		SELECT * FROM #Tmp_Condensed_Data
	End
	
Done:
	return 0


GO
GRANT VIEW DEFINITION ON [dbo].[CondenseIntegerListToRanges] TO [DDL_Viewer] AS [dbo]
GO
