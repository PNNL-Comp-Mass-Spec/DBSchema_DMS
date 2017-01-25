/****** Object:  StoredProcedure [dbo].[LookupOtherFromExperimentSamplePrep] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.LookupOtherFromExperimentSamplePrep
/****************************************************
**
**	Desc: 
**		Get values for misc fields from the sample prep
**		request associated with the given experiment (if there is one) 
**
**		This procedure is used by AddUpdateRequestedRun and
**		the error messages assume that this is the case
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	06/03/2009 grk - Initial release (Ticket #499)
**			01/23/2017 mem - Provide clearer error messages
**
*****************************************************/
(
	@experimentNum varchar(64),
	@workPackage varchar(50) output,
	@message varchar(512) output
)
As
	Set nocount on

	Declare @myError int
	Declare @myRowCount int
	Set @myError = 0
	Set @myRowCount = 0
	
	Declare @n int
	
	Set @workPackage = LTrim(RTrim(@workPackage))
	Set @message = ''

	Declare @ovr varchar(10) = '(lookup)'
	
	---------------------------------------------------
	-- Find associated sample prep request for experiment
	---------------------------------------------------
	--
	Declare @samPrepID int = 0
	--
	SELECT @samPrepID = EX_sample_prep_request_ID
	FROM T_Experiments
	WHERE Experiment_Num = @experimentNum
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
		Set @message = 'Error trying to find sample prep request for the experiment'
		Return @myError
    End

	---------------------------------------------------
	-- If there is no associated sample prep request we are done
	-- However, do not allow the workpackage to be (lookup)
	---------------------------------------------------
    If @samPrepID = 0
    Begin
		If @workPackage = '' Or @workPackage = @ovr
		Begin
			If Exists (SELECT * FROM T_Experiments WHERE Experiment_Num = @experimentNum)
				Set @message = 'Work package cannot be "' + @ovr + '" when the experiment does not have a sample prep request. Please provide a valid work package.'
			Else
				Set @message = 'Unable to change the work package from "' + @ovr + '" ' + 
				               'to the one associated with the experiment because the experiment was not found: ' + @experimentNum
				
			Return 50966
		End
		Else
		Begin
			Return 0
		End
    End

	If @workPackage = '' Or @workPackage = @ovr
	Begin
		---------------------------------------------------
		-- Update the work package using the work package associated with the sample prep request
		---------------------------------------------------

		Declare @newWorkPackage varchar(50)

		SELECT @newWorkPackage = ISNULL(Work_Package_Number, '')
		FROM T_Sample_Prep_Request
		WHERE ID = @samPrepID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		If @myError <> 0
		Begin
			Set @message = 'Error determining the work package associated with the sample prep request'
			Return @myError
		End
		
	End
	
	Return 0
	
GO
GRANT VIEW DEFINITION ON [dbo].[LookupOtherFromExperimentSamplePrep] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[LookupOtherFromExperimentSamplePrep] TO [Limited_Table_Write] AS [dbo]
GO
