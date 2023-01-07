/****** Object:  View [dbo].[V_LC_Cart_Settings_History_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_LC_Cart_Settings_History_Detail_Report
AS
SELECT dbo.T_LC_Cart_Settings_History.id, dbo.T_LC_Cart.Cart_Name AS cart, dbo.T_LC_Cart_Settings_History.Date_Of_Change AS date_of_change,
       dbo.T_LC_Cart_Settings_History.entered, dbo.T_LC_Cart_Settings_History.EnteredBy AS entered_by,
       dbo.T_LC_Cart_Settings_History.Valve_To_Column_Extension AS valve_to_column_extension,
       dbo.T_LC_Cart_Settings_History.Valve_To_Column_Extension_Dimensions AS valve_to_column_extension_dimensions,
       dbo.T_LC_Cart_Settings_History.Interface_Configuration AS interface_configuration,
       dbo.T_LC_Cart_Settings_History.Operating_Pressure AS operating_pressure, dbo.T_LC_Cart_Settings_History.Mixer_Volume AS mixer_volume,
       dbo.T_LC_Cart_Settings_History.Sample_Loop_Volume AS sample_loop_volume,
       dbo.T_LC_Cart_Settings_History.Sample_Loading_Time AS sample_loading_time,
       dbo.T_LC_Cart_Settings_History.Split_Flow_Rate AS split_flow_rate,
       dbo.T_LC_Cart_Settings_History.Split_Column_Dimensions AS split_column_dimensions,
       dbo.T_LC_Cart_Settings_History.Purge_Flow_Rate AS purge_flow_rate, dbo.T_LC_Cart_Settings_History.Purge_Volume AS purge_volume,
       dbo.T_LC_Cart_Settings_History.Purge_Column_Dimensions AS purge_column_dimensions,
       dbo.T_LC_Cart_Settings_History.Acquisition_Time AS acquisition_time, dbo.T_LC_Cart_Settings_History.Solvent_A AS solvent_a,
       dbo.T_LC_Cart_Settings_History.Solvent_B AS solvent_b, dbo.T_LC_Cart_Settings_History.comment
FROM dbo.T_LC_Cart_Settings_History INNER JOIN
     dbo.T_LC_Cart ON dbo.T_LC_Cart_Settings_History.Cart_ID = dbo.T_LC_Cart.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Settings_History_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
