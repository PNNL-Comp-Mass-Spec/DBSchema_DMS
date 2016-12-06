/****** Object:  View [dbo].[V_Processor_Tool_For_Manager] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Processor_Tool_For_Manager
AS
SELECT     Processor_Name AS MgrName, Tool_Name AS Tool, Enabled AS EnabledShort
FROM         dbo.T_Processor_Tool

GO
GRANT VIEW DEFINITION ON [dbo].[V_Processor_Tool_For_Manager] TO [DDL_Viewer] AS [dbo]
GO
