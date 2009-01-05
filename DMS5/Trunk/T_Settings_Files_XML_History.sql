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
	[Entered] [datetime] NOT NULL CONSTRAINT [DF_T_Settings_Files_XML_History_Entered]  DEFAULT (getdate()),
	[Entered_By] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_T_Settings_Files_XML_History_Entered_By]  DEFAULT (suser_sname()),
 CONSTRAINT [PK_T_Settings_Files_XML_History] PRIMARY KEY CLUSTERED 
(
	[Event_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Settings_Files_XML_History_File_Name] ******/
CREATE NONCLUSTERED INDEX [IX_T_Settings_Files_XML_History_File_Name] ON [dbo].[T_Settings_Files_XML_History] 
(
	[File_Name] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Settings_Files_XML_History_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Settings_Files_XML_History_ID] ON [dbo].[T_Settings_Files_XML_History] 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO
