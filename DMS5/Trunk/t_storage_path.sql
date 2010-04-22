/****** Object:  Table [dbo].[t_storage_path] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[t_storage_path](
	[SP_path_ID] [int] IDENTITY(10,1) NOT NULL,
	[SP_path] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SP_machine_name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SP_vol_name_client] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SP_vol_name_server] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SP_function] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SP_instrument_name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SP_code] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SP_description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_t_storage_path] PRIMARY KEY NONCLUSTERED 
(
	[SP_path_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_t_storage_path_Machine_Name_Path_ID] ******/
CREATE NONCLUSTERED INDEX [IX_t_storage_path_Machine_Name_Path_ID] ON [dbo].[t_storage_path] 
(
	[SP_machine_name] ASC,
	[SP_path_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO
