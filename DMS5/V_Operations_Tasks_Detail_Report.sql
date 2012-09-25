/****** Object:  View [dbo].[V_Operations_Tasks_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Operations_Tasks_Detail_Report
AS
SELECT     ID, Tab, Description, Assigned_Personal AS [Assigned Personal], Comments, Status, Priority, DATEDIFF(DAY, Created, GETDATE()) AS Days_In_Queue, Requestor, 
                      Requested_Personal AS [Requested Personal], Created
FROM         dbo.T_Operations_Tasks

GO
