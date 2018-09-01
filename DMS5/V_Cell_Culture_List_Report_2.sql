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
       ISNULL(U_Contact.U_Name, U.CC_Contact_PRN) AS [Contact], 
       CTN.Name AS [Type],
       U.CC_Reason AS Reason,
       U.CC_Created AS Created,
       ISNULL(U_PI.U_Name, U.CC_PI_PRN) AS PI,
       U.CC_Comment AS Comment,
       C.Campaign_Num AS Campaign,
       MC.Tag AS Container,
       ML.Tag AS Location,
       Cached_Organism_List AS Organisms,
       U.Mutation,
       U.Plasmid,
       U.Cell_Line As [Cell Line],
       U.CC_Material_Active AS [Material Status]
FROM T_Cell_Culture U
     INNER JOIN T_Cell_Culture_Type_Name CTN
       ON U.CC_Type = CTN.ID
     INNER JOIN T_Campaign C
       ON U.CC_Campaign_ID = C.Campaign_ID
     INNER JOIN T_Material_Containers MC
       ON U.CC_Container_ID = MC.ID
     INNER JOIN T_Material_Locations ML
       ON MC.Location_ID = ML.ID
     LEFT OUTER JOIN T_Users U_Contact
       ON U.CC_Contact_PRN = U_Contact.U_PRN
     LEFT OUTER JOIN T_Users U_PI
       ON U.CC_PI_PRN = U_PI.U_PRN


GO
GRANT VIEW DEFINITION ON [dbo].[V_Cell_Culture_List_Report_2] TO [DDL_Viewer] AS [dbo]
GO
