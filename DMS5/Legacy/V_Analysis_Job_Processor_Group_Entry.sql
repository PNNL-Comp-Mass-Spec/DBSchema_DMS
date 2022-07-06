/****** Object:  View [dbo].[V_Analysis_Job_Processor_Group_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Processor_Group_Entry]
AS
SELECT id,
       group_name,
       group_description,
       group_enabled,
       x_Available_For_General_Processing AS available_for_general_processing,
       '(not implemented yet)' AS processor_list
FROM dbo.T_Analysis_Job_Processor_Group


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Processor_Group_Entry] TO [DDL_Viewer] AS [dbo]
GO
