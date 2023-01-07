/****** Object:  View [dbo].[V_Reference_Compound_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Reference_Compound_Detail_Report]
AS
SELECT RC.Compound_ID AS compound_id,
       RC.Compound_Name AS compound_name,
       RC.description,
       RCT.Compound_Type_Name AS compound_type,
       RC.Gene_Name AS gene_or_protein,
       RC.modifications,
       Org.OG_Name AS organism,
       RC.PubChem_CID AS pub_chem_cid,
       Case When U.U_Name Is Null
            Then RC.contact_prn
            Else U.name_with_prn
       End AS contact,
       RC.created,
       C.Campaign_Num AS campaign,
       MC.Tag AS container,
       ML.Tag AS location,
       RC.Wellplate_Name AS wellplate,
       RC.Well_Number AS well,
       RC.supplier,
	  Product_ID AS product_id,
       CONVERT(varchar(32), RC.purchase_date, 101) AS purchase_date,
       RC.purity,
       RC.Purchase_Quantity AS purchase_quantity,
       RC.mass,
       YN.Description AS active
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
