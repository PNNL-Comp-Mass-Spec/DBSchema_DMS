/****** Object:  Table [dbo].[T_Modification_Types] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Modification_Types](
	[Mod_Type_Symbol] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Modification_Types] PRIMARY KEY CLUSTERED 
(
	[Mod_Type_Symbol] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
