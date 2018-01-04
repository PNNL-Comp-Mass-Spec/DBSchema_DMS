/****** Object:  View [dbo].[V_Reference_Compound_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Reference_Compound_Detail_Report]
AS
SELECT RC.Compound_ID AS [Compound_ID],
       RC.Compound_Name AS [Compound Name],
       RC.Description,
       RCT.Compound_Type_Name AS [Compound Type],
       RC.Gene_Name AS [Gene or Protein],
       RC.Modifications,
       Org.OG_Name AS [Organism],
       RC.PubChem_CID AS [PubChem CID],
       Case When U.U_Name Is Null 
            Then RC.Contact_PRN 
            Else U.Name_with_PRN 
       End AS [Contact],
       RC.Created,
       C.Campaign_Num AS Campaign,
       MC.Tag AS Container,
       ML.Tag AS Location,
       RC.Wellplate_Name AS [Wellplate],
       RC.Well_Number AS [Well Number],
       RC.Supplier,
	  Product_ID AS [Product ID],
       CONVERT(varchar(32), RC.Purchase_Date, 101) AS [Purchase Date],
       RC.Purity,
       RC.Purchase_Quantity AS [Purchase Quantity],
       RC.Mass,
       YN.Description AS [Active]
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
GRANT VIEW DEFINITION ON [dbo].[V_Reference_Compound_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
