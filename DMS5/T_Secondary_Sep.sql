/****** Object:  Table [dbo].[T_Secondary_Sep] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Secondary_Sep](
	[SS_name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SS_ID] [int] NOT NULL,
	[SS_comment] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SS_active] [tinyint] NOT NULL,
	[Sep_Group] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Secondary_Sep] PRIMARY KEY NONCLUSTERED 
(
	[SS_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Secondary_Sep] ******/
CREATE UNIQUE CLUSTERED INDEX [IX_T_Secondary_Sep] ON [dbo].[T_Secondary_Sep] 
(
	[SS_name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO
GRANT SELECT ON [dbo].[T_Secondary_Sep] TO [DMS_LCMSNet_User] AS [dbo]
GO
GRANT ALTER ON [dbo].[T_Secondary_Sep] TO [Limited_Table_Write] AS [dbo]
GO
GRANT DELETE ON [dbo].[T_Secondary_Sep] TO [Limited_Table_Write] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Secondary_Sep] TO [Limited_Table_Write] AS [dbo]
GO
GRANT REFERENCES ON [dbo].[T_Secondary_Sep] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Secondary_Sep] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Secondary_Sep] TO [Limited_Table_Write] AS [dbo]
GO
ALTER TABLE [dbo].[T_Secondary_Sep]  WITH CHECK ADD  CONSTRAINT [FK_T_Secondary_Sep_T_Separation_Group] FOREIGN KEY([Sep_Group])
REFERENCES [T_Separation_Group] ([Sep_Group])
GO
ALTER TABLE [dbo].[T_Secondary_Sep] CHECK CONSTRAINT [FK_T_Secondary_Sep_T_Separation_Group]
GO
ALTER TABLE [dbo].[T_Secondary_Sep] ADD  CONSTRAINT [DF_T_Secondary_Sep_SS_comment]  DEFAULT ('') FOR [SS_comment]
GO
ALTER TABLE [dbo].[T_Secondary_Sep] ADD  CONSTRAINT [DF_T_Secondary_Sep_SS_active]  DEFAULT (1) FOR [SS_active]
GO
