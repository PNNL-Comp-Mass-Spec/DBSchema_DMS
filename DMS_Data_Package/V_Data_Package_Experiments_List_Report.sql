/****** Object:  View [dbo].[V_Data_Package_Experiments_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Data_Package_Experiments_List_Report]
AS
SELECT DPE.Data_Pkg_ID AS id,
       EL.experiment,
       EL.campaign,
       DPE.package_comment,
       EL.researcher,
       EL.organism,
       EL.reason,
       EL.comment,
       EL.concentration,
       EL.created,
       EL.biomaterial_list,
       EL.tissue,
       EL.enzyme,
       EL.labelling,
       EL.predigest,
       EL.postdigest,
       EL.request,
       DPE.item_added
FROM dbo.T_Data_Package_Experiments DPE
     INNER JOIN S_V_Experiment_List_Report_2 EL
       ON EL.ID = DPE.Experiment_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Experiments_List_Report] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_Data_Package_Experiments_List_Report] TO [DMS_SP_User] AS [dbo]
GO
