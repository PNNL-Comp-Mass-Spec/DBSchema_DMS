/****** Object:  StoredProcedure [dbo].[condense_integer_list_to_ranges] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[condense_integer_list_to_ranges]
/****************************************************
**
**  Desc:
**      Given a list of integers in a temporary table, condense the list into a comma and dash separted list
**
**      Leverages code from Dwain Camps
**      https://www.simple-talk.com/sql/database-administration/condensing-a-delimited-list-of-integers-in-sql-server/
**
**      The calling procedure must create two temporary tables
**      The #Tmp_ValuesByCategory table must be populated with the integers
**
**      CREATE TABLE #Tmp_ValuesByCategory (
**          Category varchar(512),
**          Value int
**      )
**
**      CREATE TABLE #Tmp_Condensed_Data (
**          Category varchar(512),
**          ValueList varchar(max)
**      )
**
**      Example usage:
**
**          INSERT INTO #Tmp_ValuesByCategory
**          VALUES ('Job', 100),
**                 ('Job', 101),
**                 ('Job', 102),
**                 ('Job', 114),
**                 ('Job', null),
**                 ('Job', 115),
**                 ('Job', 118),
**                 ('Dataset', 500),
**                 ('Dataset', 505),
**                 ('Dataset', 506),
**                 ('Dataset', 507),
**                 ('Dataset', 508),
**                 ('Dataset', 512);
**
**          EXEC condense_integer_list_to_ranges
**
**          SELECT * FROM #Tmp_Condensed_Data
**
**          Category  ValueList
**          --------  ---------------------
**          Dataset   500, 505-508, 512
**          Job       100-102, 114-115, 118
**
**  Auth:   mem
**  Date:   07/01/2014 mem - Initial version
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/01/2024 mem - Add support for duplicate values
**
*****************************************************/
(
    @debugMode tinyint = 0
)
AS
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
        FROM (SELECT V.Category, V.Value,
                     -- This rn represents the "staggered rows"
                     rn = V.Value - ROW_NUMBER() OVER (PARTITION BY V.Category ORDER BY V.Value)
              FROM (SELECT DISTINCT VC.Category, VC.Value
                    FROM #Tmp_ValuesByCategory VC
                   ) V
              WHERE NOT V.Value IS NULL
             ) RankQ
        GROUP BY RankQ.Category, RankQ.rn
    )
    UPDATE a
    SET ValueList = STUFF((
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
        FROM (SELECT Category, Value,
                     rn = Value - ROW_NUMBER() OVER (PARTITION BY Category ORDER BY Value)
              FROM (SELECT DISTINCT VC.Category, VC.Value
                    FROM #Tmp_ValuesByCategory VC
                   ) V
              WHERE NOT V.Value IS NULL
             ) RankQ
        GROUP BY Category, rn
        ORDER BY Category, rn

        SELECT * FROM #Tmp_Condensed_Data
    End

Done:
    Return 0

GO
GRANT VIEW DEFINITION ON [dbo].[condense_integer_list_to_ranges] TO [DDL_Viewer] AS [dbo]
GO
