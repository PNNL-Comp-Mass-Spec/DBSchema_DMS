/****** Object:  StoredProcedure [dbo].[DumpMetadataForMultipleDatasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE DumpMetadataForMultipleDatasets
/****************************************************
**
**	Desc: Dump metadata for datasets in given list
**
**	Return values: 0: success, otherwise, error code
**                    recordset containing keyword-value pairs
**                    for all metadata items
**
**	Parameters: 
**
**		Auth: grk
**		Date: 11/01/2006
**    
*****************************************************/
 (
  @dataset_List varchar(7000),
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
	SELECT Item FROM dbo.MakeTableFromList(@dataset_List)

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
 
 	exec @myError = LoadMetadataForMultipleDatasets @Options, @message output
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
GRANT EXECUTE ON [dbo].[DumpMetadataForMultipleDatasets] TO [DMS_User]
GO
