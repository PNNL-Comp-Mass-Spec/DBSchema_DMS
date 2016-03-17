/****** Object:  View [dbo].[V_LC_Cart_Settings_History_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_LC_Cart_Settings_History_Entry
AS
SELECT     CONVERT(varchar, MONTH(dbo.T_LC_Cart_Settings_History.Date_Of_Change)) + '/' + CONVERT(varchar, 
                      DAY(dbo.T_LC_Cart_Settings_History.Date_Of_Change)) + '/' + CONVERT(varchar, YEAR(dbo.T_LC_Cart_Settings_History.Date_Of_Change)) 
                      AS DateOfChange, dbo.T_LC_Cart_Settings_History.ID, dbo.T_LC_Cart_Settings_History.Valve_To_Column_Extension AS ValveToColumnExtension, 
                      dbo.T_LC_Cart_Settings_History.Valve_To_Column_Extension_Dimensions AS ValveToColumnExtensionDimensions, 
                      dbo.T_LC_Cart_Settings_History.Operating_Pressure AS OperatingPressure, 
                      dbo.T_LC_Cart_Settings_History.Interface_Configuration AS InterfaceConfiguration, dbo.T_LC_Cart_Settings_History.Mixer_Volume AS MixerVolume, 
                      dbo.T_LC_Cart_Settings_History.Sample_Loop_Volume AS SampleLoopVolume, 
                      dbo.T_LC_Cart_Settings_History.Sample_Loading_Time AS SampleLoadingTime, dbo.T_LC_Cart_Settings_History.Split_Flow_Rate AS SplitFlowRate, 
                      dbo.T_LC_Cart_Settings_History.Split_Column_Dimensions AS SplitColumnDimensions, 
                      dbo.T_LC_Cart_Settings_History.Purge_Flow_Rate AS PurgeFlowRate, 
                      dbo.T_LC_Cart_Settings_History.Purge_Column_Dimensions AS PurgeColumnDimensions, 
                      dbo.T_LC_Cart_Settings_History.Purge_Volume AS PurgeVolume, dbo.T_LC_Cart_Settings_History.Acquisition_Time AS AcquisitionTime, 
                      dbo.T_LC_Cart_Settings_History.Comment, dbo.T_LC_Cart.Cart_Name AS CartName, dbo.T_LC_Cart_Settings_History.Entered, 
                      dbo.T_LC_Cart_Settings_History.EnteredBy, dbo.T_LC_Cart_Settings_History.Solvent_A AS SolventA, 
                      dbo.T_LC_Cart_Settings_History.Solvent_B AS SolventB
FROM         dbo.T_LC_Cart_Settings_History INNER JOIN
                      dbo.T_LC_Cart ON dbo.T_LC_Cart_Settings_History.Cart_ID = dbo.T_LC_Cart.ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Settings_History_Entry] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Settings_History_Entry] TO [PNL\D3M580] AS [dbo]
GO
