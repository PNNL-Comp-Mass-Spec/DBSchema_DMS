/****** Object:  View [dbo].[V_Experiment_User_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Experiment_User_Picklist]
AS
SELECT DISTINCT U.U_PRN AS Username,
                U.U_Name AS Name
FROM T_Users U
     INNER JOIN T_Experiments E
       ON E.EX_researcher_PRN = U.U_PRN
WHERE E.EX_created > DateAdd(month, -12, GetDate()) AND
      U.U_Status = 'Active'


GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_User_Picklist] TO [DDL_Viewer] AS [dbo]
GO
