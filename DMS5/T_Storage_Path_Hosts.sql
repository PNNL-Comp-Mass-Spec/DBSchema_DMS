/****** Object:  Table [dbo].[T_Storage_Path_Hosts] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Storage_Path_Hosts](
	[SP_machine_name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Host_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[DNS_Suffix] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[URL_Prefix] [varchar](12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Storage_Path_Hosts] PRIMARY KEY CLUSTERED 
(
	[SP_machine_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
