/****** Object:  Table [dbo].[T_Annotation_Keys] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Annotation_Keys](
	[Key_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Annotation_Keys] PRIMARY KEY CLUSTERED 
(
	[Key_Name] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
