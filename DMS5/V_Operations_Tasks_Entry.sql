/****** Object:  View [dbo].[V_Operations_Tasks_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Operations_Tasks_Entry]
AS
    SELECT  ID,
            Tab,
            Requester,
            Requested_Personnel AS RequestedPersonnel,
            Assigned_Personnel AS AssignedPersonnel,
            Description,
            Comments,
            Status,
            Priority,
            Work_Package,
            Created,
            Hours_Spent AS HoursSpent
    FROM    T_Operations_Tasks


GO
GRANT VIEW DEFINITION ON [dbo].[V_Operations_Tasks_Entry] TO [DDL_Viewer] AS [dbo]
GO
