/****** Object:  View [dbo].[V_LC_Cart_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_LC_Cart_Detail_Report]
AS
SELECT T.ID AS id,
       T.Cart_Name AS cart_name,
       T.Cart_Description AS description,
       S.Name AS state,
       IsNull(CartConfigQ.configcount, 0) AS configuration_count
FROM T_LC_Cart T
     INNER JOIN T_LC_Cart_State_Name S
       ON T.Cart_State_ID = S.ID
     LEFT OUTER JOIN ( SELECT Cart_ID,
                         Count(*) AS ConfigCount
                  FROM T_LC_Cart_Configuration
                  GROUP BY Cart_ID ) AS CartConfigQ
       ON CartConfigQ.Cart_ID = T.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
