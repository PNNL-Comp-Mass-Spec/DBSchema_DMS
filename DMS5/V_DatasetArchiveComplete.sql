/****** Object:  View [dbo].[V_DatasetArchiveComplete] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









/****** Object:  View dbo.V_DatasetArchiveComplete ******/

/****** Object:  View dbo.V_DatasetArchiveComplete    Script Date: 1/17/2001 2:15:34 PM ******/
CREATE VIEW dbo.V_DatasetArchiveComplete
AS
SELECT Dataset_Number, Folder_Name, Server_Vol, Client_Vol, 
   Storage_Path, Archive_Path, Instrument_Class, 
   Last_Update
FROM V_DatasetArchive
WHERE (Archive_State = 3)
GO
GRANT VIEW DEFINITION ON [dbo].[V_DatasetArchiveComplete] TO [DDL_Viewer] AS [dbo]
GO
