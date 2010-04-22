/****** Object:  View [dbo].[V_Settings_Files_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Settings_Files_Detail_Report
AS
SELECT     ID, Analysis_Tool AS [Analysis Tool], File_Name AS [File Name], Description, Active
FROM         dbo.T_Settings_Files

GO
GRANT VIEW DEFINITION ON [dbo].[V_Settings_Files_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Settings_Files_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
