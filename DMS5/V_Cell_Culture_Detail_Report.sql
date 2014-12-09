/****** Object:  View [dbo].[V_Cell_Culture_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Cell_Culture_Detail_Report]
AS
SELECT U.CC_Name AS [Name or Peptide],
       U.CC_Source_Name AS Supplier,
       Case When U_Contact.U_Name Is Null 
            Then U.CC_Contact_PRN 
            Else U_Contact.Name_with_PRN 
       End AS [Contact (usually PNNL Staff)],
       U_PI.Name_with_PRN AS PI,
       CTN.Name AS [Type],
       U.CC_Reason AS Reason,
       U.CC_Comment AS [Comment],
       C.Campaign_Num AS Campaign,
       U.CC_ID AS ID,
       MC.Tag AS Container,
       L.Tag AS Location,
       U.Gene_Name AS [Gene Name],
       U.Gene_Location AS [Gene Location],
       U.Mod_Count AS [Mod Count],
       U.Modifications AS [Modifications],
       U.Mass AS [Peptide Mass],
       CONVERT(varchar(32), U.Purchase_Date, 101) AS [Purchase Date],
       U.Peptide_Purity AS [Peptide Purity],
       U.Purchase_Quantity AS [Purchase Quantity],
       U.CC_Material_Active AS [Material Status]
FROM T_Cell_Culture U
     INNER JOIN T_Cell_Culture_Type_Name CTN
       ON U.CC_Type = CTN.ID
     INNER JOIN T_Campaign C
       ON U.CC_Campaign_ID = C.Campaign_ID
     INNER JOIN T_Material_Containers MC
       ON U.CC_Container_ID = MC.ID
     INNER JOIN T_Material_Locations L
       ON MC.Location_ID = L.ID
     LEFT OUTER JOIN T_Users U_Contact
       ON U.CC_Contact_PRN = U_Contact.U_PRN
     LEFT OUTER JOIN T_Users U_PI
       ON U.CC_PI_PRN = U_PI.U_PRN


GO
GRANT VIEW DEFINITION ON [dbo].[V_Cell_Culture_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Cell_Culture_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
