/****** Object:  StoredProcedure [dbo].[dump_metadata_for_multiple_experiments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dump_metadata_for_multiple_experiments]
/****************************************************
**
**  Desc: Dump metadata for experiments in given list
**
**  Return values: 0: success, otherwise, error code
**                    recordset containing keyword-value pairs
**                    for all metadata items
**
**  Parameters:
**
**  Auth:   grk
**  Date:   11/01/2006
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @experiment_List varchar(7000),
    @options varchar(256), -- ignore for now
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    set @message = ''

    ---------------------------------------------------
    -- temporary table to hold list of experiments
    ---------------------------------------------------

    Create Table #exp
    (
    mExp varchar(50) Not Null,
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      set @message = 'Error trying to create temp table for experiment list'
      RAISERROR (@message, 10, 1)
      return  @myError
    end

    ---------------------------------------------------
    -- load temporary table with list of experiments
    ---------------------------------------------------

    INSERT INTO #exp (mExp)
    SELECT Item FROM dbo.make_table_from_list(@Experiment_List)

    ---------------------------------------------------
    -- temporary table to hold metadata
    ---------------------------------------------------

    Create Table #metaD
    (
    mExp varchar(50) Not Null,
    mCC varchar(64) Null,
    mAType varchar(32) Null,
    mTag varchar(200) Not Null,
    mVal varchar(512)  Null
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      set @message = 'Error trying to create temp metadata table'
      RAISERROR (@message, 10, 1)
      return  @myError
    end

    ---------------------------------------------------
    -- load experiment tracking info for experiments
    -- in given list
    ---------------------------------------------------

    exec @myError = load_metadata_for_multiple_experiments @Options, @message output
    --
    if @myError <> 0
    begin
      RAISERROR (@message, 10, 1)
      return  @myError
    end

    ---------------------------------------------------
    -- dump temporary metadata table
    ---------------------------------------------------

    select
        mExp as [Experiment Name],
        mCC as [Cell Culture Name],
        mAType as [Attribute Type],
        mTag as [Attribute Name],
        mVal as [Attribute Value]
    from #metaD
    order by mExp, mCC
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      set @message = 'Error trying to query temp metadata table'
      RAISERROR (@message, 10, 1)
      return  @myError
    end

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[dump_metadata_for_multiple_experiments] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[dump_metadata_for_multiple_experiments] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[dump_metadata_for_multiple_experiments] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[dump_metadata_for_multiple_experiments] TO [Limited_Table_Write] AS [dbo]
GO
