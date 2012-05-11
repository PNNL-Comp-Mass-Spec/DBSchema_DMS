/****** Object:  Table [dbo].[T_Storage_Path_Bkup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Storage_Path_Bkup](
	[SP_path_ID] [int] NOT NULL,
	[SP_path] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SP_vol_name_client] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SP_vol_name_server] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SP_function] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SP_instrument_name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SP_code] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SP_description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Storage_Path_Bkup] ******/
CREATE CLUSTERED INDEX [IX_T_Storage_Path_Bkup] ON [dbo].[T_Storage_Path_Bkup] 
(
	[SP_path_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO
