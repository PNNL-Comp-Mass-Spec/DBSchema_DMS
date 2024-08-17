/****** Object:  StoredProcedure [dbo].[dump_metadata_for_multiple_experiments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dump_metadata_for_multiple_experiments]
/****************************************************
**
**  Desc:
**      Dump metadata for experiments in given list
**
**  Returns:
**      Recordset containing keyword-value pairs for all metadata items
**
**  Auth:   grk
**  Date:   11/01/2006
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          07/04/2024 mem - Make arguments optional
**
*****************************************************/
(
    @experiment_List varchar(7000),
    @options varchar(256) = '', -- ignore for now
    @message varchar(512) = '' output
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    ---------------------------------------------------
    -- Temporary table to hold list of experiments
    ---------------------------------------------------

    CREATE TABLE #exp (
        mExp varchar(50) NOT NULL,
    )

    ---------------------------------------------------
    -- Load temporary table with list of experiments
    ---------------------------------------------------

    INSERT INTO #exp (mExp)
    SELECT Item FROM dbo.make_table_from_list(@Experiment_List)

    ---------------------------------------------------
    -- Temporary table to hold metadata
    ---------------------------------------------------

    CREATE TABLE #metaD (
        mExp varchar(50) NOT NULL,
        mCC varchar(64) NULL,
        mAType varchar(32) NULL,
        mTag varchar(200) NOT NULL,
        mVal varchar(512)  NULL
    )

    ---------------------------------------------------
    -- Load experiment tracking info for experiments
    ---------------------------------------------------

    exec @myError = load_metadata_for_multiple_experiments @Options, @message output

    If @myError <> 0
    Begin
        RAISERROR (@message, 10, 1)
        Return  @myError
    End

    ---------------------------------------------------
    -- Dump temporary metadata table
    ---------------------------------------------------

    SELECT mExp   AS [Experiment Name],
           mCC    AS [Cell Culture Name],
           mAType AS [Attribute Type],
           mTag   AS [Attribute Name],
           mVal   AS [Attribute Value]
    FROM #metaD
    ORDER BY mExp, mCC
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Error trying to query temp metadata table'
        RAISERROR (@message, 10, 1)
    End

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[dump_metadata_for_multiple_experiments] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[dump_metadata_for_multiple_experiments] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[dump_metadata_for_multiple_experiments] TO [Limited_Table_Write] AS [dbo]
GO
