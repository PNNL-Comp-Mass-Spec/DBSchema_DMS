/****** Object:  Table [dbo].[T_Analysis_Job_Status_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Job_Status_History](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Posting_Time] [smalldatetime] NOT NULL,
	[Tool_ID] [int] NOT NULL,
	[State_ID] [int] NOT NULL,
	[Job_Count] [int] NOT NULL,
 CONSTRAINT [PK_T_Analysis_Job_Status_History] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Analysis_Job_Status_History_State_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_Status_History_State_ID] ON [dbo].[T_Analysis_Job_Status_History] 
(
	[State_ID] ASC
) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Analysis_Job_Status_History_Tool_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_Status_History_Tool_ID] ON [dbo].[T_Analysis_Job_Status_History] 
(
	[Tool_ID] ASC
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Status_History]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_Status_History_T_Analysis_State_Name] FOREIGN KEY([State_ID])
REFERENCES [T_Analysis_State_Name] ([AJS_stateID])
GO
ALTER TABLE [dbo].[T_Analysis_Job_Status_History]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_Status_History_T_Analysis_Tool] FOREIGN KEY([Tool_ID])
REFERENCES [T_Analysis_Tool] ([AJT_toolID])
GO
