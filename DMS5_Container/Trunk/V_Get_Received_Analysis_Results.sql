/****** Object:  View [dbo].[V_Get_Received_Analysis_Results] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




create view V_Get_Received_Analysis_Results
as
SELECT     
	Job, 
	Dataset, 
	StorageVol, 
	StorageVolExternal,
	StoragePath, 
	DatasetFolder, 
	StorageServer, 
	Processor, 
	ResultsFolder, 
	ServerRelativeTransferPath, 
	ClientFullTransferPath
FROM V_Analysis_Results
WHERE State = 3



GO
GRANT VIEW DEFINITION ON [dbo].[V_Get_Received_Analysis_Results] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Get_Received_Analysis_Results] TO [PNL\D3M580] AS [dbo]
GO
