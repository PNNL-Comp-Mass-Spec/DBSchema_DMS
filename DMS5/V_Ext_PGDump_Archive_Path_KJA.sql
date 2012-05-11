/****** Object:  View [dbo].[V_Ext_PGDump_Archive_Path_KJA] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Ext_PGDump_Archive_Path_KJA
AS
SELECT     dbo.T_Archive_Path.AP_path_ID AS id, dbo.T_Instrument_Name.IN_name AS instrument_name, dbo.T_Archive_Path.AP_archive_path AS archive_path, 
                      dbo.T_Archive_Path.Note AS note
FROM         dbo.T_Archive_Path INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Archive_Path.AP_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Archive_Path_KJA] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Archive_Path_KJA] TO [PNL\D3M580] AS [dbo]
GO
