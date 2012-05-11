/****** Object:  View [dbo].[V_Capture_Step_Tools_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Capture_Step_Tools_List_Report
AS
SELECT     Name, Description, Bionet_Required, Only_On_Storage_Server, Instrument_Capacity_Limited, ID, Holdoff_Interval_Minutes, Number_Of_Retries, 
                      Processor_Assignment_Applies
FROM         dbo.T_Step_Tools

GO
