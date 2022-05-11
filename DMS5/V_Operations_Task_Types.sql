/****** Object:  View [dbo].[V_Operations_Task_Types] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Operations_Task_Types]
AS
SELECT Task_Type_Name
FROM T_Operations_Task_Type
WHERE Task_Type_Active > 0


GO
GRANT VIEW DEFINITION ON [dbo].[V_Operations_Task_Types] TO [DDL_Viewer] AS [dbo]
GO
