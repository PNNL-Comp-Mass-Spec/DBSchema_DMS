/****** Object:  View [dbo].[V_Biomaterial_List_Report_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Biomaterial_List_Report_2]
AS
SELECT U.CC_ID AS id,
       U.CC_Name AS name,
       U.CC_Source_Name AS source,
       ISNULL(U_Contact.u_name, U.CC_Contact_PRN) AS contact,
       CTN.Name AS type,
       U.CC_Reason AS reason,
       U.CC_Created AS created,
       ISNULL(U_PI.U_Name, U.CC_PI_PRN) AS pi,
       U.CC_Comment AS comment,
       C.Campaign_Num AS campaign,
       MC.Tag AS container,
       ML.Tag AS location,
       Cached_Organism_List AS organisms,
       U.mutation,
       U.plasmid,
       U.Cell_Line As cell_line,
       U.CC_Material_Active AS material_status
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
GRANT VIEW DEFINITION ON [dbo].[V_Biomaterial_List_Report_2] TO [DDL_Viewer] AS [dbo]
GO
