/****** Object:  StoredProcedure [dbo].[ValidateWP] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create PROCEDURE ValidateWP
/****************************************************
**
**	Desc: 
**    Verifies that given work package exists in T_Charge_Code
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth:	mem
**	Date:	06/05/2013 mem - Initial Version
**
*****************************************************/
(
	@WorkPackage varchar(64),
	@allowNoneWP tinyint,					-- Set to 1 to allow @WorkPackage to be "none"
	@message varchar(512) output
)
As
	set nocount on

	Declare @myError int = 0
	
	Set @WorkPackage = IsNull(@WorkPackage, '')
	Set @allowNoneWP = IsNull(@allowNoneWP, 0)
	Set @message = ''
	
	If IsNull(@WorkPackage, '') = ''
	Begin
		set @message = 'Work package cannot be blank'
		Set @myError = 130
	End
	
	If @myError = 0 And @allowNoneWP > 0 And @WorkPackage = 'none'
	Begin
		-- Allow the work package to be 'none'
		Set @myError = 0
	End
	Else
	Begin
		
		If @myError = 0 And @WorkPackage IN ('none', 'na', 'n/a', '(none)')
		Begin
			set @message = 'A valid work package must be provided; see http://dms2.pnl.gov/helper_charge_code/report'
			Set @myError = 131
		End
			
		If @myError = 0 And Not Exists (SELECT * FROM T_Charge_Code Where Charge_Code = @WorkPackage)
		Begin
			set @message = 'Could not find entry in database for Work Package "' + @WorkPackage + '"; see http://dms2.pnl.gov/helper_charge_code/report'
			Set @myError = 132
		End
	End
		
	return @myError

GO
