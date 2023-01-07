/****** Object:  View [dbo].[V_LC_Cart_Configuration_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_LC_Cart_Configuration_List_Report]
AS
SELECT Config.Cart_Config_ID AS id,
       Config.Cart_Config_Name AS config_name,
       Cart.Cart_Name AS cart,
       Config.description,
       Config.autosampler,
       Config.pumps,
       Config.Primary_Injection_Volume AS primary_inj_vol,
       Config.Primary_Mobile_Phases AS primary_mp,
       Config.Primary_Trap_Column AS primary_trap_col,
       Config.Primary_Trap_Flow_Rate AS primary_trap_flow,
	   Config.Primary_Trap_Time AS primary_trap_time,
	   Config.Primary_Trap_Mobile_Phase AS primary_trap_mp,
       Config.Primary_Analytical_Column AS primary_column,
       Config.Primary_Column_Temperature AS primary_temp,
       Config.Primary_Analytical_Flow_Rate AS primary_flow,
       Config.Mass_Spec_Start_Delay AS ms_start_delay,
       Config.Upstream_Injection_Volume AS upstream_inj_vol,
       Config.Upstream_Mobile_Phases AS upstream_mp,
       Config.Upstream_Analytical_Column AS upstream_column,
       Config.Upstream_Analytical_Flow_Rate AS upstream_flow,
       Config.Upstream_Fractionation_Profile AS upstream_frac_profile,
	   Dataset_Usage_Count AS dataset_usage,
	   Dataset_Usage_Last_Year AS usage_last_year,
       Config.Cart_Config_State AS state,
       Config.entered,
       Config.entered_by,
       Config.updated,
       Config.updated_by
FROM T_LC_Cart_Configuration Config
     INNER JOIN T_LC_Cart Cart
       ON Config.Cart_ID = Cart.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Configuration_List_Report] TO [DDL_Viewer] AS [dbo]
GO
