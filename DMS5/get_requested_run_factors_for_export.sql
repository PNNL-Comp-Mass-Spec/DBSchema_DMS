/****** Object:  StoredProcedure [dbo].[get_requested_run_factors_for_export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_requested_run_factors_for_export]
/****************************************************
**
**  Desc:
**      Returns the factors associated with the
**      run requests given by the itemList
**
**  Auth:   grk
**  Date:   03/22/2010
**          03/22/2010 grk - initial release
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @itemList TEXT,
    @itemType VARCHAR(32) = 'Batch_ID',
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

    -----------------------------------------
    -- populate it with list of requests
    -----------------------------------------
    --
    EXEC @myError = get_requested_runs_from_item_list
                            @itemList,
                            @itemType,
                            @message OUTPUT
    --
    IF @myError <> 0
        RETURN @myError

    --
    IF @myError <> 0
        RETURN @myError
/*
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
*/
    -----------------------------------------
    -- Build the Sql for obtaining the factors
    -- for the requests
    -----------------------------------------
    --
    DECLARE @colList VARCHAR(256)
    SET @colList = 'BatchID, Name,  Status,  Request,  Dataset_ID,  Dataset,  Experiment,  Experiment_ID,  Block,  [Run Order] '
    --
    --
    DECLARE @FactorNameContains VARCHAR(48)
    SET @FactorNameContains = ''
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
    -- run dynamic SQL
    -----------------------------------------
    --
    --Print @Sql
    Exec (@Sql)

    --
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[get_requested_run_factors_for_export] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_requested_run_factors_for_export] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_requested_run_factors_for_export] TO [Limited_Table_Write] AS [dbo]
GO
