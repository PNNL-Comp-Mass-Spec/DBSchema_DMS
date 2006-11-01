/****** Object:  StoredProcedure [dbo].[LoadMetadataForMultipleDatasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE LoadMetadataForMultipleDatasets
/****************************************************
**
**	Desc: Load metadata for datasets in given list
**
**	Return values: 0: success, otherwise, error code
**                    recordset containing keyword-value pairs
**                    for all metadata items
**
**	Parameters: 
**      This stored procedure expects that its caller
**      will have loaded a temporary table (named #dst)
**      with all the dataset names that it should
**      load metadata for.
**
**      It also expects its caller to have created a
**      temporary table (named #metaD) into which it
**      will load the metadata.
**
**		Auth: grk
**		Date: 11/01/2006
**    
*****************************************************/
 (
  @Options varchar(256), -- ignore for now
  @message varchar(512) output
 )
As
	set nocount on
 
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''
 

	---------------------------------------------------
	-- load dataset tracking info for datasets 
	-- in given list
	---------------------------------------------------
 
	INSERT INTO #metaD(mDst, mAType, mTag, mVal)
	SELECT Name , 'Dataset', 'Name', MD.[Name]
	FROM V_Dataset_Metadata MD
	WHERE (Name IN (SELECT mDst FROM #dst))
	--
	INSERT INTO #metaD(mDst, mAType, mTag, mVal)
	SELECT Name , 'Dataset', 'ID', CONVERT(varchar(32), MD.[ID])
	FROM V_Dataset_Metadata MD
	WHERE (Name IN (SELECT mDst FROM #dst))
	--
	INSERT INTO #metaD(mDst, mAType, mTag, mVal)
	SELECT Name , 'Dataset', 'Experiment', MD.[Experiment]
	FROM V_Dataset_Metadata MD
	WHERE (Name IN (SELECT mDst FROM #dst))
	--
	INSERT INTO #metaD(mDst, mAType, mTag, mVal)
	SELECT Name , 'Dataset', 'Instrument', MD.[Instrument]
	FROM V_Dataset_Metadata MD
	WHERE (Name IN (SELECT mDst FROM #dst))
	--
	INSERT INTO #metaD(mDst, mAType, mTag, mVal)
	SELECT Name , 'Dataset', 'Separation Type', MD.[Separation Type]
	FROM V_Dataset_Metadata MD
	WHERE (Name IN (SELECT mDst FROM #dst))
	--
	INSERT INTO #metaD(mDst, mAType, mTag, mVal)
	SELECT Name , 'Dataset', 'LC Column', MD.[LC Column]
	FROM V_Dataset_Metadata MD
	WHERE (Name IN (SELECT mDst FROM #dst))
	--
	INSERT INTO #metaD(mDst, mAType, mTag, mVal)
	SELECT Name , 'Dataset', 'Wellplate Number', MD.[Wellplate Number]
	FROM V_Dataset_Metadata MD
	WHERE (Name IN (SELECT mDst FROM #dst))
	--
	INSERT INTO #metaD(mDst, mAType, mTag, mVal)
	SELECT Name , 'Dataset', 'Well Number', MD.[Well Number]
	FROM V_Dataset_Metadata MD
	WHERE (Name IN (SELECT mDst FROM #dst))
	--
	INSERT INTO #metaD(mDst, mAType, mTag, mVal)
	SELECT Name , 'Dataset', 'Type', MD.[Type]
	FROM V_Dataset_Metadata MD
	WHERE (Name IN (SELECT mDst FROM #dst))
	--
	INSERT INTO #metaD(mDst, mAType, mTag, mVal)
	SELECT Name , 'Dataset', 'Operator', MD.[Operator]
	FROM V_Dataset_Metadata MD
	WHERE (Name IN (SELECT mDst FROM #dst))
	--
	INSERT INTO #metaD(mDst, mAType, mTag, mVal)
	SELECT Name , 'Dataset', 'Comment', MD.[Comment]
	FROM V_Dataset_Metadata MD
	WHERE (Name IN (SELECT mDst FROM #dst))
	--
	INSERT INTO #metaD(mDst, mAType, mTag, mVal)
	SELECT Name , 'Dataset', 'Rating', MD.[Rating]
	FROM V_Dataset_Metadata MD
	WHERE (Name IN (SELECT mDst FROM #dst))
	--
	INSERT INTO #metaD(mDst, mAType, mTag, mVal)
	SELECT Name , 'Dataset', 'Request', CONVERT(varchar(32), MD.[Request])
	FROM V_Dataset_Metadata MD
	WHERE (Name IN (SELECT mDst FROM #dst))
	--
	INSERT INTO #metaD(mDst, mAType, mTag, mVal)
	SELECT Name , 'Dataset', 'State', MD.[State]
	FROM V_Dataset_Metadata MD
	WHERE (Name IN (SELECT mDst FROM #dst))
	--
	INSERT INTO #metaD(mDst, mAType, mTag, mVal)
	SELECT Name , 'Dataset', 'Archive State', MD.[Archive State]
	FROM V_Dataset_Metadata MD
	WHERE (Name IN (SELECT mDst FROM #dst))
	--
	INSERT INTO #metaD(mDst, mAType, mTag, mVal)
	SELECT Name , 'Dataset', 'Created', CONVERT(varchar(32), MD.[Created])
	FROM V_Dataset_Metadata MD
	WHERE (Name IN (SELECT mDst FROM #dst))
	--
	INSERT INTO #metaD(mDst, mAType, mTag, mVal)
	SELECT Name , 'Dataset', 'Folder Name', MD.[Folder Name]
	FROM V_Dataset_Metadata MD
	WHERE (Name IN (SELECT mDst FROM #dst))
	--
	INSERT INTO #metaD(mDst, mAType, mTag, mVal)
	SELECT Name , 'Dataset', 'Compressed State', CONVERT(varchar(32), MD.[Compressed State])
	FROM V_Dataset_Metadata MD
	WHERE (Name IN (SELECT mDst FROM #dst))
	--
	INSERT INTO #metaD(mDst, mAType, mTag, mVal)
	SELECT Name , 'Dataset', 'Compressed Date', CONVERT(varchar(32), MD.[Compressed Date])
	FROM V_Dataset_Metadata MD
	WHERE (Name IN (SELECT mDst FROM #dst))
	--
	INSERT INTO #metaD(mDst, mAType, mTag, mVal)
	SELECT Name , 'Dataset', 'Acquisition Start', CONVERT(varchar(32), MD.[Acquisition Start])
	FROM V_Dataset_Metadata MD
	WHERE (Name IN (SELECT mDst FROM #dst))
	--
	INSERT INTO #metaD(mDst, mAType, mTag, mVal)
	SELECT Name , 'Dataset', 'Acquisition End', CONVERT(varchar(32), MD.[Acquisition End])
	FROM V_Dataset_Metadata MD
	WHERE (Name IN (SELECT mDst FROM #dst))
	--
	INSERT INTO #metaD(mDst, mAType, mTag, mVal)
	SELECT Name , 'Dataset', 'Scan Count', CONVERT(varchar(32), MD.[Scan Count])
	FROM V_Dataset_Metadata MD
	WHERE (Name IN (SELECT mDst FROM #dst))
	--
	INSERT INTO #metaD(mDst, mAType, mTag, mVal)
	SELECT Name , 'Dataset', 'File Size MB', CONVERT(varchar(32), MD.[File Size MB])
	FROM V_Dataset_Metadata MD
	WHERE (Name IN (SELECT mDst FROM #dst))
	--

	---------------------------------------------------
	-- get auxiliary data for dataset 
	-- and insert it into temporary table
	---------------------------------------------------

	INSERT INTO #metaD(mAType, mTag, mVal)
	SELECT 'Dataset', AI.Category + '.' + AI.Subcategory + '.' + AI.Item AS Tag, AI.Value
	FROM T_Dataset T INNER JOIN
	V_AuxInfo_Value AI ON T.Dataset_ID = AI.Target_ID
	WHERE (AI.Target = 'Dataset') AND 
	(T.Dataset_Num IN (SELECT mDST FROM #dst))
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      set @message = 'Error trying to insert dataset aux info metadata into temp table'
      goto Done
    end

Done:
	return @myError
GO
