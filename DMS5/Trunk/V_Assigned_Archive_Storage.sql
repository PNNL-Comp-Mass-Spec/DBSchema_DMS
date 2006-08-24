/****** Object:  View [dbo].[V_Assigned_Archive_Storage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW dbo.V_Assigned_Archive_Storage
AS
SELECT     T_Instrument_Name.IN_name AS Instrument_Name, T_Archive_Path.AP_archive_path AS Archive_Path, 
                      T_Archive_Path.AP_Server_Name AS Archive_Server, T_Archive_Path.AP_path_ID AS Archive_Path_ID
FROM         T_Archive_Path INNER JOIN
                      T_Instrument_Name ON T_Archive_Path.AP_instrument_name_ID = T_Instrument_Name.Instrument_ID
WHERE     (T_Archive_Path.AP_Function = 'Active')



GO
