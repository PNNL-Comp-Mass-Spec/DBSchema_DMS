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
