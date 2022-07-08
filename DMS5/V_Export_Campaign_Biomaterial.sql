/****** Object:  View [dbo].[V_Export_Campaign_Biomaterial] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Export_Campaign_Biomaterial
AS
SELECT C.Campaign_Num AS Campaign,
       CC.CC_Name AS Biomaterial, 
       CC.CC_ID AS Biomaterial_ID
FROM dbo.T_Campaign C INNER JOIN
     dbo.T_Cell_Culture CC ON C.Campaign_ID = CC.CC_Campaign_ID
;

GO
