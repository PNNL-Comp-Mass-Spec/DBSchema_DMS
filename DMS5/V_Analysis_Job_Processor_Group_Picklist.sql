/****** Object:  View [dbo].[V_Analysis_Job_Processor_Group_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Analysis_Job_Processor_Group_Picklist
AS
SELECT ID, Group_Name, Group_Name + ' (' + CAST(ID AS varchar(12)) + ')' AS Name_With_ID
FROM T_Analysis_Job_Processor_Group;


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Processor_Group_Picklist] TO [DDL_Viewer] AS [dbo]
GO
