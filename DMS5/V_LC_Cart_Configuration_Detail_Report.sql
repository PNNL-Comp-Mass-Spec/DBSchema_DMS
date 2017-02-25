/****** Object:  View [dbo].[V_LC_Cart_Configuration_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_LC_Cart_Configuration_Detail_Report]
AS
SELECT Config.Cart_Config_ID AS ID,
       Config.Cart_Config_Name AS Config_Name,
       Cart.Cart_Name AS Cart,
       Config.Description,
       Config.Autosampler,
	   Config.Custom_Valve_Config As [Custom Valve Config],
       Config.Pumps,
       Config.Primary_Injection_Volume As [Primary Injection Volume],
       Config.Primary_Mobile_Phases As [Primary Mobile Phases],
       Config.Primary_Trap_Column As [Primary Trap Column],
       Config.Primary_Trap_Flow_Rate As [Primary Trap Flow Rate],
       Config.Primary_Trap_Time AS [Primary Trap Time],
	   Config.Primary_Trap_Mobile_Phase AS [Primary Trap Mobile Phase],
	   Config.Primary_Analytical_Column As [Primary Analytical Column],
       Config.Primary_Column_Temperature As [Primary Column Temperature],
       Config.Primary_Analytical_Flow_Rate As [Primary Analytical Flow Rate],
	   Config.Primary_Gradient As [Primary Gradient],
       Config.Mass_Spec_Start_Delay As [Mass Spec Start Delay],
       Config.Upstream_Injection_Volume As [Upstream Injection Volume],
       Config.Upstream_Mobile_Phases As [Upstream Mobile Phases],
	   Config.Upstream_Trap_Column As [Upstream Trap Column],
	   Config.Upstream_Trap_Flow_Rate As [Upstream Trap Flow Rate],
       Config.Upstream_Analytical_Column As [Upstream Analytical Column],
	   Config.Upstream_Column_Temperature As [Upstream Column Temperature],
       Config.Upstream_Analytical_Flow_Rate As [Upstream Analytical Flow Rate],
       Config.Upstream_Fractionation_Profile As [Upstream Fractionation Profile],
	   Config.Upstream_Fractionation_Details As [Upstream Fractionation Details],
       Dataset_Usage_Count AS [Dataset Usage],
	   Dataset_Usage_Last_Year AS [Dataset Usage Last Year],
       Config.Cart_Config_State As [Cart Config State],
       Config.Entered,
       U1.Name_with_PRN AS [Entered By],
       Config.Updated,
       U2.Name_with_PRN AS [Updated By]
FROM T_LC_Cart_Configuration Config
     INNER JOIN T_LC_Cart Cart
       ON Config.Cart_ID = Cart.ID
     INNER JOIN T_Users AS U1
       ON Config.Entered_By = U1.U_PRN
     LEFT OUTER JOIN T_Users AS U2
       ON Config.Updated_By = U2.U_PRN


GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Configuration_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
