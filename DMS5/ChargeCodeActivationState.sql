/****** Object:  UserDefinedFunction [dbo].[ChargeCodeActivationState] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[ChargeCodeActivationState]
/****************************************************
**
**	Desc:	Computes the Activation_State for a charge code, given the specified properties
**
**			WARNING: This function is used by the persisted, computed column Activation_State in T_Charge_Code
**
**	Auth:	mem
**	Date:	06/07/2013 mem - Initial release
**    
*****************************************************/
(
	@Deactivated varchar(1),	-- N or Y; assumed to never be null since not null in T_Charge_State
	@ChargeCodeState smallint,	
	@UsageSamplePrep int,
	@UsageRequestedRun int
)
RETURNS tinyint
AS
BEGIN
	Declare @ActivationState tinyint
	Declare @UsageCount int = ISNULL(@UsageSamplePrep, 0) + ISNULL(@UsageRequestedRun, 0)
	
	Set @ChargeCodeState = ISNULL(@ChargeCodeState, 0)
			
	SET @ActivationState = 
		CASE
		  WHEN @Deactivated = 'N' AND @ChargeCodeState >= 2 THEN 0
          WHEN @Deactivated = 'N' AND @ChargeCodeState  = 1 And @UsageCount > 0 THEN 0
          WHEN @Deactivated = 'N' AND @ChargeCodeState  = 1 And @UsageCount = 0 THEN 1
          WHEN @Deactivated = 'N' AND @ChargeCodeState  = 0 THEN 2
          
          WHEN @Deactivated = 'Y' AND @ChargeCodeState >= 2 THEN 3
          WHEN @Deactivated = 'Y' AND @ChargeCodeState IN (0, 1) And @UsageCount > 0 THEN 3
          WHEN @Deactivated = 'Y' AND @ChargeCodeState IN (0, 1) And @UsageCount = 0 THEN 4
          ELSE 4
        END
		
	Return @ActivationState
		
END


GO
