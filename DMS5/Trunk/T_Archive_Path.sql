/****** Object:  Table [dbo].[T_Archive_Path] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Archive_Path](
	[AP_instrument_name_ID] [int] NOT NULL,
	[AP_archive_path] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AP_path_ID] [int] IDENTITY(110,1) NOT NULL,
	[Note] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AP_Function] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AP_Server_Name] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AP_network_share_path] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Archive_Path] PRIMARY KEY NONCLUSTERED 
(
	[AP_path_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT ALTER ON [dbo].[T_Archive_Path] TO [D3L243] AS [dbo]
GO
ALTER TABLE [dbo].[T_Archive_Path]  WITH CHECK ADD  CONSTRAINT [FK_T_Archive_Path_T_Archive_Path_Function] FOREIGN KEY([AP_Function])
REFERENCES [T_Archive_Path_Function] ([APF_Function])
GO
ALTER TABLE [dbo].[T_Archive_Path] CHECK CONSTRAINT [FK_T_Archive_Path_T_Archive_Path_Function]
GO
