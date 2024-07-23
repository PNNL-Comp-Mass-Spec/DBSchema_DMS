/****** Object:  Table [dbo].[T_Instrument_Name_Bkup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Instrument_Name_Bkup](
	[IN_name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Instrument_ID] [int] NOT NULL,
	[IN_class] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IN_Group] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[IN_source_path_ID] [int] NULL,
	[IN_storage_path_ID] [int] NULL,
	[IN_capture_method] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IN_status] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IN_Room_Number] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IN_Description] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IN_Created] [datetime] NULL,
 CONSTRAINT [PK_T_Instrument_Name_Bkup] PRIMARY KEY CLUSTERED 
(
	[Instrument_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Instrument_Name_Bkup] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Instrument_Name_Bkup] ADD  CONSTRAINT [DF_T_Instrument_Name_Bkup_IN_Created]  DEFAULT (getdate()) FOR [IN_Created]
GO
