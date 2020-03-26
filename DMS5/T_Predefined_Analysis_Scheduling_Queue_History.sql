/****** Object:  Table [dbo].[T_Predefined_Analysis_Scheduling_Queue_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Predefined_Analysis_Scheduling_Queue_History](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Dataset_ID] [int] NOT NULL,
	[DS_Rating] [smallint] NOT NULL,
	[Jobs_Created] [int] NOT NULL,
	[Entered] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Predefined_Analysis_Scheduling_Queue_History] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Predefined_Analysis_Scheduling_Queue_History] TO [DDL_Viewer] AS [dbo]
GO
/****** Object:  Index [IX_T_Predefined_Analysis_Scheduling_Queue_History_Dataset_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Predefined_Analysis_Scheduling_Queue_History_Dataset_ID] ON [dbo].[T_Predefined_Analysis_Scheduling_Queue_History]
(
	[Dataset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Predefined_Analysis_Scheduling_Queue_History_Rating] ******/
CREATE NONCLUSTERED INDEX [IX_T_Predefined_Analysis_Scheduling_Queue_History_Rating] ON [dbo].[T_Predefined_Analysis_Scheduling_Queue_History]
(
	[DS_Rating] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis_Scheduling_Queue_History] ADD  CONSTRAINT [DF_T_Predefined_Analysis_Scheduling_Queue_History_Created]  DEFAULT ((0)) FOR [Jobs_Created]
GO
ALTER TABLE [dbo].[T_Predefined_Analysis_Scheduling_Queue_History] ADD  CONSTRAINT [DF_T_Predefined_Analysis_Scheduling_Queue_History_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
