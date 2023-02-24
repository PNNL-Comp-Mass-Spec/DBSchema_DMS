/****** Object:  StoredProcedure [dbo].[get_requested_run_parameters_and_factors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_requested_run_parameters_and_factors]
/****************************************************
**
**  Desc:
**      Returns the run parameters and factors associated with the run requests in the input list
**
**      This is used by https://dms2.pnl.gov/requested_run_batch_blocking/grid
**
**  Auth:   grk
**  Date:   03/28/2013 grk - Cloned from get_factor_crosstab_by_batch
**          01/05/2023 mem - Add view name to comment
**          01/24/2023 bcg - Use lowercase column names in @colList
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @itemList text,
    @infoOnly tinyint = 0,
    @message varchar(512) = '' OUTPUT
)
AS
    Set NoCount On

    Declare @myRowCount int = 0
    Declare @myError int = 0

    Declare @msg varchar(256)

    Declare @Sql varchar(max)
    Declare @CrossTabSql varchar(max)
    Declare @FactorNameList varchar(max)

    -----------------------------------------
    -- Temp tables to hold list of requests
    -- and factors
    -----------------------------------------
    --
    CREATE TABLE #REQS (
        Request int
    )
    --
    CREATE Table #FACTORS (
        FactorID INT,
        FactorName VARCHAR(128) NULL
    )

    -----------------------------------------
    -- Populate temp table from request list
    -----------------------------------------
    --
    INSERT INTO #REQS (Request)
    SELECT Item
    FROM dbo.make_table_from_list(@itemList)

/*
    If IsNull(@NameContains, '') <> ''
    Begin
        -----------------------------------------
        -- filter by request name
        -----------------------------------------
        --
        DELETE FROM
            #REQS
        WHERE
            NOT EXISTS (
                SELECT ID
                FROM T_Requested_Run
                WHERE
                    ID = Request AND
                    RDS_Name LIKE '%' + @NameContains + '%'
            )
        --
        SELECT @myRowCount = @@rowcount, @myError = @@error
    End
*/

    -----------------------------------------
    -- Build the SQL for obtaining the factors for the requests
    --
    -- These columns correspond to view V_Requested_Run_Unified_List_Ex
    -----------------------------------------
    --
    EXEC @myError = make_factor_crosstab_sql_ex
                    @colList = N'request, name, status, batch, experiment, dataset, instrument, cart, lc_col, block, run_order',
                    @Sql = @Sql OUTPUT,
                    @message = @message OUTPUT
    --
    IF @myError <> 0
        RETURN @myError

    -----------------------------------------
    -- run dynamic SQL, or dump it
    -----------------------------------------
    --
    If @infoOnly <> 0
        Print @Sql
    Else
        Exec (@Sql)

    --
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[get_requested_run_parameters_and_factors] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_requested_run_parameters_and_factors] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_requested_run_parameters_and_factors] TO [DMS2_SP_User] AS [dbo]
GO
