/****** Object:  View [dbo].[V_Biomaterial_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Biomaterial_Detail_Report]
AS
SELECT U.CC_Name AS [Name],
       U.CC_Source_Name AS Supplier,
       CASE
           WHEN U_Contact.U_Name IS NULL THEN U.CC_Contact_PRN
           ELSE U_Contact.Name_with_PRN
       END AS [Contact (usually PNNL Staff)],
       CTN.Name AS [Type],
       U.CC_Reason AS Reason,
       U.CC_Created AS Created,
       U_PI.Name_with_PRN AS PI,
       U.CC_Comment AS [Comment],
       C.Campaign_Num AS Campaign,
       U.CC_ID AS ID,
       MC.Tag AS Container,
       ML.Tag AS [Location],
       dbo.GetBiomaterialOrganismList(U.CC_ID) AS Organism_List,
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
GRANT VIEW DEFINITION ON [dbo].[V_Biomaterial_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
