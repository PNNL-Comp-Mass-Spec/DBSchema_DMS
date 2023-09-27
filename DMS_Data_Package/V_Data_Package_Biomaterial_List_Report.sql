/****** Object:  View [dbo].[V_Data_Package_Biomaterial_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Data_Package_Biomaterial_List_Report]
AS
SELECT DPB.Data_Pkg_ID AS id,
       CL.Name AS biomaterial,
       CL.campaign,
       CL.type,
       DPB.package_comment,
       CL.source,
       CL.contact,
       CL.reason,
       CL.created,
       CL.pi,
       CL.comment,
       CL.container,
       CL.location,
       CL.material_status,
       CL.ID AS biomaterial_id,
       DPB.item_added
FROM dbo.T_Data_Package_Biomaterial DPB
     INNER JOIN S_V_Biomaterial_List_Report_2 CL
       ON DPB.Biomaterial_ID = CL.ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Biomaterial_List_Report] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_Data_Package_Biomaterial_List_Report] TO [DMS_SP_User] AS [dbo]
GO
