/****** Object:  Table [dbo].[T_Experiment_Groups] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Experiment_Groups](
	[Group_ID] [int] IDENTITY(1,1) NOT NULL,
	[EG_Group_Type] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[EG_Created] [datetime] NOT NULL,
	[EG_Description] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Parent_Exp_ID] [int] NOT NULL,
	[Prep_LC_Run_ID] [int] NULL,
	[Researcher] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Tab] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Experiment_Groups] PRIMARY KEY CLUSTERED 
(
	[Group_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Experiment_Groups] ******/
CREATE NONCLUSTERED INDEX [IX_T_Experiment_Groups] ON [dbo].[T_Experiment_Groups] 
(
	[Group_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Experiment_Groups_ParentExpID_GroupID_IncludeTypeCreatedDescription] ******/
CREATE NONCLUSTERED INDEX [IX_T_Experiment_Groups_ParentExpID_GroupID_IncludeTypeCreatedDescription] ON [dbo].[T_Experiment_Groups] 
(
	[Parent_Exp_ID] ASC,
	[Group_ID] ASC
)
INCLUDE ( [EG_Group_Type],
[EG_Created],
[EG_Description]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
GRANT DELETE ON [dbo].[T_Experiment_Groups] TO [PNL\D3M578] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Experiment_Groups] TO [PNL\D3M578] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Experiment_Groups] TO [PNL\D3M578] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Experiment_Groups] TO [PNL\D3M578] AS [dbo]
GO
ALTER TABLE [dbo].[T_Experiment_Groups]  WITH CHECK ADD  CONSTRAINT [FK_T_Experiment_Groups_T_Experiments] FOREIGN KEY([Parent_Exp_ID])
REFERENCES [T_Experiments] ([Exp_ID])
GO
ALTER TABLE [dbo].[T_Experiment_Groups] CHECK CONSTRAINT [FK_T_Experiment_Groups_T_Experiments]
GO
ALTER TABLE [dbo].[T_Experiment_Groups]  WITH CHECK ADD  CONSTRAINT [FK_T_Experiment_Groups_T_Users] FOREIGN KEY([Researcher])
REFERENCES [T_Users] ([U_PRN])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Experiment_Groups] CHECK CONSTRAINT [FK_T_Experiment_Groups_T_Users]
GO
ALTER TABLE [dbo].[T_Experiment_Groups] ADD  CONSTRAINT [DF_T_Experiment_Groups_Parent_Exp_ID]  DEFAULT ((0)) FOR [Parent_Exp_ID]
GO
