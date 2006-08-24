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
) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Experiment_Group_Members] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Experiment_Group_Members] ON [dbo].[T_Experiment_Group_Members] 
(
	[Group_ID] ASC,
	[Exp_ID] ASC
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Experiment_Group_Members]  WITH CHECK ADD  CONSTRAINT [FK_T_Experiment_Group_Members_T_Experiment_Groups] FOREIGN KEY([Group_ID])
REFERENCES [T_Experiment_Groups] ([Group_ID])
GO
ALTER TABLE [dbo].[T_Experiment_Group_Members]  WITH CHECK ADD  CONSTRAINT [FK_T_Experiment_Group_Members_T_Experiments] FOREIGN KEY([Exp_ID])
REFERENCES [T_Experiments] ([Exp_ID])
GO
