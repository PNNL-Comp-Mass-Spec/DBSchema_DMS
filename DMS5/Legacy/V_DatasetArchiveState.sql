/****** Object:  View [dbo].[V_DatasetArchiveState] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_DatasetArchiveState
AS
SELECT dbo.V_DatasetArchive.Dataset_Number, 
   dbo.T_DatasetArchiveStateName.DASN_StateName AS State, 
   dbo.V_DatasetArchive.Folder_Name, 
   dbo.V_DatasetArchive.Server_Vol, 
   dbo.V_DatasetArchive.Client_Vol, 
   dbo.V_DatasetArchive.Storage_Path, 
   dbo.V_DatasetArchive.Archive_Path, 
   dbo.V_DatasetArchive.Instrument_Class, 
   dbo.V_DatasetArchive.Last_Update, 
   dbo.V_DatasetArchive.Instrument_Name
FROM dbo.V_DatasetArchive INNER JOIN
   dbo.T_DatasetArchiveStateName ON 
   dbo.V_DatasetArchive.Archive_State = dbo.T_DatasetArchiveStateName.DASN_StateID

GO
GRANT VIEW DEFINITION ON [dbo].[V_DatasetArchiveState] TO [DDL_Viewer] AS [dbo]
GO
