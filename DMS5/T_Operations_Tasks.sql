/****** Object:  Table [dbo].[T_Operations_Tasks] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Operations_Tasks](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Task_Type_ID] [int] NOT NULL,
	[Tab] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Requester] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Requested_Personnel] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Assigned_Personnel] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Description] [varchar](5132) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Comments] [varchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Lab_ID] [int] NOT NULL,
	[Status] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Priority] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Created] [datetime] NULL,
	[Work_Package] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Closed] [datetime] NULL,
	[Hours_Spent] [varchar](12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Operations_Tasks] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Operations_Tasks] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Operations_Tasks] ADD  CONSTRAINT [DF_T_Operations_Tasks_Task_Type_ID]  DEFAULT ((1)) FOR [Task_Type_ID]
GO
ALTER TABLE [dbo].[T_Operations_Tasks] ADD  CONSTRAINT [DF_T_Operations_Tasks_Lab_ID]  DEFAULT ((100)) FOR [Lab_ID]
GO
ALTER TABLE [dbo].[T_Operations_Tasks] ADD  CONSTRAINT [DF_T_Operations_Tasks_Status]  DEFAULT ('Normal') FOR [Status]
GO
ALTER TABLE [dbo].[T_Operations_Tasks] ADD  CONSTRAINT [DF_T_Operations_Tasks_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[T_Operations_Tasks]  WITH CHECK ADD  CONSTRAINT [FK_T_Operations_Tasks_T_Lab_Locations] FOREIGN KEY([Lab_ID])
REFERENCES [dbo].[T_Lab_Locations] ([Lab_ID])
GO
ALTER TABLE [dbo].[T_Operations_Tasks] CHECK CONSTRAINT [FK_T_Operations_Tasks_T_Lab_Locations]
GO
ALTER TABLE [dbo].[T_Operations_Tasks]  WITH CHECK ADD  CONSTRAINT [FK_T_Operations_Tasks_T_Operations_Task_Type] FOREIGN KEY([Task_Type_ID])
REFERENCES [dbo].[T_Operations_Task_Type] ([Task_Type_ID])
GO
ALTER TABLE [dbo].[T_Operations_Tasks] CHECK CONSTRAINT [FK_T_Operations_Tasks_T_Operations_Task_Type]
GO
