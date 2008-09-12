/****** Object:  Table [dbo].[T_Settings_Files] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Settings_Files](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Analysis_Tool] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[File_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_T_Settings_Files_Description]  DEFAULT (''),
	[Active] [tinyint] NULL CONSTRAINT [DF_T_Settings_Files_Active]  DEFAULT ((1)),
	[Last_Updated] [datetime] NULL,
	[Contents] [xml] NULL,
 CONSTRAINT [PK_T_Settings_Files] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Settings_Files_Analysis_Tool_File_Name] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Settings_Files_Analysis_Tool_File_Name] ON [dbo].[T_Settings_Files] 
(
	[Analysis_Tool] ASC,
	[File_Name] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO
GRANT DELETE ON [dbo].[T_Settings_Files] TO [Limited_Table_Write]
GO
GRANT INSERT ON [dbo].[T_Settings_Files] TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Settings_Files] TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Settings_Files] TO [Limited_Table_Write]
GO
ALTER TABLE [dbo].[T_Settings_Files]  WITH CHECK ADD  CONSTRAINT [FK_T_Settings_Files_T_Settings_Files] FOREIGN KEY([Analysis_Tool])
REFERENCES [T_Analysis_Tool] ([AJT_toolName])
GO
