/****** Object:  View [dbo].[V_Operations_Tasks_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
DROP TABLE [dbo].[T_Operations_Tasks]
CREATE TABLE [dbo].[T_Operations_Tasks]
    (
      [ID] [int] IDENTITY(1,1) NOT NULL ,
      Tab VARCHAR(64) ,
      Requestor VARCHAR(64) ,
      Requested_Personal VARCHAR(256) ,
      Assigned_Personal VARCHAR(256) ,
      [Description] VARCHAR(5132) NOT NULL  ,
      Comments VARCHAR(MAX) ,
      [Status] VARCHAR(32)  NOT NULL ,
      [Priority] VARCHAR(32) ,
      Created DATETIME
        CONSTRAINT [PK_T_Operations_Tasks] PRIMARY KEY CLUSTERED ( [ID] ASC )
    )
ALTER TABLE [dbo].[T_Operations_Tasks] ADD  CONSTRAINT [DF_T_Operations_Tasks_Created]  DEFAULT (getdate()) FOR [Created]
ALTER TABLE [dbo].[T_Operations_Tasks] ADD  CONSTRAINT [DF_T_Operations_Tasks_Status]  DEFAULT ('Normal') FOR [Status]
*/
CREATE VIEW dbo.V_Operations_Tasks_List_Report
AS
SELECT     ID, Tab, Description, Assigned_Personal AS [Assigned Personal], Comments, Status, Priority, DATEDIFF(DAY, Created, GETDATE()) AS Days_In_Queue, Created
FROM         dbo.T_Operations_Tasks

GO
