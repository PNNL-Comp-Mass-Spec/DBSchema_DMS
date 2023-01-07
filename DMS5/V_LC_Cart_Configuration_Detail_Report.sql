/****** Object:  View [dbo].[V_LC_Cart_Configuration_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_LC_Cart_Configuration_Detail_Report]
AS
SELECT Config.Cart_Config_ID AS id,
       Config.Cart_Config_Name AS config_name,
       Cart.Cart_Name AS cart,
       Config.description,
       Config.autosampler,
	   Config.Custom_Valve_Config As custom_valve_config,
       Config.pumps,
       Config.Primary_Injection_Volume As primary_injection_volume,
       Config.Primary_Mobile_Phases As primary_mobile_phases,
       Config.Primary_Trap_Column As primary_trap_column,
       Config.Primary_Trap_Flow_Rate As primary_trap_flow_rate,
       Config.Primary_Trap_Time AS primary_trap_time,
	   Config.Primary_Trap_Mobile_Phase AS primary_trap_mobile_phase,
	   Config.Primary_Analytical_Column As primary_analytical_column,
       Config.Primary_Column_Temperature As primary_column_temperature,
       Config.Primary_Analytical_Flow_Rate As primary_analytical_flow_rate,
	   Config.Primary_Gradient As primary_gradient,
       Config.Mass_Spec_Start_Delay As mass_spec_start_delay,
       Config.Upstream_Injection_Volume As upstream_injection_volume,
       Config.Upstream_Mobile_Phases As upstream_mobile_phases,
	   Config.Upstream_Trap_Column As upstream_trap_column,
	   Config.Upstream_Trap_Flow_Rate As upstream_trap_flow_rate,
       Config.Upstream_Analytical_Column As upstream_analytical_column,
	   Config.Upstream_Column_Temperature As upstream_column_temperature,
       Config.Upstream_Analytical_Flow_Rate As upstream_analytical_flow_rate,
       Config.Upstream_Fractionation_Profile As upstream_fractionation_profile,
	   Config.Upstream_Fractionation_Details As upstream_fractionation_details,
       Dataset_Usage_Count AS dataset_usage,
	   Dataset_Usage_Last_Year AS dataset_usage_last_year,
       Config.Cart_Config_State As cart_config_state,
       Cart.ID AS cart_id,
       Config.entered,
       U1.Name_with_PRN AS entered_by,
       Config.updated,
       U2.Name_with_PRN AS updated_by
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
