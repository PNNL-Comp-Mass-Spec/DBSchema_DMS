/****** Object:  View [dbo].[V_Reference_Compound_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Reference_Compound_Entry]
AS
SELECT RC.compound_id,
       RC.compound_name,
       RC.description,
       RCT.compound_type_name,
       RC.gene_name,
       RC.modifications,
       Org.OG_Name AS organism_name,
       RC.PubChem_CID AS pub_chem_cid,
       RC.contact_prn,
       RC.created,
       C.Campaign_Num AS campaign,
       MC.Tag AS container,
       RC.wellplate_name,
       RC.well_number,
       RC.supplier,
	   RC.product_id,
       CONVERT(varchar(32), RC.Purchase_Date, 101) AS purchase_date,
       RC.purity,
       RC.purchase_quantity,
       RC.mass,
       YN.Description AS [active]
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
