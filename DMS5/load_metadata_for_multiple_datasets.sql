/****** Object:  StoredProcedure [dbo].[load_metadata_for_multiple_datasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[load_metadata_for_multiple_datasets]
/****************************************************
**
**  Desc:
**      Load metadata for datasets in given list
**
**  Returns:
**      Recordset containing keyword-value pairs for all metadata items
**
**  Parameters:
**      This stored procedure expects that its caller
**      will have loaded a temporary table (named #dst)
**      with all the dataset names that it should
**      load metadata for.
**
**      It also expects its caller to have created a
**      temporary table (named #metaD) into which it
**      will load the metadata.
**
**  Auth:   grk
**  Date:   11/01/2006
**          05/30/2007 grk - Added "ORDER BY" for migration to SS2005 (ticket #226)
**          07/06/2022 mem - Use new aux info definition view name
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          07/04/2024 mem - Make arguments optional
**                         - Use new column names
**
*****************************************************/
(
    @options varchar(256) = '', -- ignore for now
    @message varchar(512) = '' output
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    ---------------------------------------------------
    -- Load dataset tracking info for the datasets
    ---------------------------------------------------

    INSERT INTO #metaD (mDst, mAType, mTag, mVal)
    SELECT Name , 'Dataset', 'Name', MD.Name
    FROM V_Dataset_Metadata MD
    WHERE Name IN (SELECT mDst FROM #dst)

    INSERT INTO #metaD (mDst, mAType, mTag, mVal)
    SELECT Name , 'Dataset', 'ID', CONVERT(varchar(32), MD.ID)
    FROM V_Dataset_Metadata MD
    WHERE Name IN (SELECT mDst FROM #dst)

    INSERT INTO #metaD (mDst, mAType, mTag, mVal)
    SELECT Name , 'Dataset', 'Experiment', MD.Experiment
    FROM V_Dataset_Metadata MD
    WHERE Name IN (SELECT mDst FROM #dst)

    INSERT INTO #metaD (mDst, mAType, mTag, mVal)
    SELECT Name , 'Dataset', 'Instrument', MD.Instrument
    FROM V_Dataset_Metadata MD
    WHERE Name IN (SELECT mDst FROM #dst)

    INSERT INTO #metaD (mDst, mAType, mTag, mVal)
    SELECT Name , 'Dataset', 'Separation Type', MD.Separation_Type
    FROM V_Dataset_Metadata MD
    WHERE Name IN (SELECT mDst FROM #dst)

    INSERT INTO #metaD (mDst, mAType, mTag, mVal)
    SELECT Name , 'Dataset', 'LC Column', MD.LC_Column
    FROM V_Dataset_Metadata MD
    WHERE Name IN (SELECT mDst FROM #dst)

    INSERT INTO #metaD (mDst, mAType, mTag, mVal)
    SELECT Name , 'Dataset', 'Wellplate Number', MD.Wellplate_Number
    FROM V_Dataset_Metadata MD
    WHERE Name IN (SELECT mDst FROM #dst)

    INSERT INTO #metaD (mDst, mAType, mTag, mVal)
    SELECT Name , 'Dataset', 'Well Number', MD.Well_Number
    FROM V_Dataset_Metadata MD
    WHERE Name IN (SELECT mDst FROM #dst)

    INSERT INTO #metaD (mDst, mAType, mTag, mVal)
    SELECT Name , 'Dataset', 'Type', MD.Type
    FROM V_Dataset_Metadata MD
    WHERE Name IN (SELECT mDst FROM #dst)

    INSERT INTO #metaD (mDst, mAType, mTag, mVal)
    SELECT Name , 'Dataset', 'Operator', MD.Operator
    FROM V_Dataset_Metadata MD
    WHERE Name IN (SELECT mDst FROM #dst)

    INSERT INTO #metaD (mDst, mAType, mTag, mVal)
    SELECT Name , 'Dataset', 'Comment', MD.Comment
    FROM V_Dataset_Metadata MD
    WHERE Name IN (SELECT mDst FROM #dst)

    INSERT INTO #metaD (mDst, mAType, mTag, mVal)
    SELECT Name , 'Dataset', 'Rating', MD.Rating
    FROM V_Dataset_Metadata MD
    WHERE Name IN (SELECT mDst FROM #dst)

    INSERT INTO #metaD (mDst, mAType, mTag, mVal)
    SELECT Name , 'Dataset', 'Request', CONVERT(varchar(32), MD.Request)
    FROM V_Dataset_Metadata MD
    WHERE Name IN (SELECT mDst FROM #dst)

    INSERT INTO #metaD (mDst, mAType, mTag, mVal)
    SELECT Name , 'Dataset', 'State', MD.State
    FROM V_Dataset_Metadata MD
    WHERE Name IN (SELECT mDst FROM #dst)

    INSERT INTO #metaD (mDst, mAType, mTag, mVal)
    SELECT Name , 'Dataset', 'Archive State', MD.Archive_State
    FROM V_Dataset_Metadata MD
    WHERE Name IN (SELECT mDst FROM #dst)

    INSERT INTO #metaD (mDst, mAType, mTag, mVal)
    SELECT Name , 'Dataset', 'Created', CONVERT(varchar(32), MD.Created)
    FROM V_Dataset_Metadata MD
    WHERE Name IN (SELECT mDst FROM #dst)

    INSERT INTO #metaD (mDst, mAType, mTag, mVal)
    SELECT Name , 'Dataset', 'Folder Name', MD.Folder_Name
    FROM V_Dataset_Metadata MD
    WHERE Name IN (SELECT mDst FROM #dst)

    INSERT INTO #metaD (mDst, mAType, mTag, mVal)
    SELECT Name , 'Dataset', 'Compressed State', CONVERT(varchar(32), MD.Compressed_State)
    FROM V_Dataset_Metadata MD
    WHERE Name IN (SELECT mDst FROM #dst)

    INSERT INTO #metaD (mDst, mAType, mTag, mVal)
    SELECT Name , 'Dataset', 'Compressed Date', CONVERT(varchar(32), MD.Compressed_Date)
    FROM V_Dataset_Metadata MD
    WHERE Name IN (SELECT mDst FROM #dst)

    INSERT INTO #metaD (mDst, mAType, mTag, mVal)
    SELECT Name , 'Dataset', 'Acquisition Start', CONVERT(varchar(32), MD.Acquisition_Start)
    FROM V_Dataset_Metadata MD
    WHERE Name IN (SELECT mDst FROM #dst)

    INSERT INTO #metaD (mDst, mAType, mTag, mVal)
    SELECT Name , 'Dataset', 'Acquisition End', CONVERT(varchar(32), MD.Acquisition_End)
    FROM V_Dataset_Metadata MD
    WHERE Name IN (SELECT mDst FROM #dst)

    INSERT INTO #metaD (mDst, mAType, mTag, mVal)
    SELECT Name , 'Dataset', 'Scan Count', CONVERT(varchar(32), MD.Scan_Count)
    FROM V_Dataset_Metadata MD
    WHERE Name IN (SELECT mDst FROM #dst)

    INSERT INTO #metaD (mDst, mAType, mTag, mVal)
    SELECT Name , 'Dataset', 'File Size MB', CONVERT(varchar(32), MD.File_Size_MB)
    FROM V_Dataset_Metadata MD
    WHERE Name IN (SELECT mDst FROM #dst)

    ---------------------------------------------------
    -- Append aux info for the datasets
    ---------------------------------------------------

    INSERT INTO #metaD(mAType, mTag, mVal)
    SELECT 'Dataset', AI.Category + '.' + AI.Subcategory + '.' + AI.Item AS Tag, AI.Value
    FROM T_Dataset T INNER JOIN
         V_Aux_Info_Value AI ON T.Dataset_ID = AI.Target_ID
    WHERE AI.Target = 'Dataset' AND
          T.Dataset_Num IN (SELECT mDST FROM #dst)
    ORDER BY SC, SS, SI
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[load_metadata_for_multiple_datasets] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[load_metadata_for_multiple_datasets] TO [Limited_Table_Write] AS [dbo]
GO
