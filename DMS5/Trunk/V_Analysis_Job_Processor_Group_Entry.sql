/****** Object:  View [dbo].[V_Analysis_Job_Processor_Group_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Processor_Group_Entry
AS
SELECT     ID, Group_Name AS GroupName, Group_Description AS GroupDescription, Group_Enabled AS GroupEnabled, 
                      Available_For_General_Processing AS AvailableForGeneralProcessing, '(not implemented yet)' AS ProcessorList
FROM         dbo.T_Analysis_Job_Processor_Group

GO
