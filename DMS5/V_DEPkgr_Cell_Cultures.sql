/****** Object:  View [dbo].[V_DEPkgr_Cell_Cultures] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_DEPkgr_Cell_Cultures]
AS
SELECT U.CC_ID AS Culture_ID,
       U.CC_Name AS Biomaterial_Source_Name,
       U.CC_Reason AS Reason_For_Preparation,
       U.CC_Comment AS Comments,
       U.CC_Source_Name AS Material_Source,
       Source_Names.U_Name AS Owner_Name,
       PI_Names.U_Name AS PI_Name,
       U.CC_Campaign_ID AS Campaign_ID,
       C.Campaign_Num AS Campaign_Name
FROM T_Cell_Culture U
     LEFT OUTER JOIN T_Campaign C
       ON U.CC_Campaign_ID = C.Campaign_ID
     LEFT OUTER JOIN T_Users PI_Names
       ON U.CC_PI_PRN = PI_Names.U_PRN
     LEFT OUTER JOIN T_Users Source_Names
       ON U.CC_Contact_PRN = Source_Names.U_PRN


GO
GRANT VIEW DEFINITION ON [dbo].[V_DEPkgr_Cell_Cultures] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_DEPkgr_Cell_Cultures] TO [PNL\D3M580] AS [dbo]
GO
