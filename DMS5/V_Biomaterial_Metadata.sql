/****** Object:  View [dbo].[V_Biomaterial_Metadata] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Biomaterial_Metadata]
AS
SELECT U.CC_Name AS Name,
       U.CC_ID AS ID,
       U.CC_Source_Name AS Source,
       CASE WHEN U_Contact.U_Name Is Null
            THEN U.CC_Contact_PRN
            ELSE U_Contact.Name_with_PRN
       END AS Source_Contact,
       U_PI.Name_with_PRN AS PI,
       CTN.Name AS Type,
       U.CC_Reason AS Reason,
       U.CC_Comment AS Comment,
       C.Campaign_Num AS Campaign
FROM T_Cell_Culture U
     INNER JOIN T_Cell_Culture_Type_Name CTN
       ON U.CC_Type = CTN.ID
     INNER JOIN T_Campaign C
       ON U.CC_Campaign_ID = C.Campaign_ID
     LEFT OUTER JOIN T_Users U_Contact
       ON U.CC_Contact_PRN = U_Contact.U_PRN
     LEFT OUTER JOIN T_Users U_PI
       ON U.CC_PI_PRN = U_PI.U_PRN

GO
GRANT VIEW DEFINITION ON [dbo].[V_Biomaterial_Metadata] TO [DDL_Viewer] AS [dbo]
GO
