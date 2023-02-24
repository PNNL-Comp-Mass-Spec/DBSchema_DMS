/****** Object:  StoredProcedure [dbo].[get_instrument_usage_allocations_for_grid] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_instrument_usage_allocations_for_grid]
/****************************************************
**
**  Desc:
**      Get grid data for editing given usage allocations
**
**  Auth:   grk
**  Date:   01/15/2013 grk - Initial release
**          01/16/2013 grk - Single fiscal year
**          10/31/2022 mem - Use new column name in view V_Instrument_Allocation_List_Report
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @itemList TEXT,             -- list of specific proposals (all if blank)
    @fiscalYear VARCHAR(256),
    @message varchar(512)='' OUTPUT
)
AS
    Set NoCount On

    Declare @myRowCount int
    Declare @myError int
    Set @myRowCount = 0
    Set @myError = 0

    SET @fiscalYear = ISNULL(@fiscalYear, '')
    SET @itemList = ISNULL(@itemList, '')

    -----------------------------------------
    -- convert item list into temp table
    -----------------------------------------
    --
    CREATE TABLE #PROPOSALS (
        Item VARCHAR(128)
    )
    --
    INSERT INTO #PROPOSALS (Item)
    SELECT Item
    FROM dbo.make_table_from_list(@itemList)


    -----------------------------------------
    --
    -----------------------------------------

    SELECT  Fiscal_Year,
            Proposal_ID,
            Title,
            Status,
            General,
            FT,
            IMS,
            ORB,
            EXA,
            LTQ,
            GC,
            QQQ,
            CONVERT(VARCHAR(24), Last_Updated, 101) AS Last_Updated,
            FY_Proposal
    FROM    V_Instrument_Allocation_List_Report
    WHERE
    Fiscal_Year = @fiscalYear AND
    (DATALENGTH(@itemList) = 0 OR Proposal_ID IN (SELECT Item FROM #PROPOSALS))

    RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[get_instrument_usage_allocations_for_grid] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_instrument_usage_allocations_for_grid] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_instrument_usage_allocations_for_grid] TO [DMS2_SP_User] AS [dbo]
GO
