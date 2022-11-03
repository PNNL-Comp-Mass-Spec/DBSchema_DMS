/****** Object:  View [dbo].[V_Biomaterial_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Biomaterial_Report]
AS

SELECT U.CC_Name AS Name,
       U.CC_Source_Name AS Source,
       U.CC_Contact_PRN AS Contact,
       CTN.Name AS [Type],
       U.CC_Reason AS Reason,
       U.CC_Created AS Created,
       U.CC_PI_PRN AS PI,
       U.CC_Comment AS [Comment],
       C.Campaign_Num AS Campaign,
       U.CC_ID AS id
FROM T_Cell_Culture U
     INNER JOIN T_Cell_Culture_Type_Name CTN
       ON U.CC_Type = CTN.ID
     INNER JOIN T_Campaign C
       ON U.CC_Campaign_ID = C.Campaign_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Biomaterial_Report] TO [DDL_Viewer] AS [dbo]
GO
