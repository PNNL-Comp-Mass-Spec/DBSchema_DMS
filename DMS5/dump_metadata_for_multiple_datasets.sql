/****** Object:  StoredProcedure [dbo].[dump_metadata_for_multiple_datasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dump_metadata_for_multiple_datasets]
/****************************************************
**
**  Desc: Dump metadata for datasets in given list
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
    @dataset_List varchar(7000),
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
    -- temporary table to hold list of datasets
    ---------------------------------------------------

    Create Table #dst
    (
    mDst varchar(128) Not Null,
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      set @message = 'Error trying to create temp table for dataset list'
      RAISERROR (@message, 10, 1)
      return  @myError
    end

    ---------------------------------------------------
    -- load temporary table with list of datasets
    ---------------------------------------------------

    INSERT INTO #dst (mDst)
    SELECT Item FROM dbo.make_table_from_list(@dataset_List)

    ---------------------------------------------------
    -- temporary table to hold metadata
    ---------------------------------------------------

    Create Table #metaD
    (
    seq int IDENTITY(1,1) NOT NULL,
    mDst varchar(128) Not Null,
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
    -- load dataset tracking info for datasets
    -- in given list
    ---------------------------------------------------

    exec @myError = load_metadata_for_multiple_datasets @Options, @message output
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
        mDst as [Dataset Name],
        mAType as [Attribute Type],
        mTag as [Attribute Name],
        mVal as [Attribute Value]
    from #metaD
    order by mDst, seq
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      set @message = 'Error trying to query temp metadata table'
      RAISERROR (@message, 10, 1)
      return  @myError
    end

 -------------------------------------------------------------------------------------------------------
 -------------------------------------------------------------------------------------------------------

Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[dump_metadata_for_multiple_datasets] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[dump_metadata_for_multiple_datasets] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[dump_metadata_for_multiple_datasets] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[dump_metadata_for_multiple_datasets] TO [Limited_Table_Write] AS [dbo]
GO
