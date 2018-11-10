/****** Object:  Table [dbo].[T_Experiment_Plex_Members] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Experiment_Plex_Members](
	[Plex_Exp_ID] [int] NOT NULL,
	[Channel] [tinyint] NOT NULL,
	[Exp_ID] [int] NOT NULL,
	[Channel_Type_ID] [tinyint] NOT NULL,
	[Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Experiment_Plex_Members] PRIMARY KEY CLUSTERED 
(
	[Plex_Exp_ID] ASC,
	[Channel] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Experiment_Plex_Members]  WITH CHECK ADD  CONSTRAINT [FK_T_Experiment_Plex_Members_T_Experiment_Plex_Channel_Type_Name] FOREIGN KEY([Channel_Type_ID])
REFERENCES [dbo].[T_Experiment_Plex_Channel_Type_Name] ([Channel_Type_ID])
GO
ALTER TABLE [dbo].[T_Experiment_Plex_Members] CHECK CONSTRAINT [FK_T_Experiment_Plex_Members_T_Experiment_Plex_Channel_Type_Name]
GO
ALTER TABLE [dbo].[T_Experiment_Plex_Members]  WITH CHECK ADD  CONSTRAINT [FK_T_Experiment_Plex_Members_T_Experiments_Channel_Exp] FOREIGN KEY([Exp_ID])
REFERENCES [dbo].[T_Experiments] ([Exp_ID])
GO
ALTER TABLE [dbo].[T_Experiment_Plex_Members] CHECK CONSTRAINT [FK_T_Experiment_Plex_Members_T_Experiments_Channel_Exp]
GO
ALTER TABLE [dbo].[T_Experiment_Plex_Members]  WITH CHECK ADD  CONSTRAINT [FK_T_Experiment_Plex_Members_T_Experiments_Plex_Exp] FOREIGN KEY([Plex_Exp_ID])
REFERENCES [dbo].[T_Experiments] ([Exp_ID])
GO
ALTER TABLE [dbo].[T_Experiment_Plex_Members] CHECK CONSTRAINT [FK_T_Experiment_Plex_Members_T_Experiments_Plex_Exp]
GO
