/****** Object:  View [dbo].[V_Data_Package_Datasets_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Data_Package_Datasets_List_Report
AS
SELECT        DPD.Data_Package_ID AS ID, DPD.Dataset, DPD.Dataset_ID, DPD.Experiment, DPD.Instrument, DPD.[Package Comment], DL.Campaign, DL.State, DL.Created, 
                         DL.Rating, DL.[Dataset Folder Path], DL.[Archive Folder Path], DL.[Acq Start], DL.[Acq. End], DL.[Acq Length], DL.[Scan Count], DL.[LC Column], DL.[Separation Type], 
                         DL.[Blocking Factor], DL.Block, DL.[Run Order], DL.Request, DPD.[Item Added], DL.Comment, DL.[Dataset Type] AS Type, DL.[EMSL Proposal]
FROM            dbo.T_Data_Package_Datasets AS DPD INNER JOIN
                         dbo.S_V_Dataset_List_Report_2 AS DL ON DPD.Dataset_ID = DL.ID

GO
GRANT SELECT ON [dbo].[V_Data_Package_Datasets_List_Report] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Datasets_List_Report] TO [PNL\D3M578] AS [dbo]
GO
