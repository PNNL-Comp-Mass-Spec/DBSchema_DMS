/****** Object:  Table [dbo].[T_Requested_Run_State_Name] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Requested_Run_State_Name](
	[State_Name] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[State_ID] [tinyint] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK_T_Requested_Run_State_Name] PRIMARY KEY CLUSTERED 
(
	[State_Name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Requested_Run_State_Name] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Requested_Run_State_Name] ON [dbo].[T_Requested_Run_State_Name] 
(
	[State_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
GO
