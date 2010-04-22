/****** Object:  StoredProcedure [dbo].[LookupInstrumentRunInfoFromExperimentSamplePrep] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE LookupInstrumentRunInfoFromExperimentSamplePrep
/****************************************************
**
**	Desc: 
**    Get values for instrument releated fields 
**    from the sample prep request associated with
**    the given experiment (if there is one) 
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 09/06/2007 (Ticket #512 http://prismtrac.pnl.gov/trac/ticket/512)
**
*****************************************************/
	@experimentNum varchar(64),
	@instrumentName varchar(64) output,
	@DatasetType varchar(20) output,
	@instrumentSettings varchar(512) output,
	@message varchar(512) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	declare @n int
	
	set @message = ''

	declare @ovr varchar(10)
	set @ovr = '(lookup)'
	
	---------------------------------------------------
	-- Find associated sample prep request for experiment
	---------------------------------------------------
	declare @samPrepID int
	set @samPrepID = 0
	--
	SELECT @samPrepID = EX_sample_prep_request_ID
	FROM T_Experiments
	WHERE Experiment_Num = @experimentNum
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      set @message = 'Error trying to find sample prep request'
      return  @myError
    end

	---------------------------------------------------
	-- If there is no associated sample prep request
	-- we are done
	---------------------------------------------------
    if @samPrepID = 0
    begin
		if (@instrumentName = @ovr) or (@DatasetType = @ovr) or (@instrumentSettings = @ovr)
		begin
			set @message = 'Trying to look up instrument run information, but experiment has no sample prep request'
			return  50966
		end
		else
			return  0
    end

	---------------------------------------------------
	-- Lookup instrument fields from sample prep request
	---------------------------------------------------

	Declare
		@irInstName varchar(64),
		@irDSType varchar(20),
		@irInstSettings varchar(512)

	SELECT
		@irInstName = ISNULL(Instrument_Name, ''),
		@irDSType = ISNULL(Dataset_Type, ''),
		@irInstSettings = ISNULL(Instrument_Analysis_Specifications, '')
	FROM 
		T_Sample_Prep_Request
	WHERE 
		(ID = @samPrepID)
	--
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      set @message = 'Error looking up EUS fields'
      return  @myError
    end

	---------------------------------------------------
	-- handle overrides
	---------------------------------------------------
	set @instrumentName = CASE WHEN @instrumentName = @ovr THEN @irInstName ELSE @instrumentName END
	set @DatasetType = CASE WHEN @DatasetType = @ovr THEN @irDSType ELSE @DatasetType END
	set @instrumentSettings = CASE WHEN @instrumentSettings = @ovr THEN @irInstSettings ELSE @instrumentSettings END

GO
GRANT VIEW DEFINITION ON [dbo].[LookupInstrumentRunInfoFromExperimentSamplePrep] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[LookupInstrumentRunInfoFromExperimentSamplePrep] TO [PNL\D3M580] AS [dbo]
GO
