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
 CONSTRAINT [PK_T_Settings_Files] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Settings_Files]  WITH CHECK ADD  CONSTRAINT [FK_T_Settings_Files_T_Settings_Files] FOREIGN KEY([Analysis_Tool])
REFERENCES [T_Analysis_Tool] ([AJT_toolName])
GO
ALTER TABLE [dbo].[T_Settings_Files] CHECK CONSTRAINT [FK_T_Settings_Files_T_Settings_Files]
GO
