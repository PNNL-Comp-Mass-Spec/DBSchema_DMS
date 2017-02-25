/****** Object:  View [dbo].[V_LC_Cart_Configuration_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_LC_Cart_Configuration_Entry]
AS
SELECT Config.Cart_Config_ID AS ID,
       Config.Cart_Config_Name AS Config_Name,
       Cart.Cart_Name AS Cart,
       Config.Description,
       Config.Autosampler,
	   Config.Custom_Valve_Config,
       Config.Pumps,
       Config.Primary_Injection_Volume,
       Config.Primary_Mobile_Phases,
       Config.Primary_Trap_Column,
       Config.Primary_Trap_Flow_Rate,
	   Config.Primary_Trap_Time,
	   Config.Primary_Trap_Mobile_Phase,
       Config.Primary_Analytical_Column,
       Config.Primary_Column_Temperature,
       Config.Primary_Analytical_Flow_Rate,
	   Config.Primary_Gradient,
       Config.Mass_Spec_Start_Delay,
       Config.Upstream_Injection_Volume,
       Config.Upstream_Mobile_Phases,
	   Config.Upstream_Trap_Column,
	   Config.Upstream_Trap_Flow_Rate,
       Config.Upstream_Analytical_Column,
	   Config.Upstream_Column_Temperature,
       Config.Upstream_Analytical_Flow_Rate,
       Config.Upstream_Fractionation_Profile,
	   Config.Upstream_Fractionation_Details,
       Config.Cart_Config_State
FROM T_LC_Cart_Configuration Config
     INNER JOIN T_LC_Cart Cart
       ON Config.Cart_ID = Cart.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Configuration_Entry] TO [DDL_Viewer] AS [dbo]
GO
