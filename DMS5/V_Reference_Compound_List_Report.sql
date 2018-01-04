/****** Object:  View [dbo].[V_Reference_Compound_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Reference_Compound_List_Report]
AS
SELECT RC.Compound_ID AS ID,
       RC.Compound_Name AS [Name],
       RC.Description AS Description,
       RCT.Compound_Type_Name AS [Type],
       RC.Gene_Name AS Gene,
       RC.Modifications,
       Org.OG_Name AS [Organism],
       RC.PubChem_CID AS [PubChem CID],
       ISNULL(U.U_Name, RC.Contact_PRN) AS [Contact], 
       RC.Created,
       C.Campaign_Num AS Campaign,
       MC.Tag AS Container,
       ML.Tag AS Location,
       RC.Supplier,
	  Product_ID AS [Product ID],
       RC.Purchase_Date AS [Purchase Date],
       RC.Purity,
       RC.Purchase_Quantity AS [Purchase Quantity],
       RC.Mass,
       YN.Description AS [Active],
       RC.ID_Name
FROM dbo.T_Reference_Compound RC
     INNER JOIN dbo.T_Campaign C
       ON RC.Campaign_ID = C.Campaign_ID
     INNER JOIN dbo.T_Reference_Compound_Type_Name RCT 
       ON RC.Compound_Type_ID = RCT.Compound_Type_ID
     INNER JOIN dbo.T_Organisms Org
       ON RC.Organism_ID = Org.Organism_ID
     INNER JOIN dbo.T_Material_Containers MC
       ON RC.Container_ID = MC.ID
     INNER JOIN dbo.T_Material_Locations ML
       ON MC.Location_ID = ML.ID
     INNER JOIN dbo.T_YesNo YN
       ON RC.Active = YN.Flag
     LEFT OUTER JOIN T_Users U
       ON RC.Contact_PRN = U.U_PRN


GO
GRANT VIEW DEFINITION ON [dbo].[V_Reference_Compound_List_Report] TO [DDL_Viewer] AS [dbo]
GO
