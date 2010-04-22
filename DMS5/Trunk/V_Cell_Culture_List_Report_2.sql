/****** Object:  View [dbo].[V_Cell_Culture_List_Report_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Cell_Culture_List_Report_2]
AS
SELECT U.CC_ID AS ID,
       U.CC_Name AS Name,
       U.CC_Source_Name AS Source,
       U.CC_Owner_PRN AS Contact,
       CTN.Name AS Type,
       U.CC_Reason AS Reason,
       U.CC_Created AS Created,
       U.CC_PI_PRN AS PI,
       U.CC_Comment AS Comment,
       C.Campaign_Num AS Campaign,
       MC.Tag AS Container,
       ML.Tag AS Location,
       U.CC_Material_Active AS [Material Status]
FROM dbo.T_Cell_Culture U
     INNER JOIN dbo.T_Cell_Culture_Type_Name CTN
       ON U.CC_Type = CTN.ID
     INNER JOIN dbo.T_Campaign C
       ON U.CC_Campaign_ID = C.Campaign_ID
     INNER JOIN dbo.T_Material_Containers MC
       ON U.CC_Container_ID = MC.ID
     INNER JOIN dbo.T_Material_Locations ML
       ON MC.Location_ID = ML.ID




GO
GRANT VIEW DEFINITION ON [dbo].[V_Cell_Culture_List_Report_2] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Cell_Culture_List_Report_2] TO [PNL\D3M580] AS [dbo]
GO
