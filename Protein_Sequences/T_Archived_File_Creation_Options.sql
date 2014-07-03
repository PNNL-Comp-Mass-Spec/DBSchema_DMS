/****** Object:  Table [dbo].[T_Archived_File_Creation_Options] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Archived_File_Creation_Options](
	[Creation_Option_ID] [int] IDENTITY(1,1) NOT NULL,
	[Keyword_ID] [int] NOT NULL,
	[Value_ID] [int] NOT NULL,
	[Archived_File_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Archived_File_Creation_Options] PRIMARY KEY CLUSTERED 
(
	[Creation_Option_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
