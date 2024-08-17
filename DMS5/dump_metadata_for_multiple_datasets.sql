/****** Object:  StoredProcedure [dbo].[dump_metadata_for_multiple_datasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dump_metadata_for_multiple_datasets]
/****************************************************
**
**  Desc:
**      Dump metadata for datasets in given list
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
    @dataset_List varchar(7000),
    @options varchar(256) = '', -- ignore for now
    @message varchar(512) = '' output
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    ---------------------------------------------------
    -- Temporary table to hold list of datasets
    ---------------------------------------------------

    CREATE TABLE #dst (
        mDst varchar(128) NOT NULL,
    )

    ---------------------------------------------------
    -- Load temporary table with list of datasets
    ---------------------------------------------------

    INSERT INTO #dst (mDst)
    SELECT Item FROM dbo.make_table_from_list(@dataset_List)

    ---------------------------------------------------
    -- Temporary table to hold metadata
    ---------------------------------------------------

    CREATE TABLE #metaD (
        seq int IDENTITY(1,1) NOT NULL,
        mDst varchar(128) NOT NULL,
        mAType varchar(32) NULL,
        mTag varchar(200) NOT NULL,
        mVal varchar(512)  NULL
    )

    ---------------------------------------------------
    -- Load dataset tracking info for datasets
    ---------------------------------------------------

    exec @myError = load_metadata_for_multiple_datasets @Options, @message output

    If @myError <> 0
    Begin
        RAISERROR (@message, 10, 1)
        Return  @myError
    End

    ---------------------------------------------------
    -- Dump temporary metadata table
    ---------------------------------------------------

    SELECT mDst   AS [Dataset Name],
           mAType AS [Attribute Type],
           mTag   AS [Attribute Name],
           mVal   AS [Attribute Value]
    FROM #metaD
    ORDER BY mDst, seq
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Error trying to query temp metadata table'
        RAISERROR (@message, 10, 1)
    End

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[dump_metadata_for_multiple_datasets] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[dump_metadata_for_multiple_datasets] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[dump_metadata_for_multiple_datasets] TO [Limited_Table_Write] AS [dbo]
GO
