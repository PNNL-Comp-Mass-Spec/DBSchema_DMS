/****** Object:  Table [dbo].[T_Experiment_Group_Members] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Experiment_Group_Members](
	[Group_ID] [int] NOT NULL,
	[Exp_ID] [int] NOT NULL
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Experiment_Group_Members_1] ******/
CREATE CLUSTERED INDEX [IX_T_Experiment_Group_Members_1] ON [dbo].[T_Experiment_Group_Members] 
(
	[Group_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Experiment_Group_Members] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Experiment_Group_Members] ON [dbo].[T_Experiment_Group_Members] 
(
	[Group_ID] ASC,
	[Exp_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Experiment_Group_Members_Exp_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Experiment_Group_Members_Exp_ID] ON [dbo].[T_Experiment_Group_Members] 
(
	[Exp_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Experiment_Group_Members_GroupID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Experiment_Group_Members_GroupID] ON [dbo].[T_Experiment_Group_Members] 
(
	[Group_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO
GRANT DELETE ON [dbo].[T_Experiment_Group_Members] TO [PNL\D3M578] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Experiment_Group_Members] TO [PNL\D3M578] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Experiment_Group_Members] TO [PNL\D3M578] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Experiment_Group_Members] TO [PNL\D3M578] AS [dbo]
GO
ALTER TABLE [dbo].[T_Experiment_Group_Members]  WITH CHECK ADD  CONSTRAINT [FK_T_Experiment_Group_Members_T_Experiment_Groups] FOREIGN KEY([Group_ID])
REFERENCES [T_Experiment_Groups] ([Group_ID])
GO
ALTER TABLE [dbo].[T_Experiment_Group_Members] CHECK CONSTRAINT [FK_T_Experiment_Group_Members_T_Experiment_Groups]
GO
ALTER TABLE [dbo].[T_Experiment_Group_Members]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Experiment_Group_Members_T_Experiments] FOREIGN KEY([Exp_ID])
REFERENCES [T_Experiments] ([Exp_ID])
GO
ALTER TABLE [dbo].[T_Experiment_Group_Members] CHECK CONSTRAINT [FK_T_Experiment_Group_Members_T_Experiments]
GO
