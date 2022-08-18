/****** Object:  Table [dbo].[T_SP_Authorization] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_SP_Authorization](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[ProcedureName] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[LoginName] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[HostName] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Host_IP] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_SP_Authorization] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_SP_Authorization_LoginName] ******/
CREATE NONCLUSTERED INDEX [IX_T_SP_Authorization_LoginName] ON [dbo].[T_SP_Authorization]
(
	[LoginName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_SP_Authorization_ProcName] ******/
CREATE NONCLUSTERED INDEX [IX_T_SP_Authorization_ProcName] ON [dbo].[T_SP_Authorization]
(
	[ProcedureName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_SP_Authorization_unique_Procedure_Login_Host_IP] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_SP_Authorization_unique_Procedure_Login_Host_IP] ON [dbo].[T_SP_Authorization]
(
	[ProcedureName] ASC,
	[LoginName] ASC,
	[Host_IP] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_SP_Authorization_unique_Procedure_Login_Host_Name] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_SP_Authorization_unique_Procedure_Login_Host_Name] ON [dbo].[T_SP_Authorization]
(
	[ProcedureName] ASC,
	[LoginName] ASC,
	[HostName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_SP_Authorization] ADD  CONSTRAINT [DF_T_SP_Authorization_Host_IP]  DEFAULT ('') FOR [Host_IP]
GO
