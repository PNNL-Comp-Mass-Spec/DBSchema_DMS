/****** Object:  View [dbo].[V_LCMSNet_Column_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_LCMSNet_Column_Export]
AS
SELECT LC.SC_Column_Number AS ColumnNumber,
       LC.SC_State AS StateID,
       LCSN.LCS_Name AS State,
       LC.SC_Created AS Created,
       LC.SC_Operator_PRN AS Operator,
       LC.SC_Comment AS [Comment],
       LC.ID
FROM T_LC_Column LC
     INNER JOIN T_LC_Column_State_Name LCSN
       ON LC.SC_State = LCSN.LCS_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_LCMSNet_Column_Export] TO [DDL_Viewer] AS [dbo]
GO
