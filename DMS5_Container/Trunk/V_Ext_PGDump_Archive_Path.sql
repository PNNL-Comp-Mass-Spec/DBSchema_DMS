/****** Object:  View [dbo].[V_Ext_PGDump_Archive_Path] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Ext_PGDump_Archive_Path
AS
SELECT     AP.AP_path_ID AS id, INN.IN_name AS instrument_name, AP.AP_archive_path AS archive_path, AP.Note, D.Dataset_ID AS ds_id
FROM         dbo.T_Archive_Path AS AP INNER JOIN
                      dbo.T_Instrument_Name AS INN ON AP.AP_instrument_name_ID = INN.Instrument_ID INNER JOIN
                      dbo.T_Dataset_Archive AS DA ON DA.AS_storage_path_ID = AP.AP_path_ID INNER JOIN
                      dbo.T_Dataset AS D ON DA.AS_Dataset_ID = D.Dataset_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Archive_Path] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Archive_Path] TO [PNL\D3M580] AS [dbo]
GO
