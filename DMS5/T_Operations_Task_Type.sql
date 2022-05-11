/****** Object:  Table [dbo].[T_Operations_Task_Type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Operations_Task_Type](
	[Task_Type_ID] [int] IDENTITY(1,1) NOT NULL,
	[Task_Type_Name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Task_Type_Active] [tinyint] NOT NULL,
 CONSTRAINT [PK_T_Operations_Task_Type] PRIMARY KEY CLUSTERED 
(
	[Task_Type_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Operations_Task_Type] TO [DDL_Viewer] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Operations_Task_Type_Active] ******/
CREATE NONCLUSTERED INDEX [IX_T_Operations_Task_Type_Active] ON [dbo].[T_Operations_Task_Type]
(
	[Task_Type_Active] ASC,
	[Task_Type_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_t_operations_task_type_name] ******/
CREATE UNIQUE NONCLUSTERED INDEX [ix_t_operations_task_type_name] ON [dbo].[T_Operations_Task_Type]
(
	[Task_Type_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Operations_Task_Type] ADD  CONSTRAINT [DF_T_Operations_Task_Type_Task_Type_Active]  DEFAULT ((1)) FOR [Task_Type_Active]
GO
