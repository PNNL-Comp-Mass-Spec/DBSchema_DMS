/****** Object:  View [dbo].[V_Data_Package_Biomaterial_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Package_Biomaterial_List_Report]
AS
SELECT DPB.Data_Package_ID AS ID,
       DPB.Name AS Biomaterial,
       DPB.Campaign,
       DPB.Type,
       DPB.[Package Comment],
       CL.[Source],
       CL.[Contact],
       CL.[Reason],
       CL.[Created],
       CL.[PI],
       CL.[Comment],
       CL.[Container],
       CL.[Location],
       CL.[Material Status],
       CL.ID AS [Cell Culture ID],
       DPB.[Item Added]
FROM dbo.T_Data_Package_Biomaterial DPB
     INNER JOIN S_V_Cell_Culture_List_Report_2 CL
       ON DPB.Biomaterial_ID = CL.ID




GO
GRANT SELECT ON [dbo].[V_Data_Package_Biomaterial_List_Report] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Biomaterial_List_Report] TO [PNL\D3M578] AS [dbo]
GO
