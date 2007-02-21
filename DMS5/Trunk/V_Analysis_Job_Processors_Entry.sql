/****** Object:  View [dbo].[V_Analysis_Job_Processors_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Analysis_Job_Processors_Entry
AS
SELECT 
    ID AS ID, 
    State AS State, 
    Processor_Name AS ProcessorName, 
    Machine AS Machine, 
    Notes AS Notes
FROM T_Analysis_Job_Processors

GO
