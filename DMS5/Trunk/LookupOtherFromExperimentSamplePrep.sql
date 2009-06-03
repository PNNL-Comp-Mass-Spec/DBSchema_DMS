/****** Object:  StoredProcedure [dbo].[LookupOtherFromExperimentSamplePrep] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[LookupOtherFromExperimentSamplePrep]
/****************************************************
**
**	Desc: 
**    Get values for misc fields from the sample prep
**    request associated with the given experiment
**    (if there is one) 
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 06/03/2009 - initial release (Ticket #499)
**
*****************************************************/
	@experimentNum varchar(64),
	@workPackage varchar(50) output,
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
		if (@workPackage = @ovr)
		begin
			set @message = 'Trying to look up information, but experiment has no sample prep request'
			return  50966
		end
		else
			return  0
    end

	---------------------------------------------------
	-- Lookup EUS fields from sample prep request
	---------------------------------------------------

	Declare
		@eWP varchar(50)

	SELECT
		@eWP = ISNULL(Work_Package_Number, '')
	FROM 
		T_Sample_Prep_Request
	WHERE 
		(ID = @samPrepID)
	--
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      set @message = 'Error looking up fields'
      return  @myError
    end

	---------------------------------------------------
	-- handle overrides
	---------------------------------------------------
	set @workPackage = CASE WHEN @workPackage = @ovr THEN @eWP ELSE @workPackage END

GO
