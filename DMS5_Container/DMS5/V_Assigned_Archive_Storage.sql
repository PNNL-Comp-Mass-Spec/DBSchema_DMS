/****** Object:  View [dbo].[V_Assigned_Archive_Storage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Assigned_Archive_Storage
AS
SELECT     dbo.T_Instrument_Name.IN_name AS Instrument_Name, dbo.T_Archive_Path.AP_archive_path AS Archive_Path, 
                      dbo.T_Archive_Path.AP_Server_Name AS Archive_Server, dbo.T_Archive_Path.AP_path_ID AS Archive_Path_ID
FROM         dbo.T_Archive_Path INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Archive_Path.AP_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID
WHERE     (dbo.T_Archive_Path.AP_Function = 'Active')

GO
GRANT VIEW DEFINITION ON [dbo].[V_Assigned_Archive_Storage] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Assigned_Archive_Storage] TO [PNL\D3M580] AS [dbo]
GO
