/****** Object:  Table [dbo].[T_Settings_Files_XML_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Settings_Files_XML_History](
	[Event_ID] [int] IDENTITY(1,1) NOT NULL,
	[Event_Action] [varchar](12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ID] [int] NOT NULL,
	[Analysis_Tool] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[File_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Contents] [xml] NULL,
	[Entered] [datetime] NOT NULL,
	[Entered_By] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Settings_Files_XML_History] PRIMARY KEY CLUSTERED 
(
	[Event_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Settings_Files_XML_History_File_Name] ******/
CREATE NONCLUSTERED INDEX [IX_T_Settings_Files_XML_History_File_Name] ON [dbo].[T_Settings_Files_XML_History] 
(
	[File_Name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Settings_Files_XML_History_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Settings_Files_XML_History_ID] ON [dbo].[T_Settings_Files_XML_History] 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Settings_Files_XML_History] ADD  CONSTRAINT [DF_T_Settings_Files_XML_History_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_Settings_Files_XML_History] ADD  CONSTRAINT [DF_T_Settings_Files_XML_History_Entered_By]  DEFAULT (suser_sname()) FOR [Entered_By]
GO
