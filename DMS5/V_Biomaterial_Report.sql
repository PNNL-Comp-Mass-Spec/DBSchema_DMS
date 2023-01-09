/****** Object:  View [dbo].[V_Biomaterial_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Biomaterial_Report]
AS

SELECT U.CC_Name AS name,
       U.CC_Source_Name AS source,
       U.CC_Contact_PRN AS contact,
       CTN.Name AS [type],
       U.CC_Reason AS reason,
       U.CC_Created AS created,
       U.CC_PI_PRN AS pi,
       U.CC_Comment AS [comment],
       C.Campaign_Num AS campaign,
       U.CC_ID AS id
FROM T_Cell_Culture U
     INNER JOIN T_Cell_Culture_Type_Name CTN
       ON U.CC_Type = CTN.ID
     INNER JOIN T_Campaign C
       ON U.CC_Campaign_ID = C.Campaign_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Biomaterial_Report] TO [DDL_Viewer] AS [dbo]
GO
