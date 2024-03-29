/****** Object:  StoredProcedure [dbo].[get_factor_crosstab_by_batch] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_factor_crosstab_by_batch]
/****************************************************
**
**  Desc:
**      Returns the factors associated with the run requests in the specified batch
**
**      This is used by https://dms2.pnl.gov/requested_run_batch_blocking/param
**
**  Auth:   mem
**  Date:   02/18/2010
**          02/26/2010 grk - merged T_Requested_Run_History with T_Requested_Run
**          03/02/2010 grk - added status field to requested run
**          03/17/2010 grk - added filtering for request name contains
**          03/18/2010 grk - eliminated call to get_factor_crosstab_by_factor_id
**          02/17/2012 mem - Updated to delete data from #REQS only if @NameContains is not blank
**          01/05/2023 mem - Use new column names in V_Requested_Run_Unified_List
**          01/24/2023 mem - Use lowercase column names in @colList
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @batchID int,
    @nameContains VARCHAR(48) = '',
    @infoOnly tinyint = 0,
    @message varchar(512)='' OUTPUT
)
AS
    Set NoCount On

    Declare @myRowCount int
    Declare @myError int
    Set @myRowCount = 0
    Set @myError = 0

    Declare @msg varchar(256)

    Declare @Sql varchar(max)
    Declare @CrossTabSql varchar(max)
    Declare @FactorNameList varchar(max)

    -----------------------------------------
    -- temp tables to hold list of requests
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

    If IsNull(@BatchID, 0) > 0
    Begin
        -----------------------------------------
        -- Populate #REQS with the requests that correspond to batch @BatchID
        -----------------------------------------
        --
        DECLARE @itemList VARCHAR(48)
        SET @itemList = CONVERT(varchar(12), @BatchID)
        EXEC @myError = get_requested_runs_from_item_list
                                @itemList,
                                'Batch_ID',
                                @message OUTPUT
        --
        IF @myError <> 0
            RETURN @myError
    End

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

    -----------------------------------------
    -- Build the Sql for obtaining the factors for the requests
    --
    -- These columns correspond to view V_Requested_Run_Unified_List
    -----------------------------------------
    --
    DECLARE @colList VARCHAR(256) = ' ''x'' as sel, batch_id, name, status, dataset_id, request, block, run_order'
    --
    DECLARE @FactorNameContains VARCHAR(48) = ''
    --
    EXEC @myError = make_factor_crosstab_sql
                        @colList,
                        @FactorNameContains,
                        @Sql OUTPUT,
                        @message OUTPUT
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
GRANT VIEW DEFINITION ON [dbo].[get_factor_crosstab_by_batch] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_factor_crosstab_by_batch] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_factor_crosstab_by_batch] TO [Limited_Table_Write] AS [dbo]
GO
