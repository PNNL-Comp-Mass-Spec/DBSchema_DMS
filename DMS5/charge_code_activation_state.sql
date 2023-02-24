/****** Object:  UserDefinedFunction [dbo].[ChargeCodeActivationState] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ChargeCodeActivationState]
/****************************************************
**
**  Desc:   Computes the Activation_State for a charge code, given the specified properties
**
**          WARNING: This function is used by trigger trig_u_Charge_Code to auto-define Activation_State in T_Charge_Code
**
**  Auth:   mem
**  Date:   06/07/2013 mem - Initial release
**          11/19/2013 mem - Bug fix assigning ActivationState for Inactive, old work packages
**
*****************************************************/
(
    @Deactivated varchar(1),    -- N or Y; assumed to never be null since not null in T_Charge_State
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
          WHEN @Deactivated = 'N' AND @ChargeCodeState >= 2 THEN 0                            -- Active
          WHEN @Deactivated = 'N' AND @ChargeCodeState  = 1 And @UsageCount > 0 THEN 0        -- Active
          WHEN @Deactivated = 'N' AND @ChargeCodeState  = 1 And @UsageCount = 0 THEN 1        -- Active, unused
          WHEN @Deactivated = 'N' AND @ChargeCodeState  = 0 THEN 2                            -- Active, old

          WHEN @Deactivated <> 'N' AND @ChargeCodeState >= 2 THEN 3                           -- Inactive, used
          WHEN @Deactivated <> 'N' AND @ChargeCodeState IN (0, 1) And @UsageCount > 0 THEN 3  -- Inactive, used
          WHEN @Deactivated <> 'N' AND @ChargeCodeState IN (0, 1) And @UsageCount = 0 THEN 4  -- Inactive, unused
          ELSE 5                                                                              -- Inactive, old
        END

    Return @ActivationState

END

GO
GRANT VIEW DEFINITION ON [dbo].[ChargeCodeActivationState] TO [DDL_Viewer] AS [dbo]
GO
