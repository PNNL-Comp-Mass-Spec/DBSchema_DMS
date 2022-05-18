/****** Object:  View [dbo].[V_LC_Cart_Configuration_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_LC_Cart_Configuration_Entry]
AS
SELECT Config.Cart_Config_ID AS id,
       Config.Cart_Config_Name AS config_name,
       Config.description,
       Config.autosampler,
	   Config.custom_valve_config,
       Config.pumps,
       Config.primary_injection_volume,
       Config.primary_mobile_phases,
       Config.primary_trap_column,
       Config.primary_trap_flow_rate,
	   Config.primary_trap_time,
	   Config.primary_trap_mobile_phase,
       Config.primary_analytical_column,
       Config.primary_column_temperature,
       Config.primary_analytical_flow_rate,
	   Config.primary_gradient,
       Config.mass_spec_start_delay,
       Config.upstream_injection_volume,
       Config.upstream_mobile_phases,
	   Config.upstream_trap_column,
	   Config.upstream_trap_flow_rate,
       Config.upstream_analytical_column,
	   Config.upstream_column_temperature,
       Config.upstream_analytical_flow_rate,
       Config.upstream_fractionation_profile,
	   Config.upstream_fractionation_details,
       Config.cart_config_state,
	   Config.entered_by
FROM T_LC_Cart_Configuration Config
     INNER JOIN T_LC_Cart Cart
       ON Config.Cart_ID = Cart.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Configuration_Entry] TO [DDL_Viewer] AS [dbo]
GO
