/****** Object:  View [dbo].[V_Analysis_Job_Processors_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Processors_Entry
AS
SELECT     ID, State, Processor_Name AS ProcessorName, Machine, Notes, dbo.GetAJProcessorAnalysisToolList(ID) AS AnalysisToolsList
FROM         dbo.T_Analysis_Job_Processors

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Processors_Entry] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Processors_Entry] TO [PNL\D3M580] AS [dbo]
GO
