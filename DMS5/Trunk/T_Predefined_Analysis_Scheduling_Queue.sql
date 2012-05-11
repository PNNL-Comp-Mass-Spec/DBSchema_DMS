/****** Object:  Table [dbo].[T_Predefined_Analysis_Scheduling_Queue] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Predefined_Analysis_Scheduling_Queue](
	[Item] [int] IDENTITY(1,1) NOT NULL,
	[Dataset_Num] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Dataset_ID] [int] NOT NULL,
	[CallingUser] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AnalysisToolNameFilter] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ExcludeDatasetsNotReleased] [tinyint] NULL,
	[PreventDuplicateJobs] [tinyint] NULL,
	[State] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Result_Code] [int] NULL,
	[Message] [varchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Jobs_Created] [int] NOT NULL,
	[Entered] [datetime] NOT NULL,
	[Last_Affected] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Predefined_Analysis_Scheduling_Queue] PRIMARY KEY CLUSTERED 
(
	[Item] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Predefined_Analysis_Scheduling_Queue_Dataset_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Predefined_Analysis_Scheduling_Queue_Dataset_ID] ON [dbo].[T_Predefined_Analysis_Scheduling_Queue] 
(
	[Dataset_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Predefined_Analysis_Scheduling_Queue_State] ******/
CREATE NONCLUSTERED INDEX [IX_T_Predefined_Analysis_Scheduling_Queue_State] ON [dbo].[T_Predefined_Analysis_Scheduling_Queue] 
(
	[State] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO
/****** Object:  Trigger [dbo].[trig_u_Predefined_Analysis_Scheduling_Queue] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create Trigger trig_u_Predefined_Analysis_Scheduling_Queue on T_Predefined_Analysis_Scheduling_Queue
For Update
/****************************************************
**
**	Desc: 
**		Updates Last_Affected in T_Predefined_Analysis_Scheduling_Queue
**
**	Auth:	mem
**	Date:	08/26/2010
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	If Update([State])
	Begin
		UPDATE T_Predefined_Analysis_Scheduling_Queue
		SET Last_Affected = GetDate()
		FROM T_Predefined_Analysis_Scheduling_Queue Q INNER JOIN
			 inserted ON Q.Item = inserted.Item

	End

GO
ALTER TABLE [dbo].[T_Predefined_Analysis_Scheduling_Queue]  WITH CHECK ADD  CONSTRAINT [FK_T_Predefined_Analysis_Scheduling_Queue_T_Predefined_Analysis_Scheduling_Queue_State] FOREIGN KEY([State])
REFERENCES [T_Predefined_Analysis_Scheduling_Queue_State] ([State])
GO
ALTER TABLE [dbo].[T_Predefined_Analysis_Scheduling_Queue] CHECK CONSTRAINT [FK_T_Predefined_Analysis_Scheduling_Queue_T_Predefined_Analysis_Scheduling_Queue_State]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis_Scheduling_Queue] ADD  CONSTRAINT [DF_T_Predefined_Analysis_Scheduling_Queue_AnalysisToolNameFilter]  DEFAULT ('') FOR [AnalysisToolNameFilter]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis_Scheduling_Queue] ADD  CONSTRAINT [DF_T_Predefined_Analysis_Scheduling_Queue_ExcludeDatasetsNotReleased]  DEFAULT ((1)) FOR [ExcludeDatasetsNotReleased]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis_Scheduling_Queue] ADD  CONSTRAINT [DF_T_Predefined_Analysis_Scheduling_Queue_PreventDuplicateJobs]  DEFAULT ((1)) FOR [PreventDuplicateJobs]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis_Scheduling_Queue] ADD  CONSTRAINT [DF_T_Predefined_Analysis_Scheduling_Queue_State]  DEFAULT ('New') FOR [State]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis_Scheduling_Queue] ADD  CONSTRAINT [DF_T_Predefined_Analysis_Scheduling_Queue_Jobs_Created]  DEFAULT ((0)) FOR [Jobs_Created]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis_Scheduling_Queue] ADD  CONSTRAINT [DF_T_Predefined_Analysis_Scheduling_Queue_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis_Scheduling_Queue] ADD  CONSTRAINT [DF_T_Predefined_Analysis_Scheduling_Queue_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
