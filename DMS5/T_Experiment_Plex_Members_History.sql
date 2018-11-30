/****** Object:  Table [dbo].[T_Experiment_Plex_Members_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Experiment_Plex_Members_History](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Plex_Exp_ID] [int] NOT NULL,
	[Channel] [tinyint] NOT NULL,
	[Exp_ID] [int] NOT NULL,
	[State] [tinyint] NOT NULL,
	[Entered] [datetime] NULL,
	[Entered_By] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Experiment_Plex_Members_History] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT UPDATE ON [dbo].[T_Experiment_Plex_Members_History] ([Entered_By]) TO [DMS2_SP_User] AS [dbo]
GO
ALTER TABLE [dbo].[T_Experiment_Plex_Members_History] ADD  CONSTRAINT [DF_T_Experiment_Plex_Members_History_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_Experiment_Plex_Members_History] ADD  CONSTRAINT [DF_T_Experiment_Plex_Members_History_Entered_By]  DEFAULT (suser_sname()) FOR [Entered_By]
GO
