/****** Object:  UserDefinedFunction [dbo].[GetNums] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetNums]
/****************************************************
**
**  Desc:
**  Returns a number table with the specified number of rows
**  From discussion at http://www.simple-talk.com/sql/learn-sql-server/oracle-to-sql-server-crossing-the-great-divide,-part-2/?utm_source=simpletalk&utm_medium=email-main&utm_content=OracletoSQL2-20100601&utm_campaign=SQL
**  Leverages the fact that master.dbo.syscolumns has over 15000 rows

**  Approxiate runtimes:
**  RowCount    Time (seconds)
**  0.5 million 0.7
**  1 million   1.5
**  2 million   2.5
**  5 million   6
**  10 million  12
**
**  Auth:   mem
**  Date:   04/14/2017
**
*****************************************************/
(
    @targetRowCount int
)
RETURNS @theTable TABLE
   (
    Value int
   )
AS
BEGIN
    -- Uncomment the following to divide the numbers into sections, with 20000 numbers per section
    --DECLARE
    --  @div INT = 50,
    --  @mod INT = 20000,
    --  @limit INT,
    --  @driver INT = 1000;

    --Set @limit = @div * @mod;

    WITH generator AS (
    SELECT TOP (@targetRowCount)
        id = Row_Number() OVER (ORDER BY a)
    FROM
        (SELECT a = 1 FROM MASTER.dbo.syscolumns) C1
        CROSS JOIN MASTER.dbo.syscolumns C2
    )
    INSERT @theTable (Value)
    SELECT
    id
    -- , (id - 1) / @div AS Section -- integer division produces integers without floor()
    -- , (id - 1) % @mod AS ID_In_Section
    FROM generator;

    RETURN
END

GO
