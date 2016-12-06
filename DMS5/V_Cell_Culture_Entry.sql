/****** Object:  View [dbo].[V_Cell_Culture_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Cell_Culture_Entry]
AS
SELECT U.CC_Name AS Name_or_Peptide,
       U.CC_Source_Name,
       U.CC_Contact_PRN,
       U.CC_PI_PRN,
       CTN.Name AS CultureTypeName,
       U.CC_Reason,
       U.CC_Comment,
       C.Campaign_Num,
       MC.Tag AS Container,
	   dbo.GetBiomaterialOrganismList(U.CC_ID) AS Organism_List,
       U.Gene_Name,
       U.Gene_Location,
       U.Mod_Count,
       U.Modifications,
       U.Mass,
       CONVERT(varchar(32), U.Purchase_Date, 101) AS Purchase_Date,
       U.Peptide_Purity,
       U.Purchase_Quantity
FROM T_Cell_Culture U
     INNER JOIN T_Cell_Culture_Type_Name CTN
       ON U.CC_Type = CTN.ID
     INNER JOIN T_Campaign C
       ON U.CC_Campaign_ID = C.Campaign_ID
     INNER JOIN T_Material_Containers MC
       ON U.CC_Container_ID = MC.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Cell_Culture_Entry] TO [DDL_Viewer] AS [dbo]
GO
