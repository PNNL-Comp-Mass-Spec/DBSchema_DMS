/****** Object:  View [dbo].[V_Reference_Compound_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Reference_Compound_Entry]
AS
SELECT RC.Compound_ID,
       RC.Compound_Name,
       RC.Description,
       RCT.Compound_Type_Name,
       Org.OG_Name AS Organism_Name,
       RC.PubChem_CID,
       RC.Contact_PRN,
       RC.Created,
       C.Campaign_Num AS Campaign,
       MC.Tag AS Container,
       RC.Wellplate_Name,
       RC.Well_Number,
       RC.Supplier,
	  Product_ID,
       CONVERT(varchar(32), RC.Purchase_Date, 101) AS [Purchase_Date],
       RC.Purity,
       RC.Purchase_Quantity,
       RC.Mass,
       RC.Modifications,
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
     INNER JOIN dbo.T_YesNo YN
       ON RC.Active = YN.Flag
     LEFT OUTER JOIN T_Users U
       ON RC.Contact_PRN = U.U_PRN


GO
GRANT VIEW DEFINITION ON [dbo].[V_Reference_Compound_Entry] TO [DDL_Viewer] AS [dbo]
GO
