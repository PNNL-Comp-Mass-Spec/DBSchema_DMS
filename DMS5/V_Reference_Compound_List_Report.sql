/****** Object:  View [dbo].[V_Reference_Compound_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Reference_Compound_List_Report]
AS
SELECT RC.Compound_ID AS id,
       RC.Compound_Name AS name,
       RC.Description AS description,
       RCT.Compound_Type_Name AS type,
       RC.Gene_Name AS gene,
       RC.modifications,
       Org.OG_Name AS organism,
       RC.PubChem_CID AS pub_chem_cid,
       ISNULL(U.u_name, RC.Contact_PRN) AS contact,
       RC.created,
       C.Campaign_Num AS campaign,
       MC.Tag AS container,
       ML.Tag AS location,
       RC.supplier,
	   Product_ID AS product_id,
       RC.Purchase_Date AS purchase_date,
       RC.purity,
       RC.Purchase_Quantity AS purchase_quantity,
       RC.mass,
       YN.Description AS active,
       RC.id_name
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
