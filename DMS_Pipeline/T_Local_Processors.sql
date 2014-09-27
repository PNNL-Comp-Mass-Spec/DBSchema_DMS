/****** Object:  Table [dbo].[T_Local_Processors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Local_Processors](
	[ID] [int] NOT NULL,
	[Processor_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[State] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ProcTool_Mgr_ID] [smallint] NOT NULL,
	[Groups] [int] NULL,
	[GP_Groups] [int] NULL,
	[Machine] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Latest_Request] [datetime] NULL,
	[Manager_Version] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Local_Processors] PRIMARY KEY CLUSTERED 
(
	[Processor_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Local_Processors_Machine] ******/
CREATE NONCLUSTERED INDEX [IX_T_Local_Processors_Machine] ON [dbo].[T_Local_Processors]
(
	[Machine] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Local_Processors_ProcTool_Mgr_ID_Machine_include_Processor_Name] ******/
CREATE NONCLUSTERED INDEX [IX_T_Local_Processors_ProcTool_Mgr_ID_Machine_include_Processor_Name] ON [dbo].[T_Local_Processors]
(
	[ProcTool_Mgr_ID] ASC,
	[Machine] ASC
)
INCLUDE ( 	[Processor_Name]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Local_Processors] ADD  CONSTRAINT [DF_T_Local_Processors_ProcTool_Mgr_Instance]  DEFAULT ((1)) FOR [ProcTool_Mgr_ID]
GO
ALTER TABLE [dbo].[T_Local_Processors] ADD  CONSTRAINT [DF_T_Local_PipelineProcessors_Groups]  DEFAULT ((0)) FOR [Groups]
GO
