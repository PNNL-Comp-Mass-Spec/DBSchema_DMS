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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT DELETE ON [dbo].[T_Internal_Std_Parent_Mixes] TO [Limited_Table_Write] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Internal_Std_Parent_Mixes] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Internal_Std_Parent_Mixes] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Internal_Std_Parent_Mixes] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[T_Internal_Std_Parent_Mixes] TO [Limited_Table_Write] AS [dbo]
GO
