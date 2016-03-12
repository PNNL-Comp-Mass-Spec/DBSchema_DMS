/****** Object:  StoredProcedure [dbo].[DumpMetadataForMultipleExperiments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE DumpMetadataForMultipleExperiments
/****************************************************
**
**	Desc: Dump metadata for experiments in given list
**
**	Return values: 0: success, otherwise, error code
**                    recordset containing keyword-value pairs
**                    for all metadata items
**
**	Parameters: 
**
**		Auth: grk
**		Date: 11/1/2006
**    
*****************************************************/
 (
  @Experiment_List varchar(7000),
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
	SELECT Item FROM dbo.MakeTableFromList(@Experiment_List)

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
 
	exec @myError = LoadMetadataForMultipleExperiments @Options, @message output
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
GRANT EXECUTE ON [dbo].[DumpMetadataForMultipleExperiments] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DumpMetadataForMultipleExperiments] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DumpMetadataForMultipleExperiments] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DumpMetadataForMultipleExperiments] TO [PNL\D3M578] AS [dbo]
GO
