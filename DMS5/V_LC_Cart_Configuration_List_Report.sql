/****** Object:  View [dbo].[V_LC_Cart_Configuration_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_LC_Cart_Configuration_List_Report]
AS
SELECT Config.Cart_Config_ID AS ID,
       Config.Cart_Config_Name AS [Config Name],
       Cart.Cart_Name AS Cart,
       Config.Description,
       Config.Autosampler,
       Config.Pumps,
       Config.Primary_Injection_Volume AS [Primary Inj Vol],
       Config.Primary_Mobile_Phases AS [Primary MP],
       Config.Primary_Trap_Column AS [Primary Trap Col],
       Config.Primary_Trap_Flow_Rate AS [Primary Trap Flow],
	   Config.Primary_Trap_Time AS [Primary Trap Time],
	   Config.Primary_Trap_Mobile_Phase AS [Primary Trap MP],
       Config.Primary_Analytical_Column AS [Primary Column],
       Config.Primary_Column_Temperature AS [Primary Temp],
       Config.Primary_Analytical_Flow_Rate AS [Primary Flow],
       Config.Mass_Spec_Start_Delay AS [MS Start Delay],
       Config.Upstream_Injection_Volume AS [Upstream Inj Vol],
       Config.Upstream_Mobile_Phases AS [Upstream MP],
       Config.Upstream_Analytical_Column AS [Upstream Column],
       Config.Upstream_Analytical_Flow_Rate AS [Upstream Flow],
       Config.Upstream_Fractionation_Profile AS [Upstream Frac Profile],
	   Dataset_Usage_Count AS [Dataset Usage],
	   Dataset_Usage_Last_Year AS [Usage Last Year],
       Config.Cart_Config_State AS [State],
       Config.Entered,
       Config.Entered_By,
       Config.Updated,
       Config.Updated_By
FROM T_LC_Cart_Configuration Config
     INNER JOIN T_LC_Cart Cart
       ON Config.Cart_ID = Cart.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Configuration_List_Report] TO [DDL_Viewer] AS [dbo]
GO
