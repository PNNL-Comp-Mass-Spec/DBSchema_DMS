/****** Object:  View [dbo].[V_Data_Package_Experiments_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Package_Experiments_List_Report]
AS
SELECT DPE.Data_Package_ID AS ID,
       DPE.Experiment,
       EL.[Campaign],
       DPE.[Package Comment],
       EL.[Researcher],
       EL.[Organism],
       EL.[Reason],
       EL.[Comment],
       EL.[Concentration],
       EL.[Created],
       EL.[Cell Cultures],
       EL.[Enzyme],
       EL.[Labelling],
       EL.[Predigest],
       EL.[Postdigest],
       EL.[Request],
       [Item Added]
FROM dbo.T_Data_Package_Experiments DPE
     INNER JOIN S_V_Experiment_List_Report_2 EL
       ON EL.ID = DPE.Experiment_ID


GO
GRANT SELECT ON [dbo].[V_Data_Package_Experiments_List_Report] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Experiments_List_Report] TO [PNL\D3M578] AS [dbo]
GO
