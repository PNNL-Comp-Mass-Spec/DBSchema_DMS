/****** Object:  Table [dbo].[T_Settings_Files] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Settings_Files](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Analysis_Tool] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[File_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Settings_Files] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
