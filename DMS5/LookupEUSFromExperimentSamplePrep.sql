/****** Object:  StoredProcedure [dbo].[LookupEUSFromExperimentSamplePrep] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE LookupEUSFromExperimentSamplePrep
/****************************************************
**
**	Desc: 
**    Get values for EUS field from the sample prep
**    request associated with the given experiment
**    (if there is one) 
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 07/11/2007 (Ticket #499)
**            07/16/2007 grk - added check for "(lookup)"
**
*****************************************************/
	@experimentNum varchar(64),
	@eusUsageType varchar(50) output,		-- If this is "(lookup)" then will override with the EUS info from the sample prep request (if found)
	@eusProposalID varchar(10) output,		-- If this is "(lookup)" then will override with the EUS info from the sample prep request (if found)
	@eusUsersList varchar(1024) output,		-- If this is "(lookup)" then will override with the EUS info from the sample prep request (if found)
	@message varchar(512) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	declare @n int
	
	set @message = ''
	
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
      return  0
    end

	---------------------------------------------------
	-- Lookup EUS fields from sample prep request
	---------------------------------------------------

	Declare
		@eUT varchar(50),
		@ePID varchar(10),
		@eUL varchar(1024)

	SELECT
		@eUT = ISNULL(EUS_UsageType, ''),
		@ePID = ISNULL(EUS_Proposal_ID, ''),
		@eUL = ISNULL(EUS_User_List, '')
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
	declare @ovr varchar(10)
	set @ovr = '(lookup)'
	set @eusUsageType = CASE WHEN @eusUsageType = @ovr THEN @eUT ELSE @eusUsageType END
	set @eusProposalID = CASE WHEN @eusProposalID = @ovr THEN @ePID ELSE @eusProposalID END
	set @eusUsersList = CASE WHEN @eusUsersList = @ovr THEN @eUL ELSE @eusUsersList END

GO
GRANT VIEW DEFINITION ON [dbo].[LookupEUSFromExperimentSamplePrep] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[LookupEUSFromExperimentSamplePrep] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[LookupEUSFromExperimentSamplePrep] TO [PNL\D3M580] AS [dbo]
GO
