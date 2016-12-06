/****** Object:  Table [dbo].[T_Modification_Types] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Modification_Types](
	[Mod_Type_Symbol] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Mod_Type_Synonym] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Modification_Types] PRIMARY KEY CLUSTERED 
(
	[Mod_Type_Symbol] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Modification_Types] TO [DDL_Viewer] AS [dbo]
GO
