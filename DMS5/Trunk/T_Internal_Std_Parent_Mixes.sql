/****** Object:  Table [dbo].[T_Internal_Std_Parent_Mixes] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Internal_Std_Parent_Mixes](
	[Parent_Mix_ID] [int] NOT NULL,
	[Name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Protein_Collection_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Internal_Std_Mixes] PRIMARY KEY CLUSTERED 
(
	[Parent_Mix_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
