/****** Object:  View [dbo].[V_LC_Cart_Settings_History_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_LC_Cart_Settings_History_List_Report
AS
SELECT     dbo.T_LC_Cart_Settings_History.ID, dbo.T_LC_Cart.Cart_Name AS Cart, dbo.T_LC_Cart_Settings_History.Date_Of_Change AS [Date of Change], 
                      dbo.T_LC_Cart_Settings_History.Entered, dbo.T_LC_Cart_Settings_History.EnteredBy AS [Entered By], 
                      dbo.T_LC_Cart_Settings_History.Valve_To_Column_Extension AS [Valve To Column Extension], 
                      dbo.T_LC_Cart_Settings_History.Valve_To_Column_Extension_Dimensions AS [Valve To Column Extension Dimensions], 
                      dbo.T_LC_Cart_Settings_History.Interface_Configuration AS [Interface Configuration], 
                      dbo.T_LC_Cart_Settings_History.Operating_Pressure AS [Operating Pressure], dbo.T_LC_Cart_Settings_History.Mixer_Volume AS [Mixer Volume], 
                      dbo.T_LC_Cart_Settings_History.Sample_Loop_Volume AS [Sample Loop Volume], 
                      dbo.T_LC_Cart_Settings_History.Sample_Loading_Time AS [Sample Loading Time], 
                      dbo.T_LC_Cart_Settings_History.Split_Flow_Rate AS [Split Flow Rate], 
                      dbo.T_LC_Cart_Settings_History.Split_Column_Dimensions AS [Split Column Dimensions], 
                      dbo.T_LC_Cart_Settings_History.Purge_Flow_Rate AS [Purge Flow Rate], dbo.T_LC_Cart_Settings_History.Purge_Volume AS [Purge Volume], 
                      dbo.T_LC_Cart_Settings_History.Purge_Column_Dimensions AS [Purge Column Dimensions], 
                      dbo.T_LC_Cart_Settings_History.Acquisition_Time AS [Acquisition Time], dbo.T_LC_Cart_Settings_History.Solvent_A AS [Solvent A], 
                      dbo.T_LC_Cart_Settings_History.Solvent_B AS [Solvent B], dbo.T_LC_Cart_Settings_History.Comment
FROM         dbo.T_LC_Cart_Settings_History INNER JOIN
                      dbo.T_LC_Cart ON dbo.T_LC_Cart_Settings_History.Cart_ID = dbo.T_LC_Cart.ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Settings_History_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Settings_History_List_Report] TO [PNL\D3M580] AS [dbo]
GO
