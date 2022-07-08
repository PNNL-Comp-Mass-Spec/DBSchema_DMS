/****** Object:  View [dbo].[V_Biomaterial_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Biomaterial_Entry]
AS
SELECT U.CC_Name AS [name],
       U.CC_Source_Name AS source_name,
       U.CC_Contact_PRN AS contact_prn,
       U.CC_PI_PRN AS pi_prn,
       CTN.Name AS biomaterial_type_name,
       U.CC_Reason AS reason,
       U.CC_Comment AS comment,
       C.Campaign_Num AS campaign,
       MC.Tag AS container,
       dbo.GetBiomaterialOrganismList(U.CC_ID) AS organism_list,
       U.Mutation AS mutation,
       U.Plasmid AS plasmid,
       U.cell_line
FROM T_Cell_Culture U
     INNER JOIN T_Cell_Culture_Type_Name CTN
       ON U.CC_Type = CTN.ID
     INNER JOIN T_Campaign C
       ON U.CC_Campaign_ID = C.Campaign_ID
     INNER JOIN T_Material_Containers MC
       ON U.CC_Container_ID = MC.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Biomaterial_Entry] TO [DDL_Viewer] AS [dbo]
GO
